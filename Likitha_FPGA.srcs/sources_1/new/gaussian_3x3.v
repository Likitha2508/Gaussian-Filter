`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.11.2025 23:22:57
// Design Name: 
// Module Name: gaussian_3x3
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

module gaussian_3x3(
    input  wire        clk,
    input  wire        rstn,

    input  wire        in_valid,
    input  wire [7:0]  w00, w01, w02,
    input  wire [7:0]  w10, w11, w12,
    input  wire [7:0]  w20, w21, w22,

    output reg         out_valid,
    output reg [15:0]  pixel_out
);

    wire [15:0] sum;

    assign sum =
        (w00*1) + (w01*2) + (w02*1) +
        (w10*2) + (w11*4) + (w12*2) +
        (w20*1) + (w21*2) + (w22*1);

    always @(posedge clk) begin
        if(!rstn) begin
            pixel_out <= 0;
            out_valid <= 0;
        end else begin
            if(in_valid) begin
                pixel_out <= sum >> 4;   // divide by 16
                out_valid <= 1;
            end else begin
                out_valid <= 0;
            end
        end
    end

endmodule

