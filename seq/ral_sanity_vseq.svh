`ifndef RAL_SANITY_VSEQ_SVH
`define RAL_SANITY_VSEQ_SVH

class ral_sanity_vseq extends router_base_vseq;
    `uvm_object_utils(ral_sanity_vseq)

    router_reg_block reg_model;

    function new(string name = "ral_sanity_vseq");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t rdata;

        `uvm_info(get_type_name(), "Starting RAL sanity test", UVM_LOW)

        // Initialize mirror by reading all registers from DUT
        // This populates the mirror with actual hardware values
        `uvm_info(get_type_name(), "Initializing register mirror from DUT", UVM_MEDIUM)
        reg_model.mirror(status, UVM_CHECK, UVM_FRONTDOOR, .parent(this));

        // Test 1: Read default value of ctrl_reg
        reg_model.ctrl.read(status, rdata, .parent(this));
        `uvm_info(get_type_name(), $sformatf("ctrl_reg default = 0x%08h", rdata), UVM_LOW)
        assert(rdata == 32'h1) else `uvm_error(get_type_name(), "ctrl_ref default mismatch")

        // Test 2: Write and read back ctrl_reg
        reg_model.ctrl.write(status, 32'h3, .parent(this)); // Enable + Priority= Port B
        reg_model.ctrl.read(status, rdata, .parent(this));
        assert(rdata == 32'h3) else `uvm_error(get_type_name(), "ctrl_reg write/read mismatch")

        // Test 3: Read collision counter (should be 0)
        reg_model.collision_cnt.read(status, rdata, .parent(this));
        `uvm_info(get_type_name(), $sformatf("collision_cnt = %0d", rdata), UVM_LOW)

        // Test 4: Field-level access
        reg_model.ctrl.global_enable.set(0); // Disable router
        reg_model.ctrl.update(status, .parent(this));

        reg_model.ctrl.mirror(status, UVM_CHECK, .parent(this)); // Verify mirror matches DUT

        `uvm_info(get_type_name(), "RAL sanity test complete", UVM_LOW)
    endtask

endclass

`endif 
