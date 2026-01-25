`ifndef OUTPUT_AGENT_SVH
`define OUTPUT_AGENT_SVH

class output_agent extends uvm_agent;

    `uvm_component_utils(output_agent)

    // Only a monitor - this is a passive agent
    output_monitor monitor;

    // Analysis port passthrough for easy access
    uvm_analysis_port #(output_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

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
