`ifndef REG_AGENT_SVH
`define REG_AGENT_SVH

class reg_agent extends uvm_agent;
    `uvm_component_utils(reg_agent)

    reg_config m_cfg;

    reg_driver drv;
    reg_monitor mon;
    reg_sequencer seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(reg_config)::get(this, "", "reg_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get reg_config from config_db")
        end

        uvm_config_db#(reg_config)::set(this, "mon", "reg_config", m_cfg);

        mon = reg_monitor::type_id::create("mon", this);

        if (m_cfg.is_active == UVM_ACTIVE) begin
            uvm_config_db#(reg_config)::set(this, "drv", "reg_config", m_cfg);
            uvm_config_db#(reg_config)::set(this, "seqr", "reg_config", m_cfg);

            drv = reg_driver::type_id::create("drv", this);
            seqr = reg_sequencer::type_id::create("seqr", this);
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