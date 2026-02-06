`ifndef CONFIG_TEST_SVH
`define CONFIG_TEST_SVH

class config_test extends router_base_test;
    `uvm_component_utils(config_test)

    function new(string name = "config_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);

        cfg.m_port_a_cfg.min_delay = 2;
        cfg.m_port_a_cfg.max_delay = 10;

        `uvm_info(get_type_name(), "Configuration customized for config_test", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "Starting config test", UVM_LOW)

        #1000ns;

        phase.drop_objection(this);
    endtask
endclass

`endif 
