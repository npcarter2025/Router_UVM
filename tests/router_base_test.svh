`ifndef ROUTER_BASE_TEST_SVH
`define ROUTER_BASE_TEST_SVH

class router_base_test extends uvm_test;
    `uvm_component_utils(router_base_test)

    router_env m_env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env = router_env::type_id::create("m_env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        uvm_top.print_topology();

    endfunction

    virtual task run_phase(uvm_phase phase);
        collision_vseq vseq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting test", UVM_LOW)

        vseq = collision_vseq::type_id::create("vseq");
        vseq.start(m_env.m_vseqr);

        // Drain time: wait for final transactions to complete
        #100ns;

        `uvm_info(get_type_name(), "Test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask



endclass

`endif 
