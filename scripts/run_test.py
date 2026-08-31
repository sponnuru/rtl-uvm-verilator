#!/usr/bin/env python3
"""Fail CI for simulator errors, UVM errors/fatals, or missing completion."""
import argparse
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--seed', type=int, action='append', required=True)
args = parser.parse_args()
for seed in args.seed:
    result = subprocess.run(
        ['./build/obj/Vtb_top', f'+verilator+seed+{seed}'],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
    Path(f'build/run_seed_{seed}.log').write_text(result.stdout)
    print(result.stdout)
    clean = all(re.search(rf'UVM_{severity}\s*:\s*0\b', result.stdout)
                for severity in ('ERROR', 'FATAL'))
    if result.returncode or not clean or '[COUNTER_STATS]' not in result.stdout:
        raise SystemExit(f'FAIL seed={seed}: simulator/UVM failure or incomplete run')
    print(f'PASS seed={seed}')
