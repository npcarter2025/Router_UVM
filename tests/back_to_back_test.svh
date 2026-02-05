`ifndef BACK_TO_BACK_TEST_SVH
`define BACK_TO_BACK_TEST_SVH

class back_to_back_test extends router_base_test;

    `uvm_component_utils(back_to_back_test)

    function new(string name = "back_to_back_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        back_to_back_vseq vseq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting back-to-back test", UVM_LOW)

        vseq = back_to_back_vseq::type_id::create("vseq");
        vseq.num_transactions = 50;
        vseq.start(m_env.m_vseqr);

        #100ns;

        `uvm_info(get_type_name(), "Back-to_back test complete", UVM_LOW)



        phase.drop_objection(this);

    endtask

endclass
`endif  


