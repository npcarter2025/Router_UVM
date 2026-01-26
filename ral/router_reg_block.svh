`ifndef ROUTER_REG_BLOCK_SVH
`define ROUTER_REG_BLOCK_SVH

class router_reg_block extends uvm_reg_block;
    `uvm_object_utils(router_reg_block)

    rand ctrl_reg       ctrl;
    rand collision_cnt_reg collision_cnt;

    uvm_reg_map default_map;

    function new(string name = "router_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();

        ctrl = ctrl_reg::type_id::create("ctrl");
        ctrl.configure(this, null, "");
        ctrl.build();

        collision_cnt = collision_cnt_reg::type_id::create("collision_cnt");
        collision_cnt.configure(this, null, "");
        collision_cnt.build();

        default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);
        default_map.add_reg(ctrl,       'h0, "RW");
        default_map.add_reg(collision_cnt, 'h8, "RO");

        lock_model();

    endfunction

endclass

`endif