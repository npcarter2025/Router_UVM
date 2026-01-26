# ============================================================================
# UVM Router Testbench Makefile for VCS
# ============================================================================

# Tool settings
VCS = vcs
SIMV = simv

# UVM settings
UVM_VERBOSITY ?= UVM_LOW

# Source files
RTL_SOURCES = src/dual_port_router_if.sv src/dual_port_router.sv
TB_SOURCES = tb/tb_top.sv

ALL_SOURCES = $(RTL_SOURCES) $(TB_SOURCES)

# DPI-C files
DPI_DIR = dpi
DPI_SRC = $(DPI_DIR)/router_model.cpp
DPI_SO = $(DPI_DIR)/router_model.so
DPI_PKG = $(DPI_DIR)/router_dpi_pkg.sv

# Test name (default: router_base_test)
TEST ?= router_base_test

# VCS compilation flags
VCS_FLAGS = -sverilog \
            -full64 \
            -timescale=1ns/1ps \
            -ntb_opts uvm-1.2 \
            +incdir+.

# Log file
LOG_FILE ?= sim.log

# Simulation flags
SIM_FLAGS = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(UVM_VERBOSITY) \
            -l $(LOG_FILE)

# Coverage flags for VCS
COV_FLAGS = -cm line+cond+fsm+tgl+branch+assert
COV_FLAGS += -cm_dir coverage.vdb
COV_FLAGS += -cm_name test_$(TEST)

# ============================================================================
# Targets
# ============================================================================

# Default target
all: compile run

# Compile C++ DPI model to shared library
$(DPI_SO): $(DPI_SRC)
	@echo "============================================"
	@echo "Compiling C++ DPI-C Model..."
	@echo "============================================"
	g++ -shared -fPIC -o $@ $< -std=c++11

# Compile the testbench (depends on DPI library)
compile: $(DPI_SO)
	@echo "============================================"
	@echo "Compiling UVM Testbench with DPI-C..."
	@echo "============================================"
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) \
		$(DPI_PKG) \
		$(ALL_SOURCES) \
		$(DPI_SO) \
		-o $(SIMV)

# Run simulation
run:
	@echo "============================================"
	@echo "Running test: $(TEST)"
	@echo "============================================"
	./$(SIMV) $(SIM_FLAGS) -cm line+cond+fsm+tgl

# Run with medium verbosity
run_medium:
	@echo "============================================"
	@echo "Running test: $(TEST) (MEDIUM verbosity)"
	@echo "============================================"
	./$(SIMV) $(SIM_FLAGS) +UVM_VERBOSITY=UVM_MEDIUM

# Run with high verbosity
run_high:
	@echo "============================================"
	@echo "Running test: $(TEST) (HIGH verbosity)"
	@echo "============================================"
	./$(SIMV) $(SIM_FLAGS) +UVM_VERBOSITY=UVM_HIGH

# Clean generated files
clean:
	@echo "Cleaning..."
	rm -rf $(SIMV) $(SIMV).daidir csrc *.log *.vpd *.vcd
	rm -rf ucli.key vc_hdrs.h .vcsmx_rebuild DVEfiles
	rm -rf $(DPI_SO) coverage.vdb

# Full clean (including waveforms)
cleanall: clean
	rm -rf *.vcd *.vpd *.fsdb novas* verdiLog coverage_report 

# View waveforms (if dump.vcd exists)
waves:
	@if [ -f dump.vcd ]; then \
		echo "Opening waveform viewer..."; \
		dve -vpd dump.vcd &; \
	else \
		echo "No waveform file found. Run simulation first."; \
	fi

report:
	urg -dir coverage.vdb -report coverage_report

html:
	@echo "Starting HTTP server on port 8000..."
	@cd coverage_report && python3 -m http.server 8000 &
	@sleep 2
	@echo "Opening Firefox..."
	@if [ -z "$$DISPLAY" ]; then export DISPLAY=:0.0; fi; \
	firefox http://localhost:8000/dashboard.html &
	@echo "Server running. Press Ctrl+C to stop, or run: pkill -f 'python3 -m http.server 8000'"


# ============================================================================
# Help
# ============================================================================
help:
	@echo "============================================"
	@echo "UVM Router Testbench Makefile"
	@echo "============================================"
	@echo ""
	@echo "Usage:"
	@echo "  make              - Compile and run default test"
	@echo "  make compile      - Compile testbench only"
	@echo "  make run          - Run simulation (default test)"
	@echo "  make run_medium   - Run with UVM_MEDIUM verbosity"
	@echo "  make run_high     - Run with UVM_HIGH verbosity"
	@echo "  make clean        - Remove generated files"
	@echo "  make cleanall     - Remove all generated files"
	@echo "  make waves        - Open waveform viewer"
	@echo "  make report	   - Generate the coverage report"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Options:"
	@echo "  TEST=<test_name>           - Specify test (default: router_base_test)"
	@echo "  UVM_VERBOSITY=<level>      - UVM_NONE/LOW/MEDIUM/HIGH/FULL"
	@echo "  LOG_FILE=<filename>        - Log file name (default: sim.log)"
	@echo ""
	@echo "Examples:"
	@echo "  make TEST=router_base_test"
	@echo "  make run UVM_VERBOSITY=UVM_HIGH"
	@echo ""

.PHONY: all compile run run_medium run_high clean cleanall waves report html help
