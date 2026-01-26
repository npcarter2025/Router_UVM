`ifndef ROUTER_BASE_VSEQ_SVH
`define ROUTER_BASE_VSEQ_SVH

class router_base_vseq extends uvm_sequence;

    `uvm_object_utils(router_base_vseq)

    // This
    `uvm_declare_p_sequencer(router_virtual_sequencer)
    // 
    
    // NOTE TO SELF::
    //This essentially expands to:
    /*
    router_virtual_sequencer p_sequencer;

    virtual function void m_set_p_sequencer();
        super.m_set_p_sequencer();
        if (!$cast(p_sequencer, m_sequencer)) begin
            `uvm_fatal("SEQTYPE", "Sequencer type mismatch")
        end
    endfunction


    Every uvm_sequence has a built-in m_sequencer handle 
        (generic uvm_sequencer_base type) 
    uvm_declare_p_sequencer creates a typed handle called 
        p_sequencer of your specific sequencer type
    
    When the sequence starts, UVM automatically casts 
        m_sequencer to p_sequencer

    SOO p_sequencer gives you access to your specific virtual sequencer
        type, including all of the agent sequencer handles it contains
    */

    port_a_sequencer p_port_a_seqr;
    port_b_sequencer p_port_b_seqr;
    reg_sequencer p_reg_seqr;

    function new(string name = "router_base_vseq");
        super.new(name);
    endfunction
    virtual task pre_body();
        p_port_a_seqr = p_sequencer.p_port_a_seqr;
        p_port_b_seqr = p_sequencer.p_port_b_seqr;
        p_reg_seqr = p_sequencer.p_reg_seqr;

    endtask

    virtual task body();
        `uvm_info(get_type_name(), "Base Virtual sequence body - This is supposed to be overridden", UVM_LOW)
    endtask

endclass

`endif