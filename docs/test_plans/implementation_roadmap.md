# Router UVM Testbench - Implementation Roadmap

This document provides a step-by-step implementation plan for adding advanced UVM features to the dual-port router testbench.

---

## Table of Contents

1. [Overview](#overview)
2. [Phase 1: Foundation](#phase-1-foundation)
3. [Phase 2: Verification Quality](#phase-2-verification-quality)
4. [Phase 3: Advanced Architecture](#phase-3-advanced-architecture)
5. [Phase 4: Optional Enhancements](#phase-4-optional-enhancements)
6. [Quick Reference](#quick-reference)

---

## Overview

### Implementation Order & Priority

| Phase | Feature | Priority | Complexity | Time Estimate | Dependencies |
|-------|---------|----------|------------|---------------|--------------|
| 1 | Configuration Objects | ⭐⭐⭐ | Easy | 2-3 days | None |
| 1 | Error Injection | ⭐⭐ | Easy | 1-2 days | Config Objects |
| 2 | DPI-C Golden Model | ⭐⭐⭐ | Medium | 3-4 days | None |
| 2 | Coverage Class | ⭐⭐⭐ | Medium | 2-3 days | Working testbench |
| 3 | Factory Overrides | ⭐⭐⭐ | Medium | 2-3 days | Config Objects |
| 3 | Layered Sequences | ⭐⭐ | Medium | 2-3 days | Sequences |
| 4 | Reactive Drivers | ⭐ | Medium | 2-3 days | Agents |
| 4 | Advanced Phasing | ⭐ | Easy | 1 day | None |

### Why This Order?

1. **Configuration Objects** - Foundation for everything else
2. **Error Injection** - Easy win, tests scoreboard robustness
3. **DPI-C** - Verification quality boost
4. **Coverage** - Find test gaps once verification is solid
5. **Factory Overrides** - Architectural flexibility
6. **Layered Sequences** - Protocol abstraction
7. **Optional features** - As needed

---

## Phase 1: Foundation

### 1.1 Configuration Objects

**Goal:** Create flexible, configurable testbench without hardcoded values.

#### Step 1: Create Agent Configurations

**File: `agent/port_a_agent/port_a_config.svh`**

```systemverilog
class port_a_config extends uvm_object;
    `uvm_object_utils(port_a_config)
    
    // Agent configuration
    uvm_active_passive_enum is_active = UVM_ACTIVE;
    
    // Coverage enable
    bit coverage_enable = 1;
    
    // Error injection controls
    bit error_injection_enable = 0;
    rand int error_rate = 5;  // 5% error rate
    
    // Timing controls
    rand int min_delay = 0;
    rand int max_delay = 5;
    
    // Virtual interface (set from test/env)
    virtual dual_port_router_if vif;
    
    function new(string name = "port_a_config");
        super.new(name);
    endfunction
    
    constraint reasonable_delays_c {
        min_delay >= 0;
        max_delay <= 20;
        max_delay >= min_delay;
    }
    
    constraint error_rate_c {
        error_rate >= 0;
        error_rate <= 100;
    }
endclass
```

**Similarly create:**
- `agent/port_b_agent/port_b_config.svh`
- `agent/reg_agent/reg_config.svh`
- `agent/output_agent/output_config.svh`

#### Step 2: Create Environment Configuration

**File: `env/router_env_config.svh`**

```systemverilog
class router_env_config extends uvm_object;
    `uvm_object_utils(router_env_config)
    
    // Agent configs
    port_a_config m_port_a_cfg;
    port_b_config m_port_b_cfg;
    reg_config m_reg_cfg;
    output_config m_output_cfg;
    
    // Scoreboard controls
    bit enable_scoreboard = 1;
    bit enable_dpi_scoreboard = 0;  // Enable when DPI-C ready
    
    // Coverage controls
    bit enable_coverage = 1;
    
    // Virtual interface
    virtual dual_port_router_if vif;
    
    function new(string name = "router_env_config");
        super.new(name);
        
        // Create sub-configs
        m_port_a_cfg = port_a_config::type_id::create("m_port_a_cfg");
        m_port_b_cfg = port_b_config::type_id::create("m_port_b_cfg");
        m_reg_cfg = reg_config::type_id::create("m_reg_cfg");
        m_output_cfg = output_config::type_id::create("m_output_cfg");
    endfunction
    
    // Set all VIFs at once
    function void set_vif(virtual dual_port_router_if vif);
        this.vif = vif;
        m_port_a_cfg.vif = vif;
        m_port_b_cfg.vif = vif;
        m_reg_cfg.vif = vif;
        m_output_cfg.vif = vif;
    endfunction
endclass
```

#### Step 3: Update Agents to Use Config

**Modify: `agent/port_a_agent/port_a_agent.svh`**

```systemverilog
class port_a_agent extends uvm_agent;
    `uvm_component_utils(port_a_agent)
    
    port_a_config m_cfg;  // Add config object
    
    port_a_driver drv;
    port_a_monitor mon;
    port_a_sequencer seqr;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config from database
        if (!uvm_config_db#(port_a_config)::get(this, "", "port_a_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get port_a_config from config_db")
        end
        
        // Pass config to sub-components
        uvm_config_db#(port_a_config)::set(this, "mon", "port_a_config", m_cfg);
        
        mon = port_a_monitor::type_id::create("mon", this);
        
        if (m_cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(port_a_config)::set(this, "drv", "port_a_config", m_cfg);
            uvm_config_db#(port_a_config)::set(this, "seqr", "port_a_config", m_cfg);
            
            drv = port_a_driver::type_id::create("drv", this);
            seqr = port_a_sequencer::type_id::create("seqr", this);
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        if (m_cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass
```

#### Step 4: Update Driver to Use Config

**Modify: `agent/port_a_agent/port_a_driver.svh`**

```systemverilog
class port_a_driver extends uvm_driver #(port_a_item);
    `uvm_component_utils(port_a_driver)
    
    virtual dual_port_router_if vif;
    port_a_config m_cfg;  // Add config
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config from database
        if (!uvm_config_db#(port_a_config)::get(this, "", "port_a_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get port_a_config")
        end
        
        vif = m_cfg.vif;  // Get VIF from config
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            
            // Use config for timing
            if (m_cfg.max_delay > 0) begin
                repeat ($urandom_range(m_cfg.min_delay, m_cfg.max_delay)) @(vif.drv_cb);
            end
            
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask
endclass
```

#### Step 5: Update Base Test

**Modify: `tests/router_base_test.svh`**

```systemverilog
class router_base_test extends uvm_test;
    `uvm_component_utils(router_base_test)
    
    router_env m_env;
    router_env_config m_env_cfg;  // Add config
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create and configure environment config
        m_env_cfg = router_env_config::type_id::create("m_env_cfg");
        
        // Get VIF from config_db
        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", m_env_cfg.vif)) begin
            `uvm_fatal(get_type_name(), "Failed to get VIF")
        end
        
        // Set VIF for all sub-configs
        m_env_cfg.set_vif(m_env_cfg.vif);
        
        // Configure environment settings
        configure_env(m_env_cfg);
        
        // Put config in database for environment
        uvm_config_db#(router_env_config)::set(this, "m_env", "router_env_config", m_env_cfg);
        uvm_config_db#(port_a_config)::set(this, "m_env.m_port_a_agent", "port_a_config", m_env_cfg.m_port_a_cfg);
        uvm_config_db#(port_b_config)::set(this, "m_env.m_port_b_agent", "port_b_config", m_env_cfg.m_port_b_cfg);
        uvm_config_db#(reg_config)::set(this, "m_env.m_reg_agent", "reg_config", m_env_cfg.m_reg_cfg);
        uvm_config_db#(output_config)::set(this, "m_env.m_output_agent", "output_config", m_env_cfg.m_output_cfg);
        
        m_env = router_env::type_id::create("m_env", this);
    endfunction
    
    // Override this in derived tests to customize config
    virtual function void configure_env(router_env_config cfg);
        // Default configuration - override in derived tests
    endfunction
endclass
```

#### Testing Configuration Objects

Create a simple test to verify configs work:

**File: `tests/config_test.svh`**

```systemverilog
class config_test extends router_base_test;
    `uvm_component_utils(config_test)
    
    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);
        
        // Customize for this test
        cfg.m_port_a_cfg.min_delay = 2;
        cfg.m_port_a_cfg.max_delay = 10;
        
        `uvm_info(get_type_name(), "Configuration customized for config_test", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting config test", UVM_LOW)
        #1000ns;
        
        phase.drop_objection(this);
    endtask
endclass
```

**Checkpoint:** Compile and run `config_test` - verify no errors.

---

### 1.2 Error Injection

**Goal:** Inject protocol errors to test scoreboard robustness.

#### Step 1: Add Error Injection to Config

Already added in `port_a_config`:
```systemverilog
bit error_injection_enable = 0;
rand int error_rate = 5;  // 5% error rate
```

#### Step 2: Create Error Injection Driver

**File: `agent/port_a_agent/port_a_error_driver.svh`**

```systemverilog
class port_a_error_driver extends port_a_driver;
    `uvm_component_utils(port_a_error_driver)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task drive_item(port_a_item item);
        port_a_item corrupted_item;
        
        // Check if we should inject error
        if (m_cfg.error_injection_enable && ($urandom_range(0, 99) < m_cfg.error_rate)) begin
            // Clone item and corrupt it
            $cast(corrupted_item, item.clone());
            inject_error(corrupted_item);
            
            `uvm_warning("ERROR_INJECT", $sformatf("Injecting error into packet: orig_data=0x%0h, corrupt_data=0x%0h", 
                item.data_a, corrupted_item.data_a))
            
            super.drive_item(corrupted_item);
        end else begin
            super.drive_item(item);
        end
    endtask
    
    virtual function void inject_error(port_a_item item);
        int error_type = $urandom_range(0, 3);
        
        case (error_type)
            0: begin  // Corrupt data
                item.data_a = item.data_a ^ 8'hFF;
                `uvm_info("ERROR_INJECT", "Error type: DATA_CORRUPTION", UVM_MEDIUM)
            end
            1: begin  // Wrong address
                item.addr_a = $urandom_range(0, 3);
                `uvm_info("ERROR_INJECT", "Error type: WRONG_ADDRESS", UVM_MEDIUM)
            end
            2: begin  // Invalid address
                item.addr_a = $urandom_range(4, 15);
                `uvm_info("ERROR_INJECT", "Error type: INVALID_ADDRESS", UVM_MEDIUM)
            end
            3: begin  // Corrupt multiple bits
                item.data_a = $urandom();
                `uvm_info("ERROR_INJECT", "Error type: RANDOM_CORRUPTION", UVM_MEDIUM)
            end
        endcase
    endfunction
endclass
```

Similarly create `port_b_error_driver.svh`.

#### Step 3: Create Error Injection Test

**File: `tests/error_injection_test.svh`**

```systemverilog
class error_injection_test extends router_base_test;
    `uvm_component_utils(error_injection_test)
    
    function void build_phase(uvm_phase phase);
        // Use factory override to replace normal driver with error driver
        port_a_driver::type_id::set_type_override(port_a_error_driver::get_type());
        port_b_driver::type_id::set_type_override(port_b_error_driver::get_type());
        
        super.build_phase(phase);
    endfunction
    
    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);
        
        // Enable error injection
        cfg.m_port_a_cfg.error_injection_enable = 1;
        cfg.m_port_a_cfg.error_rate = 10;  // 10% error rate
        
        cfg.m_port_b_cfg.error_injection_enable = 1;
        cfg.m_port_b_cfg.error_rate = 10;
        
        `uvm_info(get_type_name(), "Error injection enabled (10% rate)", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        router_base_vseq base_seq;
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Starting error injection test", UVM_LOW)
        
        base_seq = router_base_vseq::type_id::create("base_seq");
        base_seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
endclass
```

**Expected Result:** Scoreboard should report mismatches when errors are injected.

---

## Phase 2: Verification Quality

### 2.1 DPI-C Golden Model

**Goal:** Add C++ reference model for accurate checking.

#### Step 1: Create DPI Directory and C++ Model

**File: `dpi/router_model.h`**

```cpp
#ifndef ROUTER_MODEL_H
#define ROUTER_MODEL_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

    void router_model_init();
    void router_model_write_ctrl(uint32_t data);
    void router_model_port_a(uint8_t data, uint8_t addr);
    void router_model_port_b(uint8_t data, uint8_t addr);
    int router_model_get_output(uint8_t port, uint8_t* data);

#ifdef __cplusplus
}
#endif

#endif
```

**File: `dpi/router_model.cpp`**

```cpp
#include "router_model.h"
#include <cstdio>
#include <cstdint>
#include <queue>

struct RouterState {
    bool global_enable;
    bool priority_port_b;
    std::queue<uint8_t> port_fifos[4];
};

static RouterState router_state;

extern "C" {
    void router_model_init() {
        router_state.global_enable = true;
        router_state.priority_port_b = false;
        for (int i = 0; i < 4; i++) {
            while (!router_state.port_fifos[i].empty()) {
                router_state.port_fifos[i].pop();
            }
        }
        printf("[C++ Model] Router Initialized\n");
    }

    void router_model_write_ctrl(uint32_t data) {
        router_state.global_enable = (data & 0x1);
        router_state.priority_port_b = (data & 0x2) >> 1;
        printf("[C++ Model] Control: enable=%d, priority_b=%d\n",
            router_state.global_enable, router_state.priority_port_b);
    }

    void router_model_port_a(uint8_t data, uint8_t addr) {
        if (!router_state.global_enable) return;
        
        if (addr < 4) {
            router_state.port_fifos[addr].push(data);
            printf("[C++ Model] Port A: data=0x%02x -> output[%d]\n", data, addr);
        }
    }

    void router_model_port_b(uint8_t data, uint8_t addr) {
        if (!router_state.global_enable) return;
        
        if (addr < 4) {
            router_state.port_fifos[addr].push(data);
            printf("[C++ Model] Port B: data=0x%02x -> output[%d]\n", data, addr);
        }
    }

    int router_model_get_output(uint8_t port, uint8_t* data) {
        if (port >= 4) return 0;
        
        if (!router_state.port_fifos[port].empty()) {
            *data = router_state.port_fifos[port].front();
            router_state.port_fifos[port].pop();
            printf("[C++ Model] Output[%d] = 0x%02x\n", port, *data);
            return 1;
        }
        return 0;
    }
}
```

#### Step 2: Create DPI Package

**File: `dpi/router_dpi_pkg.sv`**

```systemverilog
`ifndef ROUTER_DPI_PKG_SV
`define ROUTER_DPI_PKG_SV

package router_dpi_pkg;

    import "DPI-C" function void router_model_init();
    import "DPI-C" function void router_model_write_ctrl(int unsigned data);
    import "DPI-C" function void router_model_port_a(byte unsigned data, byte unsigned addr);
    import "DPI-C" function void router_model_port_b(byte unsigned data, byte unsigned addr);
    import "DPI-C" function int router_model_get_output(byte unsigned port, output byte unsigned data);
    
endpackage

`endif
```

#### Step 3: Create DPI Scoreboard

**File: `env/router_scoreboard_dpi.svh`**

```systemverilog
`ifndef ROUTER_SCOREBOARD_DPI_SVH
`define ROUTER_SCOREBOARD_DPI_SVH

`uvm_analysis_imp_decl(_port_a_dpi)
`uvm_analysis_imp_decl(_port_b_dpi)
`uvm_analysis_imp_decl(_output_dpi)
`uvm_analysis_imp_decl(_reg_dpi)

class router_scoreboard_dpi extends uvm_scoreboard;
    `uvm_component_utils(router_scoreboard_dpi)

    uvm_analysis_imp_port_a_dpi #(port_a_item, router_scoreboard_dpi) port_a_imp;
    uvm_analysis_imp_port_b_dpi #(port_b_item, router_scoreboard_dpi) port_b_imp;
    uvm_analysis_imp_output_dpi #(output_item, router_scoreboard_dpi) output_imp;
    uvm_analysis_imp_reg_dpi    #(reg_item,    router_scoreboard_dpi) reg_imp;

    int match_count;
    int mismatch_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);
        output_imp = new("output_imp", this);
        reg_imp = new("reg_imp", this);

        router_model_init();
    endfunction

    function void write_port_a_dpi(port_a_item item);
        if (item.ready_a) begin
            router_model_port_a(item.data_a, item.addr_a);
            `uvm_info("SB_DPI", $sformatf("Fed Port A to C++ model: data=0x%02h addr=0x%0d", 
                item.data_a, item.addr_a), UVM_HIGH)
        end
    endfunction

    function void write_port_b_dpi(port_b_item item);
        if (item.ready_b) begin
            router_model_port_b(item.data_b, item.addr_b);
            `uvm_info("SB_DPI", $sformatf("Fed Port B to C++ model: data=0x%02h addr=0x%0d", 
                item.data_b, item.addr_b), UVM_HIGH)
        end
    endfunction

    function void write_reg_dpi(reg_item item);
        if (item.reg_we && item.reg_en) begin
            router_model_write_ctrl(item.reg_wdata);
            `uvm_info("SB_DPI", $sformatf("Fed register write to C++ model: data=0x%08h", 
                item.reg_wdata), UVM_HIGH)
        end
    endfunction

    function void write_output_dpi(output_item item);
        byte unsigned expected_data;
        int valid;

        valid = router_model_get_output(item.port_idx, expected_data);

        if (valid) begin
            if (item.data == expected_data) begin
                `uvm_info("SB_DPI", $sformatf("MATCH on port[%0d]: expected=0x%02h actual=0x%02h", 
                    item.port_idx, expected_data, item.data), UVM_MEDIUM)
                match_count++;
            end else begin
                `uvm_error("SB_DPI", $sformatf("MISMATCH on port[%0d]: expected=0x%02h actual=0x%02h", 
                    item.port_idx, expected_data, item.data))
                mismatch_count++;       
            end 
        end else begin
            `uvm_error("SB_DPI", $sformatf("Unexpected output on port[%0d] (C++ model has no data)", 
                item.port_idx))
            mismatch_count++;
        end 
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "  DPI-C Scoreboard Statistics:", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Matches: %0d", match_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Mismatches: %0d", mismatch_count), UVM_LOW)
        
        if (mismatch_count > 0) begin
            `uvm_error(get_type_name(), $sformatf("DPI SCOREBOARD FAILED - %0d mismatches", mismatch_count))
        end else begin
            `uvm_info(get_type_name(), "DPI SCOREBOARD PASSED!", UVM_LOW)
        end
    endfunction

endclass

`endif
```

#### Step 4: Update Makefile

Add these lines to your Makefile:

```makefile
# DPI-C files
DPI_DIR = dpi
DPI_SRC = $(DPI_DIR)/router_model.cpp
DPI_SO = $(DPI_DIR)/router_model.so
DPI_PKG = $(DPI_DIR)/router_dpi_pkg.sv

# Compile C++ DPI model to shared library
$(DPI_SO): $(DPI_SRC)
	@echo "============================================"
	@echo "Compiling C++ DPI-C Model..."
	@echo "============================================"
	g++ -shared -fPIC -o $@ $< -std=c++11

# Update compile target (depends on DPI library)
compile: $(DPI_SO)
	@echo "============================================"
	@echo "Compiling UVM Testbench with DPI-C..."
	@echo "============================================"
	$(VCS) $(VCS_FLAGS) \
		$(DPI_PKG) \
		$(ALL_SOURCES) \
		$(DPI_SO) \
		-o $(SIMV)

# Update clean target
clean:
	@echo "Cleaning..."
	rm -rf $(SIMV) $(SIMV).daidir csrc *.log *.vpd *.vcd
	rm -rf ucli.key vc_hdrs.h .vcsmx_rebuild DVEfiles
	rm -rf $(DPI_SO)
```

#### Step 5: Update Environment

**Modify: `env/router_env.svh`**

```systemverilog
class router_env extends uvm_env;
    `uvm_component_utils(router_env)
    
    // ... existing components ...
    router_scoreboard m_scoreboard;
    router_scoreboard_dpi m_scoreboard_dpi;
    router_env_config m_cfg;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config
        if (!uvm_config_db#(router_env_config)::get(this, "", "router_env_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get router_env_config")
        end
        
        // Create scoreboards based on config
        if (m_cfg.enable_scoreboard) begin
            m_scoreboard = router_scoreboard::type_id::create("m_scoreboard", this);
        end
        
        if (m_cfg.enable_dpi_scoreboard) begin
            m_scoreboard_dpi = router_scoreboard_dpi::type_id::create("m_scoreboard_dpi", this);
            `uvm_info(get_type_name(), "DPI-C scoreboard enabled", UVM_LOW)
        end
        
        // ... rest of build ...
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect to regular scoreboard
        if (m_cfg.enable_scoreboard) begin
            m_port_a_agent.mon.ap.connect(m_scoreboard.port_a_imp);
            m_port_b_agent.mon.ap.connect(m_scoreboard.port_b_imp);
            m_output_agent.monitor.ap.connect(m_scoreboard.output_imp);
        end
        
        // Connect to DPI scoreboard
        if (m_cfg.enable_dpi_scoreboard) begin
            m_port_a_agent.mon.ap.connect(m_scoreboard_dpi.port_a_imp);
            m_port_b_agent.mon.ap.connect(m_scoreboard_dpi.port_b_imp);
            m_output_agent.monitor.ap.connect(m_scoreboard_dpi.output_imp);
            m_reg_agent.mon.ap.connect(m_scoreboard_dpi.reg_imp);
        end
    endfunction
endclass
```

#### Step 6: Update Package

**Modify: `tests/router_pkg.svh`**

```systemverilog
package router_pkg;
    import uvm_pkg::*;
    import router_dpi_pkg::*;  // Add DPI import
    
    `include "uvm_macros.svh"
    
    // ... includes ...
    `include "../env/router_scoreboard_dpi.svh"
    // ... rest ...
    
endpackage
```

#### Step 7: Create DPI Test

**File: `tests/dpi_test.svh`**

```systemverilog
class dpi_test extends router_base_test;
    `uvm_component_utils(dpi_test)
    
    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);
        
        // Enable DPI scoreboard
        cfg.enable_dpi_scoreboard = 1;
        cfg.enable_scoreboard = 0;  // Disable original, use only DPI
        
        `uvm_info(get_type_name(), "DPI-C scoreboard enabled", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        router_base_vseq base_seq;
        
        phase.raise_objection(this);
        
        base_seq = router_base_vseq::type_id::create("base_seq");
        base_seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
endclass
```

**Testing:** Run `make compile TEST=dpi_test && make run TEST=dpi_test`

---

### 2.2 Coverage Class

**Goal:** Merge and integrate functional coverage to measure test completeness.

#### Step 1: Merge Coverage Branch

```bash
git checkout main
git merge feature/coverage
# Resolve any conflicts
```

#### Step 2: Update Environment to Use Coverage

**Already done in previous steps - verify:**

```systemverilog
// In router_env.svh
if (m_cfg.enable_coverage) begin
    m_coverage = router_coverage::type_id::create("m_coverage", this);
end

// In connect_phase
if (m_cfg.enable_coverage) begin
    m_port_a_agent.mon.ap.connect(m_coverage.port_a_export);
    m_port_b_agent.mon.ap.connect(m_coverage.port_b_export);
    m_output_agent.monitor.ap.connect(m_coverage.output_export);
    m_reg_agent.mon.ap.connect(m_coverage.reg_export);
end
```

#### Step 3: Enable Coverage in Test

**File: `tests/comprehensive_coverage_test.svh`**

```systemverilog
class comprehensive_coverage_test extends router_base_test;
    `uvm_component_utils(comprehensive_coverage_test)
    
    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);
        
        cfg.enable_coverage = 1;
        cfg.enable_dpi_scoreboard = 1;
    endfunction
    
    task run_phase(uvm_phase phase);
        // Run multiple sequences to hit coverage
        back_to_back_vseq bb_seq;
        collision_vseq col_seq;
        disable_vseq dis_seq;
        priority_vseq pri_seq;
        
        phase.raise_objection(this);
        
        // Run various scenarios
        bb_seq = back_to_back_vseq::type_id::create("bb_seq");
        bb_seq.start(m_env.m_vseqr);
        
        col_seq = collision_vseq::type_id::create("col_seq");
        col_seq.start(m_env.m_vseqr);
        
        dis_seq = disable_vseq::type_id::create("dis_seq");
        dis_seq.start(m_env.m_vseqr);
        
        pri_seq = priority_vseq::type_id::create("pri_seq");
        pri_seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
    
    function void report_phase(uvm_phase phase);
        uvm_report_server rs;
        int coverage_val;
        
        super.report_phase(phase);
        
        coverage_val = $get_coverage();
        `uvm_info(get_type_name(), $sformatf("Overall Coverage: %0d%%", coverage_val), UVM_LOW)
        
        if (coverage_val < 80) begin
            `uvm_warning(get_type_name(), $sformatf("Coverage is below 80%% (got %0d%%)", coverage_val))
        end
    endfunction
endclass
```

#### Step 4: Add Coverage to Makefile

```makefile
# Coverage flags
COV_FLAGS = -cm line+cond+fsm+tgl+branch+assert
COV_FLAGS += -cm_dir coverage.vdb

compile: $(DPI_SO)
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) \
		$(DPI_PKG) $(ALL_SOURCES) $(DPI_SO) \
		-o $(SIMV)

run:
	./$(SIMV) $(SIM_FLAGS) -cm line+cond+fsm+tgl

report:
	urg -dir coverage.vdb -report coverage_report
```

**Testing:** Run comprehensive test and generate coverage report

```bash
make compile TEST=comprehensive_coverage_test
make run TEST=comprehensive_coverage_test
make report
```

---

## Phase 3: Advanced Architecture

### 3.1 Factory Overrides

**Goal:** Create driver variants and use factory to swap implementations.

#### Step 1: Create Fast Driver

**File: `agent/port_a_agent/fast_port_a_driver.svh`**

```systemverilog
class fast_port_a_driver extends port_a_driver;
    `uvm_component_utils(fast_port_a_driver)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            
            // No delay - drive immediately!
            drive_item(req);
            
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_item(port_a_item item);
        // Drive immediately with no clock delays
        vif.drv_cb.data_a  <= item.data_a;
        vif.drv_cb.addr_a  <= item.addr_a;
        vif.drv_cb.valid_a <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.valid_a <= 1'b0;
    endtask
endclass
```

#### Step 2: Create Debug Driver

**File: `agent/port_a_agent/debug_port_a_driver.svh`**

```systemverilog
class debug_port_a_driver extends port_a_driver;
    `uvm_component_utils(debug_port_a_driver)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task drive_item(port_a_item item);
        `uvm_info("DEBUG_DRV", "=== Starting drive ===", UVM_LOW)
        `uvm_info("DEBUG_DRV", $sformatf("Item: %s", item.convert2string()), UVM_LOW)
        `uvm_info("DEBUG_DRV", $sformatf("Interface before: valid=%b ready=%b", 
            vif.valid_a, vif.ready_a), UVM_LOW)
        
        super.drive_item(item);
        
        `uvm_info("DEBUG_DRV", $sformatf("Interface after: valid=%b ready=%b", 
            vif.valid_a, vif.ready_a), UVM_LOW)
        `uvm_info("DEBUG_DRV", "=== Drive complete ===", UVM_LOW)
    endtask
endclass
```

#### Step 3: Create Burst Driver

**File: `agent/port_a_agent/burst_port_a_driver.svh`**

```systemverilog
class burst_port_a_driver extends port_a_driver;
    `uvm_component_utils(burst_port_a_driver)
    
    int burst_count = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task drive_item(port_a_item item);
        // Drive in burst mode - keep valid high
        vif.drv_cb.data_a  <= item.data_a;
        vif.drv_cb.addr_a  <= item.addr_a;
        vif.drv_cb.valid_a <= 1'b1;
        @(vif.drv_cb);
        
        burst_count++;
        
        // Deassert valid every 4 transactions
        if (burst_count % 4 == 0) begin
            vif.drv_cb.valid_a <= 1'b0;
            @(vif.drv_cb);
        end
    endtask
endclass
```

#### Step 4: Create Tests Using Factory Overrides

**File: `tests/fast_test.svh`**

```systemverilog
class fast_test extends router_base_test;
    `uvm_component_utils(fast_test)
    
    function void build_phase(uvm_phase phase);
        // Override both port drivers with fast versions
        port_a_driver::type_id::set_type_override(fast_port_a_driver::get_type());
        port_b_driver::type_id::set_type_override(fast_port_b_driver::get_type());
        
        super.build_phase(phase);
    endfunction
    
    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);
        cfg.enable_dpi_scoreboard = 1;
    endfunction
    
    task run_phase(uvm_phase phase);
        router_base_vseq seq;
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Running with FAST drivers", UVM_LOW)
        
        seq = router_base_vseq::type_id::create("seq");
        seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
endclass
```

**File: `tests/debug_test.svh`**

```systemverilog
class debug_test extends router_base_test;
    `uvm_component_utils(debug_test)
    
    function void build_phase(uvm_phase phase);
        // Use debug drivers for detailed logging
        port_a_driver::type_id::set_type_override(debug_port_a_driver::get_type());
        
        super.build_phase(phase);
    endfunction
    
    task run_phase(uvm_phase phase);
        router_base_vseq seq;
        
        phase.raise_objection(this);
        
        seq = router_base_vseq::type_id::create("seq");
        seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
endclass
```

**File: `tests/burst_test.svh`**

```systemverilog
class burst_test extends router_base_test;
    `uvm_component_utils(burst_test)
    
    function void build_phase(uvm_phase phase);
        // Use burst drivers
        port_a_driver::type_id::set_type_override(burst_port_a_driver::get_type());
        port_b_driver::type_id::set_type_override(burst_port_b_driver::get_type());
        
        super.build_phase(phase);
    endfunction
    
    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);
        cfg.enable_dpi_scoreboard = 1;
    endfunction
    
    task run_phase(uvm_phase phase);
        back_to_back_vseq seq;
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Running with BURST drivers", UVM_LOW)
        
        seq = back_to_back_vseq::type_id::create("seq");
        seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
endclass
```

#### Step 5: Instance Override Example

**File: `tests/mixed_driver_test.svh`**

```systemverilog
class mixed_driver_test extends router_base_test;
    `uvm_component_utils(mixed_driver_test)
    
    function void build_phase(uvm_phase phase);
        // Instance override - only port_a uses fast driver
        set_inst_override_by_type("m_env.m_port_a_agent.drv",
            port_a_driver::get_type(),
            fast_port_a_driver::get_type());
        
        // Instance override - only port_b uses burst driver
        set_inst_override_by_type("m_env.m_port_b_agent.drv",
            port_b_driver::get_type(),
            burst_port_b_driver::get_type());
        
        super.build_phase(phase);
    endfunction
    
    task run_phase(uvm_phase phase);
        router_base_vseq seq;
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Port A: FAST, Port B: BURST", UVM_LOW)
        
        seq = router_base_vseq::type_id::create("seq");
        seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
endclass
```

**Testing:** Run different driver variants

```bash
make run TEST=fast_test
make run TEST=burst_test
make run TEST=debug_test UVM_VERBOSITY=UVM_HIGH
make run TEST=mixed_driver_test
```

---

### 3.2 Layered Sequences

**Goal:** Create protocol-level sequences on top of signal-level sequences.

#### Step 1: Create Protocol Transaction

**File: `seq/router_protocol_item.svh`**

```systemverilog
class router_protocol_item extends uvm_sequence_item;
    `uvm_object_utils(router_protocol_item)
    
    typedef enum {PORT_A, PORT_B} port_select_e;
    
    rand port_select_e port;
    rand bit [7:0] data;
    rand bit [3:0] dest_port;
    
    constraint valid_port_c {
        dest_port inside {[0:3]};
    }
    
    function new(string name = "router_protocol_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf("Protocol: port=%s data=0x%02h dest=%0d",
            port.name(), data, dest_port);
    endfunction
endclass
```

#### Step 2: Create Layered Sequence

**File: `seq/router_protocol_sequence.svh`**

```systemverilog
class router_protocol_sequence extends uvm_sequence #(router_protocol_item);
    `uvm_object_utils(router_protocol_sequence)
    
    router_virtual_sequencer p_vseqr;
    
    function new(string name = "router_protocol_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        router_protocol_item protocol_item;
        
        `uvm_do(protocol_item)
        
        // Convert protocol item to signal-level transactions
        if (protocol_item.port == router_protocol_item::PORT_A) begin
            send_port_a(protocol_item.data, protocol_item.dest_port);
        end else begin
            send_port_b(protocol_item.data, protocol_item.dest_port);
        end
    endtask
    
    virtual task send_port_a(bit [7:0] data, bit [3:0] addr);
        port_a_base_sequence port_a_seq;
        
        port_a_seq = port_a_base_sequence::type_id::create("port_a_seq");
        port_a_seq.data_val = data;
        port_a_seq.addr_val = addr;
        
        `uvm_info(get_type_name(), $sformatf("Sending via Port A: data=0x%02h addr=%0d", 
            data, addr), UVM_MEDIUM)
        
        port_a_seq.start(p_vseqr.p_port_a_seqr);
    endtask
    
    virtual task send_port_b(bit [7:0] data, bit [3:0] addr);
        port_b_base_sequence port_b_seq;
        
        port_b_seq = port_b_base_sequence::type_id::create("port_b_seq");
        port_b_seq.data_val = data;
        port_b_seq.addr_val = addr;
        
        `uvm_info(get_type_name(), $sformatf("Sending via Port B: data=0x%02h addr=%0d", 
            data, addr), UVM_MEDIUM)
        
        port_b_seq.start(p_vseqr.p_port_b_seqr);
    endtask
endclass
```

#### Step 3: Create Multi-Packet Protocol Sequence

**File: `seq/multi_packet_protocol_vseq.svh`**

```systemverilog
class multi_packet_protocol_vseq extends router_base_vseq;
    `uvm_object_utils(multi_packet_protocol_vseq)
    
    rand int num_packets;
    
    constraint reasonable_packets_c {
        num_packets inside {[10:50]};
    }
    
    function new(string name = "multi_packet_protocol_vseq");
        super.new(name);
    endfunction
    
    virtual task body();
        router_protocol_sequence proto_seq;
        
        `uvm_info(get_type_name(), $sformatf("Sending %0d protocol packets", num_packets), UVM_LOW)
        
        repeat (num_packets) begin
            proto_seq = router_protocol_sequence::type_id::create("proto_seq");
            proto_seq.p_vseqr = p_sequencer;
            proto_seq.start(null);
        end
    endtask
endclass
```

#### Step 4: Create Test Using Layered Sequences

**File: `tests/protocol_test.svh`**

```systemverilog
class protocol_test extends router_base_test;
    `uvm_component_utils(protocol_test)
    
    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);
        cfg.enable_dpi_scoreboard = 1;
    endfunction
    
    task run_phase(uvm_phase phase);
        multi_packet_protocol_vseq seq;
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "Running protocol-level test", UVM_LOW)
        
        seq = multi_packet_protocol_vseq::type_id::create("seq");
        assert(seq.randomize() with {num_packets == 20;});
        seq.start(m_env.m_vseqr);
        
        phase.drop_objection(this);
    endtask
endclass
```

---

## Phase 4: Optional Enhancements

### 4.1 Reactive Drivers (Optional)

Create if you need reactive protocol (handshaking, backpressure).

**File: `agent/port_a_agent/reactive_port_a_driver.svh`**

```systemverilog
class reactive_port_a_driver extends port_a_driver;
    `uvm_component_utils(reactive_port_a_driver)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task drive_item(port_a_item item);
        // Wait for ready signal before driving
        @(vif.drv_cb);
        vif.drv_cb.valid_a <= 1'b1;
        vif.drv_cb.data_a  <= item.data_a;
        vif.drv_cb.addr_a  <= item.addr_a;
        
        // Wait for handshake
        wait(vif.drv_cb.ready_a == 1'b1);
        @(vif.drv_cb);
        
        vif.drv_cb.valid_a <= 1'b0;
        
        `uvm_info("REACTIVE_DRV", "Handshake completed", UVM_HIGH)
    endtask
endclass
```

### 4.2 Advanced Phasing (Optional)

Use for complex test coordination.

**Example: Extract phase for scoreboard final checks**

```systemverilog
class router_scoreboard_dpi extends uvm_scoreboard;
    // ... existing code ...
    
    function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        
        // Check for leftover items in C++ model
        byte unsigned data;
        for (int port = 0; port < 4; port++) begin
            while (router_model_get_output(port, data)) begin
                `uvm_warning("SB_DPI", $sformatf("Leftover data in model port[%0d]: 0x%02h", 
                    port, data))
            end
        end
    endfunction
endclass
```

---

## Quick Reference

### Compilation & Run

```bash
# Compile with DPI-C and coverage
make compile TEST=<test_name>

# Run test
make run TEST=<test_name>

# Run with verbosity
make run TEST=<test_name> UVM_VERBOSITY=UVM_HIGH

# Generate coverage report
make report

# View coverage in browser
make html
```

### Test Progression

```bash
# Phase 1: Foundation
make run TEST=config_test
make run TEST=error_injection_test

# Phase 2: Verification Quality
make run TEST=dpi_test
make run TEST=comprehensive_coverage_test

# Phase 3: Advanced Architecture
make run TEST=fast_test
make run TEST=burst_test
make run TEST=debug_test
make run TEST=mixed_driver_test
make run TEST=protocol_test
```

### Debugging Tips

1. **Config issues:** Set `UVM_VERBOSITY=UVM_HIGH` to see config_db messages
2. **Factory issues:** Use `factory.print()` in test to see overrides
3. **DPI issues:** Check `.so` compiled correctly, check `LD_LIBRARY_PATH`
4. **Coverage low:** Run `make report` and check which bins are empty

---

## Summary Checklist

- [ ] Configuration Objects implemented
- [ ] Error Injection working
- [ ] DPI-C model compiling and passing tests
- [ ] Coverage class merged and connected
- [ ] Factory overrides creating driver variants
- [ ] Layered sequences abstracting protocol
- [ ] All tests passing with DPI scoreboard
- [ ] Coverage > 80%
- [ ] Code reviewed and documented

---

## Next Steps

After completing this roadmap:

1. **RAL Implementation** - Register Abstraction Layer
2. **Constraint Randomization** - Advanced constraints
3. **UVM Callbacks** - Dynamic behavior injection
4. **Virtual Sequences** - Complex test scenarios
5. **Regression Suite** - Automated test running

Good luck with your implementation! 🚀
