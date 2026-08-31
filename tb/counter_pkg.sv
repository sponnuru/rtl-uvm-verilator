`timescale 1ns/1ps
package counter_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class counter_item extends uvm_sequence_item;
    `uvm_object_utils(counter_item)
    bit rst_n;
    bit enable;
    bit [7:0] count;
    function new(string name = "counter_item"); super.new(name); endfunction
  endclass

  class counter_sequence extends uvm_sequence #(counter_item);
    `uvm_object_utils(counter_sequence)
    function new(string name = "counter_sequence"); super.new(name); endfunction
    task send(bit reset_n, bit en);
      counter_item item = counter_item::type_id::create("item");
      start_item(item);
      item.rst_n = reset_n;
      item.enable = en;
      finish_item(item);
    endtask
    task body();
      // Directed reset, hold, increment, overflow, and reset while enabled.
      repeat (3) send(0, 0);
      repeat (5) send(1, 0);
      repeat (260) send(1, 1);
      repeat (5) send(1, 0);
      send(0, 1);
      // Seed-controlled stimulus without an external constraint solver.
      repeat (500) send($urandom_range(0, 19) != 0, $urandom_range(0, 1) != 0);
    endtask
  endclass

  class counter_driver extends uvm_driver #(counter_item);
    `uvm_component_utils(counter_driver)
    virtual counter_if vif;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual counter_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "counter_if was not configured")
    endfunction
    task run_phase(uvm_phase phase);
      forever begin
        seq_item_port.get_next_item(req);
        @(negedge vif.clk);
        vif.rst_n = req.rst_n;
        vif.enable = req.enable;
        @(posedge vif.clk);
        #2ns; // Monitor samples at +1 ns, before transaction completion.
        seq_item_port.item_done();
      end
    endtask
  endclass

  class counter_monitor extends uvm_monitor;
    `uvm_component_utils(counter_monitor)
    virtual counter_if vif;
    uvm_analysis_port #(counter_item) ap;
    function new(string name, uvm_component parent);
      super.new(name, parent); ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual counter_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "counter_if was not configured")
    endfunction
    task run_phase(uvm_phase phase);
      forever begin
        counter_item sample;
        @(posedge vif.clk);
        #1ns; // Observe the completed nonblocking RTL update.
        sample = counter_item::type_id::create("sample");
        sample.rst_n = vif.rst_n;
        sample.enable = vif.enable;
        sample.count = vif.count;
        ap.write(sample);
      end
    endtask
  endclass

  class counter_scoreboard extends uvm_subscriber #(counter_item);
    `uvm_component_utils(counter_scoreboard)
    bit [7:0] expected;
    int unsigned checked, resets, holds, increments, wraps;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void write(counter_item t);
      if (!t.rst_n) begin expected = 0; resets++; end
      else if (t.enable) begin
        if (expected == 8'hff) wraps++;
        expected = expected + 8'd1;
        increments++;
      end else holds++;
      checked++;
      if (t.count !== expected)
        `uvm_error("MISMATCH", $sformatf("sample=%0d reset_n=%b enable=%b expected=%0d actual=%0d",
          checked, t.rst_n, t.enable, expected, t.count))
    endfunction
    function void check_phase(uvm_phase phase);
      super.check_phase(phase);
      if (checked < 774 || resets == 0 || holds == 0 || increments == 0 || wraps == 0)
        `uvm_error("COVERAGE", "Missing transactions or required counter scenarios")
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("COUNTER_STATS", $sformatf("checked=%0d resets=%0d holds=%0d increments=%0d wraps=%0d",
        checked, resets, holds, increments, wraps), UVM_LOW)
    endfunction
  endclass

  class counter_env extends uvm_env;
    `uvm_component_utils(counter_env)
    uvm_sequencer #(counter_item) sequencer;
    counter_driver driver;
    counter_monitor monitor;
    counter_scoreboard scoreboard;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      sequencer = new("sequencer", this);
      driver = counter_driver::type_id::create("driver", this);
      monitor = counter_monitor::type_id::create("monitor", this);
      scoreboard = counter_scoreboard::type_id::create("scoreboard", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      driver.seq_item_port.connect(sequencer.seq_item_export);
      monitor.ap.connect(scoreboard.analysis_export);
    endfunction
  endclass

  class counter_test extends uvm_test;
    `uvm_component_utils(counter_test)
    counter_env env;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = counter_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      counter_sequence seq = counter_sequence::type_id::create("seq");
      phase.raise_objection(this);
      seq.start(env.sequencer);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
