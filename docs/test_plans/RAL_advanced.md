# Advanced RAL Features

This document covers optional and advanced RAL features beyond the basic implementation in `testbench_plan.md`.

---

## Table of Contents

1. [Backdoor Access](#backdoor-access)
2. [Register Coverage](#register-coverage)
3. [Register Sequences](#register-sequences)
4. [Memory Models](#memory-models)
5. [Register Callbacks](#register-callbacks)
6. [Feature Comparison](#feature-comparison)

---

## 1. Backdoor Access

### What It Is

Backdoor access allows direct reading/writing of RTL signals, bypassing the bus interface entirely.

**Frontdoor (Normal):**
```
Sequence → Adapter → Driver → Bus → DUT Register
(Slow, takes clock cycles, tests bus protocol)
```

**Backdoor (Fast):**
```
Sequence → Direct RTL Access → DUT Register
(Instant, no clock cycles, no bus protocol)
```

### When to Use

- ✅ **Fast initialization** - Set up registers quickly in setup phase
- ✅ **Backdoor reads** - Check register state without disturbing DUT
- ✅ **Long tests** - Speed up regression tests
- ❌ **NOT for protocol testing** - Bypasses the bus you want to test!

### Implementation

**Step 1: Add HDL paths to register definitions**

```systemverilog
// In ctrl_reg.svh build() function:
virtual function void build();
    global_enable = uvm_reg_field::type_id::create("global_enable");
    global_enable.configure(this, 1, 0, "RW", 0, 1'h1, 1, 1, 0);
    
    // Add HDL path for backdoor access
    add_hdl_path_slice("ctrl_reg[0]", 0, 1);  // global_enable at bit 0
    add_hdl_path_slice("ctrl_reg[1]", 1, 1);  // priority at bit 1
endfunction
```

**Step 2: Configure register block with root HDL path**

```systemverilog
// In router_env.svh build_phase:
m_reg_model.build();
m_reg_model.lock_model();

// Set root HDL path
m_reg_model.set_hdl_path_root("tb_top.dut");
```

**Step 3: Use backdoor in sequences**

```systemverilog
// Frontdoor (uses bus)
reg_model.ctrl.write(status, 32'h3, .parent(this));  // Goes through driver

// Backdoor (direct RTL)
reg_model.ctrl.poke(status, 32'h3);  // Direct write, no bus traffic
reg_model.ctrl.peek(status, rdata);  // Direct read, no bus traffic
```

### Comparison

| Method | Speed | Tests Bus? | Clock Cycles |
|--------|-------|------------|--------------|
| Frontdoor (`write/read`) | Slow | ✅ Yes | Multiple |
| Backdoor (`poke/peek`) | Fast | ❌ No | Zero |

### Recommendation

⚠️ **For Learning: Skip backdoor for now**
- Frontdoor is sufficient
- Backdoor doesn't test your register agent
- Add later when you need faster tests

---

## 2. Register Coverage

### What It Is

Built-in coverage tracking for register/field accesses:
- Which registers were accessed?
- Which fields were written/read?
- Were all register values exercised?

### Implementation

**Step 1: Enable coverage in register classes**

```systemverilog
// In ctrl_reg.svh:
function new(string name = "ctrl_reg");
    // Change from UVM_NO_COVERAGE to UVM_CVR_ALL
    super.new(name, 32, UVM_CVR_ALL);  // Enable all coverage
endfunction
```

**Step 2: Enable coverage in register block**

```systemverilog
// In router_reg_block.svh:
function new(string name = "router_reg_block");
    // Enable register coverage
    super.new(name, UVM_CVR_REG_BITS | UVM_CVR_ADDR_MAP);
endfunction
```

**Step 3: Sample coverage**

```systemverilog
// Coverage is auto-sampled on register accesses
// Or manually sample:
reg_model.sample_values();  // Sample all register values
```

### Coverage Types

| Type | What It Tracks |
|------|----------------|
| `UVM_CVR_REG_BITS` | Individual register bit toggles |
| `UVM_CVR_ADDR_MAP` | Address map coverage |
| `UVM_CVR_FIELD_VALS` | Field value coverage |
| `UVM_CVR_ALL` | All of the above |

### Viewing Coverage

```systemverilog
// In test report_phase:
function void report_phase(uvm_phase phase);
    real reg_cov = m_reg_model.get_coverage();
    `uvm_info("COV", $sformatf("Register Coverage: %.2f%%", reg_cov), UVM_LOW)
endfunction
```

### Recommendation

✅ **Add this when you want more detailed analysis**
- Easy to enable (just change constructor args)
- Useful for verifying register test completeness
- Complements your functional coverage

---

## 3. Register Sequences

### What It Is

`uvm_reg_sequence` is a base class for sequences that need access to the register model.

**Regular sequence:**
```systemverilog
class my_seq extends uvm_sequence;
    router_reg_block reg_model;  // Must pass manually
    
    virtual task body();
        // Use reg_model...
    endtask
endclass

// In test:
my_seq seq = my_seq::type_id::create("seq");
seq.reg_model = m_env.m_reg_model;  // Manual assignment
seq.start(seqr);
```

**Register sequence:**
```systemverilog
class my_reg_seq extends uvm_reg_sequence;
    // model handle is built-in!
    
    virtual task body();
        model.ctrl.write(status, 32'h1);  // Use 'model' directly
    endtask
endclass

// In test:
my_reg_seq seq = my_reg_seq::type_id::create("seq");
seq.start(null, m_env.m_reg_model);  // Model passed in start()
```

### Pros and Cons

**Pros:**
- ✅ Cleaner - no manual model assignment
- ✅ Built-in `model` handle

**Cons:**
- ❌ Tied to register-only sequences
- ❌ Can't coordinate with data traffic (no access to data sequencers)

### Recommendation

❌ **Skip this - stick with virtual sequences**

Your approach (passing reg_model to virtual sequences) is better because:
- Virtual sequences can coordinate registers AND data
- More flexible
- Same as your current disable_vseq pattern

---

## 4. Memory Models

### What It Is

RAL also supports memory modeling with `uvm_mem` (not just registers).

**Use cases:**
- RAM blocks
- FIFOs
- Buffers
- Lookup tables

### Example

```systemverilog
class my_mem extends uvm_mem;
    `uvm_object_utils(my_mem)
    
    function new(string name = "my_mem");
        // 1024 entries, 32-bits each
        super.new(name, 1024, 32, "RW", UVM_NO_COVERAGE);
    endfunction
endclass

// In register block:
class my_reg_block extends uvm_reg_block;
    rand my_mem data_ram;
    
    virtual function void build();
        data_ram = my_mem::type_id::create("data_ram");
        data_ram.configure(this, "");
        
        // Add to map
        default_map.add_mem(data_ram, 'h1000, "RW");
    endfunction
endclass

// Usage:
data_ram.write(status, addr, data);
data_ram.read(status, addr, data);
```

### Recommendation

❌ **Not applicable to your router**
- You only have registers, no memory blocks
- Skip this entirely

---

## 5. Register Callbacks

### What It Is

Hooks that execute custom code before/after register operations.

**Use cases:**
- Custom checking
- Side effects modeling
- Debug logging
- Protocol violations

### Implementation

**Step 1: Define callback**

```systemverilog
class my_reg_callback extends uvm_reg_cbs;
    `uvm_object_utils(my_reg_callback)
    
    // Called before register write
    virtual task pre_write(uvm_reg_item rw);
        `uvm_info("CB", $sformatf("About to write %h to %s", 
            rw.value[0], rw.element.get_name()), UVM_LOW)
    endtask
    
    // Called after register read
    virtual task post_read(uvm_reg_item rw);
        `uvm_info("CB", $sformatf("Read %h from %s", 
            rw.value[0], rw.element.get_name()), UVM_LOW)
    endtask
endclass
```

**Step 2: Register callback**

```systemverilog
// In test or env:
my_reg_callback cb = my_reg_callback::type_id::create("cb");
uvm_reg_cb::add(m_reg_model.ctrl, cb);  // Add to specific register
// or
uvm_reg_cb::add(m_reg_model.*, cb);     // Add to all registers
```

### Common Uses

```systemverilog
// Example: Verify reserved fields always read 0
virtual task post_read(uvm_reg_item rw);
    if (rw.element.get_name() == "reserved") begin
        assert(rw.value[0] == 0) else
            `uvm_error("CB", "Reserved field not zero!")
    end
endtask

// Example: Model side effects
virtual task post_write(uvm_reg_item rw);
    if (rw.element.get_name() == "command_reg") begin
        // Trigger some other action
        execute_command(rw.value[0]);
    end
endtask
```

### Recommendation

⏸️ **Advanced feature - skip for now**
- Useful for complex register behavior
- Not needed for basic RAL implementation
- Can add later if you need custom checking

---

## Feature Comparison

### When to Use Each Feature

| Feature | Usefulness | When to Add | Complexity |
|---------|-----------|-------------|------------|
| **Backdoor** | Medium | After basic RAL works, for speed | Easy |
| **Coverage** | High | When analyzing test quality | Very Easy |
| **Reg Sequences** | Low | Probably never (use vseqs) | Easy |
| **Memory Models** | N/A | Not applicable to your design | Medium |
| **Callbacks** | Low | Only for complex register behavior | Medium |

### Recommended Priority

**Phase 1: Basic RAL (From testbench_plan.md)** ⬅️ **START HERE**
- Register classes
- Register block
- Adapter
- Predictor
- Integration

**Phase 2: Useful Additions** ⬅️ **ADD NEXT**
- ✅ Register coverage (just change constructor)
- ⏸️ Backdoor (if tests are too slow)

**Phase 3: Advanced (Optional)**
- ⏸️ Callbacks (only if you need custom behavior)
- ❌ Reg sequences (skip - use virtual sequences)
- ❌ Memory models (not applicable)

---

## Summary

Your `testbench_plan.md` covers all the **essential** RAL components. The features in this document are:

- **Optional** - Your RAL will work fine without them
- **Advanced** - Add complexity, useful in specific scenarios
- **Reference** - Good to know they exist for future projects

**Stick with your plan** to implement basic RAL first. You can always come back and add these features later if needed!

---

## Additional Resources

### Key UVM RAL Classes (Built-in)

- `uvm_reg` - Base register class
- `uvm_reg_field` - Individual field within register
- `uvm_reg_block` - Container for registers
- `uvm_reg_map` - Address map
- `uvm_reg_adapter` - Protocol conversion (YOU write this)
- `uvm_reg_predictor` - Auto-update mechanism
- `uvm_reg_sequence` - Register sequence base
- `uvm_mem` - Memory model
- `uvm_reg_cbs` - Callback base

### Useful Methods

**Register operations:**
- `write()` / `read()` - Frontdoor access
- `poke()` / `peek()` - Backdoor access
- `update()` - Write only if changed
- `mirror()` - Read and compare
- `set()` / `get()` - Modify shadow value (no bus access)

**Field operations:**
- `set()` / `get()` - Set/get field value
- `read()` / `write()` - Access individual field

**Coverage:**
- `get_coverage()` - Get coverage percentage
- `sample_values()` - Sample register values

---

*Last Updated: Feb 2026*
