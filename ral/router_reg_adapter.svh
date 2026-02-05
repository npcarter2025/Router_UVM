`ifndef ROUTER_REG_ADAPTER_SVH
`define ROUTER_REG_ADAPTER_SVH

class router_reg_adapter extends uvm_reg_adapter;

    `uvm_object_utils(router_reg_adapter)

    function new(string name = "router_reg_adapter");
        super.new(name);
        supports_byte_enable = 0;
        provides_responses = 1;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        reg_item item   = reg_item::type_id::create("item");
        item.reg_addr   = rw.addr[3:0];
        item.reg_wdata  = rw.data;
        item.reg_en     = 1;
        item.reg_we     = (rw.kind == UVM_WRITE);
        return item;

    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        reg_item item;

        if (!$cast(item, bus_item)) begin
            `uvm_fatal("REG_ADAPTER", "Failed to cast bus_item to reg_item")
        end
        
        // Determine operation type from bus transaction
        rw.kind = item.reg_we ? UVM_WRITE : UVM_READ;
        rw.addr = item.reg_addr;
        rw.data = item.reg_we ? item.reg_wdata : item.reg_rdata;
        rw.status = UVM_IS_OK;
    endfunction

endclass

`endif 
