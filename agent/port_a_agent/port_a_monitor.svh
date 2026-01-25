`ifndef PORT_A_MONITOR_SVH
`define PORT_A_MONITOR_SVH

class port_a_monitor extends uvm_monitor;
    `uvm_component_utils(port_a_monitor)

    virtual dual_port_router_if vif;

    uvm_analysis_port #(port_a_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        ap = new("ap", this);

        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("PORT_A_MON", "couldn't get vif from config_db")
        end

    endfunction

    virtual task run_phase(uvm_phase phase);
        `uvm_info("PORT_A_MON", "port a monitor run phase has begun", UVM_LOW)


        // first wait for reset

        @(vif.mon_cb);
        wait(vif.rst_n);
        @(vif.mon_cb);


        forever begin

            @(vif.mon_cb);

            if (vif.mon_cb.valid_a && vif.mon_cb.ready_a) begin
                port_a_item item = port_a_item::type_id::create("port_a_item");
                item.data_a = vif.mon_cb.data_a;
                item.addr_a = vif.mon_cb.addr_a;
                item.valid_a = vif.mon_cb.valid_a;
                item.ready_a = vif.mon_cb.ready_a;

                `uvm_info("PORT_A_MON", $sformatf("Observed: %s", item.convert2string()), UVM_MEDIUM)

                ap.write(item);
            end
        end
    endtask
endclass

`endif 
