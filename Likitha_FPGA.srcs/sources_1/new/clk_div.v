`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.11.2025 00:18:13
// Design Name: 
// Module Name: clk_div
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


module clk_div(
    input wire clk_in,
    input wire rstn,
    output reg clk_out
);
    reg [1:0] cnt = 0;

    always @(posedge clk_in or negedge rstn) begin
        if(!rstn) begin
            cnt <= 0;
            clk_out <= 0;
        end else begin
            cnt <= cnt + 1;
            clk_out <= cnt[1];   // divide 100MHz by 4 → 25MHz
        end
    end
endmodule

