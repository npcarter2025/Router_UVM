`ifndef ROUTER_SCOREBOARD_DPI_SVH
`define ROUTER_SCOREBOARD_DPI_SVH

`uvm_analysis_imp_decl(_port_a_dpi)
`uvm_analysis_imp_decl(_port_b_dpi)
`uvm_analysis_imp_decl(_output_dpi)
`uvm_analysis_imp_decl(_reg_dpi)

class router_scoreboard_dpi extends uvm_scoreboard;
    `uvm_component_utils(router_scoreboard_dpi)

    uvm_analysis_imp_port_a_dpi #(port_a_item, router_scoreboard_dpi) port_a_imp;
    uvm_analysis_imp_port_b_dpi #(port_b_item, router_scoreboard_dpi) port_b_imp;
    uvm_analysis_imp_output_dpi #(output_item, router_scoreboard_dpi) output_imp;
    uvm_analysis_imp_reg_dpi    #(reg_item,    router_scoreboard_dpi) reg_imp;

    int match_count;
    int mismatch_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        port_a_imp = new("port_a_imp", this);
        port_b_imp = new("port_b_imp", this);
        output_imp = new("output_imp", this);
        reg_imp = new("reg_imp", this);

        // init C++ Model
        router_model_init();
    endfunction

    function void write_port_a_dpi(port_a_item item);
        if (item.ready_a) begin
            router_model_port_a(item.data_a, item.addr_a);
            `uvm_info("SB_DPI", $sformatf("Fed Port A to C++ model: data=0x%02h addr=0x%0d", item.data_a, item.addr_a), UVM_HIGH)
        end
    endfunction

    function void write_port_b_dpi(port_b_item item);
        if (item.ready_b) begin
            router_model_port_b(item.data_b, item.addr_b);
            `uvm_info("SB_DPI", $sformatf("Fed Port B to C++ model: data=0x%02h addr=0x%0d", item.data_b, item.addr_b), UVM_HIGH)
        end
    endfunction

    function void write_reg_dpi(reg_item item);
        if (item.reg_we && item.reg_en) begin
            router_model_write_ctrl(item.reg_wdata);
            `uvm_info("SB_DPI", $sformatf("Fed Port register write to C++ model: data=0x%08h", item.reg_wdata), UVM_HIGH)
        end
    endfunction

    function void write_output_dpi(output_item item);
        byte unsigned expected_data;
        int valid;

        valid = router_model_get_output(item.port_idx, expected_data);

        if (valid) begin
            if (item.data == expected_data) begin
                `uvm_info("SB_DPI", $sformatf("DPI MATCH on port[%0d]: expected=0x%02h actual=0x%02h", item.port_idx, expected_data, item.data), UVM_MEDIUM)
                match_count++;
            end else begin
                `uvm_error("SB_DPI", $sformatf("DPI MISMATCH on port[%0d]: expected=0x%02h actual=0x%02h", item.port_idx, expected_data, item.data))
                mismatch_count++;       
            end 
        end else begin
            `uvm_error("SB_DPI", $sformatf("DPI: Unexpected output on port[%0d] (C++ model has no data)", item.port_idx))
            mismatch_count++;
        end 
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "  DPI-C Scoreboard Statistics:", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Matches: %0d", match_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Mismatches: %0d", mismatch_count), UVM_LOW)
        
        if (mismatch_count > 0) begin
            `uvm_error(get_type_name(), $sformatf("DPI SCOREBOARD FAILED - %0d mismatches", mismatch_count))
        end else begin
            `uvm_info(get_type_name(), "DPI SCOREBOARD PASSED!", UVM_LOW)
        end
    endfunction                   



endclass
       

`endif
