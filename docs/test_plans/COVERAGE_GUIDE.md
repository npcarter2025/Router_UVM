# Functional Coverage Guide

## Current Coverage Status: 72.38%

### Coverage Breakdown:

| Category | Current | Target | Gap |
|----------|---------|--------|-----|
| Port A | 75% | 100% | 25% |
| Port B | 75% | 100% | 25% |
| Output | 100% | 100% | ✅ COMPLETE |
| Register | 75% | 100% | 25% |
| Collision | 37% | 100% | 63% |

---

## 🎯 What's Missing?

### 1. Port A/B Coverage (75% each) - Missing 25%

**Defined Bins:**
- `cp_data_a/b`: 5 bins (zero, low, mid, high, all_ones)
- `cp_addr_a/b`: 4 bins (ports 0-3)
- `cp_ready_a/b`: 2 bins (accepted, rejected)
- `cross_addr_data`: 4x5 = 20 bins
- `cross_addr_ready`: 4x2 = 8 bins

**Likely Missing:**
- Some **data patterns** (especially edge cases like 0x00, 0xFF)
- **Rejected transactions** (ready_a/b = 0) - these happen when router is disabled or collision occurs
- Specific **addr-data** and **addr-ready** cross combinations

**How to Hit:**
```systemverilog
// Send data to all ports with various patterns
// Test with router disabled to get rejected transactions
```

---

### 2. Register Coverage (75%) - Missing 25%

**Defined Bins:**
- `cp_enable`: 2 bins (0, 1)
- `cp_priority`: 2 bins (0, 1)
- `cp_priority_transitions`: 4 bins (0=>0, 0=>1, 1=>0, 1=>1)
- `cross_enable_priority`: 2x2 = 4 bins

**Likely Missing:**
- **Priority transitions** like 0=>1 or 1=>0
- Some **enable/priority** combinations

**How to Hit:**
```systemverilog
// Write priority=0, sample
// Write priority=1, sample
// Write priority=0 again, sample  // Gets 1=>0 transition
```

---

### 3. Collision Coverage (37%) - **BIGGEST GAP: 63%**

**Defined Bins:**
- `cp_collision`: 2 bins (no_collision, collision)
- `cp_enable_during_collision`: 2 bins (disabled, enabled)
- `cp_priority_during_collision`: 2 bins (port_a_wins, port_b_wins)
- `cp_collision_transitions`: 4 bins (0=>0, 0=>1, 1=>0, 1=>1)
- `cross_collision_enable`: 3 valid bins (excluding illegal collision_when_disabled)
- `cross_collision_priority`: 2 bins (ignores no_collision cases)
- `cross_collision_enable_priority`: 3 bins (ignores no_collision, excludes illegal)

**Total bins ≈ 2 + 2 + 2 + 4 + 3 + 2 + 3 = 18+ bins**

**What's Missing:**
1. **Non-collision scenarios** (`collision_occurred = 0`)
   - Currently only sampling when collisions occur
   - Need to sample when only Port A active
   - Need to sample when only Port B active
   - Need to sample when neither port active

2. **Collision Transitions**:
   - **0=>0**: No collision → No collision (need consecutive non-collision samples)
   - **0=>1**: No collision → Collision
   - **1=>0**: Collision → No collision
   - **1=>1**: Collision → Collision (back-to-back collisions)

3. **Disabled Scenarios**:
   - Sample when `global_enable = 0`

**How to Fix:**
```systemverilog
// Need to sample EVERY transaction, not just on collisions
// In scoreboard:
//   write_port_a() → sample_collision_scenario(0)  // No collision yet
//   write_port_b() → sample_collision_scenario(0)  // No collision yet
//   write_output() → sample_collision_scenario(got_port_a && got_port_b)
```

---

## 🔧 Action Plan to Reach 100%

### Step 1: Fix Collision Sampling (Will get ~40% boost)
The **main issue** is we only sample collisions in `write_output()`. We need to sample on **every** transaction to capture:
- Non-collision scenarios
- Proper transition sequences

### Step 2: Add Rejected Transaction Tests (~10% boost)
- Send traffic when router is **disabled**
- This will hit `ready_a/b = 0` bins

### Step 3: Add Priority Transition Tests (~10% boost)
- Dynamically change priority during test
- Sample between changes

### Step 4: Complete Data Pattern Coverage (~5% boost)
- Ensure all 5 data patterns hit all 4 ports

---

## 📝 Recommended Test Sequence

```bash
# Run comprehensive test (already does most things)
make run_coverage

# To debug specific coverage:
# 1. Check which bins are hit/missed
# 2. Look at simulation log for transaction counts
# 3. Verify collision detection is working

# View coverage details (if you have coverage analysis tools):
urg -dir <coverage.vdb>
```

---

## 🐛 Current Issues

1. **Collision sampling is incomplete**
   - Only samples on output transactions
   - Misses non-collision and proper transitions
   
2. **Need more disabled-router tests**
   - Current `disable_vseq` might not exercise all scenarios
   
3. **Priority transitions not fully exercised**
   - Need explicit back-and-forth priority changes

---

## 💡 Quick Win: Modify Scoreboard Sampling

Instead of only sampling collisions in `write_output()`, sample on EVERY port transaction:

```systemverilog
// In write_port_a():
if (!got_port_b) 
    m_coverage.sample_collision_scenario(0);  // No collision yet

// In write_port_b():
if (!got_port_a)
    m_coverage.sample_collision_scenario(0);  // No collision yet

// In write_output():
m_coverage.sample_collision_scenario(got_port_a && got_port_b);
```

This will capture the full collision state machine!
