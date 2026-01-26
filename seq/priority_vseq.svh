`ifndef PRIORITY_VSEQ_SVH
`define PRIORITY_VSEQ_SVH
/* This test is to simply test the priority register */

// This test verifies the priority register by:
// 1. Setting priority to Port A, causing collision, verifying Port A wins
// 2. Setting priority to Port B, causing collision, verifying Port B wins

class priority_vseq extends router_base_vseq;
    `uvm_object_utils(priority_vseq)

    // Number of collisions to test per priority setting
    int num_collisions = 3;

    function new(string name = "priority_vseq");
        super.new(name);
    endfunction

    virtual task body();
        port_a_base_sequence port_a_seq;
        port_b_base_sequence port_b_seq;
        reg_item reg_txn;

        `uvm_info(get_type_name(), "Starting priority test", UVM_LOW)

        // ========== Test 1: Port A Priority ==========
        `uvm_info(get_type_name(), "Setting priority = 0 (Port A wins)", UVM_LOW)
        
        // Write to ctrl_reg: global_enable=1, priority=0 (Port A)
        `uvm_do_on_with(reg_txn, p_reg_seqr, {
            reg_addr  == 4'h0;
            reg_wdata == 32'h1;  // bit[0]=1 (enable), bit[1]=0 (Port A priority)
            reg_en    == 1;
            reg_we    == 1;
        })

        // Send colliding traffic - Port A should win
        repeat (num_collisions) begin
            `uvm_info(get_type_name(), "Collision with Port A priority", UVM_MEDIUM)
            fork
                `uvm_do_on(port_a_seq, p_port_a_seqr)
                `uvm_do_on(port_b_seq, p_port_b_seqr)
            join
        end

        // ========== Test 2: Port B Priority ==========
        `uvm_info(get_type_name(), "Setting priority = 1 (Port B wins)", UVM_LOW)
        
        // Write to ctrl_reg: global_enable=1, priority=1 (Port B)
        `uvm_do_on_with(reg_txn, p_reg_seqr, {
            reg_addr  == 4'h0;
            reg_wdata == 32'h3;  // bit[0]=1 (enable), bit[1]=1 (Port B priority)
            reg_en    == 1;
            reg_we    == 1;
        })

        // Send colliding traffic - Port B should win
        repeat (num_collisions) begin
            `uvm_info(get_type_name(), "Collision with Port B priority", UVM_MEDIUM)
            fork
                `uvm_do_on(port_a_seq, p_port_a_seqr)
                `uvm_do_on(port_b_seq, p_port_b_seqr)
            join
        end

        // ========== Verify collision counter increased ==========
        `uvm_info(get_type_name(), "Reading collision counter", UVM_LOW)
        `uvm_do_on_with(reg_txn, p_reg_seqr, {
            reg_addr == 4'h8;  // collision_cnt address
            reg_en   == 1;
            reg_we   == 0;     // Read
        })

        `uvm_info(get_type_name(), $sformatf("Priority test complete - collision_cnt should be %0d", 
                  num_collisions * 2), UVM_LOW)
    endtask

endclass

`endif