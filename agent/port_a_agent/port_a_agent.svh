`ifndef PORT_A_AGENT_SVH
`define PORT_A_AGENT_SVH

class port_a_agent extends uvm_agent;
    `uvm_component_utils(port_a_agent)

    port_a_driver drv;
    port_a_monitor mon;
    port_a_sequencer seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        drv = port_a_driver::type_id::create("drv", this);
        mon = port_a_monitor::type_id::create("mon", this);
        
        seqr = port_a_sequencer::type_id::create("seqr", this);



    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction



endclass

`endif