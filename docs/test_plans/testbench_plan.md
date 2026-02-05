# Router UVM Testbench Plan

## Overview

This document outlines the steps to complete the UVM testbench for the `dual_port_router` DUT.

## DUT Summary

- **Port A**: 8-bit data input with 2-bit address, valid/ready handshake
- **Port B**: 8-bit data input with 2-bit address, valid/ready handshake
- **Register Interface**: APB-like control plane (addr, wdata, rdata, en, we)
- **Outputs**: 4 output ports (data_out[4], valid_out[4])

## Completed Components

### Agents

| Agent | Item | Sequencer | Driver | Monitor | Agent Container |
|-------|------|-----------|--------|---------|-----------------|
| port_a_agent | ✅ | ✅ | ✅ | ✅ | ✅ |
| port_b_agent | ✅ | ✅ | ✅ | ✅ | ✅ |
| reg_agent | ✅ | ✅ | ✅ | ✅ | ⬜ |
| output_agent | ✅ | N/A | N/A | ✅ | ✅ |

### Interface

- `dual_port_router_if.sv` - Contains clocking blocks and modports

---

## Next Steps

### Step 1: Create Environment (`env/router_env.svh`)

The environment instantiates all agents and connects them.

**Contains:**
- All 4 agents (port_a, port_b, reg, output)
- Virtual sequencer
- Scoreboard
- Analysis port connections

```systemverilog
class router_env extends uvm_env;
    port_a_agent    m_port_a_agent;
    port_b_agent    m_port_b_agent;
    reg_agent       m_reg_agent;
    output_agent    m_output_agent;
    
    router_virtual_sequencer m_vseqr;
    router_scoreboard        m_scoreboard;
    // ...
endclass
```

---

### Step 2: Create Virtual Sequencer (`env/router_virtual_sequencer.svh`)

Holds handles to all agent sequencers for coordinated multi-agent sequences.

**Contains:**
- Handles to port_a_sequencer, port_b_sequencer, reg_sequencer

```systemverilog
class router_virtual_sequencer extends uvm_sequencer;
    port_a_sequencer p_port_a_seqr;
    port_b_sequencer p_port_b_seqr;
    reg_sequencer    p_reg_seqr;
    // ...
endclass
```

---

### Step 3: Create Scoreboard (`env/router_scoreboard.svh`)

Verifies DUT correctness by comparing inputs to outputs.

**Logic:**
1. Receive transactions from port_a_monitor and port_b_monitor
2. Receive transactions from output_monitor
3. Check: data sent to addr X should appear at output[X]

---

### Step 4: Create Sequences

#### Base Sequences (per agent)
- `seq/port_a_base_sequence.svh`
- `seq/port_b_base_sequence.svh`
- `seq/reg_base_sequence.svh`

#### Virtual Sequences (coordinated)
- `seq/router_base_vseq.svh` - Base virtual sequence
- `seq/collision_vseq.svh` - Test Port A and B collision
- `seq/priority_vseq.svh` - Test priority register
- `seq/disable_vseq.svh` - Test global enable = 0

---

### Step 5: Create Test (`test/router_base_test.svh`)

Creates environment and runs sequences.

```systemverilog
class router_base_test extends uvm_test;
    router_env m_env;
    
    virtual function void build_phase(uvm_phase phase);
        m_env = router_env::type_id::create("m_env", this);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        // Run sequences
    endtask
endclass
```

---

### Step 6: Create Top-Level Testbench (`tb/tb_top.sv`)

Instantiates DUT, interface, and starts UVM.

```systemverilog
module tb_top;
    logic clk, rst_n;
    
    // Clock generation
    // Reset generation
    
    // Interface
    dual_port_router_if intf(clk, rst_n);
    
    // DUT
    dual_port_router dut(...);
    
    // Set interface in config_db
    // Run test
endmodule
```

---

## RAL (Register Abstraction Layer)

RAL provides a high-level way to access registers without manually creating low-level transactions.

### Router Register Map

| Address | Name | Access | Description |
|---------|------|--------|-------------|
| 0x0 | ctrl_reg | R/W | [0]=Global Enable, [1]=Priority |
| 0x4 | status_reg | R | Reserved (returns 0) |
| 0x8 | collision_cnt | R | Collision counter (read-only) |

### RAL Components to Create

#### 1. Register Definitions (`ral/router_reg_block.svh`)

Define each register and its fields:

```systemverilog
// Control Register
class ctrl_reg extends uvm_reg;
    rand uvm_reg_field global_enable;
    rand uvm_reg_field priority;
    // ...
endclass

// Collision Counter Register
class collision_cnt_reg extends uvm_reg;
    rand uvm_reg_field count;
    // ...
endclass

// Register Block (contains all registers)
class router_reg_block extends uvm_reg_block;
    rand ctrl_reg          ctrl;
    rand uvm_reg           status;
    rand collision_cnt_reg collision_cnt;
    uvm_reg_map            default_map;
    // ...
endclass
```

