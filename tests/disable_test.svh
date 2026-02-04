`ifndef DISABLE_TEST_SVH
`define DISABLE_TEST_SVH

class disable_test extends router_base_test;
    `uvm_component_utils(disable_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        disable_vseq vseq;
        
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting disable test", UVM_LOW)

        vseq = disable_vseq::type_id::create("vseq");
        vseq.start(m_env.m_vseqr);

        #100ns;

        `uvm_info(get_type_name(), "Disable test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif