`ifndef ERROR_INJECTION_TEST_SVH
`define ERROR_INJECTION_TEST_SVH

class error_injection_test extends router_base_test;
    `uvm_component_utils(error_injection_test)

    function new(string name = "error_injection_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        // Use factor override to replace normal driver with error driver

        port_a_driver::type_id::set_type_override(port_a_error_driver::get_type());
        port_b_driver::type_id::set_type_override(port_b_error_driver::get_type());

        super.build_phase(phase);
    endfunction

    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);

        //Enable error injection
        cfg.m_port_a_cfg.error_injection_enable = 1;
        cfg.m_port_a_cfg.error_rate = 10; // 10% error rate

        cfg.m_port_b_cfg.error_injection_enable = 1;
        cfg.m_port_b_cfg.error_rate = 10;

        `uvm_info(get_type_name(), "Error injection enabled (10% rate)", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        directed_data_vseq data_seq;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting error injection test with directed data", UVM_LOW)

        // Generate directed traffic to test error injection
        data_seq = directed_data_vseq::type_id::create("data_seq");
        data_seq.num_port_a_items = 3000;  // Send 30 items on Port A
        data_seq.num_port_b_items = 3000;  // Send 30 items on Port B
        data_seq.start(m_env.m_vseqr);

        #100ns;

        `uvm_info(get_type_name(), "Error injection test completed", UVM_LOW)



        phase.drop_objection(this);
    endtask
endclass

`endif 
