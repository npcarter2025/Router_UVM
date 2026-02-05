# Advanced UVM Features

This document covers advanced UVM features to practice after completing RAL implementation.

---

## Table of Contents

1. [Factory Overrides](#1-factory-overrides)
2. [Configuration Objects](#2-configuration-objects)
3. [Error Injection](#3-error-injection)
4. [Reactive Drivers](#4-reactive-drivers)
5. [Layered Sequences](#5-layered-sequences)
6. [Advanced Phasing](#6-advanced-phasing)
7. [TLM Ports Deep Dive](#7-tlm-ports-deep-dive)
8. [Field Macros](#8-field-macros)
9. [Reporting & Verbosity Control](#9-reporting--verbosity-control)
10. [Learning Projects](#learning-projects)

---

## Priority Guide

| Feature | Priority | Complexity | Learning Value |
|---------|----------|------------|----------------|
| Factory Overrides | ⭐⭐⭐ High | Medium | Very High |
| Configuration Objects | ⭐⭐⭐ High | Easy | High |
| Error Injection | ⭐⭐ Medium | Easy | High |
| Layered Sequences | ⭐⭐ Medium | Medium | Medium |
| Reactive Drivers | ⭐ Low | Medium | Medium |
| Advanced Phasing | ⭐ Low | Easy | Low |

---

## 1. Factory Overrides

### What It Is

The UVM factory allows you to **replace one class with another at runtime** without changing any code. This is one of the most powerful features in UVM!

### Why Use It?

- **Different driver implementations** (fast vs. slow, normal vs. debug)
- **Test-specific components** (inject errors, change timing)
- **Enhanced debugging** (add extra logging to specific components)
- **Reusability** (same testbench, different implementations)

### How It Works

```
Normal Flow:
Test creates → port_a_driver instance → used in testbench

With Factory Override:
Test creates → factory intercepts → returns fast_port_a_driver instead!
```

### Basic Example

**Step 1: Create base and derived classes**

```systemverilog
// Base driver (normal speed)
class port_a_driver extends uvm_driver #(port_a_item);
    `uvm_component_utils(port_a_driver)
    
    virtual dual_port_router_if vif;
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);  // Virtual method
            seq_item_port.item_done();
        end
    endtask
    
    virtual task drive_item(port_a_item item);
        @(vif.drv_cb);  // One clock delay
        vif.drv_cb.data_a  <= item.data_a;
        vif.drv_cb.addr_a  <= item.addr_a;
        vif.drv_cb.valid_a <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.valid_a <= 1'b0;
    endtask
endclass

// Fast driver (no delays)
class fast_port_a_driver extends port_a_driver;
    `uvm_component_utils(fast_port_a_driver)
    
    // Override drive_item to remove delays
    virtual task drive_item(port_a_item item);
        // Drive immediately - no clock delay!
        vif.drv_cb.data_a  <= item.data_a;
        vif.drv_cb.addr_a  <= item.addr_a;
        vif.drv_cb.valid_a <= 1'b1;
        // Continue immediately
    endtask
endclass
```

**Step 2: Use factory override in test**

```systemverilog
class speed_test extends router_base_test;
    `uvm_component_utils(speed_test)
    
    function void build_phase(uvm_phase phase);
        // Replace ALL port_a_driver instances with fast_port_a_driver
        port_a_driver::type_id::set_type_override(fast_port_a_driver::get_type());
        
        super.build_phase(phase);  // Creates fast driver automatically!
    endfunction
endclass
```

**Result:** Test runs faster without changing agent code!

### Types of Overrides

#### Type Override (Most Common)

Replace ALL instances of a type:

```systemverilog
// Replace every port_a_driver in the testbench
port_a_driver::type_id::set_type_override(fast_port_a_driver::get_type());
```

#### Instance Override (Selective)

Replace only specific instances:

```systemverilog
// Replace only port_a driver, not port_b
set_inst_override_by_type("m_env.m_port_a_agent.drv",
    port_a_driver::get_type(),
    fast_port_a_driver::get_type());
```

### Practical Use Cases

**1. Debug Driver:**

```systemverilog
class debug_port_a_driver extends port_a_driver;
    virtual task drive_item(port_a_item item);
        `uvm_info("DEBUG", $sformatf("Driving: %s", item.convert2string()), UVM_LOW)
        `uvm_info("DEBUG", $sformatf("Interface state: valid=%b ready=%b", 
            vif.valid_a, vif.ready_a), UVM_LOW)
        super.drive_item(item);
        `uvm_info("DEBUG", "Drive complete", UVM_LOW)
    endtask
endclass
```

**2. Burst Mode Driver:**

```systemverilog
class burst_port_a_driver extends port_a_driver;
    // Send multiple items back-to-back without deasserting valid
    virtual task drive_item(port_a_item item);
        vif.drv_cb.data_a  <= item.data_a;
        vif.drv_cb.addr_a  <= item.addr_a;
        vif.drv_cb.valid_a <= 1'b1;  // Keep valid high!
        @(vif.drv_cb);
        // Don't deassert valid - next item comes immediately
    endtask
endclass
```

### Best Practices

✅ **DO:**
- Use for behavior changes (timing, protocol variations)
- Keep base functionality in base class
- Use virtual methods for override points

❌ **DON'T:**
- Override for structural changes (use proper parameterization)
- Break interface contracts
- Create deep inheritance hierarchies

---

## 2. Configuration Objects

### What It Is

Configuration objects centralize testbench parameters and settings, making your testbench easily configurable.

### Why Use It?

- **Avoid hardcoded values** scattered throughout code
- **Easy test customization** without code changes
- **Pass configuration** to multiple components
- **Runtime flexibility** via command line

### Implementation

**Step 1: Create configuration class**

```systemverilog
class router_config extends uvm_object;
    `uvm_object_utils(router_config)
    
    // Testbench control
    bit enable_coverage = 1;
    bit enable_scoreboard = 1;
    bit enable_dpi_scoreboard = 1;
    
    // Test parameters
    int num_transactions = 100;
    int timeout_cycles = 1000;
    
    // Agent configuration
    bit port_a_active = 1;  // Active or passive
    bit port_b_active = 1;
    bit has_coverage = 1;
    
    // Protocol timing
    int min_delay_cycles = 1;
    int max_delay_cycles = 10;
    
    // Debug
    uvm_verbosity verbosity = UVM_MEDIUM;
    
    function new(string name = "router_config");
        super.new(name);
    endfunction
    
    // Optional: Field macros for printing/copying
    `uvm_object_utils_begin(router_config)
        `uvm_field_int(enable_coverage, UVM_DEFAULT)
        `uvm_field_int(num_transactions, UVM_DEFAULT)
        `uvm_field_int(port_a_active, UVM_DEFAULT)
    `uvm_object_utils_end
endclass
```

**Step 2: Create and set configuration in test**

```systemverilog
class configurable_test extends router_base_test;
    router_config cfg;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create config
        cfg = router_config::type_id::create("cfg");
        
        // Customize settings
        cfg.num_transactions = 1000;    // Long test
        cfg.enable_coverage = 0;        // Disable for speed
        cfg.min_delay_cycles = 0;       // Back-to-back
        
        // Put in config DB - accessible to all components
        uvm_config_db#(router_config)::set(this, "*", "config", cfg);
    endfunction
endclass
```

**Step 3: Get configuration in components**

```systemverilog
// In agent:
class port_a_agent extends uvm_agent;
    router_config cfg;
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get config from DB
        if (!uvm_config_db#(router_config)::get(this, "", "config", cfg)) begin
            `uvm_info("AGENT", "No config found, using defaults", UVM_LOW)
        end
        
        // Use config
        if (cfg.port_a_active) begin
            drv = port_a_driver::type_id::create("drv", this);
        end
    endfunction
endclass

// In sequence:
class configurable_vseq extends router_base_vseq;
    router_config cfg;
    
    virtual task body();
        // Get config
        if (!uvm_config_db#(router_config)::get(null, get_full_name(), "config", cfg)) begin
            cfg = router_config::type_id::create("cfg");  // Use defaults
        end
        
        // Use configured value
        repeat(cfg.num_transactions) begin
            `uvm_do_on(port_a_seq, p_port_a_seqr)
        end
    endtask
endclass
```

### Command Line Override

Set config from command line:

```bash
# In test:
if ($value$plusargs("NUM_TRANS=%d", cfg.num_transactions)) begin
    `uvm_info("TEST", $sformatf("Overriding num_transactions=%0d", 
        cfg.num_transactions), UVM_LOW)
end

# Run:
make TEST=configurable_test +NUM_TRANS=5000
```

### Benefits

✅ Single source of truth for configuration  
✅ Easy to create test variants  
✅ Runtime flexibility  
✅ Clean, maintainable code  

---

## 3. Error Injection

### What It Is

Intentionally inject errors to verify that your checking (scoreboard, assertions) actually works!

### Why Use It?

- **Verify checking works** - If injected error isn't caught, your checking is broken!
- **Test corner cases** - Protocol violations, data corruption
- **Stress test** - How does DUT handle errors?

### Implementation with Factory Override

**Step 1: Create error-injecting driver**

```systemverilog
class error_inject_driver extends port_a_driver;
    `uvm_component_utils(error_inject_driver)
    
    // Configuration
    int error_rate = 10;        // 10% of transactions
    bit corrupt_data = 1;       // Corrupt data field
    bit corrupt_addr = 0;       // Corrupt address field
    bit corrupt_protocol = 0;   // Protocol violations
    
    virtual task drive_item(port_a_item item);
        if ($urandom_range(100) < error_rate) begin
            inject_error(item);
        end else begin
            super.drive_item(item);  // Normal operation
        end
    endtask
    
    virtual task inject_error(port_a_item item);
        port_a_item corrupted = port_a_item::type_id::create("corrupted");
        corrupted.copy(item);
        
        `uvm_warning("ERROR_INJECT", $sformatf("INJECTING ERROR for %s", 
            item.convert2string()))
        
        if (corrupt_data) begin
            corrupted.data_a = ~item.data_a;  // Flip all bits
        end
        
        if (corrupt_addr) begin
            corrupted.addr_a = item.addr_a + 1;  // Wrong address
        end
        
        if (corrupt_protocol) begin
            // Drive without waiting for ready
            vif.drv_cb.data_a <= corrupted.data_a;
            vif.drv_cb.valid_a <= 1'b1;
            // Skip ready check!
        end else begin
            super.drive_item(corrupted);
        end
    endtask
endclass
```

**Step 2: Create error injection test**

```systemverilog
class error_test extends router_base_test;
    `uvm_component_utils(error_test)
    
    function void build_phase(uvm_phase phase);
        // Replace driver with error-injecting version
        port_a_driver::type_id::set_type_override(error_inject_driver::get_type());
        
        super.build_phase(phase);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        sanity_vseq vseq;
        
        phase.raise_objection(this);
        
        vseq = sanity_vseq::type_id::create("vseq");
        vseq.start(m_env.m_vseqr);
        
        #100ns;
        
        // Check that scoreboard caught errors
        if (m_env.m_scoreboard.mismatch_count == 0) begin
            `uvm_error("ERROR_TEST", "NO ERRORS DETECTED - Checking may be broken!")
        end else begin
            `uvm_info("ERROR_TEST", $sformatf("Successfully detected %0d errors", 
                m_env.m_scoreboard.mismatch_count), UVM_LOW)
        end
        
        phase.drop_objection(this);
    endtask
endclass
```

### Expected Results

```
UVM_WARNING: ERROR_INJECT: INJECTING ERROR for data_a=0x42
UVM_ERROR: SB: MISMATCH on port[0]: expected=0x42, actual=0xBD
...
UVM_INFO: ERROR_TEST: Successfully detected 10 errors
```

### Use Cases

- **Negative testing** - Verify error detection
- **Coverage** - Hit error handling code paths
- **Robustness** - Stress test corner cases

---

## 4. Reactive Drivers

### What It Is

**Active drivers** (what you have) initiate transactions.  
**Reactive drivers** respond to DUT requests.

### Difference

**Active (Your current drivers):**
```
Driver: "Here's data!"
DUT:    "OK, I'll take it when ready"
```

**Reactive:**
```
DUT:    "I need data!"
Driver: "OK, here it is"
```

### Example: Reactive Output Monitor

Your output monitor could be reactive - respond to DUT's output requests:

```systemverilog
class reactive_output_monitor extends output_monitor;
    
    virtual task run_phase(uvm_phase phase);
        forever begin
            @(vif.mon_cb);
            
            // Wait for DUT to output data
            if (vif.valid_out[0]) begin  // DUT initiates
                output_item item = output_item::type_id::create("item");
                item.port_idx = 0;
                item.data = vif.data_out[0];
                item.valid = vif.valid_out[0];
                
                ap.write(item);  // Send to scoreboard
            end
        end
    endtask
endclass
```

### When to Use

- Memory models (respond to read/write requests)
- Slave protocols (respond to master)
- Interrupt handlers (respond to interrupts)

**Your router:** Already mostly reactive (drivers wait for ready signals)

---

## 5. Layered Sequences

### What It Is

Build complex sequences by composing simpler sequences.

### Benefits

- **Reusability** - Combine existing sequences
- **Maintainability** - Change one layer, all users benefit
- **Abstraction** - High-level test intent

### Example

**Layer 1: Basic sequences (you have these)**

```systemverilog
class sanity_vseq extends router_base_vseq;
    // 8 transactions
endclass

class disable_vseq extends router_base_vseq;
    // Test enable/disable
endclass

class backtoback_vseq extends router_base_vseq;
    // Stress test
endclass
```

**Layer 2: Combined sequences**

```systemverilog
class comprehensive_vseq extends router_base_vseq;
    `uvm_object_utils(comprehensive_vseq)
    
    virtual task body();
        sanity_vseq      sanity;
        disable_vseq     disable;
        backtoback_vseq  stress;
        
        `uvm_info(get_type_name(), "Running comprehensive test suite", UVM_LOW)
        
        // Run all sequences in order
        `uvm_do(sanity)
        `uvm_do(disable)
        `uvm_do(stress)
        
        `uvm_info(get_type_name(), "Comprehensive test complete", UVM_LOW)
    endtask
endclass
```

**Layer 3: Randomized suite**

```systemverilog
class random_suite_vseq extends router_base_vseq;
    rand int num_iterations;
    rand sequence_type_e seq_type;
    
    constraint reasonable {
        num_iterations inside {[5:20]};
    }
    
    virtual task body();
        repeat(num_iterations) begin
            randcase
                30: `uvm_do(sanity)
                20: `uvm_do(disable)
                50: `uvm_do(backtoback)
            endcase
        end
    endtask
endclass
```

---

## 6. Advanced Phasing

### Standard UVM Phases (You're Using)

```
build_phase         - Create components
connect_phase       - Connect ports
end_of_elaboration  - Final setup (you use this!)
run_phase          - Main test execution
extract_phase      - Extract coverage/data
check_phase        - Run checks
report_phase       - Report results (you use this!)
```

### What You Could Explore

**1. Extract Phase**

Collect data after run completes:

```systemverilog
virtual function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    
    // Collect coverage
    port_a_cov = port_a_cg.get_coverage();
    port_b_cov = port_b_cg.get_coverage();
endfunction
```

**2. Check Phase**

Separate checking from reporting:

```systemverilog
virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    
    // Final checks
    if (expected_queue.size() != 0) begin
        `uvm_error("CHECK", "Unmatched transactions remain")
    end
endfunction
```

**3. Custom Phases** (Advanced)

Define your own phases for specific needs.

---

## 7. TLM Ports Deep Dive

### What You're Using

**`uvm_analysis_port`** - Broadcast to multiple subscribers

```systemverilog
// In monitor:
uvm_analysis_port #(port_a_item) ap;

// Sends to multiple places:
ap.write(item);  // → scoreboard
                 // → coverage
                 // → anyone else connected
```

### Other TLM Port Types

#### Blocking Put Port

```systemverilog
// Producer:
uvm_blocking_put_port #(port_a_item) put_port;
put_port.put(item);  // Blocks until consumer takes it

// Consumer:
uvm_blocking_put_imp #(port_a_item, consumer) put_export;
virtual task put(port_a_item item);
    // Process item
endtask
```

#### Blocking Get Port

```systemverilog
// Consumer requests:
uvm_blocking_get_port #(port_a_item) get_port;
get_port.get(item);  // Blocks until producer provides

// Producer:
uvm_blocking_get_imp #(port_a_item, producer) get_export;
virtual task get(output port_a_item item);
    // Provide item
endtask
```

**When to use:** Mailbox-like communication, backpressure handling

---

## 8. Field Macros

### What You're Using

```systemverilog
`uvm_object_utils_begin(port_a_item)
    `uvm_field_int(data_a, UVM_ALL_ON)
    `uvm_field_int(addr_a, UVM_ALL_ON)
`uvm_object_utils_end
```

### What These Do

Field macros auto-generate:
- `copy()` - Deep copy
- `compare()` - Field-by-field comparison
- `print()` / `convert2string()` - Formatted output
- `pack()` / `unpack()` - Serialization

### Flags

```systemverilog
`uvm_field_int(data_a, UVM_DEFAULT)        // Copy, compare, print
`uvm_field_int(data_a, UVM_NOCOPY)         // Don't copy
`uvm_field_int(data_a, UVM_NOCOMPARE)      // Don't compare
`uvm_field_int(data_a, UVM_NOPRINT)        // Don't print
`uvm_field_int(data_a, UVM_ALL_ON)         // Everything
```

### When NOT to Use

Some prefer manual implementation for:
- **Performance** - Macros have overhead
- **Control** - Custom copy/compare logic
- **Clarity** - Explicit code vs. "magic" macros

```systemverilog
// Manual implementation:
virtual function void do_copy(uvm_object rhs);
    port_a_item item;
    if (!$cast(item, rhs)) return;
    data_a = item.data_a;
    addr_a = item.addr_a;
endfunction
```

---

## 9. Reporting & Verbosity Control

### Current Usage

```systemverilog
`uvm_info("TAG", "Message", UVM_LOW)
`uvm_error("TAG", "Error message")
```

### Verbosity Levels

```systemverilog
UVM_NONE    // Only fatals
UVM_LOW     // Key milestones
UVM_MEDIUM  // Transaction level
UVM_HIGH    // Detailed
UVM_FULL    // Everything
UVM_DEBUG   // Debug info
```

### Advanced Controls

**1. ID Filtering**

```systemverilog
// In test:
set_report_id_action("PORT_A_DRV", UVM_NO_ACTION);  // Silence driver
set_report_id_action("SB", UVM_DISPLAY);            // Show scoreboard
```

**2. Severity Actions**

```systemverilog
// Make warnings into errors
set_report_severity_action(UVM_WARNING, UVM_ERROR);

// Count occurrences
set_report_severity_action(UVM_INFO, UVM_COUNT);
```

**3. File Logging**

```systemverilog
// Log to file
set_report_default_file(file_handle);
```

---

## Learning Projects

### Project 1: Speed Optimization ⭐⭐⭐

**Goal:** Create fast driver variant, measure speedup

**Tasks:**
1. Create `fast_port_a_driver` with no delays
2. Create `fast_port_b_driver` with no delays  
3. Use factory override in test
4. Compare simulation times

**Learning:** Factory overrides, performance analysis

---

### Project 2: Configurable Testbench ⭐⭐⭐

**Goal:** Make testbench fully configurable

**Tasks:**
1. Create `router_config` class
2. Add knobs for: coverage, transaction counts, timeouts
3. Use config in agents, sequences, env
4. Add command-line overrides

**Learning:** Config DB, parameterization

---

### Project 3: Error Detection Verification ⭐⭐

**Goal:** Verify scoreboard catches errors

**Tasks:**
1. Create `error_inject_driver`
2. Configure error rates and types
3. Run test, verify errors are caught
4. If not caught, fix scoreboard!

**Learning:** Error injection, validation

---

### Project 4: Test Suite ⭐⭐

**Goal:** Build comprehensive test from existing sequences

**Tasks:**
1. Create `comprehensive_vseq` that runs all tests
2. Create `random_suite_vseq` with randomized order
3. Compare coverage between targeted and random

**Learning:** Layered sequences, randomization

---

### Project 5: Debug Infrastructure ⭐

**Goal:** Enhanced debugging capabilities

**Tasks:**
1. Create `debug_driver` with detailed logging
2. Create `debug_monitor` tracking all transitions
3. Add transaction logging to file
4. Use factory override to enable/disable

**Learning:** Debugging, logging

---

## Recommended Learning Path

After completing RAL:

### Phase 1: Core Features (Do These)
1. ✅ **Factory Overrides** (Project 1 - Speed optimization)
2. ✅ **Configuration Objects** (Project 2 - Configurable testbench)
3. ✅ **Error Injection** (Project 3 - Verify checking)

### Phase 2: Enhancement (If Time)
4. ⏸️ **Layered Sequences** (Project 4 - Test suite)
5. ⏸️ **Debug Infrastructure** (Project 5 - Enhanced logging)

### Phase 3: Deep Dive (Reference)
6. 📚 **TLM Ports** - Understand communication mechanisms
7. 📚 **Field Macros** - Manual vs. automatic implementation
8. 📚 **Reporting** - Advanced message control

---

## Summary

These features will take your UVM skills to the next level:

**Must Learn:**
- ✅ Factory Overrides
- ✅ Configuration Objects
- ✅ Error Injection

**Should Learn:**
- ⏸️ Layered Sequences
- ⏸️ Advanced Phasing

**Nice to Know:**
- 📚 TLM Ports
- 📚 Field Macros
- 📚 Reporting

**Start with the learning projects** - they provide hands-on experience with the most important features!

---

*Last Updated: Feb 2026*
