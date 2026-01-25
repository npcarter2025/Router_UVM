`ifndef OUTPUT_MONITOR_SVH
`define OUTPUT_MONITOR_SVH

class output_monitor extends uvm_monitor;

    `uvm_component_utils(output_monitor)

    virtual dual_port_router_if vif;

    // Analysis port to send observed transactions
    uvm_analysis_port #(output_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);

        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("OUTPUT_MON", "Couldn't get virtual interface from config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("OUTPUT_MON", "Output monitor run phase started", UVM_LOW)

        // Wait for reset to complete
        @(vif.mon_cb);
        wait(vif.rst_n);
        @(vif.mon_cb);

        `uvm_info("OUTPUT_MON", "Reset complete, monitor ready", UVM_LOW)

        forever begin
            @(vif.mon_cb);
            
            // Check all 4 output ports each cycle
            for (int i = 0; i < 4; i++) begin
                if (vif.mon_cb.valid_out[i]) begin
                    output_item item = output_item::type_id::create("output_item");
                    item.port_idx = i;
                    item.data     = vif.mon_cb.data_out[i];
                    item.valid    = vif.mon_cb.valid_out[i];

                    `uvm_info("OUTPUT_MON", $sformatf("Observed: %s", item.convert2string()), UVM_MEDIUM)

                    // Send to analysis port (scoreboard, coverage, etc.)
                    ap.write(item);
                end
            end
        end
    endtask

endclass

`endif
