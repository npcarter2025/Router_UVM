`ifndef ROUTER_VIRTUAL_SEQUENCER_SVH
`define ROUTER_VIRTUAL_SEQUENCER_SVH

class router_virtual_sequencer extends uvm_sequencer;
    `uvm_component_utils(router_virtual_sequencer)

    port_a_sequencer p_port_a_seqr;
    port_b_sequencer p_port_b_seqr;
    reg_sequencer p_reg_seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


endclass




`endif