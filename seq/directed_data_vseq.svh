`ifndef DIRECTED_DATA_VSEQ_SVH
`define DIRECTED_DATA_VSEQ_SVH

class directed_data_vseq extends router_base_vseq;
    `uvm_object_utils(directed_data_vseq)

    // Configurable parameters
    int num_port_a_items = 20;
    int num_port_b_items = 20;

    function new(string name = "directed_data_vseq");
        super.new(name);
    endfunction

    virtual task body();
        port_a_base_sequence port_a_seq;
        port_b_base_sequence port_b_seq;

        `uvm_info(get_type_name(), "Starting directed data virtual sequence", UVM_LOW)

        // Start Port A sequence
        port_a_seq = port_a_base_sequence::type_id::create("port_a_seq");
        port_a_seq.num_items = num_port_a_items;
        
        // Start Port B sequence  
        port_b_seq = port_b_base_sequence::type_id::create("port_b_seq");
        port_b_seq.num_items = num_port_b_items;

        // Run sequences in parallel on both ports
        fork
            begin
                `uvm_info(get_type_name(), $sformatf("Starting Port A sequence with %0d items", num_port_a_items), UVM_LOW)
                port_a_seq.start(p_port_a_seqr);
            end
            begin
                `uvm_info(get_type_name(), $sformatf("Starting Port B sequence with %0d items", num_port_b_items), UVM_LOW)
                port_b_seq.start(p_port_b_seqr);
            end
        join

        `uvm_info(get_type_name(), "Directed data virtual sequence completed", UVM_LOW)
    endtask

endclass

`endif
