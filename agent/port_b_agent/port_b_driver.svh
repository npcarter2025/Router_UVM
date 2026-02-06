`ifndef PORT_B_DRIVER_SVH
`define PORT_B_DRIVER_SVH


class port_b_driver extends uvm_driver #(port_b_item);
    `uvm_component_utils(port_b_driver)

    virtual dual_port_router_if vif;
    port_b_config m_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(port_b_config)::get(this, "", "port_b_config", m_cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get port_b_config")
        end

        vif = m_cfg.vif;
    endfunction 

    virtual task run_phase(uvm_phase phase);

        @(vif.drv_cb_Port_B);
        wait(vif.rst_n);
        @(vif.drv_cb_Port_B);

        `uvm_info("PORT_B_DRV", "Reset complete and driver ready", UVM_LOW)

        vif.drv_cb_Port_B.data_b <= 8'b0;
        vif.drv_cb_Port_B.addr_b <= 2'b0;
        vif.drv_cb_Port_B.valid_b <= '0;

        forever begin 
            seq_item_port.get_next_item(req);

            // Drive the item (can be overridden for error injection)
            drive_item(req);

            seq_item_port.item_done();
        end

    endtask

    // Virtual method to drive a single item - can be overridden for error injection
    virtual task drive_item(port_b_item item);
        // Apply configurable delay before driving
        if (m_cfg.max_delay > 0) begin
            repeat ($urandom_range(m_cfg.min_delay, m_cfg.max_delay)) @(vif.drv_cb_Port_B);
        end

        `uvm_info("PORT_B_DRV", $sformatf("Driving %s", item.convert2string()), UVM_MEDIUM)

        vif.drv_cb_Port_B.data_b <= item.data_b;
        vif.drv_cb_Port_B.addr_b <= item.addr_b;
        vif.drv_cb_Port_B.valid_b <= item.valid_b;

        @(vif.drv_cb_Port_B);
        while (!vif.drv_cb_Port_B.ready_b) begin
            @(vif.drv_cb_Port_B);
        end

        item.ready_b = vif.drv_cb_Port_B.ready_b;

        vif.drv_cb_Port_B.valid_b <= 1'b0;
    endtask
endclass

`endif