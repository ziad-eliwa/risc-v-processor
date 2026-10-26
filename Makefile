# Usage:
#   make lint                 Verilator lint of everything in rtl/
#   make test                 run every tb/tb_*.v and tb/tb_*.sv testbench
#   make test TB=tb_alu       run one testbench (file must be tb/tb_alu.v or .sv)
#   make clean
#
# Assumptions:
#   - RTL source files are in rtl/
#   - Testbenches are in tb/ and named tb_*.v or tb_*.sv
#   - Each testbench's top module matches its filename (without extension)
#
# Override the RTL top module for linting with: make lint TOP=my_top

TOP ?= cpu
RTL := $(shell find rtl \( -name '*.v' -o -name '*.sv' \) 2>/dev/null | sort)
TB_FILES := $(shell find tb \( -name 'tb_*.v' -o -name 'tb_*.sv' \) 2>/dev/null | sort)

LINT_FLAGS := -Wall -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM -Irtl
SIM_FLAGS := --binary --timing --trace --Wno-fatal -Irtl
BUILD := build/sim

.PHONY: lint test test-one clean

lint:
	@test -n "$(RTL)" || { echo "No RTL files found in rtl/"; exit 1; }
	verilator --lint-only $(LINT_FLAGS) --top-module $(TOP) $(RTL)

test:
	@test -n "$(RTL)" || { echo "No RTL files found in rtl/"; exit 1; }
	@test -n "$(TB_FILES)" || { echo "No testbenches found in tb/ (expected tb_*.v or tb_*.sv)"; exit 1; }
	@if [ -n "$(TB)" ]; then \
		tb_file=$$(find tb -type f \( -name "$(TB).v" -o -name "$(TB).sv" \) -print -quit); \
		if [ -z "$$tb_file" ]; then echo "Testbench $(TB) not found in tb/"; exit 1; fi; \
		$(MAKE) --no-print-directory test-one TB="$(TB)" TB_FILE="$$tb_file"; \
	else \
		set -e; \
		for tb_file in $(TB_FILES); do \
			tb=$$(basename "$$tb_file"); tb=$${tb%.*}; \
			$(MAKE) --no-print-directory test-one TB="$$tb" TB_FILE="$$tb_file"; \
		done; \
	fi

test-one:
	@test -n "$(TB_FILE)" || { echo "Set TB_FILE to a testbench source file"; exit 1; }
	mkdir -p $(BUILD)
	verilator $(SIM_FLAGS) $(LINT_FLAGS) --top-module $(TB) --Mdir $(BUILD)/obj_$(TB) $(RTL) $(TB_FILE)
	$(BUILD)/obj_$(TB)/V$(TB)

clean:
	rm -rf build