`ifndef OUTPUT_AGENT_SVH
`define OUTPUT_AGENT_SVH

class output_agent extends uvm_agent;
    `uvm_component_utils(output_agent)

    output_config m_cfg;

    // Only a monitor - this is a passive agent
    output_monitor monitor;

    // Analysis port passthrough for easy access
    uvm_analysis_port #(output_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(output_config)::get(this, "", "output_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get output_config from config_db")
        end

        uvm_config_db#(output_config)::set(this, "monitor", "output_config", m_cfg);

        // Always create monitor (passive agent)
        monitor = output_monitor::type_id::create("monitor", this);

        `uvm_info("OUTPUT_AGENT", "Output agent built (passive - monitor only)", UVM_LOW)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor's analysis port to agent's passthrough port
        ap = monitor.ap;
    endfunction

endclass

`endif
