`ifndef COLLISION_CNT_REG_SVH
`define COLLISION_CNT_REG_SVH

class collision_cnt_reg extends uvm_reg;
    `uvm_object_utils(collision_cnt_reg)

    rand uvm_reg_field count;

    function new(string name = "collision_cnt_reg");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        count = uvm_reg_field::type_id::create("count");
        count.configure(this, 32, 0, "RO", 0, 32'h0, 1, 0, 0); // Read-only

        //configure() args:  parent, size(bits), lsb, access, volatile, reset_value, has_reset, is_rand, individually_accessible
        

        // Adding HDL path for backdoor access
        add_hdl_path_slice("collision_cnt", 0, 32);
    endfunction

endclass

`endif 
