`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  import counter_pkg::*;
  bit clk = 0;
  always #5ns clk = ~clk;
  counter_if vif(clk);
  counter dut(.clk(clk), .rst_n(vif.rst_n), .enable(vif.enable), .count(vif.count));
  initial begin
    uvm_config_db#(virtual counter_if)::set(null, "uvm_test_top.env.*", "vif", vif);
    run_test("counter_test");
  end
  initial begin
    #100us;
    $fatal(1, "Simulation watchdog expired");
  end
endmodule
