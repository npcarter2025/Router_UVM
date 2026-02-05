`ifndef CTRL_REG_SVH
`define CTRL_REG_SVH

class ctrl_reg extends uvm_reg;
    `uvm_object_utils(ctrl_reg)

    rand uvm_reg_field global_enable;   // bit 0
    rand uvm_reg_field priority_val;    // bit 1
    rand uvm_reg_field reserved;        // bits 31:2

    function new(string name = "ctrl_reg");
        super.new(name, 32, UVM_CVR_ALL);
    endfunction

    virtual function void build(); // Note that this is NOT build_phase
        global_enable = uvm_reg_field::type_id::create("global_enable");
        global_enable.configure(this, 1, 0, "RW", 0, 1'h1, 1, 1, 0);

        //configure() args:  parent, size(bits), lsb, access, volatile, reset_value, has_reset, is_rand, individually_accessible

        priority_val = uvm_reg_field::type_id::create("priority_val");
        priority_val.configure(this, 1, 1, "RW", 0, 1'h0, 1, 1, 0);

        reserved = uvm_reg_field::type_id::create("reserved");
        reserved.configure(this, 30, 2, "RO", 1, 30'h0, 1, 0, 0);

        // Adding HDL path for backdoor access
        add_hdl_path_slice("ctrl_reg", 0, 32); //

    endfunction

endclass

`endif 
