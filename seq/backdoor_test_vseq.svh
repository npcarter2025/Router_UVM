`ifndef BACKDOOR_TEST_VSEQ_SVH
`define BACKDOOR_TEST_VSEQ_SVH

class backdoor_test_vseq extends router_base_vseq;
    `uvm_object_utils(backdoor_test_vseq)

    router_reg_block reg_model;

    function new(string name = "backdoor_test_vseq");
        super.new(name);
    endfunction

    virtual task body();

        uvm_status_e status;
        uvm_reg_data_t rdata;

        `uvm_info(get_type_name(), "Testing backdoor access", UVM_LOW)

        // Front door write (goes through driver)
        `uvm_info(get_type_name(), "Frontdoor write", UVM_LOW)
        reg_model.ctrl.write(status, 32'h3, .parent(this));

        // Backdoor read (direct RTL, instant)
        reg_model.ctrl.peek(status, rdata);
        `uvm_info(get_type_name(), $sformatf("Backdoor read value: 0x%08h", rdata), UVM_LOW)

        // Backdoor write (direct RTL, instant and no bus traffic)
        `uvm_info(get_type_name(), "Backdoor write", UVM_LOW)
        reg_model.ctrl.poke(status, 32'h1);

        // Update mirror after backdoor write
        reg_model.ctrl.set(32'h1);

        // Verify with frontdoor read
        reg_model.ctrl.read(status, rdata, .parent(this));
        `uvm_info(get_type_name(), $sformatf("Frontdoor read after backdoor write: 0x%08h", rdata), UVM_LOW)

    endtask
endclass

`endif 