#### 2. Register Adapter (`ral/router_reg_adapter.svh`)

Converts between `uvm_reg_bus_op` and your `reg_item`:

```systemverilog
class router_reg_adapter extends uvm_reg_adapter;

    // Convert register op to bus transaction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        reg_item item = reg_item::type_id::create("item");
        item.reg_addr  = rw.addr[3:0];
        item.reg_wdata = rw.data;
        item.reg_en    = 1;
        item.reg_we    = (rw.kind == UVM_WRITE);
        return item;
    endfunction

    // Convert bus transaction back to register op
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        reg_item item;
        if (!$cast(item, bus_item)) `uvm_fatal(...)
        rw.data   = (rw.kind == UVM_READ) ? item.reg_rdata : item.reg_wdata;
        rw.status = UVM_IS_OK;
    endfunction
endclass
```

#### 3. Predictor (Optional but recommended)

Updates register model based on observed bus transactions:

```systemverilog
// In environment, use built-in predictor:
uvm_reg_predictor #(reg_item) m_predictor;
```

### RAL Integration in Environment

```systemverilog
class router_env extends uvm_env;
    // ... agents ...
    
    // RAL components
    router_reg_block    m_reg_model;
    router_reg_adapter  m_reg_adapter;
    uvm_reg_predictor #(reg_item) m_predictor;

    virtual function void build_phase(uvm_phase phase);
        // Create register model
        m_reg_model = router_reg_block::type_id::create("m_reg_model");
        m_reg_model.build();
        m_reg_model.lock_model();
        
        // Create adapter
        m_reg_adapter = router_reg_adapter::type_id::create("m_reg_adapter");
        
        // Create predictor
        m_predictor = uvm_reg_predictor#(reg_item)::type_id::create("m_predictor", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // Connect register model to sequencer via adapter
        m_reg_model.default_map.set_sequencer(m_reg_agent.seqr, m_reg_adapter);
        
        // Connect predictor
        m_predictor.map = m_reg_model.default_map;
        m_predictor.adapter = m_reg_adapter;
        m_reg_agent.mon.ap.connect(m_predictor.bus_in);
    endfunction
endclass
```

### Using RAL in Tests

Instead of manually creating register transactions:

```systemverilog
// Without RAL (manual)
reg_item item = reg_item::type_id::create("item");
item.reg_addr = 4'h0;
item.reg_wdata = 32'h3;
item.reg_we = 1;
// ... start sequence ...

