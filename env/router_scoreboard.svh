`ifndef ROUTER_SCOREBOARD_SVH
`define ROUTER_SCOREBOARD_SVH

// Declare analysis imp macros BEFORE the class
`uvm_analysis_imp_decl(_port_a)
`uvm_analysis_imp_decl(_port_b)
`uvm_analysis_imp_decl(_output)
//`uvm_analysis_imp_decl(_reg)

class router_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(router_scoreboard)

    // Analysis imports - receive from monitors
    uvm_analysis_imp_port_a #(port_a_item, router_scoreboard) port_a_imp;
    uvm_analysis_imp_port_b #(port_b_item, router_scoreboard) port_b_imp;
    uvm_analysis_imp_output #(output_item, router_scoreboard) output_imp;
    //uvm_analysis_imp_reg    #(reg_item,    router_scoreboard) reg_imp;

    // Adding RAL COMPONENTS
    router_reg_block reg_model;

    // // Tracking Register State here:
    // bit global_enable;
    // bit port_priority;  // 0 = PortA, 1 = PortB

    // Expected queue - stores expected data for each output port
    // Using a struct to handle both port_a and port_b items
    typedef struct {
        bit [7:0] data;
        bit [1:0] addr;
        string    source;
    } expected_t;

    expected_t expected_queue[4][$];

    // Counters
    int match_count;
    int mismatch_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);
        output_imp = new("output_imp", this);
        //reg_imp    = new("reg_imp",    this);

        // initialize to reset values
        // global_enable = 1'b1;
        // port_priority = 1'b0;
    endfunction

    // function void write_reg(reg_item item);
    //     if (item.is_write() && item.reg_addr == 4'h0) begin
    //         global_enable = item.reg_wdata[0];
    //         port_priority = item.reg_wdata[1];

    //         `uvm_info("SB", $sformatf("Register state updated: enable=%0b, priority=%s", global_enable, port_priority ? "Port B" : "Port A"), UVM_MEDIUM)
    //     end
    // endfunction


    // Called when port_a_monitor observes a transaction
    function void write_port_a(port_a_item item);
        `uvm_info("SB", $sformatf("Port A sent: %s", item.convert2string()), UVM_MEDIUM)
        if (!reg_model.ctrl.global_enable.get_mirrored_value()) begin
        //if (!global_enable) begin
            `uvm_info("SB", "Router disabled, ignoring Port A", UVM_HIGH)
            return;
        end

        
        // Only add to expected if transaction was accepted
        if (item.ready_a) begin
            expected_t exp;
            exp.data   = item.data_a;
            exp.addr   = item.addr_a;
            exp.source = "port_a";

            expected_queue[item.addr_a].push_back(exp);

            `uvm_info("SB", $sformatf("Added to expected_queue[%0d], queue size=%0d",
                item.addr_a, expected_queue[item.addr_a].size()), UVM_HIGH)
        end else begin
            `uvm_info("SB", "Port A transaction not accepted (ready_a=0), ignoring", UVM_HIGH)
        end
    endfunction

    // Called when port_b_monitor observes a transaction
    function void write_port_b(port_b_item item);
        `uvm_info("SB", $sformatf("Port B sent: %s", item.convert2string()), UVM_MEDIUM)
        if (!reg_model.ctrl.global_enable.get_mirrored_value()) begin
        //if (!global_enable) begin
            `uvm_info("SB", "Router disabled, ignoring Port B", UVM_HIGH)
            return;
        end

        // Only add to expected if transaction was accepted
        if (item.ready_b) begin
            expected_t exp;
            exp.data   = item.data_b;
            exp.addr   = item.addr_b;
            exp.source = "port_b";

            expected_queue[item.addr_b].push_back(exp);

            `uvm_info("SB", $sformatf("Added to expected_queue[%0d], queue size=%0d",
                item.addr_b, expected_queue[item.addr_b].size()), UVM_HIGH)
        end else begin
            `uvm_info("SB", "Port B transaction not accepted (ready_b=0), ignoring", UVM_HIGH)
        end
    endfunction

    // Called when output_monitor observes a transaction
    function void write_output(output_item item);
        `uvm_info("SB", $sformatf("Output received: %s", item.convert2string()), UVM_MEDIUM)

        // Check if we expected anything on this output port
        if (expected_queue[item.port_idx].size() == 0) begin
            `uvm_error("SB", $sformatf("UNEXPECTED output on port[%0d]: data=0x%02h (no transaction expected)",
                item.port_idx, item.data))
            mismatch_count++;
            return;
        end

        begin
            expected_t exp_item;
            exp_item = expected_queue[item.port_idx].pop_front();

            if (item.data == exp_item.data) begin
                `uvm_info("SB", $sformatf("MATCH on port[%0d]: expected=0x%02h, actual=0x%02h (from %s)",
                    item.port_idx, exp_item.data, item.data, exp_item.source), UVM_MEDIUM)
                match_count++;
            end else begin
                `uvm_error("SB", $sformatf("MISMATCH on port[%0d]: expected=0x%02h, actual=0x%02h (from %s)",
                    item.port_idx, exp_item.data, item.data, exp_item.source))
                mismatch_count++;
            end
        end
    endfunction

    // Report results at end of simulation
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "Scoreboard Statistics:", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Matches: %0d", match_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Mismatches: %0d", mismatch_count), UVM_LOW)

        // Check for leftover expected transactions
        foreach (expected_queue[i]) begin
            if (expected_queue[i].size() > 0) begin
                `uvm_error(get_type_name(), $sformatf("Expected queue[%0d] has %0d unmatched transactions",
                    i, expected_queue[i].size()))
                mismatch_count += expected_queue[i].size();
            end
        end

        if (mismatch_count > 0) begin
            `uvm_error(get_type_name(), $sformatf("TEST FAILED - %0d mismatches", mismatch_count))
        end else begin
            `uvm_info(get_type_name(), "TEST PASSED - All checks passed!", UVM_LOW)
        end
    endfunction

endclass

`endif
