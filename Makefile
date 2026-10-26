# Usage:
#   make lint            Verilator lint of everything in rtl/
#   make test            run every tb/tb_*.v with Icarus Verilog
#   make test TB=tb_alu  run a single testbench
#   make clean
#
# Override the top module with:  make lint TOP=my_top

TOP ?= cpu_top
RTL := $(shell find rtl \( -name '*.v' -o -name '*.sv' \) 2>/dev/null | sort)

# -Wall includes LATCH, WIDTH, CASEINCOMPLETE, etc. The two waived warnings are
# very noisy in processors (unused instruction bits). Remove the waivers once
# the design is clean if you want stricter checking.
LINT_FLAGS := -Wall -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Irtl

.PHONY: lint test clean

lint:
	@test -n "$(RTL)" || { echo "No RTL files found in rtl/"; exit 1; }
	verilator --lint-only $(LINT_FLAGS) --top-module $(TOP) $(RTL)

test:
	bash scripts/run_tests.sh $(TB)

clean:
	rm -rf build