# UART Receiver in Verilog

## Overview

In this project, I implemented a UART (Universal Asynchronous Receiver-Transmitter) receiver in Verilog using a finite state machine. My goal was to create a circuit that receives an 8-bit data word framed by a start bit (0) and a stop bit (1) on the rx input, storing the data in dout and asserting done when complete. For example, with a baud rate of 4 clock cycles and input rx sequence 0_10100101_1 (representing 0xA5), the receiver outputs dout=0xA5 and done=1. I used a state machine with four states (idle, start, data, stop) and a baud rate counter to sample the input signal, and wrote a testbench to verify the functionality with a specific input byte. I confirmed the design works as expected through simulation.

### Module: UART_rx





### What I Did: I designed a UART receiver to capture an 8-bit data word from a serial input.



### Parameters:





baud_rate: Number of clock cycles per bit (defined as 4 for simulation).



## Inputs:





clk: Clock signal.



reset: Asynchronous reset signal.



rx: Serial input line.



## Outputs:





dout[7:0]: 8-bit received data.



done: Signal indicating successful reception.



## How It Works:





I implemented a finite state machine with four states:





idle (00): Waits for a start bit (rx=0).



start (10): Samples the start bit at its midpoint to confirm validity.



data (01): Samples 8 data bits into shift_reg.



stop (11): Samples the stop bit, outputs dout, and sets done.



A 10-bit baud_cntr counts down from baud_rate-1 (3) to 0 for each bit’s duration.



A 3-bit bit_cntr tracks the current data bit (0 to 7) in the data state.



An 8-bit shift_reg stores incoming data bits, shifting right with each sample.



On positive clock edge or reset:





If reset=1, state, baud_cntr, bit_cntr, shift_reg, dout, and done are cleared.



In idle, if rx=0, transition to start and reset baud_cntr.



In start, sample rx at baud_cntr=baud_rate/2 (2); if rx=0, proceed to data, else return to idle.



In data, when baud_cntr=0, shift rx into shift_reg, increment bit_cntr, and reset baud_cntr; after bit 7, transition to stop.



In stop, when baud_cntr=0, if rx=1, set dout=shift_reg and done=1, then return to idle.



### Style: Behavioral modeling with a finite state machine and sequential logic.

Testbench: uart_rx_tb





What I Did: I created a testbench to verify the UART receiver’s functionality.



## How It Works:





I generated a clock with a 4ns period (#2 clk = ~clk, 250 MHz).



I tested one scenario:





reset=1 for 20ns, then reset=0.



rx=1 (idle) initially, then sends 0_10100101_1 (start bit, 0xA5 LSB-first, stop bit), with each bit lasting 16ns (4 clock cycles).



After reception, checks if dout=0xA5 and done=1, displaying pass/fail.



Simulation runs for 188ns, ending with $finish.



I used $display to report the test result.



Time Scale: I set 1ns / 1ps for precise simulation timing.



Purpose: My testbench ensures the receiver correctly captures the data byte and asserts done at the appropriate time.

Files





UART_rx.v: Verilog module for the UART receiver.



uart_rx_tb.v: Testbench for simulation.




## Simulation Waveform

Below is the simulation waveform, showing inputs clk, reset, rx, and outputs dout[7:0], done, along with internal signals state, baud_cntr, bit_cntr, and shift_reg.


![Screenshot 2025-06-27 205958](https://github.com/user-attachments/assets/dfa1d0de-51e2-4bc2-8477-f0d463876848)


## Console Output

Below is the console output from my testbench simulation.

![Screenshot 2025-06-27 210431](https://github.com/user-attachments/assets/660cd179-0f80-49a4-a10e-beb1ed618244)

