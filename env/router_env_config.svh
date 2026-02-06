`ifndef ROUTER_ENV_CONFIG_SVH
`define ROUTER_ENV_CONFIG_SVH

class router_env_config extends uvm_object;
    `uvm_object_utils(router_env_config)

    port_a_config m_port_a_cfg;
    port_b_config m_port_b_cfg;
    reg_config m_reg_cfg;
    output_config m_output_cfg;

    bit enable_scoreboard = 1;
    bit enable_dpi_scoreboard = 0; // 

    bit enable_coverage = 1;

    virtual dual_port_router_if vif;

    function new(string name = "router_env_config");
        super.new(name);

        // create sub-configs
        m_port_a_cfg = port_a_config::type_id::create("m_port_a_cfg");
        m_port_b_cfg = port_b_config::type_id::create("m_port_b_cfg");
        m_reg_cfg = reg_config::type_id::create("m_reg_cfg");
        m_output_cfg = output_config::type_id::create("m_output_cfg");
    endfunction

    // Set all VIFs at once

    function void set_vif(virtual dual_port_router_if vif);
        this.vif = vif;
        m_port_a_cfg.vif = vif;
        m_port_b_cfg.vif = vif;
        m_reg_cfg.vif = vif;
        m_output_cfg.vif = vif;
    endfunction


endclass

`endif 
