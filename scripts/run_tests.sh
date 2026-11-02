#!/usr/bin/env bash
# Compile and run SystemVerilog testbenches with Verilator.
#   scripts/run_tests.sh         -> every tb/*_tb.v and tb/*_tb.sv
#   scripts/run_tests.sh alu_tb  -> just tb/alu_tb.v or tb/alu_tb.sv

set -uo pipefail
cd "$(dirname "$0")/.."

OUT=build/sim
OBJ_ROOT=${SIM_OBJ_DIR:-/tmp/riscv-processor-sim-$(id -u)}
TIMEOUT=${SIM_TIMEOUT:-120}
mkdir -p "$OUT" "$OBJ_ROOT"

mapfile -t RTL < <(find rtl \( -name '*.v' -o -name '*.sv' \) 2>/dev/null | sort)

if [ $# -gt 0 ]; then
  TBS=()
  for n in "$@"; do
    tb=""
    for ext in v sv; do
      if [ -f "tb/$n.$ext" ]; then
        tb="tb/$n.$ext"
        break
      fi
    done
    if [ -z "$tb" ]; then
      echo "Testbench not found: tb/$n.v or tb/$n.sv"
      exit 1
    fi
    TBS+=("$tb")
  done
else
  shopt -s nullglob
  TBS=(tb/*_tb.v tb/*_tb.sv)
fi

if [ ${#TBS[@]} -eq 0 ]; then
  echo "No testbenches found (expected tb/*_tb.v or tb/*_tb.sv)"
  exit 1
fi

passed=()
failed=()

for tb in "${TBS[@]}"; do
  name=$(basename "${tb%.*}")
  obj="$OBJ_ROOT/obj_$name"
  echo "=== $name ==="

  if ! verilator --binary --timing --trace --Wno-fatal \
        -Wall -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Irtl \
        --top-module "$name" --Mdir "$obj" \
        "${RTL[@]}" "$tb"  \
        > "$OUT/$name.compile.log" 2>&1; then
    cat "$OUT/$name.compile.log"
    failed+=("$name (compile error)")
    continue
  fi

  if ! timeout "$TIMEOUT" "$obj/V$name" 2>&1 | tee "$OUT/$name.log"; then
    rc=${PIPESTATUS[0]}
    if [ "$rc" -eq 124 ]; then
      failed+=("$name (timeout after ${TIMEOUT}s)")
    else
      failed+=("$name (simulator exit code $rc)")
    fi
  elif grep -q 'FAIL' "$OUT/$name.log"; then
    failed+=("$name (check failed)")
  elif ! grep -q 'TEST PASSED' "$OUT/$name.log"; then
    failed+=("$name (no 'TEST PASSED' line)")
  else
    passed+=("$name")
  fi
done

echo
echo "================ SUMMARY ================"
echo "passed: ${#passed[@]}   failed: ${#failed[@]}"
for f in "${failed[@]}"; do echo "  FAILED: $f"; done

[ ${#failed[@]} -eq 0 ]
