# RTL counter with a SystemVerilog UVM testbench

A small synthesizable 8-bit up-counter, verified using the real Accellera UVM
library from the Verilator UVM repository. No substitute/mock UVM framework is used.

## Design

At each rising clock edge, active-low **synchronous** reset clears `count`.
Otherwise `enable=1` increments it modulo 256; `enable=0` holds its value.
Reset takes priority over enable.

## Testbench

`counter_sequence -> sequencer -> driver -> DUT -> monitor -> scoreboard`

The UVM environment uses factory registration, a virtual interface passed through
`uvm_config_db`, a sequence/driver handshake, an analysis connection, run-phase
objections, and UVM error reporting. The scoreboard independently predicts every
sample and checks that reset, hold, increment, and wraparound all occur.

Each seed sends 774 transactions: initial resets, disabled cycles, 260 consecutive
increments to force overflow, a hold, reset with enable asserted, and 500 random
cycles. Random stimulus uses `$urandom_range`, so no external SMT solver is needed.
The monitor also checks the initial clock edge before the first transaction.
Drivers update on falling edges; the monitor samples 1 ns after rising edges to
avoid nonblocking-assignment races. A 100 us watchdog catches deadlocks.

## Run

Prerequisites: Verilator 5.050, a C++ compiler supporting C++20, GNU Make, Python 3,
and Git. The UVM dependency is pinned as a Git submodule.

```sh
git clone --recurse-submodules https://github.com/sponnuru/rtl-uvm-verilator.git
cd rtl-uvm-verilator
make test             # seeds 1, 42, 2026
make run SEED=123     # one seed
```

For an existing checkout: `git submodule update --init --recursive`.
Use `make test VERILATOR=/absolute/path/to/verilator` to select a local simulator.
The compile command uses `--binary --timing --assert` and `UVM_NO_DPI` (no DPI
features are needed by this example). Build output is in `build/compile.log`;
each run has its own `build/run_seed_<seed>.log`.

The runner fails on a nonzero simulator exit code, UVM errors/fatals, a missing
scoreboard report, or a timeout. A normal `$finish` alone does not count as success.
This is a teaching example; it does not exercise all UVM or SystemVerilog features.

## Files

- `rtl/counter.sv`: synthesizable DUT.
- `tb/counter_if.sv`: signal interface.
- `tb/counter_pkg.sv`: transaction, sequence, driver, monitor, scoreboard, environment, test.
- `tb/tb_top.sv`: DUT wiring, clock, UVM startup, watchdog.
- `scripts/run_test.py`: regression execution and result validation.
- `.github/workflows/simulate.yml`: reproducible Linux compile and regression.
- `results/`: recorded local validation results.

## Dependency sources

- Verilator: https://github.com/verilator/verilator (5.050, commit `848d926ebd4addacacd294dc84e35d9d4ae8078c`).
- UVM: https://github.com/verilator/uvm (commit recorded in the submodule).

The UVM dependency retains its upstream Apache-2.0 license and notices.

## Verified results

All three seeds passed locally with 775 checked samples per seed and zero UVM
errors/fatals. See [results/VALIDATION.md](results/VALIDATION.md) for the exact
tool versions, scenario counts, warnings, and captured logs.
