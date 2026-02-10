`ifndef ROUTER_FUNCTIONAL_COVERAGE_SVH
`define ROUTER_FUNCTIONAL_COVERAGE_SVH

`uvm_analysis_imp_decl(_port_a_func)
`uvm_analysis_imp_decl(_port_b_func)

class router_functional_coverage extends router_coverage_base;
    `uvm_component_utils(router_functional_coverage)

    uvm_analysis_imp_port_a_func #(port_a_item, router_functional_coverage) port_a_imp;
    uvm_analysis_imp_port_b_func #(port_b_item, router_functional_coverage) port_b_imp;
    uvm_analysis_imp #(output_item, router_functional_coverage) output_imp;

    // Transaction items
    port_a_item port_a_txn;
    port_b_item port_b_txn;
    output_item output_txn;

    // Sampling variables
    bit global_enable_s;
    bit priority_s;
    bit [7:0] data_a_s;
    bit [7:0] data_b_s;
    bit [1:0] addr_a_s;
    bit [1:0] addr_b_s;
    bit port_a_valid_s;
    bit port_b_valid_s;
    bit collision_s;
    int active_outputs_s;


    //----------------------------------------------------------
    // COVERGROUP 1: Register Configuration
    //----------------------------------------------------------

    covergroup cg_register_config;
        option.per_instance = 1;
        option.name = "functional_register_config";

        cp_enable: coverpoint global_enable_s {
            bins enabled = {1};
            bins disabled = {0};
        }

        cp_priority: coverpoint priority_s {}