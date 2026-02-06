`ifndef PORT_B_AGENT_SVH
`define PORT_B_AGENT_SVH

class port_b_agent extends uvm_agent;
    `uvm_component_utils(port_b_agent)

    port_b_config m_cfg;

    port_b_driver drv;
    port_b_monitor mon;
    port_b_sequencer seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(port_b_config)::get(this, "", "port_b_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get port_b_config from config_db")
        end

        uvm_config_db#(port_b_config)::set(this, "mon", "port_b_config", m_cfg);

        mon = port_b_monitor::type_id::create("mon", this);

        if (m_cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(port_b_config)::set(this, "drv", "port_b_config", m_cfg);
            uvm_config_db#(port_b_config)::set(this, "seqr", "port_b_config", m_cfg);

            drv = port_b_driver::type_id::create("drv", this);
            seqr = port_b_sequencer::type_id::create("seqr", this);
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