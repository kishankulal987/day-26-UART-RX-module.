`timescale 1ns / 1ps

`define baud_rate 4

module UART_rx (
    input clk,
    input reset,
    input rx,
    output reg [7:0] dout,
    output reg done
);
    localparam idle = 2'b00;
    localparam start = 2'b10;
    localparam data = 2'b01;
    localparam stop = 2'b11;

    reg [1:0] state;
    reg [9:0] baud_cntr;
    reg [2:0] bit_cntr;
    reg [7:0] shift_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= idle;
            baud_cntr <= 0;
            bit_cntr <= 0;
            shift_reg <= 8'b0;
            dout <= 8'b0;
            done <= 0;
        end else begin
            done <= 0; 
            case (state)
                idle: begin
                    if (rx == 0) begin
                        state <= start;
                        baud_cntr <= `baud_rate - 1; // Reset for start bit
                    end else begin
                        baud_cntr <= 0;
                    end
                end
                start: begin
                    if (baud_cntr == `baud_rate/2) begin // Sample mid-bit (2 cycles)
                        if (rx == 0) begin // Confirm start bit
                            state <= data;
                            baud_cntr <= `baud_rate - 1;
                            bit_cntr <= 0;
                        end else begin
                            state <= idle;
                        end
                    end else begin
                        baud_cntr <= baud_cntr - 1;
                    end
                end
                data: begin
                    if (baud_cntr == 0) begin // Sample at end of bit period
                        shift_reg <= {rx, shift_reg[7:1]};
                        bit_cntr <= bit_cntr + 1;
                        baud_cntr <= `baud_rate - 1;
                        if (bit_cntr == 7) begin
                            state <= stop;
                        end
                    end else begin
                        baud_cntr <= baud_cntr - 1;
                    end
                end
                stop: begin
                    if (baud_cntr == 0) begin // Sample at end of bit period
                        if (rx == 1) begin 
                            dout <= shift_reg;
                            done <= 1;
                        end
                        state <= idle;
                        baud_cntr <= `baud_rate - 1;
                    end else begin
                        baud_cntr <= baud_cntr - 1;
                    end
                end
                default: state <= idle;
            endcase
        end
    end
endmodule

//________________________testbench______________________//
`timescale 1ns / 1ps

module uart_rx_tb;

    // Testbench signals
    reg clk;
    reg reset;
    reg rx;
    wire [7:0] dout;
    wire done;

    // Instantiate the UART RX module
    UART_rx uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .dout(dout),
        .done(done)
    );

    // Clock generation: 4ns period (250 MHz)
    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        rx = 1; // Idle state (high)
        #20;
        
        // Release reset
        reset = 0;
        #20;

        // Send byte 0xA5 (10100101 in binary)
        // Start bit (0)
        rx = 0;
        #16; // 4 clock cycles (baud_rate = 4 at 250 MHz)

        // Data bits (LSB first: 1,0,1,0,0,1,0,1)
        rx = 1; #16; // Bit 0
        rx = 0; #16; // Bit 1
        rx = 1; #16; // Bit 2
        rx = 0; #16; // Bit 3
        rx = 0; #16; // Bit 4
        rx = 1; #16; // Bit 5
        rx = 0; #16; // Bit 6
        rx = 1; #16; // Bit 7

        // Stop bit (1)
        rx = 1; #16;

        // Wait for processing
        #16;

        // Check results
        if (dout == 8'hA5)
            $display("Test Passed: Received dout = 0x%h, done = %b", dout, done);
        else
            $display("Test Failed: Expected dout = 0xA5, done = 1, but got dout = 0x%h, done = %b", dout, done);

        // End simulation
        #20;
        $finish;
    end

endmodule