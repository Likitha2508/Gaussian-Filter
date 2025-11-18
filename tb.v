`timescale 1ns/1ps

module top_tb;

    reg clk = 0;        // 100 MHz input clock
    wire tx;            // UART output from DUT

    // Clock generation: 100 MHz (10 ns period)
    always #5 clk = ~clk;

    // Instantiate DUT
    top dut (
        .clk(clk),
        .tx(tx)
    );

    // =========================================================================
    // UART RECEIVER (BEHAVIORAL) - No X, and `i` will NOT be shown in waveform
    // =========================================================================
    localparam UART_BAUD      = 115200;
    localparam UART_CLK_HZ    = 25_000_000;
    localparam BIT_PERIOD_NS  = 1_000_000_000 / UART_BAUD;

    reg [7:0] received_byte = 8'd0;
    integer i = 0;               // required internally, but NOT dumped

    // Detect Start Bit (falling edge on TX)
    always @(negedge tx) begin
        #(BIT_PERIOD_NS + BIT_PERIOD_NS/2);

        received_byte = 8'd0;

        // Sample 8 data bits
        for (i = 0; i < 8; i = i + 1) begin
            #(BIT_PERIOD_NS);
            received_byte[i] = tx;
        end

        #(BIT_PERIOD_NS); // Skip stop bit

        $display("UART BYTE RECEIVED = %0d (0x%02h) @ %0t ns",
                  received_byte, received_byte, $time);
    end

    // =========================================================================
    // SIMULATION CONTROL
    // =========================================================================
    initial begin
        $dumpfile("top_tb.vcd");

        // dump EVERYTHING EXCEPT i
        $dumpvars(0, top_tb);
        $dumpvars(0, dut);       // but NOT "i"

        $display("==== Simulation Started ====");

        #10_000_000;
        $display("==== Simulation Finished ====");
        $finish;
    end

endmodule
