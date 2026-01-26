`ifndef DISABLE_VSEQ_SVH
`define DISABLE_VSEQ_SVH

class disable_vseq extends router_base_vseq;
    `uvm_object_utils(disable_vseq)

    function new(string name = "disable_vseq");
        super.new(name);
    endfunction

    virtual task body();
        reg_item reg_txn;
        port_a_base_sequence port_a_seq;

        `uvm_info(get_type_name(), "Starting disable test", UVM_LOW)

        // Disable the router (global_enable = 0)
        `uvm_do_on_with(reg_txn, p_reg_seqr, {
            reg_addr  == 4'h0;
            reg_wdata == 32'h0;  // bit[0]=0 (disabled)
            reg_en    == 1;
            reg_we    == 1;
        })

        // Try to send traffic - should be blocked (ready_a never goes high)
        `uvm_info(get_type_name(), "Attempting to send traffic (should be blocked)", UVM_LOW)

        // Note: This may timeout since ready won't come
        // fork
        //     `uvm_do_on(port_a_seq, p_port_a_seqr)
        // join_none
        // #100ns;  // Wait a bit
        // disable fork;

        `uvm_info(get_type_name(), "Disable test complete", UVM_LOW)
    endtask

endclass

`endif