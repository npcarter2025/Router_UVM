`ifndef ROUTER_REG_BLOCK_SVH
`define ROUTER_REG_BLOCK_SVH

class router_reg_block extends uvm_reg_block;

    `uvm_object_utils(router_reg_block)

    rand ctrl_reg               ctrl;
    rand collision_cnt_reg      collision_cnt;

    uvm_reg_map                 default_map;  

    function new(string name = "router_reg_block");
        super.new(name, UVM_CVR_REG_BITS | UVM_CVR_ADDR_MAP);
    endfunction

    virtual function void build();

        ctrl = ctrl_reg::type_id::create("ctrl");
        ctrl.configure(this, null, "");
        ctrl.build();
        
        // Include coverage for ctrl register
        if (has_coverage(UVM_CVR_REG_BITS)) begin
            ctrl.include_coverage("*", UVM_CVR_REG_BITS);
            `uvm_info("REG_BLOCK", "Coverage included for ctrl", UVM_MEDIUM)
        end else begin
            `uvm_info("REG_BLOCK", "Coverage NOT available for ctrl", UVM_MEDIUM)
        end

        collision_cnt = collision_cnt_reg::type_id::create("collision_cnt");
        collision_cnt.configure(this, null, "");
        collision_cnt.build();
        
        // Include coverage for collision_cnt register
        if (has_coverage(UVM_CVR_REG_BITS)) begin
            collision_cnt.include_coverage("*", UVM_CVR_REG_BITS);
            `uvm_info("REG_BLOCK", "Coverage included for collision_cnt", UVM_MEDIUM)
        end else begin
            `uvm_info("REG_BLOCK", "Coverage NOT available for collision_cnt", UVM_MEDIUM)
        end

        default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);

        //virtual function uvm_reg_map create_map(		
        // string 	name,	  	
        // uvm_reg_addr_t 	base_addr,	  	
        // int 	unsigned 	n_bytes,	  	
        // uvm_endianness_e 	endian,	  	
        // bit 	byte_addressing	 = 	1	)

        default_map.add_reg(ctrl,       'h0, "RW");
        // virtual function void add_reg (	
        // uvm_reg 	rg,	  	
        // uvm_reg_addr_t 	offset,	  	
        // string 	rights	 = 	"RW",
        // bit 	unmapped	 = 	0,
        // uvm_reg_frontdoor 	frontdoor	 = 	null	)

        default_map.add_reg(collision_cnt, 'h8, "RO");

        lock_model();

    endfunction        

endclass

`endif
