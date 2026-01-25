`ifndef PORT_B_DRIVER_SVH
`define PORT_B_DRIVER_SVH


class port_b_driver extends uvm_driver #(port_b_item);
    `uvm_component_utils(port_b_driver)

    virtual dual_port_router_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("PORT_B_DRV", "Couldn't get vif from config_db")
        end
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
            `seq_item_port.get_next_item(req);

            `uvm_info("PORT_B_DRV", $sformatf("Driving $s", req.convert2string()), UVM_MEDIUM)


            vif.drv_cb_Port_B.data_b <= req.data_b;
            vif.drv_cb_Port_B.addr_b <= req.addr_b;
            vif.drv_cb_Port_B.valid_b <= req.valid_b;

            @(vif.drv_cb_Port_B);
            while (!vif.drv_cb_Port_B.ready_b) begin
                @(vif.drv_cb_Port_B);
            end

            req.ready_b = vif.drv_cb_Port_B.ready_b;

            vif.drv_cb_Port_B.valid_b <= 1'b0;

            seq_item_port.item_done();
        end

    endtask
endclass

`endif