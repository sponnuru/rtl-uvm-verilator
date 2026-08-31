VERILATOR ?= verilator
UVM_HOME ?= $(CURDIR)/third_party/uvm
JOBS ?= 4
SEED ?= 1
SOURCES = rtl/counter.sv tb/counter_if.sv tb/counter_pkg.sv tb/tb_top.sv

.PHONY: all build run test clean
all: test
build: build/obj/Vtb_top
build/obj/Vtb_top: $(SOURCES) Makefile $(UVM_HOME)/src/uvm_pkg.sv
	mkdir -p build
	$(VERILATOR) --binary --timing --assert -j $(JOBS) --top-module tb_top \
	  --Mdir build/obj -Wno-fatal +define+UVM_NO_DPI +incdir+$(UVM_HOME)/src \
	  $(UVM_HOME)/src/uvm_pkg.sv $(SOURCES) > build/compile.log 2>&1 || \
	  { tail -80 build/compile.log; exit 1; }
run: build
	python3 scripts/run_test.py --seed $(SEED)
test: build
	python3 scripts/run_test.py --seed 1 --seed 42 --seed 2026
clean:
	rm -rf build
