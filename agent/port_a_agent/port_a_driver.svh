`ifndef PORT_A_DRIVER_SVH
`define PORT_A_DRIVER_SVH

class port_a_driver extends uvm_driver #(port_a_item);
    `uvm_component_utils(port_a_driver)

    virtual dual_port_router_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("PORT_A_DRV", "Coudln't get virtual interface from config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("PORT_A_DRV", "Driver run phase started", UVM_LOW)

        @(vif.drv_cb_Port_A);
        wait(vif.rst_n);
        @(vif.drv_cb_Port_A);

        `uvm_info("PORT_A_DRV", "Reset complete and driver ready", UVM_LOW)

        vif.drv_cb_Port_A.data_a <= 8'b0;
        vif.drv_cb_Port_A.addr_a <= 2'b0;
        vif.drv_cb_Port_A.valid_a <= '0;

        forever begin

            `uvm_info("PORT_A_DRV", "Driver ")

    endtask


endclass

`endif