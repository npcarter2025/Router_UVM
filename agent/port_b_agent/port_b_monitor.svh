`ifndef PORT_B_MONITOR_SVH
`define PORT_B_MONITOR_SVH

class port_b_monitor extends uvm_monitor;
    `uvm_component_utils(port_b_monitor)

    virtual dual_port_router_if vif;
    port_b_config m_cfg;

    uvm_analysis_port #(port_b_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ap = new("ap", this);

        if (!uvm_config_db#(port_b_config)::get(this, "", "port_b_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get port_b_config")
        end

        vif = m_cfg.vif;
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("PORT_B_MON", "Port B monitor run phase has begun", UVM_LOW)

        // Wait for reset
        @(vif.mon_cb);
        wait(vif.rst_n);
        @(vif.mon_cb);

        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.valid_b && vif.mon_cb.ready_b) begin
                port_b_item item = port_b_item::type_id::create("port_b_item");
                item.data_b  = vif.mon_cb.data_b;
                item.addr_b  = vif.mon_cb.addr_b;
                item.valid_b = vif.mon_cb.valid_b;
                item.ready_b = vif.mon_cb.ready_b;

                `uvm_info("PORT_B_MON", $sformatf("Observed: %s", item.convert2string()), UVM_MEDIUM)

                ap.write(item);
            end
        end
    endtask

endclass

`endif
