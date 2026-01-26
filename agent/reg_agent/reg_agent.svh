`ifndef REG_AGENT_SVH
`define REG_AGENT_SVH

class reg_agent extends uvm_agent;
    `uvm_component_utils(reg_agent)

    reg_driver drv;
    reg_monitor mon;
    reg_sequencer seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        drv = reg_driver::type_id::create("drv", this);
        mon = reg_monitor::type_id::create("mon", this);
        seqr = reg_sequencer::type_id::create("seqr", this);

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction



endclass

`endif