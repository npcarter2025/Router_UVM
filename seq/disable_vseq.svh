`ifndef DISABLE_VSEQ_SVH
`define DISABLE_VSEQ_SVH

// ============================================================================
// Disable/Enable Virtual Sequence
// ============================================================================
// Tests the register-aware scoreboard by verifying:
// 1. Router works when enabled (default state)
// 2. Register disable is tracked by scoreboard
// 3. Router works again after re-enabling
//
// This exercises the scoreboard's ability to track register state and
// adjust its checking behavior accordingly.
// ============================================================================

class disable_vseq extends router_base_vseq;
    `uvm_object_utils(disable_vseq)

    function new(string name = "disable_vseq");
        super.new(name);
    endfunction

    virtual task body();
        reg_item reg_txn;
        port_a_base_sequence port_a_seq;
        port_b_base_sequence port_b_seq;

        `uvm_info(get_type_name(), "Starting disable/enable test", UVM_LOW)

        // ====================================================================
        // Phase 1: Verify router works when ENABLED (default state)
        // ====================================================================
        `uvm_info(get_type_name(), "Phase 1: Sending traffic while ENABLED", UVM_MEDIUM)
        
        // Send 2 transactions on Port A - should complete successfully
        repeat(20) begin
            `uvm_do_on(port_a_seq, p_port_a_seqr)
        end
        
        #50ns;  // Allow transactions to complete

        // ====================================================================
        // Phase 2: DISABLE the router via control register
        // ====================================================================
        `uvm_info(get_type_name(), "Phase 2: DISABLING router", UVM_MEDIUM)
        
        // Write 0 to control register (bit[0] = global_enable = 0)
        `uvm_do_on_with(reg_txn, p_reg_seqr, {
            reg_addr    == 4'h0;      // Control register
            reg_wdata   == 32'h0;     // Disable router
            reg_en      == 1;
            reg_we      == 1;
        })

        #50ns;  // Allow disable to propagate

        // ====================================================================
        // Phase 3: RE-ENABLE the router
        // ====================================================================
        `uvm_info(get_type_name(), "Phase 3: RE-ENABLING router", UVM_MEDIUM)
        
        // Write 1 to control register (bit[0] = global_enable = 1)
        `uvm_do_on_with(reg_txn, p_reg_seqr, {
            reg_addr    == 4'h0;      // Control register
            reg_wdata   == 32'h1;     // Enable router
            reg_en      == 1;
            reg_we      == 1;
        })

        #10ns;  // Allow enable to propagate

        // ====================================================================
        // Phase 4: Verify router works again after RE-ENABLE
        // ====================================================================
        `uvm_info(get_type_name(), "Phase 4: Sending traffic after RE-ENABLE", UVM_MEDIUM)
        
        // Send 2 transactions on Port B - should complete successfully
        repeat(20) begin
            `uvm_do_on(port_b_seq, p_port_b_seqr)
        end

        #50ns;  // Allow transactions to complete

        `uvm_info(get_type_name(), "Disable/enable test complete", UVM_LOW)
    endtask

endclass

`endif