`ifndef PORT_A_AGENT_SVH
`define PORT_A_AGENT_SVH

class port_a_agent extends uvm_agent;
    `uvm_component_utils(port_a_agent)

    port_a_config m_cfg;

    port_a_driver drv;
    port_a_monitor mon;
    port_a_sequencer seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(port_a_config)::get(this, "", "port_a_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get port_a_config from config_db")
        end

        uvm_config_db#(port_a_config)::set(this, "mon", "port_a_config", m_cfg);

        mon = port_a_monitor::type_id::create("mon", this);

        if (m_cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(port_a_config)::set(this, "drv", "port_a_config", m_cfg);
            uvm_config_db#(port_a_config)::set(this, "seqr", "port_a_config", m_cfg);

            drv = port_a_driver::type_id::create("drv", this);
            seqr = port_a_sequencer::type_id::create("seqr", this);
        end


    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (m_cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end

    endfunction

endclass

`endif