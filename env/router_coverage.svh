`ifndef ROUTER_COVERAGE_SVH
`define ROUTER_COVERAGE_SVH

`uvm_analysis_imp_decl(_port_a_cov)
`uvm_analysis_imp_decl(_port_b_cov)

class router_coverage extends uvm_subscriber #(output_item);
    `uvm_component_utils(router_coverage)

    uvm_analysis_imp_port_a_cov #(port_a_item, router_coverage) port_a_imp;
    uvm_analysis_imp_port_b_cov #(port_b_item, router_coverage) port_b_imp;

    port_a_item port_a_txn;
    port_b_item port_b_txn;
    output_item output_txn;

    router_reg_block reg_model;

    bit global_enable;
    bit priority_val;
    bit port_a_valid;
    bit port_b_valid;
    bit collision_occurred;
    int collision_count;

    // Covergroup Types You Should Create:
    // Register Field Coverage: Track all combinations of ctrl_reg fields
    // Port A/B Transaction Coverage: Track data patterns sent to each port
    // Output Transaction Coverage: Track which port won and why
    // Collision Scenarios: Track when both ports active simultaneously
    // Disable Scenarios: Track traffic when router disabled
    // Collision Counter Coverage: Track collision_cnt register values

    covergroup cg_register_fields;
        option.per_instance = 1;
        option.name = "register_fields_cg";

        cp_global_enable: coverpoint global_enable {
            bins enabled = {1};
            bins disabled = {0};
        }

        cp_priority: coverpoint priority_val {
            bins port_a_priority = {0};
            bins port_b_priority = {1};
        }
        
        // Transition coverage for priority changes
        cp_priority_transitions: coverpoint priority_val {
            bins a_to_b = (0 => 1);
            bins b_to_a = (1 => 0);
            bins stays_a = (0 => 0);
            bins stays_b = (1 => 1);
        }

        // Cross coverage: all combinations of enable and priority
        cross_enable_priority: cross cp_global_enable, cp_priority;
    endgroup

    // Port A transaction covergroup
    covergroup cg_port_a_transactions;
        option.per_instance = 1;
        
        cp_port_a_valid: coverpoint port_a_valid {
            bins valid = {1};
            bins invalid = {0};
        }
        
        // Data value ranges
        cp_data_a: coverpoint port_a_txn.data_a {
            bins zero = {8'h00};
            bins low = {[8'h01:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
            bins all_ones = {8'hFF};
        }
        
        // Address coverage - all output ports
        cp_addr_a: coverpoint port_a_txn.addr_a {
            bins port_0 = {0};
            bins port_1 = {1};
            bins port_2 = {2};
            bins port_3 = {3};
        }
        
        // Ready signal (acceptance)
        cp_ready_a: coverpoint port_a_txn.ready_a {
            bins accepted = {1};
            bins rejected = {0};
        }
        
        // Cross: data ranges sent to each port
        cross_addr_data: cross cp_addr_a, cp_data_a;
        
        // Cross: ready signal with address
        cross_addr_ready: cross cp_addr_a, cp_ready_a;
    endgroup

    // Port B transaction covergroup
    covergroup cg_port_b_transactions;
        option.per_instance = 1;
        
        cp_port_b_valid: coverpoint port_b_valid {
            bins valid = {1};
            bins invalid = {0};
        }
        
        // Data value ranges
        cp_data_b: coverpoint port_b_txn.data_b {
            bins zero = {8'h00};
            bins low = {[8'h01:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
            bins all_ones = {8'hFF};
        }
        
        // Address coverage - all output ports
        cp_addr_b: coverpoint port_b_txn.addr_b {
            bins port_0 = {0};
            bins port_1 = {1};
            bins port_2 = {2};
            bins port_3 = {3};
        }
        
        // Ready signal (acceptance)
        cp_ready_b: coverpoint port_b_txn.ready_b {
            bins accepted = {1};
            bins rejected = {0};
        }
        
        // Cross: data ranges sent to each port
        cross_addr_data: cross cp_addr_b, cp_data_b;
        
        // Cross: ready signal with address
        cross_addr_ready: cross cp_addr_b, cp_ready_b;
    endgroup

    // Output transaction covergroup
    covergroup cg_output_transactions;
        option.per_instance = 1;
        
        // Track which output ports are used
        cp_output_port: coverpoint output_txn.port_idx {
            bins port_0 = {0};
            bins port_1 = {1};
            bins port_2 = {2};
            bins port_3 = {3};
        }
        
        // Track data patterns on outputs
        cp_output_data: coverpoint output_txn.data {
            bins zero = {8'h00};
            bins low = {[8'h01:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins high = {[8'hC0:8'hFE]};
            bins all_ones = {8'hFF};
        }
        
        // Cross: which data values go to which ports
        cross_port_data: cross cp_output_port, cp_output_data;
    endgroup

    // Collision scenario covergroup
    covergroup cg_collision_scenarios;
        option.per_instance = 1;
        
        cp_collision: coverpoint collision_occurred {
            bins no_collision = {0};
            bins collision = {1};
        }
        
        cp_enable_during_collision: coverpoint global_enable {
            bins disabled = {0};
            bins enabled = {1};
        }
        
        cp_priority_during_collision: coverpoint priority_val {
            bins port_a_wins = {0};
            bins port_b_wins = {1};
        }
        
        // Transition coverage for collision events
        cp_collision_transitions: coverpoint collision_occurred {
            bins idle_to_collision = (0 => 1);
            bins collision_to_idle = (1 => 0);
            bins continuous_collision = (1 => 1);
            bins continuous_idle = (0 => 0);
        }
        
        // Cross: collision state with enable
        cross_collision_enable: cross cp_collision, cp_enable_during_collision {
            // Illegal: shouldn't have collision when disabled (router drops packets)
            illegal_bins collision_when_disabled = 
                binsof(cp_collision.collision) && binsof(cp_enable_during_collision.disabled);
        }
        
        // Cross: collision with priority setting (only matters during collision)
        cross_collision_priority: cross cp_collision, cp_priority_during_collision {
            // Only interesting when collision occurs
            ignore_bins no_collision_cases = 
                binsof(cp_collision.no_collision);
        }
        
        // Cross: all three - collision, enable, and priority
        cross_collision_enable_priority: cross cp_collision, cp_enable_during_collision, cp_priority_during_collision {
            ignore_bins no_collision_cases = 
                binsof(cp_collision.no_collision);
            illegal_bins collision_when_disabled = 
                binsof(cp_collision.collision) && binsof(cp_enable_during_collision.disabled);
        }
    endgroup

    function new(string name = "router_coverage", uvm_component parent = null);
        super.new(name, parent);

        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);

        cg_register_fields = new();
        cg_port_a_transactions = new();
        cg_port_b_transactions = new();
        cg_output_transactions = new();
        cg_collision_scenarios = new();
        
    endfunction

    virtual function void write(output_item t);
        output_txn = t;
        cg_output_transactions.sample();
    endfunction

    function void write_port_a_cov(port_a_item t);
        port_a_txn = t;
        port_a_valid = 1;
        sample_registers();  // Sample register state
        cg_port_a_transactions.sample();
    endfunction

    function void write_port_b_cov(port_b_item t);
        port_b_txn = t;
        port_b_valid = 1;
        sample_registers();  // Sample register state
        cg_port_b_transactions.sample();
    endfunction

    function void sample_collision_scenario(bit collision);
        if (reg_model != null) begin
            global_enable = reg_model.ctrl.global_enable.get_mirrored_value();
            priority_val = reg_model.ctrl.priority_val.get_mirrored_value();
        end 

        collision_occurred = collision;
        cg_collision_scenarios.sample();
        
        port_a_valid = 0;
        port_b_valid = 0;
    endfunction

    // Sample register fields when they change
    function void sample_registers();
        if (reg_model != null) begin
            global_enable = reg_model.ctrl.global_enable.get_mirrored_value();
            priority_val = reg_model.ctrl.priority_val.get_mirrored_value();
            cg_register_fields.sample();
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        real port_a_cov, port_b_cov, output_cov, reg_cov, collision_cov, total_cov;

        super.report_phase(phase);

        port_a_cov = cg_port_a_transactions.get_coverage();
        port_b_cov = cg_port_b_transactions.get_coverage();
        output_cov = cg_output_transactions.get_coverage();
        reg_cov = cg_register_fields.get_coverage();
        collision_cov = cg_collision_scenarios.get_coverage();

        total_cov = (port_a_cov + port_b_cov + output_cov + reg_cov + collision_cov) / 5.0;
        
        // Print coverage report
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "     FUNCTIONAL COVERAGE REPORT        ", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Port A Coverage      : %.2f%%", port_a_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Port B Coverage      : %.2f%%", port_b_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Output Coverage      : %.2f%%", output_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Register Coverage    : %.2f%%", reg_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Collision Coverage   : %.2f%%", collision_cov), UVM_LOW)
        `uvm_info(get_type_name(), "----------------------------------------", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("TOTAL Coverage       : %.2f%%", total_cov), UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        
        // Check coverage goals
        if (total_cov < 100.0) begin
            `uvm_warning(get_type_name(), 
                $sformatf("Coverage goal not met! Target: 100%%, Achieved: %.2f%%", total_cov))
        end else begin
            `uvm_info(get_type_name(), "Coverage goal ACHIEVED!", UVM_LOW)
        end
    endfunction


endclass

`endif 
