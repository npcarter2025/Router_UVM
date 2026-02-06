`ifndef REG_CONFIG_SVH
`define REG_CONFIG_SVH

class reg_config extends uvm_object;
    `uvm_object_utils(reg_config)

    uvm_active_passive_enum is_active = UVM_ACTIVE;

    bit coverage_enable = 1;

    bit error_injection_enable = 0;
    rand int error_rate = 5; // 5% error rate

    rand int min_delay = 0;
    rand int max_delay = 5;

    virtual dual_port_router_if vif;

    function new(string name = "reg_config");
        super.new(name);
    endfunction

    constraint reasonable_delays_c {
        min_delay >= 0;
        max_delay <= 20;
        max_delay >= min_delay;
    }

    constraint error_rate_c {
        error_rate >= 0;
        error_rate <= 100;
    }

endclass

`endif 
