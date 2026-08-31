# Local validation — 2026-08-31

Compiled and executed successfully on macOS arm64 with Apple Clang 21.0.0,
Verilator 5.050 (848d926ebd4addacacd294dc84e35d9d4ae8078c), and UVM
2020.3.1 (656f20d087370a7c742e00188d20bbf30fa95339).

Command: `make test VERILATOR=<local-verilator>/bin/verilator JOBS=8`.

| Seed | Samples checked | Reset | Hold | Increment | Wrap | UVM errors | UVM fatals |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 775 | 31 | 254 | 490 | 1 | 0 | 0 |
| 42 | 775 | 26 | 260 | 489 | 1 | 0 | 0 |
| 2026 | 775 | 23 | 254 | 498 | 1 | 0 | 0 |

Each test finished at 7,747 ns. All regression runner checks passed.
There are 774 driven transactions plus one initial reset sample per run.

Known warnings: missing timescale on the upstream UVM package, an upstream
C++ `sprintf` deprecation warning, two UVM warnings about intentionally disabled
DPI/name-validation features, and a Verilator stack-size request that exceeds
macOS limits. None prevented these tests from completing. This does not imply
that every UVM feature is supported or that the design is exhaustively verified.

The adjacent compile and run logs are actual captured output; local installation
paths are replaced with `<project>` and `<verilator>` for portability.
GitHub Actions is separately configured to repeat the build on Linux.
