`ifndef REG_MONITOR_SVH
`define REG_MONITOR_SVH

class reg_monitor extends uvm_monitor;

    `uvm_component_utils(reg_monitor)

    virtual dual_port_router_if vif;

    uvm_analysis_port #(reg_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        ap = new("ap", this);

        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("REG_MON", "couldn't get the vif from config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("REG_MON", "reg monitor run_phase beginning", UVM_LOW)

        @(vif.drv_cb_Ctrl);
        wait(vif.rst_n);
        @(vif.drv_cb_Ctrl);

        `uvm_info("REG_MON", "Reset completed")

        forever begin
            @(vif.drv_cb_Ctrl);

            if (vif.drv_cb_Ctrl.reg_en) begin
                reg_item item = reg_item::type_id::create("reg_item");

                item.reg_addr = vif.drv_cb_Ctrl.reg_addr;
                item.reg_wdata = vif.drv_cb_Ctrl.reg_wdata;
                item.reg_en = vif.drv_cb_Ctrl.reg_en;
                item.reg_we = vif.drv_cb_Ctrl.reg_we;
                item.reg_rdata = vif.drv_cb_Ctrl.reg_rdata;

                `uvm_info("REG_MON", $sformatf("Observed: %s", item.convert2string()), UVM_MEDIUM)

                ap.write(item);
            end
        end
    endtask
endclass
    // clocking drv_cb_Ctrl @(posedge clk);
    //     default input #1ns output #1ns;
    //     output reg_addr, reg_wdata, reg_en, reg_we;
    //     input reg_rdata;
    // endclocking


    // rand bit [3:0] reg_addr;
    // rand bit [31:0] reg_wdata;
    // rand bit reg_en;
    // rand bit reg_we;

    // // Responses
    // bit [31:0] reg_rdata;



`endif 
