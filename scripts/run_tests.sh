#!/usr/bin/env bash
# Compile and run SystemVerilog testbenches with Verilator.
#   scripts/run_tests.sh         -> every tb/tb_*.v and tb/tb_*.sv
#   scripts/run_tests.sh tb_alu  -> just tb/tb_alu.v or tb/tb_alu.sv

set -uo pipefail
cd "$(dirname "$0")/.."

OUT=build/sim
TIMEOUT=${SIM_TIMEOUT:-120}
mkdir -p "$OUT"

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
  TBS=(tb/tb_*.v tb/tb_*.sv)
fi

if [ ${#TBS[@]} -eq 0 ]; then
  echo "No testbenches found (expected tb/tb_*.v or tb/tb_*.sv)"
  exit 1
fi

passed=()
failed=()

for tb in "${TBS[@]}"; do
  name=$(basename "${tb%.*}")
  obj="$OUT/obj_$name"
  echo "=== $name ==="

  if ! verilator --binary --timing --trace --Wno-fatal 
        -Wall -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Irtl 
        --top-module "$name" --Mdir "$obj" 
        "${RTL[@]}" "$tb" 
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
