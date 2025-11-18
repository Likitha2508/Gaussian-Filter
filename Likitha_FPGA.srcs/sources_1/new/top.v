`timescale 1ns / 1ps

// top.v
// BRAM (64x64 image) → line_window_3x3 → gaussian_3x3 → cordic(exp) → UART
// Interleaves GAUSSIAN and EXP pixels over UART.

module top(
    input  wire clk,     // 100 MHz Basys-3 clock
    output wire tx       // UART TX output
);

//////////////////////////////////////////////////////////////
// 25 MHz Clock Divider (100MHz → 25MHz)
//////////////////////////////////////////////////////////////
reg [1:0] div = 0;
always @(posedge clk)
    div <= div + 1'b1;

wire slow_clk = div[1];


//////////////////////////////////////////////////////////////
// BRAM Address Generator (row*64 + col)
//////////////////////////////////////////////////////////////
reg  [5:0] col = 0;     // 0..63
reg  [5:0] row = 0;     // 0..63
wire [11:0] bram_addr = {row, col};

wire [7:0] bram_douta;

blk_mem_gen_0 image_bram (
    .clka(slow_clk),
    .ena(1'b1),
    .wea(1'b0),
    .addra(bram_addr),
    .dina(8'd0),
    .douta(bram_douta)
);

always @(posedge slow_clk) begin
    if (col == 6'd63) begin
        col <= 0;
        if (row == 6'd63)
            row <= 0;
        else
            row <= row + 1'b1;
    end 
    else begin
        col <= col + 1'b1;
    end
end


//////////////////////////////////////////////////////////////
// 3×3 Line Window (IMG_W=64)
//////////////////////////////////////////////////////////////
wire [7:0] w00, w01, w02;
wire [7:0] w10, w11, w12;
wire [7:0] w20, w21, w22;
wire       win_valid;

line_window_3x3 #(
    .PIX_W(8),
    .IMG_W(64)
) lw_inst (
    .clk(slow_clk),
    .rstn(1'b1),
    .in_pixel(bram_douta),
    .in_valid(1'b1),

    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22),

    .out_valid(win_valid)
);


//////////////////////////////////////////////////////////////
// Gaussian 3×3 Filter
//////////////////////////////////////////////////////////////
wire [15:0] gauss_out;
wire        gauss_valid;

gaussian_3x3 g3_inst (
    .clk(slow_clk),
    .rstn(1'b1),
    .in_valid(win_valid),

    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22),

    .out_valid(gauss_valid),
    .pixel_out(gauss_out)
);


//////////////////////////////////////////////////////////////
// CORDIC EXP: exp(x) = cosh(x) + sinh(x)
//////////////////////////////////////////////////////////////
localparam integer PHASE_FRAC = 15;

// Use LSB 8 bits of gaussian output
wire signed [15:0] gauss_signed   = {8'b0, gauss_out[7:0]};
wire signed [15:0] gauss_centered = gauss_signed - 16'sd128;

// Scale by 4 (<<<2)
wire signed [15:0] phase_unreg = gauss_centered <<< 2;

// Register CORDIC input
reg signed [15:0] s_axis_phase_tdata = 16'sd0;
reg               s_axis_phase_tvalid = 1'b0;

always @(posedge slow_clk) begin
    s_axis_phase_tvalid <= gauss_valid;
    if (gauss_valid)
        s_axis_phase_tdata <= phase_unreg;
end

// CORDIC output (64 bits)
wire [63:0] cordic_out_tdata;
wire        cordic_out_valid;

cordic_0 cordic_inst (
    .aclk(slow_clk),
    .s_axis_phase_tvalid(s_axis_phase_tvalid),
    .s_axis_phase_tdata(s_axis_phase_tdata),
    .m_axis_dout_tvalid(cordic_out_valid),
    .m_axis_dout_tdata(cordic_out_tdata)
);

wire signed [31:0] cosh_val = cordic_out_tdata[31:0];
wire signed [31:0] sinh_val = cordic_out_tdata[63:32];

wire signed [32:0] exp_raw = cosh_val + sinh_val;

// Normalize
wire signed [31:0] exp_norm = exp_raw >>> 20;

reg [7:0] exp_pixel_reg;
always @(posedge slow_clk) begin
    if (cordic_out_valid) begin
        if (exp_norm < 0)
            exp_pixel_reg <= 8'd0;
        else if (exp_norm > 32'sd255)
            exp_pixel_reg <= 8'd255;
        else
            exp_pixel_reg <= exp_norm[7:0];
    end
end


//////////////////////////////////////////////////////////////
// Gaussian 8-bit pixel register
//////////////////////////////////////////////////////////////
reg [7:0] gauss_pixel_reg;

always @(posedge slow_clk) begin
    if (gauss_valid)
        gauss_pixel_reg <= gauss_out[7:0];
end


//////////////////////////////////////////////////////////////
// UART Transmitter - Interleaves GAUSS then EXP
//////////////////////////////////////////////////////////////
wire tx_busy;
reg  tx_start = 0;
reg  [7:0] tx_data = 8'd0;

uart_tx #(
    .CLK_FREQ(25_000_000),
    .BAUD_RATE(115200)
) uart_inst (
    .clk(slow_clk),
    .rstn(1'b1),
    .tx_start(tx_start),
    .tx_data(tx_data),
    .tx(tx),
    .tx_busy(tx_busy)
);

// Ready flags
reg gauss_ready = 0;
reg exp_ready   = 0;

always @(posedge slow_clk) begin
    if (gauss_valid)
        gauss_ready <= 1'b1;

    if (cordic_out_valid)
        exp_ready <= 1'b1;

    tx_start <= 1'b0;

    if (!tx_busy) begin
        if (gauss_ready) begin
            tx_data  <= gauss_pixel_reg;
            tx_start <= 1'b1;
            gauss_ready <= 1'b0;
        end
        else if (exp_ready) begin
            tx_data  <= exp_pixel_reg;
            tx_start <= 1'b1;
            exp_ready <= 1'b0;
        end
    end
end

endmodule