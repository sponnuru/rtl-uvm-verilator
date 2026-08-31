`timescale 1ns/1ps
interface counter_if(input logic clk);
  logic rst_n = 0;
  logic enable = 0;
  logic [7:0] count;
endinterface
