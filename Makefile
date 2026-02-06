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
			-cm line+cond+fsm+tgl \
			-cm line+cond+fsm+tgl \
			-LDFLAGS -Wl,-rpath=$(shell pwd)/$(DPI_DIR)

# Log file
LOG_FILE ?= $(BUILD_DIR)/sim.log

# Simulation flags
SIM_FLAGS = +UVM_TESTNAME=$(TEST) \
            +UVM_VERBOSITY=$(UVM_VERBOSITY) \
            -l $(LOG_FILE)

# DPI-C files
DPI_DIR = dpi
DPI_SRC = $(DPI_DIR)/router_model.cpp
DPI_SO = $(DPI_DIR)/router_model.so 
DPI_PKG = $(DPI_DIR)/router_dpi_pkg.sv



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
	rm -rf *.log *.vcd
	rm -rf $(DPI_SO)

# View waveforms (if dump.vcd exists)
waves:
	@if [ -f $(BUILD_DIR)/dump.vcd ]; then \
		echo "Opening waveform viewer..."; \
		dve -vpd $(BUILD_DIR)/dump.vcd &; \
	elif [ -f dump.vcd ]; then \
		echo "Opening waveform viewer..."; \
		dve -vpd dump.vcd &; \
	else \
		echo "No waveform file found. Run simulation first."; \
	fi

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
	@echo "  make cleanall     - Remove all generated files"
	@echo "  make waves        - Open waveform viewer"
	@echo "  make diagrams     - Generate PlantUML documentation diagrams"
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

.PHONY: all compile run run_medium run_high clean cleanall waves diagrams help
