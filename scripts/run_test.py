#!/usr/bin/env python3
"""Fail CI for simulator errors, UVM errors/fatals, or missing completion."""
import argparse
from pathlib import Path
import re
import subprocess
from check_vcd import check_vcd

parser = argparse.ArgumentParser()
parser.add_argument('--seed', type=int, action='append', required=True)
args = parser.parse_args()
for seed in args.seed:
    wave = Path(f'build/counter_seed_{seed}.vcd')
    wave.unlink(missing_ok=True)
    log = Path(f'build/run_seed_{seed}.log')
    with log.open('w') as output:
        try:
            result = subprocess.run(
                ['./build/obj/Vtb_top', f'+verilator+seed+{seed}', f'+WAVE_FILE={wave}'],
                stdout=output, stderr=subprocess.STDOUT, text=True, timeout=120)
        except subprocess.TimeoutExpired:
            raise SystemExit(f'FAIL seed={seed}: timeout; see {log}')
    result.stdout = log.read_text()
    print(result.stdout)
    clean = all(re.search(rf'UVM_{severity}\s*:\s*0\b', result.stdout)
                for severity in ('ERROR', 'FATAL'))
    if result.returncode or not clean or '[COUNTER_STATS]' not in result.stdout:
        raise SystemExit(f'FAIL seed={seed}: simulator/UVM failure or incomplete run')
    if not wave.is_file() or wave.stat().st_size == 0:
        raise SystemExit(f'FAIL seed={seed}: missing waveform')
    stats = check_vcd(wave)
    print(f'PASS seed={seed}; waveform={wave}; independently checked={stats}')
