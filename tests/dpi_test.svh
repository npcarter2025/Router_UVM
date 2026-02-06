`ifndef DPI_TEST_SVH
`define DPI_TEST_SVH

class dpi_test extends router_base_test;
    `uvm_component_utils(dpi_test)

    function new(string name = "dpi_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void configure_env(router_env_config cfg);
        super.configure_env(cfg);

        cfg.enable_dpi_scoreboard = 1;
        cfg.enable_scoreboard = 0;

        `uvm_info(get_type_name(), "DPI-C scoreboard enabled", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        priority_vseq base_seq;

        phase.raise_objection(this);

        base_seq = priority_vseq::type_id::create("base_seq");
        base_seq.start(m_env.m_vseqr);

        phase.drop_objection(this);
    endtask

endclass
`endif
