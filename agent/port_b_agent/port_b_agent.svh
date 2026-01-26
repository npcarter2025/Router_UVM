`ifndef PORT_B_AGENT_SVH
`define PORT_B_AGENT_SVH

class port_b_agent extends uvm_agent;
    `uvm_component_utils(port_b_agent)

    port_b_driver drv;
    port_b_monitor mon;
    port_b_sequencer seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        drv = port_b_driver::type_id::create("drv", this);
        mon = port_b_monitor::type_id::create("mon", this);
        seqr = port_b_sequencer::type_id::create("seqr", this);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction



endclass

`endif