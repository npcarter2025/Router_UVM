`ifndef RAL_SANITY_TEST_SVH
`define RAL_SANITY_TEST_SVH

class ral_sanity_test extends router_base_test;
    `uvm_component_utils(ral_sanity_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ral_sanity_vseq vseq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting RAL sanity test", UVM_LOW)

        // Create RAL sanity sequence
        vseq = ral_sanity_vseq::type_id::create("vseq");
        
        // Pass register model to sequence
        vseq.reg_model = m_env.m_reg_model;
        
        // Start sequence on virtual sequencer
        vseq.start(m_env.m_vseqr);

        // Drain time: wait for final transactions to complete
        #100ns;

        `uvm_info(get_type_name(), "RAL sanity test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

`endif
