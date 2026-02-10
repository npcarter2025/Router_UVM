# ============================================================================
# UVM Router Testbench Makefile for VCS
# ============================================================================

# Tool settings
VCS = vcs

# Build directory
BUILD_DIR = build
SIMV = $(BUILD_DIR)/simv

# UVM settings
UVM_VERBOSITY ?= UVM_LOW

# Source files
RTL_SOURCES = src/dual_port_router_if.sv src/dual_port_router.sv
DPI_SOURCES = dpi/router_dpi_pkg.sv
TB_SOURCES = tb/tb_top.sv




ALL_SOURCES = $(RTL_SOURCES) $(DPI_SOURCES) $(TB_SOURCES)

# Test name (default: router_base_test)
TEST ?= router_base_test

# VCS compilation flags
VCS_FLAGS = -sverilog \
            -full64 \
            -timescale=1ns/1ps \
            -ntb_opts uvm-1.2 \
            +incdir+. \
            -Mdir=$(BUILD_DIR)/csrc \
			+acc+rw \
			-debug_access+r \
			-cm line+cond+fsm+tgl \
			-cm_dir $(BUILD_DIR)/coverage.vdb \
			-LDFLAGS -Wl,-rpath=$(shell pwd)/$(DPI_DIR)

# Log file
LOG_FILE ?= $(BUILD_DIR)/sim.log

# Waveform viewer: dve (default) or gtkwave
WAVE_VIEWER ?= dve
# DVE invocation (override if your install needs a different path or flags)
DVE_CMD ?= dve -full64

# Simulation flags
SIM_FLAGS = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(UVM_VERBOSITY) \
            -l $(LOG_FILE) \
			-cm line+cond+fsm+tgl \
			-cm_dir $(BUILD_DIR)/coverage.vdb 

# DPI-C files
DPI_DIR = dpi
DPI_SRC = $(DPI_DIR)/router_model.cpp
DPI_SO = $(DPI_DIR)/router_model.so 
DPI_PKG = $(DPI_DIR)/router_dpi_pkg.sv

# Coverage test name (for dedicated coverage runs)
COVERAGE_TEST ?= comprehensive_coverage_test



# ============================================================================
# Targets
# ============================================================================

# Default target
all: compile run

#Compile C++ DPI model to shared library
$(DPI_SO): $(DPI_SRC)
	@echo "============================================"
	@echo "Compiling C++ DPI-C Model..."
	@echo "============================================"
	g++ -shared -fPIC -o $@ $< -std=c++11

# Compile the testbench
compile: $(DPI_SO)
	@echo "============================================"
	@echo "Compiling UVM Testbench..."
	@echo "============================================"
	@mkdir -p $(BUILD_DIR)
	$(VCS) $(VCS_FLAGS) $(ALL_SOURCES) $(DPI_SO) -o $(SIMV)

# Run simulation
run:
	@echo "============================================"
	@echo "Running test: $(TEST)"
	@echo "============================================"
	LD_LIBRARY_PATH=$(shell pwd)/$(DPI_DIR):$$LD_LIBRARY_PATH ./$(SIMV) $(SIM_FLAGS)

# Run with medium verbosity
run_medium:
	@echo "============================================"
	@echo "Running test: $(TEST) (MEDIUM verbosity)"
	@echo "============================================"
	LD_LIBRARY_PATH=$(shell pwd)/$(DPI_DIR):$$LD_LIBRARY_PATH ./$(SIMV) $(SIM_FLAGS) +UVM_VERBOSITY=UVM_MEDIUM

# Run with high verbosity
run_high:
	@echo "============================================"
	@echo "Running test: $(TEST) (HIGH verbosity)"
	@echo "============================================"
	LD_LIBRARY_PATH=$(shell pwd)/$(DPI_DIR):$$LD_LIBRARY_PATH ./$(SIMV) $(SIM_FLAGS) +UVM_VERBOSITY=UVM_HIGH

# Clean generated files
clean:
	@echo "Cleaning..."
	rm -rf $(BUILD_DIR)
	rm -rf ucli.key vc_hdrs.h .vcsmx_rebuild DVEfiles
	rm -rf AN.DB novas* verdiLog
	rm -rf *.log *.vcd *.vpd
	rm -rf $(DPI_SO)

# View waveforms (testbench creates both dump.vcd and vcdplus.vpd)
# DVE uses vcdplus.vpd; GTKWave uses dump.vcd
waves:
	@if [ "$(WAVE_VIEWER)" = "dve" ]; then \
		WAVEFILE=""; \
		if [ -f $(BUILD_DIR)/vcdplus.vpd ]; then WAVEFILE="$(BUILD_DIR)/vcdplus.vpd"; \
		elif [ -f vcdplus.vpd ]; then WAVEFILE="vcdplus.vpd"; fi; \
		if [ -z "$$WAVEFILE" ]; then echo "No vcdplus.vpd found. Run 'make run_waves' first."; exit 1; fi; \
		echo "Opening $$WAVEFILE with DVE..."; \
		$(DVE_CMD) -vpd $$WAVEFILE & \
	else \
		WAVEFILE=""; \
		if [ -f $(BUILD_DIR)/dump.vcd ]; then WAVEFILE="$(BUILD_DIR)/dump.vcd"; \
		elif [ -f dump.vcd ]; then WAVEFILE="dump.vcd"; fi; \
		if [ -z "$$WAVEFILE" ]; then echo "No dump.vcd found. Run 'make run_waves' first."; exit 1; fi; \
		echo "Opening $$WAVEFILE with GTKWave..."; \
		gtkwave $$WAVEFILE & \
	fi

