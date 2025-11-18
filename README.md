# Gaussian-Filter
This project implements a Gaussian Filter–based image processing system on an FPGA using HDL for the datapath and CORDIC IP for exponential computation.
The design reads image data from BRAM, performs a 3×3 Gaussian convolution, computes the exponential of the filtered output using Vivado’s CORDIC (Hyperbolic Mode) IP core, and finally streams the processed pixel data to a host PC using a UART interface.
