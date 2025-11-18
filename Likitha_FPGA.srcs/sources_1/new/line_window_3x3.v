`timescale 1ns / 1ps
module line_window_3x3 #
(
    parameter PIX_W = 8,         // Bits per pixel
    parameter IMG_W = 64         // Image width in pixels (default to 64)
)
(
    input  wire                  clk,
    input  wire                  rstn,

    input  wire [PIX_W-1:0]      in_pixel,        // Pixel from BRAM
    input  wire                  in_valid,        // 1 clock per pixel

    output reg  [PIX_W-1:0]      w00, w01, w02,
    output reg  [PIX_W-1:0]      w10, w11, w12,
    output reg  [PIX_W-1:0]      w20, w21, w22,
    output reg                   out_valid
);

    // width for column counter derived from IMG_W
    localparam COL_W = (IMG_W<=1) ? 1 : $clog2(IMG_W);

    // ------------------------------------------------------------
    // Line Buffers (store previous 2 rows)
    // ------------------------------------------------------------
    reg [PIX_W-1:0] linebuf1 [0:IMG_W-1];
    reg [PIX_W-1:0] linebuf2 [0:IMG_W-1];

    // Horizontal shift registers for the 3 rows
    reg [PIX_W-1:0] row1_shift [0:2];
    reg [PIX_W-1:0] row2_shift [0:2];
    reg [PIX_W-1:0] row3_shift [0:2];

    // column and row counters
    reg [COL_W-1:0] col;
    reg [15:0] row;  // image height unknown, keep generous width

    integer i;

    // optional: zero line buffers on reset to avoid X's in simulation
    // (large loops can cost on synthesis compile time but are okay for small IMG_W)
    // You can comment this block if synthesis complains about initialization loops.
    always @(posedge clk) begin
        if (!rstn) begin
            col <= 0;
            row <= 0;
            out_valid <= 0;
            // clear shifts
            row1_shift[0] <= 0; row1_shift[1] <= 0; row1_shift[2] <= 0;
            row2_shift[0] <= 0; row2_shift[1] <= 0; row2_shift[2] <= 0;
            row3_shift[0] <= 0; row3_shift[1] <= 0; row3_shift[2] <= 0;
            // optional clear line buffers (uncomment if desired)
            for (i = 0; i < IMG_W; i = i + 1) begin
                linebuf1[i] <= {PIX_W{1'b0}};
                linebuf2[i] <= {PIX_W{1'b0}};
            end
        end
        else if (in_valid) begin

            // ------------------------------
            // READ / SHIFT (handle new-row specially)
            // ------------------------------
            if (col == 0) begin
                // Start of row: avoid wrapping by initializing shift regs
                // read current column (0) from line buffers
                row1_shift[0] <= linebuf2[0];
                row1_shift[1] <= linebuf2[0];
                row1_shift[2] <= linebuf2[0];

                row2_shift[0] <= linebuf1[0];
                row2_shift[1] <= linebuf1[0];
                row2_shift[2] <= linebuf1[0];

                // current row: load current pixel into all three positions
                row3_shift[0] <= in_pixel;
                row3_shift[1] <= in_pixel;
                row3_shift[2] <= in_pixel;
            end
            else begin
                // Normal pixel in row: fetch the pixel at this column,
                // then shift left (older pixels move to higher indices)
                row1_shift[0] <= linebuf2[col];
                row1_shift[1] <= row1_shift[0];
                row1_shift[2] <= row1_shift[1];

                row2_shift[0] <= linebuf1[col];
                row2_shift[1] <= row2_shift[0];
                row2_shift[2] <= row2_shift[1];

                row3_shift[0] <= in_pixel;
                row3_shift[1] <= row3_shift[0];
                row3_shift[2] <= row3_shift[1];
            end

            // ------------------------------
            // WRITE current pixel into line buffers (shift rows)
            // linebuf2 <= previous linebuf1; linebuf1 <= in_pixel;
            // ------------------------------
            linebuf2[col] <= linebuf1[col];
            linebuf1[col] <= in_pixel;

            // ------------------------------
            // Window outputs (after shift update)
            // ------------------------------
            w00 <= row1_shift[2];  w01 <= row1_shift[1];  w02 <= row1_shift[0];
            w10 <= row2_shift[2];  w11 <= row2_shift[1];  w12 <= row2_shift[0];
            w20 <= row3_shift[2];  w21 <= row3_shift[1];  w22 <= row3_shift[0];

            // ------------------------------
            // Update column and row counters
            // ------------------------------
            if (col == IMG_W - 1) begin
                col <= {COL_W{1'b0}};
                row <= row + 1;
            end else begin
                col <= col + 1;
            end

            // ------------------------------
            // Assert out_valid only when full 3x3 is available
            // (row >= 2 and col >= 2)
            // Note: we must consider that 'col' used here is the column index
            // *before* the increment -- this code uses the updated shift registers
            // so checking row>=2 and col>=2 is correct for the sample being output.
            // ------------------------------
            if (row >= 2 && col >= 2)
                out_valid <= 1'b1;
            else
                out_valid <= 1'b0;
        end
    end

endmodule
