`ifndef PORT_A_BASE_SEQUENCE_SVH
`define PORT_A_BASE_SEQUENCE_SVH

class port_a_base_sequence extends uvm_sequence #(port_a_item);

    `uvm_object_utils(port_a_base_sequence)

    function new(string name = "port_a_base_sequence");
        super.new(name);
    endfunction


endclass

`endif