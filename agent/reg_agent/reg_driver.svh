`ifndef REG_DRIVER_SVH
`define REG_DRIVER_SVH

class reg_driver extends uvm_driver #(reg_item);


    `uvm_component_utils(reg_driver)

    virtual dual_port_router_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("REG_DRV", "Vif couldn't be found in the config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("REG_DRV", "Register driver run phase started", UVM_LOW)

        // Wait for reset to complete
        @(vif.drv_cb_Ctrl);
        wait(vif.rst_n);
        @(vif.drv_cb_Ctrl);

        `uvm_info("REG_DRV", "Reset complete, driver ready", UVM_LOW)

        // Initialize signals
        vif.drv_cb_Ctrl.reg_addr  <= 4'b0;
        vif.drv_cb_Ctrl.reg_wdata <= 32'b0;
        vif.drv_cb_Ctrl.reg_en <= '0;
        vif.drv_cb_Ctrl.reg_we <= '0;

        forever begin
            `uvm_info("REG_DRV", "waiting for next item", UVM_HIGH)
            seq_item_port.get_next_item(req);
            `uvm_info("REG_DRV", $sformatf("Got item: %s", req.convert2string()), UVM_MEDIUM)

            @(vif.drv_cb_Ctrl);
            vif.drv_cb_Ctrl.reg_addr  <= req.reg_addr;
            vif.drv_cb_Ctrl.reg_wdata <= req.reg_wdata;
            vif.drv_cb_Ctrl.reg_en    <= req.reg_en;
            vif.drv_cb_Ctrl.reg_we    <= req.reg_we;

            @(vif.drv_cb_Ctrl);

            // Capture read data (combinational output from DUT)
            req.reg_rdata = vif.drv_cb_Ctrl.reg_rdata;

            // Deassert enable
            vif.drv_cb_Ctrl.reg_en <= 1'b0;
            vif.drv_cb_Ctrl.reg_we <= 1'b0;

            `uvm_info("REG_DRV", $sformatf("Completed: %s", req.convert2string()), UVM_MEDIUM)

            // Signal sequencer we're done and send response back
            seq_item_port.item_done(req);
        end
    endtask

endclass

`endif