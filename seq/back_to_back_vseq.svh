`ifndef BACK_TO_BACK_VSEQ_SVH
`define BACK_TO_BACK_VSEQ_SVH

class back_to_back_vseq extends router_base_vseq;
    `uvm_object_utils(back_to_back_vseq)

    int num_transactions = 50;

    function new(string name = "back_to_back_vseq");
        super.new(name);
    endfunction

    virtual task body();
        port_a_base_sequence port_a_seq;
        port_b_base_sequence port_b_seq;

        `uvm_info(get_type_name(), "Starting back-to-back traffic test", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Sending %0d back-to-back transactions per port", num_transactions), UVM_MEDIUM)

        fork
            begin
                repeat(num_transactions) begin
                    `uvm_do_on(port_a_seq, p_port_a_seqr)
                end
            end
            begin
                repeat(num_transactions) begin
                    `uvm_do_on(port_b_seq, p_port_b_seqr)
                end
            end
        join

        #200ns;

        `uvm_info(get_type_name(), "Back-to-back traffic test complete", UVM_LOW)
    endtask

endclass

`endif

