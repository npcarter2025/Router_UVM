`ifndef PORT_B_BASE_SEQUENCE_SVH
`define PORT_B_BASE_SEQUENCE_SVH

class port_b_base_sequence extends uvm_sequence #(port_b_item);

    `uvm_object_utils(port_b_base_sequence)

    function new(string name = "port_b_base_sequence");
        super.new(name);
    endfunction


endclass

`endif