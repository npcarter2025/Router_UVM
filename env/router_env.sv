`ifndef ROUTER_ENV_SVH
`define ROUTER_ENV_SVH

class router_env extends uvm_env;
    `uvm_component_utils(router_env)

    port_a_agent m_port_a_agent;
    port_b_agent m_port_b_agent;
    reg_agent m_reg_agent;
    output_agent m_output_agent;

    router_virtual_sequencer m_vseqr;
    router_scoreboard m_scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_port_a_agent = port_a_agent::type_id::create("m_port_a_agent", this);
        m_port_b_agent = port_b_agent::type_id::create("m_port_b_agent", this);
        m_reg_agent = reg_agent::type_id::create("m_reg_agent", this);
        m_output_agent = output_agent::type_id::create("m_output_agent", this);

        m_vseqr = router_virtual_sequencer::type_id::create("m_vseqr", this);
        m_scoreboard = router_scoreboard::type_id::create("m_scoreboard", this);

    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

    endfunction
endclass



`endif