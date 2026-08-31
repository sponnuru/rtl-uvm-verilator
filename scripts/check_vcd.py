#!/usr/bin/env python3
"""Independently check this counter's DUT signals at every rising edge in VCD."""
from pathlib import Path
import argparse


def check_vcd(path):
    scopes, ids, values, changes = [], {}, {}, {}
    now, previous_clk, expected = 0, 0, 0
    stats = dict(checked=0, resets=0, holds=0, increments=0, wraps=0)

    def sample():
        nonlocal previous_clk, expected
        values.update(changes)
        changes.clear()
        if not ids:
            return
        clk = values.get(ids['clk'], 0)
        if clk == 1 and previous_clk == 0:
            reset_n, en, count = (values[ids[k]] for k in ('rst_n', 'enable', 'count'))
            if not reset_n:
                expected = 0
                stats['resets'] += 1
            elif en:
                stats['wraps'] += expected == 255
                expected = (expected + 1) % 256
                stats['increments'] += 1
            else:
                stats['holds'] += 1
            assert count == expected, f'{path}: mismatch at {now} ps: {count} != {expected}'
            stats['checked'] += 1
        previous_clk = clk

    for line in Path(path).read_text().splitlines():
        words = line.split()
        if not words:
            continue
        if words[0] == '$scope':
            scopes.append(words[2])
        elif words[0] == '$upscope':
            scopes.pop()
        elif words[0] == '$var' and scopes[-1:] == ['dut']:
            if words[4] in ('clk', 'rst_n', 'enable', 'count'):
                ids[words[4]] = words[3]
        elif words[0] == '$enddefinitions':
            assert len(ids) == 4, f'{path}: missing DUT signals'
        elif line.startswith('#'):
            sample()
            now = int(line[1:])
        elif line[0] in '01xz' and line[1:] in ids.values():
            assert line[0] in '01', f'{path}: unknown signal value'
            changes[line[1:]] = int(line[0])
        elif line[0] == 'b' and len(words) == 2 and words[1] in ids.values():
            changes[words[1]] = int(words[0][1:], 2)
    sample()
    assert stats['checked'] == 775, f'{path}: incomplete trace: {stats}'
    assert all(stats[k] > 0 for k in ('resets', 'holds', 'increments', 'wraps')), stats
    assert now == 7747000, f'{path}: unexpected end time {now} ps'
    return stats


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('waveforms', nargs='+')
    for path in parser.parse_args().waveforms:
        print(f'WAVEFORM PASS {path}: {check_vcd(path)}; end=7747 ns')
