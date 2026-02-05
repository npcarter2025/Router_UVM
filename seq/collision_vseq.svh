`ifndef COLLISION_VSEQ_SVH
`define COLLISION_VSEQ_SVH

class collision_vseq extends router_base_vseq;  // Extend base vseq for sequencer handles
    `uvm_object_utils(collision_vseq)

    // Configuration - set before starting sequence
    bit test_port_a_priority = 1;  // 1 = Port A wins, 0 = Port B wins
    int num_collisions = 50;        // Number of collision attempts

    function new(string name = "collision_vseq");
        super.new(name);
    endfunction

    virtual task body();
        port_a_base_sequence port_a_seq;
        port_b_base_sequence port_b_seq;

        `uvm_info(get_type_name(), "Starting collision test", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Priority setting: %s wins on collision",
            test_port_a_priority ? "Port A" : "Port B"), UVM_LOW)

        // Run multiple collision attempts
        repeat (num_collisions) begin
            `uvm_info(get_type_name(), "Sending simultaneous traffic on both ports", UVM_MEDIUM)

            // Fork to send on both ports at the same time
            fork
                begin
                    `uvm_do_on(port_a_seq, p_port_a_seqr)
                end
                begin
                    `uvm_do_on(port_b_seq, p_port_b_seqr)
                end
            join
        end

        `uvm_info(get_type_name(), $sformatf("Collision test complete - %0d attempts", num_collisions), UVM_LOW)
    endtask

endclass

`endif 