# Run simulation with waves
run_waves: compile
	@echo "============================================"
	@echo "Running test with waveform dump: $(TEST)"
	@echo "============================================"
	LD_LIBRARY_PATH=$(shell pwd)/$(DPI_DIR):$$LD_LIBRARY_PATH ./$(SIMV) $(SIM_FLAGS) +vcs+dumpvars

# Run with GUI debugger (DVE)
gui: compile
	@echo "============================================"
	@echo "Launching GUI debugger..."
	@echo "============================================"
	LD_LIBRARY_PATH=$(shell pwd)/$(DPI_DIR):$$LD_LIBRARY_PATH ./$(SIMV) $(SIM_FLAGS) -gui &

# Run comprehensive coverage test
run_coverage:
	@echo "============================================"
	@echo "Running coverage test: $(COVERAGE_TEST)"
	@echo "============================================"
	LD_LIBRARY_PATH=$(shell pwd)/$(DPI_DIR):$$LD_LIBRARY_PATH ./$(SIMV) +UVM_TESTNAME=$(COVERAGE_TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY) -l $(BUILD_DIR)/coverage_sim.log -cm line+cond+fsm+tgl -cm_dir $(BUILD_DIR)/coverage.vdb

report:
	@echo "============================================"
	@echo "Generating Coverage Report..."
	@echo "============================================"
	urg -dir $(BUILD_DIR)/coverage.vdb -report $(BUILD_DIR)/coverage_report
	@echo "Coverage report generated in $(BUILD_DIR)/coverage_report/"
	@echo "Open $(BUILD_DIR)/coverage_report/dashboard.html to view"


# Open coverage report in browser (no server needed)
open_report: report
	@echo "Opening coverage report in browser..."
	@if [ -z "$$DISPLAY" ]; then export DISPLAY=:0.0; fi; \
	firefox "file://$(shell pwd)/$(BUILD_DIR)/coverage_report/dashboard.html" &

# Serve report via HTTP and open in browser (use if open_report has path issues)
html: report
	@echo "============================================"
	@echo "Starting HTTP server on port 8000..."
	@echo "============================================"
	@cd $(BUILD_DIR)/coverage_report && python3 -m http.server 8000 &
	@sleep 2
	@if [ -z "$$DISPLAY" ]; then export DISPLAY=:0.0; fi; \
	firefox http://localhost:8000/dashboard.html &
	@echo "Server running. If port 8000 was in use, run: make open_report"

# Generate PlantUML diagrams
diagrams:
	@echo "============================================"
	@echo "Generating PlantUML Diagrams..."
	@echo "============================================"
	@cd docs/diagrams && ./generate_diagrams.sh
	@echo "Diagrams generated in docs/diagrams/PlantUML_scripts/"

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
	@echo "  make run_waves    - Run simulation with waveform dump"
	@echo "  make gui          - Launch simulation with GUI debugger"
	@echo "  make waves        - Open waveform viewer"
	@echo "  make run_coverage - Run comprehensive coverage test"
	@echo "  make report       - Generate coverage report"
	@echo "  make open_report  - Open coverage report in browser (no server)"
	@echo "  make html         - Serve report via HTTP and open in browser"
	@echo "  make diagrams     - Generate PlantUML documentation diagrams"
	@echo "  make help         - Show this help"
	@echo ""
	@echo "Options:"
	@echo "  TEST=<test_name>                - Specify test (default: router_base_test)"
	@echo "  COVERAGE_TEST=<test_name>       - Specify coverage test (default: comprehensive_coverage_test)"
	@echo "  UVM_VERBOSITY=<level>           - UVM_NONE/LOW/MEDIUM/HIGH/FULL"
	@echo "  LOG_FILE=<filename>             - Log file name (default: sim.log)"
	@echo "  WAVE_VIEWER=dve|gtkwave         - Waveform viewer (default: dve)"
	@echo "  DVE_CMD=<command>               - DVE invocation (default: dve -full64)"
	@echo ""
	@echo "Examples:"
	@echo "  make TEST=router_base_test"
	@echo "  make run UVM_VERBOSITY=UVM_HIGH"
	@echo "  make run_coverage COVERAGE_TEST=my_coverage_test"
	@echo "  make html    # Generate and view coverage report"
	@echo ""

.PHONY: all compile run run_medium run_high run_waves gui run_coverage clean waves report open_report html diagrams help
