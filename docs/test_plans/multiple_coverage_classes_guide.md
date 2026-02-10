# Multiple Coverage Classes Guide

## Overview

This guide shows how to create **multiple specialized coverage classes** to measure different aspects of your design verification. Instead of one monolithic coverage class, you'll create separate classes focused on specific verification goals.

---

## Table of Contents

1. [Why Multiple Coverage Classes?](#why-multiple-coverage-classes)
2. [Architecture Overview](#architecture-overview)
3. [Coverage Class Types](#coverage-class-types)
4. [Step-by-Step Implementation](#step-by-step-implementation)
5. [Integration with Environment](#integration-with-environment)
6. [Controlling Coverage Classes](#controlling-coverage-classes)
7. [Analyzing Results](#analyzing-results)

---

## Why Multiple Coverage Classes?

### Benefits

✅ **Separation of Concerns**: Each class focuses on one aspect  
✅ **Selective Enabling**: Enable only what you need for specific tests  
✅ **Cleaner Reports**: Separate coverage reports per category  
✅ **Performance**: Disable expensive coverage when not needed  
✅ **Team Organization**: Different engineers can own different classes  

### Example Use Cases

| Coverage Class | Purpose | When to Use |
|---|---|---|
| **Functional** | Protocol scenarios, data patterns | All tests |
| **Performance** | Throughput, latency, back-pressure | Performance tests only |
| **Stress** | Corner cases, rare combinations | Stress/regression tests |
| **Power** | Low-power modes, clock gating | Power verification |

---

## Architecture Overview

```
                     Monitors
                    /   |   \
                   /    |    \
              Port A  Port B  Output
                 |      |      |
        +--------+------+------+--------+
        |        |      |      |        |
        v        v      v      v        v
   +----------+  +-----------+  +----------+
   |Functional|  |Performance|  |  Stress  |
   | Coverage |  | Coverage  |  | Coverage |
   +----------+  +-----------+  +----------+
   
   All classes can be enabled/disabled independently
```

---

## Coverage Class Types

### 1. Functional Coverage (`router_functional_coverage`)

**Purpose**: Measure feature and scenario coverage

**What to Cover**:
- Register field values and transitions
- Port arbitration scenarios
- Data routing patterns
- Collision detection
- Priority changes
- Enable/disable scenarios

### 2. Performance Coverage (`router_performance_coverage`)

**Purpose**: Measure performance-related scenarios

**What to Cover**:
- Throughput levels (packets/cycle)
- Back-to-back transactions
- Pipeline utilization
- Latency buckets
- Bandwidth utilization per output
- Sustained traffic patterns

### 3. Stress Coverage (`router_stress_coverage`)

**Purpose**: Measure corner case and stress scenarios

**What to Cover**:
- Rare value combinations
- Maximum queue depths
- Rapid priority switching
- All outputs active simultaneously
- Collision bursts (multiple consecutive collisions)
- Edge case data patterns (0x00, 0xFF, alternating)

---

## Step-by-Step Implementation

### Step 1: Create Base Coverage Class (Optional)

Create a base class with common functionality to avoid code duplication.

**File**: `env/router_coverage_base.svh`

```systemverilog
`ifndef ROUTER_COVERAGE_BASE_SVH
`define ROUTER_COVERAGE_BASE_SVH

class router_coverage_base extends uvm_component;
    `uvm_component_utils(router_coverage_base)
    
    // Common handles
    router_reg_block reg_model;
    
    // Common tracking variables
    int transaction_count;
    
    function new(string name = "router_coverage_base", uvm_component parent = null);
        super.new(name, parent);
        transaction_count = 0;
    endfunction
    
    // Common report function
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), 
            $sformatf("Total transactions sampled: %0d", transaction_count), 
            UVM_LOW)
    endfunction
    
    // Helper function to get register values
    function bit get_global_enable();
        uvm_reg_data_t data;
        if (reg_model != null) begin
            data = reg_model.ctrl_reg.get_mirrored_value();
            return data[0];
        end
        return 0;
    endfunction
    
    function bit get_priority();
        uvm_reg_data_t data;
        if (reg_model != null) begin
            data = reg_model.ctrl_reg.get_mirrored_value();
            return data[1];
        end
        return 0;
    endfunction
    
endclass

`endif
```

---

### Step 2: Create Functional Coverage Class

**File**: `env/router_functional_coverage.svh`

```systemverilog
`ifndef ROUTER_FUNCTIONAL_COVERAGE_SVH
`define ROUTER_FUNCTIONAL_COVERAGE_SVH

`uvm_analysis_imp_decl(_port_a_func)
`uvm_analysis_imp_decl(_port_b_func)

class router_functional_coverage extends router_coverage_base;
    `uvm_component_utils(router_functional_coverage)
    
    // Analysis ports
    uvm_analysis_imp_port_a_func #(port_a_item, router_functional_coverage) port_a_imp;
    uvm_analysis_imp_port_b_func #(port_b_item, router_functional_coverage) port_b_imp;
    uvm_analysis_imp #(output_item, router_functional_coverage) output_imp;
    
    // Transaction items
    port_a_item port_a_txn;
    port_b_item port_b_txn;
    output_item output_txn;
    
    // Sampling variables
    bit global_enable_s;
    bit priority_s;
    bit [7:0] data_a_s;
    bit [7:0] data_b_s;
    bit [1:0] addr_a_s;
    bit [1:0] addr_b_s;
    bit port_a_valid_s;
    bit port_b_valid_s;
    bit collision_s;
    int active_outputs_s;
    
    //----------------------------------------------------------
    // COVERGROUP 1: Register Configuration
    //----------------------------------------------------------
    covergroup cg_register_config;
        option.per_instance = 1;
        option.name = "functional_register_config";
        
        cp_enable: coverpoint global_enable_s {
            bins enabled = {1};
            bins disabled = {0};
        }
        
        cp_priority: coverpoint priority_s {
            bins port_a = {0};
            bins port_b = {1};
        }
        
        // Transitions
        cp_priority_trans: coverpoint priority_s {
            bins a_to_b = (0 => 1);
            bins b_to_a = (1 => 0);
            bins stable_a = (0 => 0);
            bins stable_b = (1 => 1);
        }
        
        // Cross coverage
        cross cp_enable, cp_priority;
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 2: Port Activity Patterns
    //----------------------------------------------------------
    covergroup cg_port_activity;
        option.per_instance = 1;
        option.name = "functional_port_activity";
        
        cp_port_a_active: coverpoint port_a_valid_s {
            bins active = {1};
            bins idle = {0};
        }
        
        cp_port_b_active: coverpoint port_b_valid_s {
            bins active = {1};
            bins idle = {0};
        }
        
        // Combined port activity
        cp_both_ports: coverpoint {port_a_valid_s, port_b_valid_s} {
            bins only_a = {2'b10};
            bins only_b = {2'b01};
            bins both = {2'b11};
            bins neither = {2'b00};
        }
        
        // Activity with priority setting
        cross cp_both_ports, priority_s {
            // Focus on collision cases
            ignore_bins no_collision = binsof(cp_both_ports) intersect {2'b00, 2'b01, 2'b10};
        }
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 3: Data Routing
    //----------------------------------------------------------
    covergroup cg_data_routing;
        option.per_instance = 1;
        option.name = "functional_data_routing";
        
        // Address coverage
        cp_addr_a: coverpoint addr_a_s {
            bins dest[4] = {[0:3]};
        }
        
        cp_addr_b: coverpoint addr_b_s {
            bins dest[4] = {[0:3]};
        }
        
        // Data pattern coverage
        cp_data_a: coverpoint data_a_s {
            bins zero = {8'h00};
            bins all_ones = {8'hFF};
            bins low = {[8'h01:8'h7F]};
            bins high = {[8'h80:8'hFE]};
        }
        
        cp_data_b: coverpoint data_b_s {
            bins zero = {8'h00};
            bins all_ones = {8'hFF};
            bins low = {[8'h01:8'h7F]};
            bins high = {[8'h80:8'hFE]};
        }
        
        // Route to all destinations
        cross cp_addr_a, cp_data_a;
        cross cp_addr_b, cp_data_b;
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 4: Collision Scenarios
    //----------------------------------------------------------
    covergroup cg_collision_scenarios;
        option.per_instance = 1;
        option.name = "functional_collisions";
        
        cp_collision: coverpoint collision_s {
            bins no_collision = {0};
            bins collision = {1};
        }
        
        cp_collision_dest: coverpoint {addr_a_s == addr_b_s} {
            bins same_dest = {1};
            bins diff_dest = {0};
        }
        
        // Collisions with different priority settings
        cross collision_s, priority_s {
            // Only care about actual collisions
            ignore_bins no_collision = binsof(collision_s) intersect {0};
        }
        
        // Same destination collisions
        cross collision_s, cp_collision_dest;
    endgroup
    
    //----------------------------------------------------------
    // Constructor and Methods
    //----------------------------------------------------------
    
    function new(string name = "router_functional_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_register_config = new();
        cg_port_activity = new();
        cg_data_routing = new();
        cg_collision_scenarios = new();
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);
        output_imp = new("output_imp", this);
    endfunction
    
    // Write functions for analysis ports
    function void write_port_a_func(port_a_item t);
        port_a_txn = t;
        port_a_valid_s = t.valid;
        data_a_s = t.data;
        addr_a_s = t.addr;
        sample_coverage();
    endfunction
    
    function void write_port_b_func(port_b_item t);
        port_b_txn = t;
        port_b_valid_s = t.valid;
        data_b_s = t.data;
        addr_b_s = t.addr;
        sample_coverage();
    endfunction
    
    function void write(output_item t);
        output_txn = t;
        // Count active outputs
        active_outputs_s = 0;
        for (int i = 0; i < 4; i++) begin
            if (t.valid_out[i]) active_outputs_s++;
        end
        sample_coverage();
    endfunction
    
    function void sample_coverage();
        // Get register values
        global_enable_s = get_global_enable();
        priority_s = get_priority();
        
        // Detect collision
        collision_s = port_a_valid_s && port_b_valid_s;
        
        // Sample all covergroups
        cg_register_config.sample();
        cg_port_activity.sample();
        
        if (port_a_valid_s || port_b_valid_s) begin
            cg_data_routing.sample();
        end
        
        if (collision_s) begin
            cg_collision_scenarios.sample();
        end
        
        transaction_count++;
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), 
            $sformatf("Functional Coverage: %.2f%%", $get_coverage()), 
            UVM_LOW)
    endfunction
    
endclass

`endif
```

---

### Step 3: Create Performance Coverage Class

**File**: `env/router_performance_coverage.svh`

```systemverilog
`ifndef ROUTER_PERFORMANCE_COVERAGE_SVH
`define ROUTER_PERFORMANCE_COVERAGE_SVH

`uvm_analysis_imp_decl(_port_a_perf)
`uvm_analysis_imp_decl(_port_b_perf)

class router_performance_coverage extends router_coverage_base;
    `uvm_component_utils(router_performance_coverage)
    
    // Analysis ports
    uvm_analysis_imp_port_a_perf #(port_a_item, router_performance_coverage) port_a_imp;
    uvm_analysis_imp_port_b_perf #(port_b_item, router_performance_coverage) port_b_imp;
    uvm_analysis_imp #(output_item, router_performance_coverage) output_imp;
    
    // Performance tracking
    int cycle_count;
    int port_a_txn_count;
    int port_b_txn_count;
    int output_txn_count;
    int collision_count;
    int back_to_back_count_a;
    int back_to_back_count_b;
    
    bit prev_valid_a;
    bit prev_valid_b;
    
    // Sampling variables
    int throughput_s;  // Transactions per cycle
    int utilization_a_s;  // % of cycles Port A is active
    int utilization_b_s;  // % of cycles Port B is active
    int active_outputs_s;
    bit back_to_back_a_s;
    bit back_to_back_b_s;
    
    //----------------------------------------------------------
    // COVERGROUP 1: Throughput
    //----------------------------------------------------------
    covergroup cg_throughput;
        option.per_instance = 1;
        option.name = "performance_throughput";
        
        cp_packets_per_cycle: coverpoint throughput_s {
            bins idle = {0};
            bins low = {[1:10]};
            bins medium = {[11:50]};
            bins high = {[51:100]};
            bins maximum = {[101:$]};
        }
        
        cp_active_outputs: coverpoint active_outputs_s {
            bins none = {0};
            bins single = {1};
            bins dual = {2};
            bins triple = {3};
            bins all = {4};
        }
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 2: Port Utilization
    //----------------------------------------------------------
    covergroup cg_port_utilization;
        option.per_instance = 1;
        option.name = "performance_port_util";
        
        cp_util_a: coverpoint utilization_a_s {
            bins idle = {0};
            bins low = {[1:25]};
            bins medium = {[26:75]};
            bins high = {[76:99]};
            bins full = {100};
        }
        
        cp_util_b: coverpoint utilization_b_s {
            bins idle = {0};
            bins low = {[1:25]};
            bins medium = {[26:75]};
            bins high = {[76:99]};
            bins full = {100};
        }
        
        // Both ports highly utilized
        cross cp_util_a, cp_util_b {
            bins both_high = binsof(cp_util_a.high) && binsof(cp_util_b.high);
            bins both_full = binsof(cp_util_a.full) && binsof(cp_util_b.full);
        }
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 3: Back-to-Back Transactions
    //----------------------------------------------------------
    covergroup cg_back_to_back;
        option.per_instance = 1;
        option.name = "performance_back_to_back";
        
        cp_b2b_a: coverpoint back_to_back_a_s {
            bins no = {0};
            bins yes = {1};
        }
        
        cp_b2b_b: coverpoint back_to_back_b_s {
            bins no = {0};
            bins yes = {1};
        }
        
        // Both ports doing back-to-back
        cross cp_b2b_a, cp_b2b_b;
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 4: Collision Rate
    //----------------------------------------------------------
    covergroup cg_collision_rate;
        option.per_instance = 1;
        option.name = "performance_collision_rate";
        
        cp_collision_percentage: coverpoint ((collision_count * 100) / (cycle_count + 1)) {
            bins none = {0};
            bins rare = {[1:5]};
            bins occasional = {[6:20]};
            bins frequent = {[21:50]};
            bins very_frequent = {[51:$]};
        }
    endgroup
    
    //----------------------------------------------------------
    // Constructor and Methods
    //----------------------------------------------------------
    
    function new(string name = "router_performance_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_throughput = new();
        cg_port_utilization = new();
        cg_back_to_back = new();
        cg_collision_rate = new();
        
        cycle_count = 0;
        port_a_txn_count = 0;
        port_b_txn_count = 0;
        collision_count = 0;
        prev_valid_a = 0;
        prev_valid_b = 0;
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);
        output_imp = new("output_imp", this);
    endfunction
    
    function void write_port_a_perf(port_a_item t);
        cycle_count++;
        
        if (t.valid) begin
            port_a_txn_count++;
            
            // Detect back-to-back
            back_to_back_a_s = prev_valid_a && t.valid;
            if (back_to_back_a_s) back_to_back_count_a++;
        end
        
        prev_valid_a = t.valid;
        calculate_metrics();
    endfunction
    
    function void write_port_b_perf(port_b_item t);
        if (t.valid) begin
            port_b_txn_count++;
            
            // Detect back-to-back
            back_to_back_b_s = prev_valid_b && t.valid;
            if (back_to_back_b_s) back_to_back_count_b++;
        end
        
        prev_valid_b = t.valid;
        calculate_metrics();
    endfunction
    
    function void write(output_item t);
        output_txn_count++;
        
        // Count active outputs
        active_outputs_s = 0;
        for (int i = 0; i < 4; i++) begin
            if (t.valid_out[i]) active_outputs_s++;
        end
        
        calculate_metrics();
    endfunction
    
    function void calculate_metrics();
        if (cycle_count > 0) begin
            throughput_s = output_txn_count / cycle_count;
            utilization_a_s = (port_a_txn_count * 100) / cycle_count;
            utilization_b_s = (port_b_txn_count * 100) / cycle_count;
        end
        
        // Detect collisions (both ports active)
        if (prev_valid_a && prev_valid_b) collision_count++;
        
        // Sample covergroups periodically (every 10 cycles)
        if (cycle_count % 10 == 0) begin
            cg_throughput.sample();
            cg_port_utilization.sample();
            cg_back_to_back.sample();
            cg_collision_rate.sample();
        end
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "=== Performance Metrics ===", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Cycles: %0d", cycle_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Port A Utilization: %0d%%", utilization_a_s), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Port B Utilization: %0d%%", utilization_b_s), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Collision Rate: %0d%%", (collision_count * 100) / (cycle_count + 1)), UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("Performance Coverage: %.2f%%", $get_coverage()), 
            UVM_LOW)
    endfunction
    
endclass

`endif
```

---

### Step 4: Create Stress Coverage Class

**File**: `env/router_stress_coverage.svh`

```systemverilog
`ifndef ROUTER_STRESS_COVERAGE_SVH
`define ROUTER_STRESS_COVERAGE_SVH

`uvm_analysis_imp_decl(_port_a_stress)
`uvm_analysis_imp_decl(_port_b_stress)

class router_stress_coverage extends router_coverage_base;
    `uvm_component_utils(router_stress_coverage)
    
    // Analysis ports
    uvm_analysis_imp_port_a_stress #(port_a_item, router_stress_coverage) port_a_imp;
    uvm_analysis_imp_port_b_stress #(port_b_item, router_stress_coverage) port_b_imp;
    uvm_analysis_imp #(output_item, router_stress_coverage) output_imp;
    
    // Stress scenario tracking
    int consecutive_collisions;
    int max_consecutive_collisions;
    int priority_switch_count;
    bit prev_priority;
    bit [7:0] prev_data_a;
    bit [7:0] prev_data_b;
    
    // Sampling variables
    bit [7:0] data_a_s;
    bit [7:0] data_b_s;
    bit collision_s;
    int collision_burst_s;
    bit rapid_priority_change_s;
    bit all_outputs_active_s;
    
    //----------------------------------------------------------
    // COVERGROUP 1: Edge Case Data Patterns
    //----------------------------------------------------------
    covergroup cg_edge_case_data;
        option.per_instance = 1;
        option.name = "stress_edge_data";
        
        cp_data_a_edge: coverpoint data_a_s {
            bins all_zeros = {8'h00};
            bins all_ones = {8'hFF};
            bins alternating_01 = {8'b01010101};
            bins alternating_10 = {8'b10101010};
            bins walking_ones[] = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins walking_zeros[] = {8'hFE, 8'hFD, 8'hFB, 8'hF7, 8'hEF, 8'hDF, 8'hBF, 8'h7F};
        }
        
        cp_data_b_edge: coverpoint data_b_s {
            bins all_zeros = {8'h00};
            bins all_ones = {8'hFF};
            bins alternating_01 = {8'b01010101};
            bins alternating_10 = {8'b10101010};
            bins walking_ones[] = {8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80};
            bins walking_zeros[] = {8'hFE, 8'hFD, 8'hFB, 8'hF7, 8'hEF, 8'hDF, 8'hBF, 8'h7F};
        }
        
        // Both ports with edge case data during collision
        cross collision_s, cp_data_a_edge, cp_data_b_edge {
            ignore_bins no_collision = binsof(collision_s) intersect {0};
        }
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 2: Collision Bursts
    //----------------------------------------------------------
    covergroup cg_collision_bursts;
        option.per_instance = 1;
        option.name = "stress_collision_bursts";
        
        cp_burst_length: coverpoint collision_burst_s {
            bins single = {1};
            bins short_burst = {[2:5]};
            bins medium_burst = {[6:10]};
            bins long_burst = {[11:20]};
            bins very_long_burst = {[21:$]};
        }
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 3: Rapid Priority Changes
    //----------------------------------------------------------
    covergroup cg_rapid_priority_changes;
        option.per_instance = 1;
        option.name = "stress_priority_changes";
        
        cp_rapid_change: coverpoint rapid_priority_change_s {
            bins no = {0};
            bins yes = {1};
        }
        
        // Rapid changes during collision
        cross rapid_priority_change_s, collision_s;
    endgroup
    
    //----------------------------------------------------------
    // COVERGROUP 4: Maximum Resource Usage
    //----------------------------------------------------------
    covergroup cg_max_resource_usage;
        option.per_instance = 1;
        option.name = "stress_max_usage";
        
        cp_all_outputs_active: coverpoint all_outputs_active_s {
            bins no = {0};
            bins yes = {1};
        }
        
        cp_collision_count: coverpoint consecutive_collisions {
            bins none = {0};
            bins few = {[1:3]};
            bins many = {[4:10]};
            bins excessive = {[11:$]};
        }
    endgroup
    
    //----------------------------------------------------------
    // Constructor and Methods
    //----------------------------------------------------------
    
    function new(string name = "router_stress_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_edge_case_data = new();
        cg_collision_bursts = new();
        cg_rapid_priority_changes = new();
        cg_max_resource_usage = new();
        
        consecutive_collisions = 0;
        max_consecutive_collisions = 0;
        priority_switch_count = 0;
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);
        output_imp = new("output_imp", this);
    endfunction
    
    function void write_port_a_stress(port_a_item t);
        data_a_s = t.data;
        sample_coverage();
    endfunction
    
    function void write_port_b_stress(port_b_item t);
        data_b_s = t.data;
        sample_coverage();
    endfunction
    
    function void write(output_item t);
        // Check if all outputs active
        all_outputs_active_s = 1;
        for (int i = 0; i < 4; i++) begin
            if (!t.valid_out[i]) all_outputs_active_s = 0;
        end
        sample_coverage();
    endfunction
    
    function void sample_coverage();
        bit current_priority;
        
        // Detect collision
        collision_s = (data_a_s != 0) && (data_b_s != 0);  // Simplified
        
        // Track collision bursts
        if (collision_s) begin
            consecutive_collisions++;
            if (consecutive_collisions > max_consecutive_collisions) begin
                max_consecutive_collisions = consecutive_collisions;
            end
        end else begin
            collision_burst_s = consecutive_collisions;
            consecutive_collisions = 0;
        end
        
        // Track rapid priority changes
        if (reg_model != null) begin
            current_priority = get_priority();
            if (current_priority != prev_priority) begin
                priority_switch_count++;
            end
            rapid_priority_change_s = (priority_switch_count > 5);  // More than 5 switches
            prev_priority = current_priority;
        end
        
        // Sample covergroups
        cg_edge_case_data.sample();
        
        if (collision_burst_s > 0) begin
            cg_collision_bursts.sample();
        end
        
        cg_rapid_priority_changes.sample();
        cg_max_resource_usage.sample();
        
        transaction_count++;
    endfunction
    
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), "=== Stress Test Metrics ===", UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("  Max Consecutive Collisions: %0d", max_consecutive_collisions), 
            UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("  Priority Switches: %0d", priority_switch_count), 
            UVM_LOW)
        `uvm_info(get_type_name(), 
            $sformatf("Stress Coverage: %.2f%%", $get_coverage()), 
            UVM_LOW)
    endfunction
    
endclass

`endif
```

---

## Integration with Environment

### Step 5: Update Environment Config

**File**: `env/router_env_config.svh`

Add config knobs to enable/disable each coverage class:

```systemverilog
class router_env_config extends uvm_object;
    `uvm_object_utils(router_env_config)
    
    // ... existing config fields ...
    
    // Coverage control
    bit enable_functional_coverage = 1;
    bit enable_performance_coverage = 0;  // Disabled by default (overhead)
    bit enable_stress_coverage = 0;       // Disabled by default
    
    // ... rest of config ...
endclass
```

---

### Step 6: Update Environment

**File**: `env/router_env.svh`

```systemverilog
class router_env extends uvm_env;
    `uvm_component_utils(router_env)
    
    // ... existing components ...
    
    // Multiple coverage classes
    router_functional_coverage  m_functional_cov;
    router_performance_coverage m_performance_cov;
    router_stress_coverage      m_stress_cov;
    
    // ... existing code ...
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // ... existing builds ...
        
        // Create coverage classes based on config
        if (m_cfg.enable_functional_coverage) begin
            m_functional_cov = router_functional_coverage::type_id::create("m_functional_cov", this);
            `uvm_info(get_type_name(), "Functional coverage enabled", UVM_LOW)
        end
        
        if (m_cfg.enable_performance_coverage) begin
            m_performance_cov = router_performance_coverage::type_id::create("m_performance_cov", this);
            `uvm_info(get_type_name(), "Performance coverage enabled", UVM_LOW)
        end
        
        if (m_cfg.enable_stress_coverage) begin
            m_stress_cov = router_stress_coverage::type_id::create("m_stress_cov", this);
            `uvm_info(get_type_name(), "Stress coverage enabled", UVM_LOW)
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // ... existing connections ...
        
        // Connect functional coverage
        if (m_cfg.enable_functional_coverage) begin
            m_port_a_agent.mon.ap.connect(m_functional_cov.port_a_imp);
            m_port_b_agent.mon.ap.connect(m_functional_cov.port_b_imp);
            m_output_agent.monitor.ap.connect(m_functional_cov.output_imp);
            m_functional_cov.reg_model = m_reg_model;
        end
        
        // Connect performance coverage
        if (m_cfg.enable_performance_coverage) begin
            m_port_a_agent.mon.ap.connect(m_performance_cov.port_a_imp);
            m_port_b_agent.mon.ap.connect(m_performance_cov.port_b_imp);
            m_output_agent.monitor.ap.connect(m_performance_cov.output_imp);
            m_performance_cov.reg_model = m_reg_model;
        end
        
        // Connect stress coverage
        if (m_cfg.enable_stress_coverage) begin
            m_port_a_agent.mon.ap.connect(m_stress_cov.port_a_imp);
            m_port_b_agent.mon.ap.connect(m_stress_cov.port_b_imp);
            m_output_agent.monitor.ap.connect(m_stress_cov.output_imp);
            m_stress_cov.reg_model = m_reg_model;
        end
    endfunction
    
endclass
```

---

### Step 7: Update Package File

**File**: `tests/router_pkg.svh`

Include all coverage files:

```systemverilog
package router_pkg;
    
    // ... existing imports and includes ...
    
    // Coverage classes
    `include "env/router_coverage_base.svh"
    `include "env/router_functional_coverage.svh"
    `include "env/router_performance_coverage.svh"
    `include "env/router_stress_coverage.svh"
    
    // ... rest of includes ...
    
endpackage
```

---

## Controlling Coverage Classes

### Method 1: Config in Test

```systemverilog
class performance_test extends router_base_test;
    `uvm_component_utils(performance_test)
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Enable only performance coverage
        cfg.enable_functional_coverage = 0;
        cfg.enable_performance_coverage = 1;
        cfg.enable_stress_coverage = 0;
    endfunction
    
endclass
```

### Method 2: Command Line

```bash
# Enable all coverage
./simv +UVM_TESTNAME=stress_test \
    +uvm_set_config_int=*,enable_functional_coverage,1 \
    +uvm_set_config_int=*,enable_performance_coverage,1 \
    +uvm_set_config_int=*,enable_stress_coverage,1

# Enable only functional (default)
./simv +UVM_TESTNAME=basic_test

# Performance test
./simv +UVM_TESTNAME=performance_test \
    +uvm_set_config_int=*,enable_performance_coverage,1
```

---

## Analyzing Results

### Separate Coverage Reports

Each coverage class can generate its own report:

```bash
# Generate coverage reports
urg -dir simv.vdb -format text

# Look for separate coverage groups:
# - functional_register_config
# - functional_port_activity
# - performance_throughput
# - stress_edge_data
```

### Viewing in DVE

```bash
dve -cov -dir simv.vdb
```

Navigate to:
- **Functional Coverage** → See feature scenarios
- **Performance Coverage** → See throughput/utilization
- **Stress Coverage** → See corner cases

---

## Example Test Strategy

| Test Type | Functional | Performance | Stress |
|-----------|-----------|-------------|--------|
| `basic_test` | ✅ | ❌ | ❌ |
| `random_test` | ✅ | ❌ | ❌ |
| `performance_test` | ❌ | ✅ | ❌ |
| `stress_test` | ❌ | ❌ | ✅ |
| `regression_test` | ✅ | ✅ | ✅ |

---

## Summary Checklist

- [ ] Create base coverage class (`router_coverage_base.svh`)
- [ ] Create functional coverage class
- [ ] Create performance coverage class
- [ ] Create stress coverage class
- [ ] Update environment config with enable flags
- [ ] Update environment to conditionally create coverage classes
- [ ] Update package file with includes
- [ ] Create tests that enable specific coverage
- [ ] Run simulations and verify separate reports
- [ ] Analyze coverage data per category

---

## Benefits Recap

✅ **Modularity**: Each class focuses on one aspect  
✅ **Performance**: Disable expensive coverage when not needed  
✅ **Clarity**: Separate reports make analysis easier  
✅ **Scalability**: Easy to add new coverage types  
✅ **Team Workflow**: Different engineers can own different coverage  

**Key Takeaway**: Multiple specialized coverage classes give you fine-grained control over what you measure and when, leading to better verification efficiency!

