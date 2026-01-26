`ifndef REG_BASE_SEQUENCE_SVH
`define REG_BASE_SEQUENCE_SVH

class reg_base_sequence extends uvm_sequence #(reg_item);
    `uvm_object_utils(reg_base_sequence)

    function new(string name = "reg_base_sequence");
        super.new(name);
    endfunction

endclass



`endif