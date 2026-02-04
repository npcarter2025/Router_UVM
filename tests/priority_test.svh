`ifndef PRIORITY_TEST_SVH
`define PRIORITY_TEST_SVH

class priority_test extends router_base_test;
    `uvm_component_utils(priority_test)

    function new(string name = "priority_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        priority_vseq vseq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting priority test", UVM_LOW)

        vseq = priority_vseq::type_id::create("vseq");
        vseq.start(m_env.m_vseqr);

        #100ns;

        `uvm_info(get_type_name(), "Priority test completed", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif

