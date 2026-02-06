`ifndef ROUTER_BASE_TEST_SVH
`define ROUTER_BASE_TEST_SVH

class router_base_test extends uvm_test;
    `uvm_component_utils(router_base_test)

    router_env m_env;
    router_env_config m_env_cfg; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_env_cfg = router_env_config::type_id::create("m_env_cfg");

        if (!uvm_config_db#(virtual dual_port_router_if)::get(this, "", "vif", m_env_cfg.vif)) begin
            `uvm_fatal(get_type_name(), "Failed to get VIF")
        end

        m_env_cfg.set_vif(m_env_cfg.vif);

        configure_env(m_env_cfg);

        // Put config in database for environment
        uvm_config_db#(router_env_config)::set(this, "m_env", "router_env_config", m_env_cfg);
        uvm_config_db#(port_a_config)::set(this, "m_env.m_port_a_agent", "port_a_config", m_env_cfg.m_port_a_cfg);
        uvm_config_db#(port_b_config)::set(this, "m_env.m_port_b_agent", "port_b_config", m_env_cfg.m_port_b_cfg);
        uvm_config_db#(reg_config)::set(this, "m_env.m_reg_agent", "reg_config", m_env_cfg.m_reg_cfg);
        uvm_config_db#(output_config)::set(this, "m_env.m_output_agent", "output_config", m_env_cfg.m_output_cfg);


        m_env = router_env::type_id::create("m_env", this);
    endfunction

    virtual function void configure_env(router_env_config cfg);
        //Default configuration - override in derived tests
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        
        uvm_top.print_topology();

    endfunction

    virtual task run_phase(uvm_phase phase);
        collision_vseq vseq;

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Starting test", UVM_LOW)

        vseq = collision_vseq::type_id::create("vseq");
        vseq.start(m_env.m_vseqr);

        // Drain time: wait for final transactions to complete
        #100ns;

        `uvm_info(get_type_name(), "Test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        real reg_cov;
        real ctrl_cov;
        real collision_cov;
        super.report_phase(phase);

        if (m_env.m_reg_model != null) begin
            // Try different coverage models
            reg_cov = m_env.m_reg_model.get_coverage(UVM_CVR_REG_BITS);
            ctrl_cov = m_env.m_reg_model.ctrl.get_coverage(UVM_CVR_REG_BITS);
            collision_cov = m_env.m_reg_model.collision_cnt.get_coverage(UVM_CVR_REG_BITS);
            `uvm_info("COV", $sformatf("Register Block Coverage (REG_BITS): %.2f%%", reg_cov), UVM_LOW)
            `uvm_info("COV", $sformatf("  ctrl_reg Coverage (REG_BITS): %.2f%%", ctrl_cov), UVM_LOW)
            `uvm_info("COV", $sformatf("  collision_cnt Coverage (REG_BITS): %.2f%%", collision_cov), UVM_LOW)
            
            // Also check address map coverage
            reg_cov = m_env.m_reg_model.get_coverage(UVM_CVR_ADDR_MAP);
            `uvm_info("COV", $sformatf("Register Block Coverage (ADDR_MAP): %.2f%%", reg_cov), UVM_LOW)
        end

    endfunction



endclass

`endif 
