`ifndef ROUTER_COVERAGE_SVH
`define ROUTER_COVERAGE_SVH

class router_coverage extends uvm_component;
    `uvm_component_utils(router_coverage)
    
    `uvm_analysis_imp_decl(_port_a)
    `uvm_analysis_imp_decl(_port_b)
    `uvm_analysis_imp_decl(_output)

    `uvm_analysis_imp_decl(_reg)

    uvm_analysis_imp_port_a #(port_a_item, router_coverage) port_a_export;
    uvm_analysis_imp_port_b #(port_b_item, router_coverage) port_b_export;
    uvm_analysis_imp_output #(output_item, router_coverage) output_export;
    uvm_analysis_imp_reg    #(reg_item, router_coverage) reg_export;

    port_a_item m_port_a_item;
    port_b_item m_port_b_item;
    output_item m_output_item;
    reg_item    m_reg_item;

    covergroup port_a_cg;
        addr_cp: coverpoint m_port_a_item.addr_a {
            bins addr_0 = {2'b00};
            bins addr_1 = {2'b01};
            bins addr_2 = {2'b10};
            bins addr_3 = {2'b11};
        }

        data_cp: coverpoint m_port_a_item.data_a {
            bins low = {[8'h00:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins high ={[8'hC0:8'hFF]};
        }

        addr_data_cross: cross addr_cp, data_cp;
    endgroup

    covergroup port_b_cg;
        addr_cp: coverpoint m_port_b_item.addr_b {
            bins addr_0 = {2'b00};
            bins addr_1 = {2'b01};
            bins addr_2 = {2'b10};
            bins addr_3 = {2'b11};
        }

        data_cp: coverpoint m_port_b_item.data_b {
            bins low = {[8'h00:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins high ={[8'hC0:8'hFF]};
        }

        addr_data_cross: cross addr_cp, data_cp;
    endgroup

    covergroup output_cg;
        port_idx_cp: coverpoint m_output_item.port_idx {
            bins port_0 = {2'b00};
            bins port_1 = {2'b01};
            bins port_2 = {2'b10};
            bins port_3 = {2'b11};
        }

        data_cp: coverpoint m_output_item.data {
            bins low = {[8'h00:8'h3F]};
            bins mid = {[8'h40:8'hBF]};
            bins high ={[8'hC0:8'hFF]};
        }

        valid_cp: coverpoint m_output_item.valid {
            bins is_valid = {1'b1};
            bins not_valid = {1'b0};
        }

        port_data_cross: cross port_idx_cp, data_cp;
    endgroup

    covergroup reg_cg;
        addr_cp: coverpoint m_reg_item.reg_addr {
            bins ctrl_reg   = {4'h0};
            bins status_reg = {4'h4};
            bins collisions_cnt = {4'h8};
        }

        rw_cp: coverpoint m_reg_item.reg_we {
            bins read  = {0};
            bins write = {1};
        }

        ctrl_data_cp: coverpoint m_reg_item.reg_wdata[1:0] {
            bins disabled                = {2'b00}; // global_enable = 0
            bins enabled_port_a_priority = {2'b01}; // enabled, priority = port_a
            bins enabled_port_b_priority = {2'b10}; // enabled, priority = port_b

        }

        addr_rw_cross: cross addr_cp, rw_cp {
            illegal_bins write_to_ro = binsof(rw_cp.write) && (binsof(addr_cp.status_reg) || binsof(addr_cp.collisions_cnt));
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        
        // Create analysis exports
        port_a_export = new("port_a_export", this);
        port_b_export = new("port_b_export", this);
        output_export = new("output_export", this);
        reg_export = new("reg_export", this);
        
        // Create covergroups
        port_a_cg = new();
        port_b_cg = new();
        output_cg = new();
        reg_cg = new();
    endfunction

    virtual function void write_port_a(port_a_item t);
        m_port_a_item = t;
        port_a_cg.sample();
    endfunction

    virtual function void write_port_b(port_b_item t);
        m_port_b_item = t;
        port_b_cg.sample();
    endfunction

    virtual function void write_output(output_item t);
        m_output_item = t;
        output_cg.sample();
    endfunction

    virtual function void write_reg(reg_item t);
        m_reg_item = t;
        reg_cg.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        real port_a_cov, port_b_cov, output_cov, reg_cov, total_cov;


        super.report_phase(phase);

        port_a_cov = port_a_cg.get_coverage();
        port_b_cov = port_b_cg.get_coverage();
        output_cov = output_cg.get_coverage();
        reg_cov = reg_cg.get_coverage();

        total_cov = (port_a_cov + port_b_cov + output_cov + reg_cov) / 4.0;
            // Print coverage report
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "     FUNCTIONAL COVERAGE REPORT        ", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Port A Coverage    : %.2f%%", port_a_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Port B Coverage    : %.2f%%", port_b_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Output Coverage    : %.2f%%", output_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Register Coverage  : %.2f%%", reg_cov), UVM_LOW)
        `uvm_info(get_type_name(), "----------------------------------------", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("TOTAL Coverage     : %.2f%%", total_cov), UVM_LOW)
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