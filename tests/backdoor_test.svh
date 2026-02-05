`ifndef BACKDOOR_TEST_SVH
`define BACKDOOR_TEST_SVH

class backdoor_test extends router_base_test;
    `uvm_component_utils(backdoor_test)

    function new(string name = "backdoor_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);


        backdoor_test_vseq vseq;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting backdoor test", UVM_LOW)

        vseq = backdoor_test_vseq::type_id::create("vseq");
        vseq.reg_model = m_env.m_reg_model;
        vseq.start(m_env.m_vseqr);

        #100ns;

        `uvm_info(get_type_name(), "Backdoor test completed", UVM_LOW)

        phase.drop_objection(this);

    endtask

endclass

`endif 
