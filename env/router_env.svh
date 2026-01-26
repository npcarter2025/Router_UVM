`ifndef ROUTER_ENV_SVH
`define ROUTER_ENV_SVH

class router_env extends uvm_env;
    `uvm_component_utils(router_env)

    port_a_agent m_port_a_agent;
    port_b_agent m_port_b_agent;
    reg_agent m_reg_agent;
    output_agent m_output_agent;

    // RAL components:
    router_reg_block                m_reg_model;
    router_reg_adapter              m_reg_adapter;
    uvm_reg_predictor #(reg_item)   m_predictor;

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

        m_reg_model = router_reg_block::type_id::create("m_reg_model");
        m_reg_model.build();

        m_reg_adapter = router_reg_adapter::type_id::create("m_reg_adapter");

        m_predictor = uvm_reg_predictor#(reg_item)::type_id::create("m_predictor", this);


    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect virtual sequencer to agent sequencers
        m_vseqr.p_port_a_seqr = m_port_a_agent.seqr;
        m_vseqr.p_port_b_seqr = m_port_b_agent.seqr;
        m_vseqr.p_reg_seqr    = m_reg_agent.seqr;

        // Connect monitors to scoreboard
        m_port_a_agent.mon.ap.connect(m_scoreboard.port_a_imp);
        m_port_b_agent.mon.ap.connect(m_scoreboard.port_b_imp);
        m_output_agent.monitor.ap.connect(m_scoreboard.output_imp);

        m_reg_model.default_map.set_sequencer(m_reg_agent.seqr, m_reg_adapter);
        m_reg_model.default_map.set_auto_predict(0);

        m_predictor.map     = m_reg_model.default_map;
        m_predictor.adapter = m_reg_adapter;
        m_reg_agent.mon.ap.connect(m_predictor.bus_in);

        
    endfunction
endclass



`endif