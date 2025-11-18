`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.11.2025 00:07:53
// Design Name: 
// Module Name: uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// uart_tx.v
// Simple byte-wise UART transmitter (start + 8 data bits + 1 stop)
// Assumes clk = 100 MHz and default BAUD = 115200
module uart_tx #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire       rstn,
    input  wire       tx_start,   // pulse 1 cycle to start sending tx_data
    input  wire [7:0] tx_data,
    output reg        tx,         // UART TX pin (idle = 1)
    output reg        tx_busy     // high while transmitting
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // width enough for CLKS_PER_BIT
    localparam integer CNT_W = $clog2(CLKS_PER_BIT+1);

    reg [CNT_W-1:0] clk_cnt;
    reg [3:0]       bit_index;    // 0..9 (start + 8 data + stop)
    reg [9:0]       shift_reg;    // {stop(1), data[7:0], start(0)}

    // reset / idle
    initial begin
        tx = 1'b1;
        tx_busy = 1'b0;
        clk_cnt = 0;
        bit_index = 0;
        shift_reg = 10'b1111111111;
    end

    always @(posedge clk) begin
        if (!rstn) begin
            tx <= 1'b1;
            tx_busy <= 1'b0;
            clk_cnt <= 0;
            bit_index <= 0;
            shift_reg <= 10'b1111111111;
        end else begin
            if (tx_start && !tx_busy) begin
                // load frame: LSB first: start(0), data[7:0], stop(1)
                shift_reg <= {1'b1, tx_data, 1'b0}; // shift_reg[0] -> start bit
                tx_busy <= 1'b1;
                clk_cnt <= 0;
                bit_index <= 0;
            end

            if (tx_busy) begin
                if (clk_cnt < CLKS_PER_BIT - 1) begin
                    clk_cnt <= clk_cnt + 1;
                end else begin
                    clk_cnt <= 0;
                    tx <= shift_reg[bit_index];
                    bit_index <= bit_index + 1;
                    if (bit_index == 9) begin
                        tx_busy <= 1'b0;
                        bit_index <= 0;
                    end
                end
            end
        end
    end

endmodule