// With RAL (abstracted)
m_env.m_reg_model.ctrl.write(status, 32'h3);  // Write
m_env.m_reg_model.ctrl.read(status, rdata);   // Read
m_env.m_reg_model.ctrl.global_enable.set(1);  // Set field
m_env.m_reg_model.update(status);             // Update DUT
```

### RAL Benefits

1. **Abstraction** - Access registers by name, not address
2. **Mirror** - Model tracks expected register values
3. **Checking** - Automatic compare of expected vs actual
4. **Backdoor** - Direct access for speed (optional)
5. **Coverage** - Built-in register coverage

---

## RAL Implementation Plan (Step-by-Step)

### Phase 1: Create Register Model

#### Task 1.1: Create `ctrl_reg` class (`ral/ctrl_reg.svh`)

```systemverilog
class ctrl_reg extends uvm_reg;
    `uvm_object_utils(ctrl_reg)

    rand uvm_reg_field global_enable;  // Bit 0
    rand uvm_reg_field priority;       // Bit 1
    rand uvm_reg_field reserved;       // Bits 31:2

    function new(string name = "ctrl_reg");
        super.new(name, 32, UVM_NO_COVERAGE);  // 32-bit register
    endfunction

    virtual function void build();
        global_enable = uvm_reg_field::type_id::create("global_enable");
        global_enable.configure(this, 1, 0, "RW", 0, 1'h1, 1, 1, 0);
        //                      parent, size, lsb, access, volatile, reset, has_reset, is_rand, individually_accessible

        priority = uvm_reg_field::type_id::create("priority");
        priority.configure(this, 1, 1, "RW", 0, 1'h0, 1, 1, 0);

        reserved = uvm_reg_field::type_id::create("reserved");
        reserved.configure(this, 30, 2, "RO", 0, 30'h0, 1, 0, 0);
    endfunction
endclass
```

#### Task 1.2: Create `collision_cnt_reg` class (`ral/collision_cnt_reg.svh`)

```systemverilog
class collision_cnt_reg extends uvm_reg;
    `uvm_object_utils(collision_cnt_reg)

    rand uvm_reg_field count;

    function new(string name = "collision_cnt_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        count = uvm_reg_field::type_id::create("count");
        count.configure(this, 32, 0, "RO", 0, 32'h0, 1, 0, 0);  // Read-only
    endfunction
endclass
```

#### Task 1.3: Create `router_reg_block` class (`ral/router_reg_block.svh`)

```systemverilog
class router_reg_block extends uvm_reg_block;
    `uvm_object_utils(router_reg_block)

    rand ctrl_reg          ctrl;
    rand collision_cnt_reg collision_cnt;

    uvm_reg_map default_map;

    function new(string name = "router_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Create registers
        ctrl = ctrl_reg::type_id::create("ctrl");
        ctrl.configure(this, null, "");
        ctrl.build();

        collision_cnt = collision_cnt_reg::type_id::create("collision_cnt");
        collision_cnt.configure(this, null, "");
        collision_cnt.build();

        // Create address map
        default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);
        default_map.add_reg(ctrl,          'h0, "RW");
        default_map.add_reg(collision_cnt, 'h8, "RO");

        lock_model();
    endfunction
endclass
```

---

### Phase 2: Create Register Adapter

#### Task 2.1: Create `router_reg_adapter` (`ral/router_reg_adapter.svh`)

```systemverilog
class router_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(router_reg_adapter)

    function new(string name = "router_reg_adapter");
        super.new(name);
        supports_byte_enable = 0;
        provides_responses   = 1;
    endfunction

    // Convert UVM register operation to bus transaction
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        reg_item item = reg_item::type_id::create("item");
        
        item.reg_addr  = rw.addr[3:0];
        item.reg_wdata = rw.data;
        item.reg_en    = 1'b1;
        item.reg_we    = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;
        
        return item;
    endfunction

    // Convert bus transaction back to register operation
    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        reg_item item;
        
        if (!$cast(item, bus_item)) begin
            `uvm_fatal("RAL_ADAPTER", "Failed to cast bus_item to reg_item")
        end
        
        rw.data   = item.reg_rdata;
        rw.status = UVM_IS_OK;
    endfunction
endclass
```

---

### Phase 3: Integrate RAL into Environment

#### Task 3.1: Update `router_env.svh`

Add to class members:
```systemverilog
// RAL components
router_reg_block                  m_reg_model;
router_reg_adapter                m_reg_adapter;
uvm_reg_predictor #(reg_item)     m_predictor;
```

Add to `build_phase`:
```systemverilog
// Create and build register model
m_reg_model = router_reg_block::type_id::create("m_reg_model");
m_reg_model.build();

// Create adapter
m_reg_adapter = router_reg_adapter::type_id::create("m_reg_adapter");

// Create predictor
m_predictor = uvm_reg_predictor#(reg_item)::type_id::create("m_predictor", this);
```

Add to `connect_phase`:
```systemverilog
// Connect RAL to sequencer via adapter
m_reg_model.default_map.set_sequencer(m_reg_agent.seqr, m_reg_adapter);
m_reg_model.default_map.set_auto_predict(0);  // Use explicit predictor

// Connect predictor
m_predictor.map     = m_reg_model.default_map;
m_predictor.adapter = m_reg_adapter;
m_reg_agent.mon.ap.connect(m_predictor.bus_in);
```

---

### Phase 4: Create RAL Test Sequences

#### Task 4.1: Create `ral_sanity_vseq` (`seq/ral_sanity_vseq.svh`)

```systemverilog
class ral_sanity_vseq extends router_base_vseq;
    `uvm_object_utils(ral_sanity_vseq)

    router_reg_block reg_model;  // Set by test

    function new(string name = "ral_sanity_vseq");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t rdata;

        `uvm_info(get_type_name(), "Starting RAL sanity test", UVM_LOW)

        // Test 1: Read default value of ctrl_reg
        reg_model.ctrl.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("ctrl_reg default = 0x%08h", rdata), UVM_LOW)
        assert(rdata == 32'h1) else `uvm_error(get_type_name(), "ctrl_reg default mismatch!")

        // Test 2: Write and read back ctrl_reg
        reg_model.ctrl.write(status, 32'h3);  // Enable + Priority=Port B
        reg_model.ctrl.read(status, rdata);
        assert(rdata == 32'h3) else `uvm_error(get_type_name(), "ctrl_reg write/read mismatch!")

        // Test 3: Read collision counter (should be 0)
        reg_model.collision_cnt.read(status, rdata);
        `uvm_info(get_type_name(), $sformatf("collision_cnt = %0d", rdata), UVM_LOW)

        // Test 4: Field-level access
        reg_model.ctrl.global_enable.set(0);  // Disable router
        reg_model.ctrl.update(status);
        
        reg_model.ctrl.mirror(status, UVM_CHECK);  // Verify mirror matches DUT

        `uvm_info(get_type_name(), "RAL sanity test complete", UVM_LOW)
    endtask
endclass
```

---

### RAL Implementation Checklist

| Task | File | Status |
|------|------|--------|
| 1.1 | `ral/ctrl_reg.svh` | ⬜ |
| 1.2 | `ral/collision_cnt_reg.svh` | ⬜ |
| 1.3 | `ral/router_reg_block.svh` | ⬜ |
| 2.1 | `ral/router_reg_adapter.svh` | ⬜ |
| 3.1 | Update `env/router_env.svh` | ⬜ |
| 4.1 | `seq/ral_sanity_vseq.svh` | ⬜ |

---

### RAL Test Scenarios

| Test | Description | RAL Methods Used |
|------|-------------|------------------|
| Read defaults | Verify reset values | `read()` |
| Write/read | Write and read back | `write()`, `read()` |
| Field access | Access individual fields | `set()`, `get()`, `update()` |
| Mirror check | Verify model matches DUT | `mirror()` |
| Predict | Auto-update model on observed transactions | Predictor |

---

## Test Scenarios to Implement

| Test | Description | Components Used |
|------|-------------|-----------------|
| Basic Port A | Send single transaction via Port A | port_a_agent |
| Basic Port B | Send single transaction via Port B | port_b_agent |
| Register R/W | Read/write control registers | reg_agent |
| Collision | Send on both ports simultaneously | port_a + port_b + reg |
| Priority | Change priority, verify winner | port_a + port_b + reg |
| Disable | Set global_enable=0, verify blocked | all agents |

---

## Coverage Implementation

Functional coverage tracks which scenarios have been exercised during simulation.

### Coverage Types

#### 1. Transaction Coverage
Cover important fields in each transaction type.

#### 2. Cross Coverage
Cover interactions between different signals.

#### 3. Register Coverage
Built-in with RAL (register read/write/field coverage).

---

### Phase 1: Create Coverage Collector (`env/router_coverage.svh`)

```systemverilog
class router_coverage extends uvm_subscriber #(port_a_item);
    `uvm_component_utils(router_coverage)

    // Coverage groups
    covergroup port_a_cg;
        addr_cp: coverpoint m_item.addr {
            bins addr_0 = {2'b00};
            bins addr_1 = {2'b01};
            bins addr_2 = {2'b10};
            bins addr_3 = {2'b11};
        }
        
        data_cp: coverpoint m_item.data {
            bins low    = {[8'h00:8'h3F]};
            bins mid    = {[8'h40:8'hBF]};
            bins high   = {[8'hC0:8'hFF]};
        }
        
        // Cross coverage
        addr_data_cross: cross addr_cp, data_cp;
    endgroup

    covergroup port_b_cg;
        // Similar to port_a_cg
    endgroup

    covergroup collision_cg;
        option.per_instance = 1;
        
        port_a_valid: coverpoint port_a_valid_sig;
        port_b_valid: coverpoint port_b_valid_sig;
        
        collision: cross port_a_valid, port_b_valid {
            bins both_valid = binsof(port_a_valid) intersect {1} &&
                              binsof(port_b_valid) intersect {1};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        port_a_cg = new();
        port_b_cg = new();
        collision_cg = new();
    endfunction

    virtual function void write(port_a_item t);
        m_item = t;
        port_a_cg.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), 
            $sformatf("Port A Coverage: %.2f%%", port_a_cg.get_coverage()), 
            UVM_LOW)
    endfunction
endclass
```

---

### Phase 2: Integrate Coverage into Environment

Update `router_env.svh`:

```systemverilog
class router_env extends uvm_env;
    // ... existing components ...
    
    router_coverage m_coverage;
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // ... existing builds ...
        
        m_coverage = router_coverage::type_id::create("m_coverage", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // ... existing connections ...
        
        // Connect coverage to monitors
        m_port_a_agent.mon.ap.connect(m_coverage.analysis_export);
    endfunction
endclass
```

---

### Phase 3: Enable Coverage Collection

Add to `Makefile`:

```makefile
# Coverage flags for VCS
COV_FLAGS = -cm line+cond+fsm+tgl+branch+assert
COV_FLAGS += -cm_dir coverage.vdb
COV_FLAGS += -cm_name test_$(TEST)

compile:
    vcs $(VCS_FLAGS) $(COV_FLAGS) $(SRC_FILES)

run:
    ./simv +UVM_TESTNAME=$(TEST) -cm line+cond+fsm+tgl

# Generate coverage report
report:
    urg -dir coverage.vdb -report coverage_report
```

---

### Coverage Checklist

| Task | File | Status |
|------|------|--------|
| 1. Create coverage collector | `env/router_coverage.svh` | ⬜ |
| 2. Define covergroups | `env/router_coverage.svh` | ⬜ |
| 3. Integrate into environment | `env/router_env.svh` | ⬜ |
| 4. Update Makefile | `Makefile` | ⬜ |
| 5. Generate reports | Run `make report` | ⬜ |

---

### Coverage Goals

| Metric | Target | Description |
|--------|--------|-------------|
| Line Coverage | >95% | All code lines executed |
| Branch Coverage | >90% | All decision branches taken |
| Functional Coverage | 100% | All scenarios exercised |
| Register Coverage | 100% | All registers/fields accessed |

---

## DPI-C Golden Reference Model

DPI-C allows SystemVerilog to call C/C++ functions, useful for creating a golden reference model.

### Why Use DPI-C for Reference Model?

1. **Performance** - C++ is faster than SystemVerilog for complex algorithms
2. **Reusability** - Use existing C++ models or libraries
3. **Debug** - Easier to debug complex logic in C++
4. **Portability** - Reference model can be used in software simulations

---

### Architecture

```
┌─────────────────────────────────────────┐
│         UVM Scoreboard                   │
│  ┌─────────────┐      ┌──────────────┐ │
│  │   Monitor   │      │   DPI-C      │ │
│  │   Actual    │──────│   Golden     │ │
│  │   Output    │      │   Reference  │ │
│  └─────────────┘      └──────────────┘ │
│                              │          │
│                              ▼          │
│                       ┌──────────────┐ │
│                       │  C++ Model   │ │
│                       │  (.so/.dll)  │ │
│                       └──────────────┘ │
└─────────────────────────────────────────┘
```

---

### Phase 1: Create C++ Reference Model (`dpi/router_model.cpp`)

```cpp
#include "router_model.h"
#include <cstdio>
#include <queue>

// Router state
struct RouterState {
    bool global_enable;
    bool priority_port_b;
    std::queue<uint8_t> port_fifos[4];
};

static RouterState router_state;

// DPI-C exported functions
extern "C" {

// Initialize the model
void router_model_init() {
    router_state.global_enable = true;
    router_state.priority_port_b = false;
    for (int i = 0; i < 4; i++) {
        while (!router_state.port_fifos[i].empty()) {
            router_state.port_fifos[i].pop();
        }
    }
    printf("[C++ Model] Router initialized\n");
}

// Write to control register
void router_model_write_ctrl(uint32_t data) {
    router_state.global_enable = (data & 0x1);
    router_state.priority_port_b = (data & 0x2) >> 1;
    printf("[C++ Model] Control: enable=%d, priority_b=%d\n",
           router_state.global_enable, router_state.priority_port_b);
}

// Process Port A transaction
void router_model_port_a(uint8_t data, uint8_t addr) {
    if (!router_state.global_enable) return;
    
    if (addr < 4) {
        router_state.port_fifos[addr].push(data);
        printf("[C++ Model] Port A: data=0x%02x -> output[%d]\n", data, addr);
    }
}

// Process Port B transaction
void router_model_port_b(uint8_t data, uint8_t addr) {
    if (!router_state.global_enable) return;
    
    if (addr < 4) {
        router_state.port_fifos[addr].push(data);
        printf("[C++ Model] Port B: data=0x%02x -> output[%d]\n", data, addr);
    }
}

// Get expected output for a given port
int router_model_get_output(uint8_t port, uint8_t* data) {
    if (port >= 4) return 0;
    
    if (!router_state.port_fifos[port].empty()) {
        *data = router_state.port_fifos[port].front();
        router_state.port_fifos[port].pop();
        printf("[C++ Model] Output[%d] = 0x%02x\n", port, *data);
        return 1; // Valid
    }
    return 0; // No data
}

} // extern "C"
```

---

### Phase 2: Create DPI-C Header (`dpi/router_model.h`)

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

#endif // ROUTER_MODEL_H
```

---

### Phase 3: Create SystemVerilog DPI Import (`dpi/router_dpi_pkg.sv`)

```systemverilog
package router_dpi_pkg;
    
    // Import DPI-C functions
    import "DPI-C" function void router_model_init();
    import "DPI-C" function void router_model_write_ctrl(int unsigned data);
    import "DPI-C" function void router_model_port_a(byte unsigned data, byte unsigned addr);
    import "DPI-C" function void router_model_port_b(byte unsigned data, byte unsigned addr);
    import "DPI-C" function int router_model_get_output(byte unsigned port, output byte unsigned data);

endpackage
```

---

### Phase 4: Update Scoreboard to Use DPI-C Model

```systemverilog
class router_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(router_scoreboard)

    import router_dpi_pkg::*;

    // Analysis ports
    uvm_analysis_imp_port_a #(port_a_item, router_scoreboard) port_a_imp;
    uvm_analysis_imp_output #(output_item, router_scoreboard) output_imp;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        port_a_imp = new("port_a_imp", this);
        output_imp = new("output_imp", this);
        
        // Initialize DPI-C model
        router_model_init();
    endfunction

    virtual function void write_port_a(port_a_item t);
        // Feed transaction to C++ model
        router_model_port_a(t.data, t.addr);
    endfunction

    virtual function void write_output(output_item t);
        byte unsigned expected_data;
        int valid;
        
        // Get expected output from C++ model
        valid = router_model_get_output(t.port, expected_data);
        
        if (valid && t.valid) begin
            if (t.data == expected_data) begin
                `uvm_info(get_type_name(), 
                    $sformatf("PASS: Port[%0d] data=0x%02x", t.port, t.data), 
                    UVM_MEDIUM)
            end else begin
                `uvm_error(get_type_name(), 
                    $sformatf("FAIL: Port[%0d] Expected=0x%02x Got=0x%02x", 
                        t.port, expected_data, t.data))
            end
        end
    endfunction
endclass
```

---

### Phase 5: Create Separate DPI-C Scoreboard (Recommended Alternative)

Instead of modifying the existing scoreboard, create a **separate DPI-C scoreboard** that runs alongside the original.

#### Why This Approach?

✅ **No Risk** - Keep working SV scoreboard untouched  
✅ **Dual Checking** - Both scoreboards verify simultaneously  
✅ **Easy Comparison** - Compare SV vs. C++ results  
✅ **Flexible** - Enable/disable via configuration  
✅ **Clean Design** - Single responsibility per scoreboard  

#### Architecture

```
router_env
├── router_scoreboard        (existing - SV queue-based)
└── router_scoreboard_dpi    (new - C++ model-based)
        ↓
    Both receive same transactions
    Both check independently
    Both report separately
```

#### Implementation: `env/router_scoreboard_dpi.svh`

```systemverilog
`ifndef ROUTER_SCOREBOARD_DPI_SVH
`define ROUTER_SCOREBOARD_DPI_SVH

import router_dpi_pkg::*;

`uvm_analysis_imp_decl(_port_a_dpi)
`uvm_analysis_imp_decl(_port_b_dpi)
`uvm_analysis_imp_decl(_output_dpi)
`uvm_analysis_imp_decl(_reg_dpi)

class router_scoreboard_dpi extends uvm_scoreboard;
    `uvm_component_utils(router_scoreboard_dpi)
    
    // Analysis imports (with _dpi suffix to avoid naming conflicts)
    uvm_analysis_imp_port_a_dpi #(port_a_item, router_scoreboard_dpi) port_a_imp;
    uvm_analysis_imp_port_b_dpi #(port_b_item, router_scoreboard_dpi) port_b_imp;
    uvm_analysis_imp_output_dpi #(output_item, router_scoreboard_dpi) output_imp;
    uvm_analysis_imp_reg_dpi    #(reg_item, router_scoreboard_dpi)    reg_imp;
    
    int match_count;
    int mismatch_count;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);
        output_imp = new("output_imp", this);
        reg_imp = new("reg_imp", this);
        
        // Initialize C++ model
        router_model_init();
        `uvm_info(get_type_name(), "DPI-C Scoreboard built, C++ model initialized", UVM_LOW)
    endfunction
    
    // Feed Port A transactions to C++ model
    virtual function void write_port_a_dpi(port_a_item item);
        if (item.ready_a) begin
            router_model_port_a(item.data_a, item.addr_a);
            `uvm_info("SB_DPI", $sformatf("Port A -> C++: data=0x%02h addr=%0d", 
                item.data_a, item.addr_a), UVM_HIGH)
        end
    endfunction
    
    // Feed Port B transactions to C++ model
    virtual function void write_port_b_dpi(port_b_item item);
        if (item.ready_b) begin
            router_model_port_b(item.data_b, item.addr_b);
            `uvm_info("SB_DPI", $sformatf("Port B -> C++: data=0x%02h addr=%0d", 
                item.data_b, item.addr_b), UVM_HIGH)
        end
    endfunction
    
    // Feed register writes to C++ model
    virtual function void write_reg_dpi(reg_item item);
        if (item.reg_we && item.reg_en) begin
            router_model_write_ctrl(item.reg_wdata);
            `uvm_info("SB_DPI", $sformatf("Reg Write -> C++: data=0x%08h", 
                item.reg_wdata), UVM_HIGH)
        end
    endfunction
    
    // Check output against C++ model
    virtual function void write_output_dpi(output_item item);
        byte unsigned expected_data;
        int valid;
        
        // Query C++ model for expected output
        valid = router_model_get_output(item.port_idx, expected_data);
        
        if (valid) begin
            if (item.data == expected_data) begin
                `uvm_info("SB_DPI", $sformatf("✓ DPI MATCH port[%0d]: exp=0x%02h act=0x%02h", 
                    item.port_idx, expected_data, item.data), UVM_MEDIUM)
                match_count++;
            end else begin
                `uvm_error("SB_DPI", $sformatf("✗ DPI MISMATCH port[%0d]: exp=0x%02h act=0x%02h", 
                    item.port_idx, expected_data, item.data))
                mismatch_count++;
            end
        end else begin
            `uvm_error("SB_DPI", $sformatf("✗ UNEXPECTED output port[%0d]: data=0x%02h (C++ has no data)", 
                item.port_idx, item.data))
            mismatch_count++;
        end
    endfunction
    
    // Report DPI scoreboard results
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "    DPI-C Scoreboard Results           ", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Matches:    %0d", match_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Mismatches: %0d", mismatch_count), UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        
        if (mismatch_count > 0) begin
            `uvm_error(get_type_name(), 
                $sformatf("DPI SCOREBOARD FAILED - %0d mismatches detected", mismatch_count))
        end else begin
            `uvm_info(get_type_name(), "✓ DPI SCOREBOARD PASSED - All checks successful!", UVM_LOW)
        end
    endfunction
endclass

`endif
```

#### Update Environment to Support Both Scoreboards

Modify `env/router_env.svh`:

```systemverilog
class router_env extends uvm_env;
    `uvm_component_utils(router_env)
    
    // ... existing agents ...
    
    // Dual scoreboard support
    router_scoreboard     m_scoreboard;      // Original SV-based
    router_scoreboard_dpi m_scoreboard_dpi;  // New DPI-C based
    
    // Configuration flag (can be set from test or command line)
    bit enable_dpi_scoreboard = 1;  // Default: enabled
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // ... build agents ...
        
        // Always create original scoreboard
        m_scoreboard = router_scoreboard::type_id::create("m_scoreboard", this);
        
        // Optionally create DPI scoreboard
        if (enable_dpi_scoreboard) begin
            m_scoreboard_dpi = router_scoreboard_dpi::type_id::create("m_scoreboard_dpi", this);
            `uvm_info(get_type_name(), "DPI-C scoreboard enabled", UVM_LOW)
        end else begin
            `uvm_info(get_type_name(), "DPI-C scoreboard disabled", UVM_LOW)
        end
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect original scoreboard (always)
        m_port_a_agent.mon.ap.connect(m_scoreboard.port_a_imp);
        m_port_b_agent.mon.ap.connect(m_scoreboard.port_b_imp);
        m_output_agent.monitor.ap.connect(m_scoreboard.output_imp);
        
        // Connect DPI scoreboard (if enabled)
        if (enable_dpi_scoreboard) begin
            m_port_a_agent.mon.ap.connect(m_scoreboard_dpi.port_a_imp);
            m_port_b_agent.mon.ap.connect(m_scoreboard_dpi.port_b_imp);
            m_output_agent.monitor.ap.connect(m_scoreboard_dpi.output_imp);
            m_reg_agent.mon.ap.connect(m_scoreboard_dpi.reg_imp);
        end
        
        // ... other connections ...
    endfunction
endclass
```

#### Add to Package (`tests/router_pkg.svh`)

```systemverilog
// After scoreboard section
`include "env/router_scoreboard.svh"
`include "env/router_scoreboard_dpi.svh"  // Add this

// Before environment
`include "env/router_env.svh"
```

#### Configuration Options

**Enable/disable from test:**

```systemverilog
class my_test extends router_base_test;
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env.enable_dpi_scoreboard = 0;  // Disable DPI scoreboard
    endfunction
endclass
```

**Enable/disable from command line:**

```bash
# Disable DPI scoreboard
./simv +UVM_TESTNAME=router_base_test +uvm_set_config_int=*,enable_dpi_scoreboard,0

# Enable DPI scoreboard (default)
./simv +UVM_TESTNAME=router_base_test +uvm_set_config_int=*,enable_dpi_scoreboard,1
```

#### Expected Output (Both Scoreboards Running)

```
--- UVM Report Summary ---
========================================
    Scoreboard Statistics:
========================================
  Matches: 567
  Mismatches: 0
TEST PASSED - All checks passed!
========================================
    DPI-C Scoreboard Results
========================================
  Matches:    567
  Mismatches: 0
✓ DPI SCOREBOARD PASSED - All checks successful!
========================================
```

#### Benefits of Dual Scoreboard Approach

| Benefit | Description |
|---------|-------------|
| **Cross-Verification** | If SV and C++ disagree, one has a bug |
| **No Risk** | Original scoreboard still works if DPI has issues |
| **Learning** | Experiment with DPI-C without breaking verification |
| **Debugging** | Compare results to isolate issues |
| **Flexibility** | Run one, both, or neither easily |
| **Gradual Transition** | Can move to pure DPI-C over time |

---

### Phase 6: Compile with DPI-C

Update `Makefile`:

```makefile
# DPI-C compilation
DPI_DIR = dpi
DPI_SRC = $(DPI_DIR)/router_model.cpp
DPI_SO = $(DPI_DIR)/router_model.so

# Compile C++ shared library
$(DPI_SO): $(DPI_SRC)
    g++ -shared -fPIC -o $@ $< -I$(VCS_HOME)/include

# VCS compilation with DPI
compile: $(DPI_SO)
    vcs -sverilog -full64 \
        -timescale=1ns/1ps \
        -ntb_opts uvm-1.2 \
        $(DPI_DIR)/router_dpi_pkg.sv \
        $(SRC_FILES) \
        $(TB_FILES) \
        -LDFLAGS "-Wl,-rpath,$(DPI_DIR) -L$(DPI_DIR) -lrouter_model" \
        -o simv

clean:
    rm -rf $(DPI_SO) simv* csrc *.log
```

---

### DPI-C Implementation Checklist

| Task | File | Status |
|------|------|--------|
| 1. Create C++ model | `dpi/router_model.cpp` | ⬜ |
| 2. Create C++ header | `dpi/router_model.h` | ⬜ |
| 3. Create SV DPI package | `dpi/router_dpi_pkg.sv` | ⬜ |
| 4. Create DPI scoreboard | `env/router_scoreboard_dpi.svh` | ⬜ |
| 5. Update environment | `env/router_env.svh` | ⬜ |
| 6. Add to package | `tests/router_pkg.svh` | ⬜ |
| 7. Update Makefile | `Makefile` | ⬜ |
| 8. Compile and test | Run simulation | ⬜ |

---

### DPI-C Best Practices

1. **Keep It Simple** - Start with basic functions, add complexity gradually
2. **Memory Management** - Be careful with pointers; avoid memory leaks
3. **Thread Safety** - DPI-C calls are synchronous; no threading needed
4. **Debug** - Use printf in C++ and `$display` in SV for debugging
5. **Performance** - DPI-C calls have overhead; batch operations when possible

---

### DPI-C vs. Pure SystemVerilog Reference

| Aspect | DPI-C | Pure SV |
|--------|-------|---------|
| Performance | Faster | Slower |
| Complexity | Higher | Lower |
| Debugging | C++ tools | Waveforms |
| Reusability | High | Medium |
| Portability | Need recompile | Direct |

---

## File Structure

```
Router_UVM/
├── src/
│   ├── dual_port_router.sv
│   └── dual_port_router_if.sv
├── agent/
│   ├── port_a_agent/
│   ├── port_b_agent/
│   ├── reg_agent/
│   └── output_agent/
├── env/
│   ├── router_env.svh
│   ├── router_virtual_sequencer.svh
│   ├── router_scoreboard.svh         # Original SV-based scoreboard
│   ├── router_scoreboard_dpi.svh     # DPI-C based scoreboard (optional)
│   └── router_coverage.svh           # Coverage collector
├── ral/
│   ├── ctrl_reg.svh
│   ├── collision_cnt_reg.svh
│   ├── router_reg_block.svh          # Register model
│   └── router_reg_adapter.svh        # Converts uvm_reg_bus_op <-> reg_item
├── seq/
│   ├── port_a_base_sequence.svh
│   ├── port_b_base_sequence.svh
│   ├── reg_base_sequence.svh
│   ├── router_base_vseq.svh
│   ├── collision_vseq.svh
│   ├── priority_vseq.svh
│   ├── disable_vseq.svh
│   └── ral_sanity_vseq.svh
├── tests/
│   ├── router_pkg.svh
│   ├── router_base_test.svh
│   └── ral_sanity_test.svh
├── tb/
│   └── tb_top.sv
├── dpi/
│   ├── router_model.cpp              # C++ golden reference model
│   ├── router_model.h                # C++ header
│   ├── router_model.so               # Compiled shared library
│   └── router_dpi_pkg.sv             # SystemVerilog DPI imports
├── docs/
│   └── testbench_plan.md
└── Makefile
```
