# UVM Testbench for a Dual_Port Router

I made this so I could practice writing Virtual Sequencers, and RAL.
I'm thinking I'll add a DPI-C Golden Reference Model when I'm done.
Below are some good debugging patterns that I am trying to memorize.

# UVM Debugging Grep Patterns

Quick reference for filtering UVM simulation logs.

## Grep Flags Reference

| Flag | Meaning | Example |
|------|---------|---------|
| `-E` | Extended regex (allows `\|` for OR) | `grep -E "ERROR\|FATAL"` |
| `-i` | Case insensitive | `grep -i "error"` |
| `-c` | Count matches (don't show lines) | `grep -c "UVM_ERROR"` |
| `-n` | Show line numbers | `grep -n "MISMATCH"` |
| `-B5` | Show 5 lines **B**efore match | `grep -B5 "ERROR"` |
| `-A3` | Show 3 lines **A**fter match | `grep -A3 "ERROR"` |
| `-C2` | Show 2 lines **C**ontext (before+after) | `grep -C2 "ERROR"` |
| `-v` | In**v**ert match (lines NOT matching) | `grep -v "UVM_INFO"` |
| `-l` | List filenames only | `grep -l "ERROR" *.log` |
| `-r` | **R**ecursive search in directories | `grep -r "TODO" src/` |
| `-w` | Match whole **w**ord only | `grep -w "data"` |

## Shell Redirection Reference

| Syntax | Meaning | Example |
|--------|---------|---------|
| `>` | Redirect stdout to file (overwrite) | `./simv > sim.log` |
| `>>` | Redirect stdout to file (append) | `./simv >> sim.log` |
| `2>` | Redirect stderr to file | `./simv 2> errors.log` |
| `2>&1` | Redirect stderr to same place as stdout | `./simv > sim.log 2>&1` |
| `&>` | Redirect both stdout and stderr to file | `./simv &> sim.log` |
| `\|` | Pipe stdout to another command | `./simv \| grep ERROR` |
| `\| tee` | Pipe to screen AND file | `./simv \| tee sim.log` |
| `2>&1 \| tee` | Both streams to screen and file | `./simv 2>&1 \| tee sim.log` |

### Common Patterns

```bash
# Save all output to file (won't see on screen)
./simv > sim.log 2>&1

# See output AND save to file
./simv 2>&1 | tee sim.log

# Separate stdout and stderr
./simv > output.log 2> errors.log

# Discard output entirely
./simv > /dev/null 2>&1
```

## Finding Errors and Warnings

```bash
grep "UVM_ERROR" sim.log                    # All errors
grep "UVM_FATAL" sim.log                    # All fatals
grep "UVM_WARNING" sim.log                  # All warnings
grep -E "UVM_ERROR|UVM_FATAL" sim.log       # Errors and fatals
grep -c "UVM_ERROR" sim.log                 # Count errors
```

## Filter by Message ID

```bash
grep "\[SB\]" sim.log                       # Scoreboard messages
grep "\[PORT_A_DRV\]" sim.log               # Port A driver
grep "\[PORT_B_MON\]" sim.log               # Port B monitor
grep "\[router_scoreboard\]" sim.log        # Scoreboard summary
```

## Filter by Time

```bash
grep "@ 0:" sim.log                         # Events at time 0
grep "@ 145000" sim.log                     # Events at specific time
grep -E "@ [0-9]+00:" sim.log               # Events at round numbers
```

## Transaction Flow

```bash
grep -E "sent|received" sim.log             # Track transactions
grep -E "MATCH|MISMATCH" sim.log            # Scoreboard comparisons
grep "Driving" sim.log                      # Driver activity
grep "Observed" sim.log                     # Monitor activity
```

## Component Hierarchy

```bash
grep "uvm_test_top.m_env" sim.log           # All env messages
grep "m_port_a_agent" sim.log               # Port A agent messages
grep "m_scoreboard" sim.log                 # Scoreboard messages
```

## UVM Phases

```bash
grep "phase" sim.log                        # Phase transitions
grep "raise_objection\|drop_objection" sim.log  # Objections
grep "TEST_DONE" sim.log                    # Test completion
```

## Combine Patterns

```bash
# Errors with context (3 lines before/after)
grep -B3 -A3 "UVM_ERROR" sim.log

# Scoreboard activity in time order
grep -E "\[SB\].*@" sim.log | sort -t@ -k2 -n

# Find mismatches and their context
grep -B5 "MISMATCH" sim.log

# All activity at end of simulation
tail -50 sim.log | grep -E "UVM_ERROR|UVM_INFO.*scoreboard"
```

## UVM Verbosity Levels

Run with different verbosity to see more/less detail:

```bash
./simv +UVM_VERBOSITY=UVM_NONE     # Errors/fatals only
./simv +UVM_VERBOSITY=UVM_LOW      # + low priority info
./simv +UVM_VERBOSITY=UVM_MEDIUM   # + medium priority info (recommended for debug)
./simv +UVM_VERBOSITY=UVM_HIGH     # + high priority info
./simv +UVM_VERBOSITY=UVM_FULL     # Everything
```

## Understanding UVM Log Format

```
UVM_INFO file.svh(42) @ 1000: uvm_test_top.m_env.agent [MSG_ID] Message text
         ^^^^^^^^^^^   ^^^^  ^^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^
         |             |     |                           |
         File:Line     Time  Component hierarchy         Message tag
```
