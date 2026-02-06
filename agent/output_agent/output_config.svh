`ifndef OUTPUT_CONFIG_SVH
`define OUTPUT_CONFIG_SVH

class output_config extends uvm_object;
    `uvm_object_utils(output_config)

    uvm_active_passive_enum is_active = UVM_PASSIVE;

    bit coverage_enable = 1;

    // Optional idea: Monitoring Controls
    bit enable_protocol_checking = 1;       // check for protocol violations
    bit enable_transaction_recording = 1;   // Record to waveform DB

    virtual dual_port_router_if vif;

    function new(string name = "output_config");
        super.new(name);
    endfunction


endclass

`endif 
