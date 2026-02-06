`ifndef ROUTER_PKG_SVH
`define ROUTER_PKG_SVH

package router_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    //----------------------------------------------------------
    // Configuration Objects (must come before agents/env)
    //----------------------------------------------------------
    `include "agent/port_a_agent/port_a_config.svh"
    `include "agent/port_b_agent/port_b_config.svh"
    `include "agent/reg_agent/reg_config.svh"
    `include "agent/output_agent/output_config.svh"
    `include "env/router_env_config.svh"

    //----------------------------------------------------------
    // Items (sequence items / transactions)
    //----------------------------------------------------------
    `include "agent/port_a_agent/port_a_item.svh"
    `include "agent/port_b_agent/port_b_item.svh"
    `include "agent/reg_agent/reg_item.svh"
    `include "agent/output_agent/output_item.svh"

    //----------------------------------------------------------
    // Sequencers
    //----------------------------------------------------------
    `include "agent/port_a_agent/port_a_sequencer.svh"
    `include "agent/port_b_agent/port_b_sequencer.svh"
    `include "agent/reg_agent/reg_sequencer.svh"

    //----------------------------------------------------------
    // Drivers
    //----------------------------------------------------------
    `include "agent/port_a_agent/port_a_driver.svh"
    `include "agent/port_b_agent/port_b_driver.svh"
    `include "agent/reg_agent/reg_driver.svh"

    //----------------------------------------------------------
    // Monitors
    //----------------------------------------------------------
    `include "agent/port_a_agent/port_a_monitor.svh"
    `include "agent/port_b_agent/port_b_monitor.svh"
    `include "agent/reg_agent/reg_monitor.svh"
    `include "agent/output_agent/output_monitor.svh"

    //----------------------------------------------------------
    // Agents
    //----------------------------------------------------------
    `include "agent/port_a_agent/port_a_agent.svh"
    `include "agent/port_b_agent/port_b_agent.svh"
    `include "agent/reg_agent/reg_agent.svh"
    `include "agent/output_agent/output_agent.svh"

    //----------------------------------------------------------
    // RAL (Register Abstraction Layer) - Must come before scoreboard
    //----------------------------------------------------------
    `include "ral/ctrl_reg.svh"
    `include "ral/collision_cnt_reg.svh"
    `include "ral/router_reg_block.svh"
    `include "ral/router_reg_adapter.svh"

    //----------------------------------------------------------
    // Scoreboard (needs RAL types)
    //----------------------------------------------------------
    `include "env/router_scoreboard.svh"

    //----------------------------------------------------------
    // Virtual Sequencer
    //----------------------------------------------------------
    `include "env/router_virtual_sequencer.svh"

    //----------------------------------------------------------
    // Coverage
    //----------------------------------------------------------
    // Note: Coverage not implemented on this branch yet
    // `include "env/router_coverage.svh"

    //----------------------------------------------------------
    // Environment
    //----------------------------------------------------------
    `include "env/router_env.svh"

    //----------------------------------------------------------
    // Base Sequences (per agent)
    //----------------------------------------------------------
    `include "seq/port_a_base_sequence.svh"
    `include "seq/port_b_base_sequence.svh"
    `include "seq/reg_base_sequence.svh"

    //----------------------------------------------------------
    // Virtual Sequences
    //----------------------------------------------------------
    `include "seq/router_base_vseq.svh"
    `include "seq/collision_vseq.svh"
    `include "seq/priority_vseq.svh"
    `include "seq/disable_vseq.svh"
    `include "seq/back_to_back_vseq.svh"
    `include "seq/ral_sanity_vseq.svh"
    `include "seq/backdoor_test_vseq.svh"

    //----------------------------------------------------------
    // Tests
    //----------------------------------------------------------
    `include "tests/router_base_test.svh"
    `include "tests/config_test.svh"
    `include "tests/disable_test.svh"
    `include "tests/priority_test.svh"
    `include "tests/back_to_back_test.svh"
    `include "tests/ral_sanity_test.svh"
    `include "tests/backdoor_test.svh"

endpackage

`endif
