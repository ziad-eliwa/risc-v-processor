#!/usr/bin/env bash
# Compile and run testbenches with Icarus Verilog.
#   scripts/run_tests.sh            -> every tb/tb_*.v (and .sv)
#   scripts/run_tests.sh tb_alu     -> just tb/tb_alu.v
#
# Convention every testbench must follow:
#   - print a line containing "FAIL" for each failed check
#   - print "TEST PASSED" at the very end only if nothing failed
# iverilog/vvp return exit code 0 even when checks fail, so we decide
# pass/fail by reading the log.
set -uo pipefail
cd "$(dirname "$0")/.."          # always run from repo root so $readmemh paths like "sw/prog.hex" work

OUT=build/sim
TIMEOUT=${SIM_TIMEOUT:-120}      # seconds per testbench, catches infinite loops
mkdir -p "$OUT"

mapfile -t RTL < <(find rtl \( -name '*.v' -o -name '*.sv' \) 2>/dev/null | sort)

if [ $# -gt 0 ]; then
  TBS=()
  for n in "$@"; do TBS+=("tb/$n.v"); done
else
  shopt -s nullglob
  TBS=(tb/tb_*.v tb/tb_*.sv)
fi

if [ ${#TBS[@]} -eq 0 ]; then
  echo "No testbenches found (expected tb/tb_*.v)"
  exit 1
fi

passed=(); failed=()
for tb in "${TBS[@]}"; do
  name=$(basename "${tb%.*}")
  echo "=== $name ==="

  if ! iverilog -g2012 -Wall -Wno-timescale -Irtl -s "$name" -o "$OUT/$name.vvp" "${RTL[@]}" "$tb" 2>&1 \
        | tee "$OUT/$name.compile.log"; then
    failed+=("$name (compile error)"); continue
  fi

  timeout "$TIMEOUT" vvp -n "$OUT/$name.vvp" 2>&1 | tee "$OUT/$name.log"
  rc=${PIPESTATUS[0]}

  if [ "$rc" -eq 124 ]; then
    failed+=("$name (timeout after ${TIMEOUT}s)")
  elif [ "$rc" -ne 0 ]; then
    failed+=("$name (simulator exit code $rc)")
  elif grep -q 'FAIL' "$OUT/$name.log"; then
    failed+=("$name (check failed)")
  elif ! grep -q 'TEST PASSED' "$OUT/$name.log"; then
    failed+=("$name (no 'TEST PASSED' line, did it reach the end?)")
  else
    passed+=("$name")
  fi
done

echo
echo "================ SUMMARY ================"
echo "passed: ${#passed[@]}   failed: ${#failed[@]}"
for f in "${failed[@]}"; do echo "  FAILED: $f"; done
[ ${#failed[@]} -eq 0 ]