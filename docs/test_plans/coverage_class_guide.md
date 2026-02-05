# UVM Functional Coverage Class - Step-by-Step Guide

## Overview
This guide walks you through creating a functional coverage class for your Router UVM testbench. Functional coverage measures how well your tests exercise the design's features and corner cases.

---

## Table of Contents
1. [What is Functional Coverage?](#what-is-functional-coverage)
2. [Coverage vs RAL Coverage](#coverage-vs-ral-coverage)
3. [Step-by-Step Implementation](#step-by-step-implementation)
4. [Best Practices](#best-practices)
5. [Example Scenarios to Cover](#example-scenarios-to-cover)

---

## What is Functional Coverage?

**Functional Coverage** tracks whether you've tested the interesting scenarios and corner cases in your design, such as:
- All register field values (enable=0/1, priority=0/1)
- Different data patterns on ports
- Collision scenarios (both ports active at same time)
- Disable scenarios (traffic arrives when router is disabled)
- Priority arbitration (which port wins based on priority setting)

---

## Coverage vs RAL Coverage

### RAL Coverage (What you just implemented)
- **UVM_CVR_ADDR_MAP**: Tracks which register addresses were accessed
- **UVM_CVR_REG_BITS**: Tracks basic register accesses
- Automatic, minimal setup required
- Generally gives low % because it measures address space coverage

### Functional Coverage (What you'll build)
- **Custom covergroups**: You define exactly what to measure
- Tracks meaningful scenarios and corner cases
- Requires explicit covergroup definitions
- Gives you detailed insight into test completeness

---

## Step-by-Step Implementation

### Step 1: Create the Coverage Class File

**Location**: `env/router_coverage.svh`

**Base Class**: Your coverage class should extend `uvm_subscriber` (or `uvm_component`)
- `uvm_subscriber` is convenient because it includes a built-in `write()` method for analysis ports

```systemverilog
class router_coverage extends uvm_subscriber #(output_item);
    `uvm_component_utils(router_coverage)
    
    function new(string name = "router_coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
```

---

### Step 2: Add Analysis Imports for Multiple Monitors

Since you want coverage from Port A, Port B, and Output monitors, you need multiple analysis imports:

```systemverilog
// At top of file, before class declaration:
`uvm_analysis_imp_decl(_port_a)
`uvm_analysis_imp_decl(_port_b)

class router_coverage extends uvm_subscriber #(output_item);
    `uvm_component_utils(router_coverage)
    
    // Analysis imps
    uvm_analysis_imp_port_a #(port_a_item, router_coverage) port_a_imp;
    uvm_analysis_imp_port_b #(port_b_item, router_coverage) port_b_imp;
    // Note: output_item uses the default write() from uvm_subscriber
```

---

### Step 3: Add Member Variables for Coverage Sampling

```systemverilog
    // Transaction items
    port_a_item port_a_txn;
    port_b_item port_b_txn;
    output_item output_txn;
    
    // Register model handle (for sampling register state)
    router_reg_block reg_model;
    
    // Coverage sampling variables
    bit global_enable;
    bit priority_val;
    bit port_a_valid;
    bit port_b_valid;
    int collision_count;
```

---

### Step 4: Define Covergroups

A **covergroup** defines what you want to measure. Here's a simple example:

```systemverilog
covergroup cg_register_fields;
    option.per_instance = 1;  // Each instance gets its own coverage
    option.name = "register_fields_cg";
    
    // Coverpoint: Track global_enable values
    cp_global_enable: coverpoint global_enable {
        bins enabled = {1};
        bins disabled = {0};
    }
    
    // Coverpoint: Track priority values
    cp_priority: coverpoint priority_val {
        bins port_a_priority = {0};
        bins port_b_priority = {1};
    }
    
    // Cross coverage: All combinations
    cross_enable_priority: cross cp_global_enable, cp_priority;
    // This creates 4 bins: {enabled, port_a}, {enabled, port_b}, 
    //                      {disabled, port_a}, {disabled, port_b}
endgroup
```

#### Covergroup Types You Should Create:

1. **Register Field Coverage**: Track all combinations of ctrl_reg fields
2. **Port A/B Transaction Coverage**: Track data patterns sent to each port
3. **Output Transaction Coverage**: Track which port won and why
4. **Collision Scenarios**: Track when both ports active simultaneously
5. **Disable Scenarios**: Track traffic when router disabled
6. **Collision Counter Coverage**: Track collision_cnt register values

---

### Step 5: Instantiate Covergroups in Constructor

```systemverilog
function new(string name = "router_coverage", uvm_component parent = null);
    super.new(name, parent);
    
    // Create analysis imps
    port_a_imp = new("port_a_imp", this);
    port_b_imp = new("port_b_imp", this);
    
    // Instantiate covergroups
    cg_register_fields = new();
    cg_port_a_transactions = new();
    // ... etc
endfunction
```

---

### Step 6: Implement Write Methods

These methods are called by monitors via analysis ports:

```systemverilog
// Called by output monitor (via uvm_subscriber base class)
virtual function void write(output_item t);
    output_txn = t;
    cg_output_transactions.sample();  // Sample coverage
endfunction

// Called by Port A monitor
function void write_port_a(port_a_item t);
    port_a_txn = t;
    port_a_valid = 1;
    cg_port_a_transactions.sample();
endfunction

// Called by Port B monitor
function void write_port_b(port_b_item t);
    port_b_txn = t;
    port_b_valid = 1;
    cg_port_b_transactions.sample();
endfunction
```

---

### Step 7: Add Helper Methods for Complex Scenarios

Some coverage scenarios need multiple pieces of information:

```systemverilog
function void sample_collision_scenario(bit collision);
    // Update state from register model
    if (reg_model != null) begin
        global_enable = reg_model.ctrl.global_enable.get_mirrored_value();
        priority_val = reg_model.ctrl.priority_val.get_mirrored_value();
    end
    
    collision_occurred = collision;
    cg_collision_scenarios.sample();
    
    // Reset flags
    port_a_valid = 0;
    port_b_valid = 0;
endfunction
```

**Called from scoreboard** when it detects a collision.

---

### Step 8: Integrate into Environment

**File**: `env/router_env.svh`

```systemverilog
class router_env extends uvm_env;
    // ... existing components ...
    router_coverage m_coverage;  // ADD THIS
    
    function void build_phase(uvm_phase phase);
        // ... existing code ...
        m_coverage = router_coverage::type_id::create("m_coverage", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        // ... existing connections ...
        
        // Connect monitors to coverage
        m_port_a_agent.mon.ap.connect(m_coverage.port_a_imp);
        m_port_b_agent.mon.ap.connect(m_coverage.port_b_imp);
        m_output_agent.monitor.ap.connect(m_coverage.analysis_export);
        
        // Pass register model handle
        m_coverage.reg_model = m_reg_model;
    endfunction
endclass
```

---

### Step 9: Sample Coverage from Scoreboard (Optional)

For complex scenarios like collisions, call coverage methods from scoreboard:

**File**: `env/router_scoreboard.svh`

```systemverilog
class router_scoreboard extends uvm_scoreboard;
    router_coverage m_coverage;  // Add handle
    
    function void write_output(output_item t);
        // ... existing checking logic ...
        
        // Sample collision coverage if both ports were valid
        if (got_port_a && got_port_b) begin
            m_coverage.sample_collision_scenario(1'b1);
        end
    endfunction
endclass
```

Then in `router_env.svh` connect_phase:
```systemverilog
m_scoreboard.m_coverage = m_coverage;
```

---

### Step 10: Add Coverage Report

Add a `report_phase` to your coverage class:

```systemverilog
virtual function void report_phase(uvm_phase phase);
    real total_cov;
    
    super.report_phase(phase);
    
    `uvm_info("COV_REPORT", "=== Functional Coverage Summary ===", UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Register Fields: %.2f%%", 
              cg_register_fields.get_coverage()), UVM_LOW)
    `uvm_info("COV_REPORT", $sformatf("  Port A Trans:    %.2f%%", 
              cg_port_a_transactions.get_coverage()), UVM_LOW)
    // ... etc for all covergroups ...
endfunction
```

---

### Step 11: Include in Package

**File**: `tests/router_pkg.svh`

```systemverilog
// After scoreboard, before environment
`include "env/router_coverage.svh"
`include "env/router_env.svh"
```

---

## Best Practices

### 1. Coverage Bins
- **Discrete values**: Use specific bins for known important values
  ```systemverilog
  coverpoint data {
      bins zero = {0};
      bins max = {8'hFF};
      bins mid = {[1:254]};
  }
  ```
  
- **Ranges**: Group similar values
  ```systemverilog
  coverpoint data {
      bins low = {[0:63]};
      bins mid = {[64:127]};
      bins high = {[128:191]};
      bins max = {[192:255]};
  }
  ```

### 2. Cross Coverage
Use `cross` to capture important combinations:
```systemverilog
cross cp_enable, cp_priority;  // Tests all combinations
```

### 3. Ignore Bins
Filter out impossible or uninteresting combinations:
```systemverilog
cross cp_collision, cp_enable {
    ignore_bins disabled_cases = binsof(cp_enable.disabled);
}
```

### 4. Per-Instance Coverage
Always set this for testbench components:
```systemverilog
covergroup cg_example;
    option.per_instance = 1;  // Each component instance tracks separately
```

---

## Example Scenarios to Cover

### For Your Router:

1. **Basic Register Operations**
   - ✓ global_enable = {0, 1}
   - ✓ priority_val = {0, 1}
   - ✓ All 4 combinations of enable × priority

2. **Port Traffic Patterns**
   - ✓ Data values in different ranges
   - ✓ Traffic when enabled vs disabled
   - ✓ Single port active vs both ports active

3. **Collision Scenarios**
   - ✓ Both ports valid with port_a_priority
   - ✓ Both ports valid with port_b_priority
   - ✓ Collision counter values: {0, low, medium, high}

4. **Priority Arbitration**
   - ✓ Port A wins when priority=0
   - ✓ Port B wins when priority=1
   - ✓ Cross: which port won × priority setting

5. **Disable Scenarios**
   - ✓ Disabled with no traffic
   - ✓ Disabled with port A traffic
   - ✓ Disabled with port B traffic
   - ✓ Disabled with both ports traffic

---

## Complete File Structure

```
Router_UVM/
├── env/
│   ├── router_coverage.svh      ← Your coverage class
│   ├── router_env.svh            ← Modified to include coverage
│   └── router_scoreboard.svh     ← Modified to call coverage methods
└── tests/
    └── router_pkg.svh            ← Include coverage.svh
```

---

## Compilation & VCS Flags

Coverage already enabled in your Makefile:
```makefile
VCS_FLAGS = ... -cm line+cond+fsm+tgl
```

This enables:
- `line`: Line coverage
- `cond`: Condition coverage  
- `fsm`: FSM coverage
- `tgl`: Toggle coverage

**Functional coverage** (covergroups) is automatically collected when covergroups are defined.

---

## Quick Start Checklist

- [ ] Step 1: Create `env/router_coverage.svh` class file
- [ ] Step 2: Declare analysis imps for multiple monitors
- [ ] Step 3: Add member variables for sampling
- [ ] Step 4: Define covergroups for each scenario
- [ ] Step 5: Instantiate covergroups in constructor
- [ ] Step 6: Implement `write()` methods
- [ ] Step 7: Add helper methods for complex scenarios
- [ ] Step 8: Add coverage component to environment
- [ ] Step 9: Connect monitors to coverage in environment
- [ ] Step 10: Add coverage report in report_phase
- [ ] Step 11: Include in package file
- [ ] Step 12: Compile and run tests
- [ ] Step 13: Check coverage report

---

## Debugging Coverage

If coverage is 0% or not sampling:

1. **Check connections**: Verify monitors connected to coverage analysis imps
2. **Check instantiation**: Verify covergroups instantiated in `new()`
3. **Check sampling**: Add `uvm_info` in `write()` methods to verify they're called
4. **Check variables**: Print coverpoint variables before `sample()` to verify values
5. **Check bins**: Use `get_inst_coverage()` to see which bins were hit

---

## Summary

Functional coverage helps you:
- Measure test quality (not just pass/fail)
- Identify untested corner cases
- Prove verification completeness
- Generate coverage reports for signoff

The key is defining **meaningful scenarios** that matter for your design!
