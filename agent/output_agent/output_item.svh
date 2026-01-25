`ifndef OUTPUT_ITEM_SVH
`define OUTPUT_ITEM_SVH

class output_item extends uvm_sequence_item;

    // Output port index (0-3)
    bit [1:0] port_idx;
    
    // Output data
    bit [7:0] data;
    
    // Valid signal
    bit valid;

    `uvm_object_utils_begin(output_item)
        `uvm_field_int(port_idx, UVM_ALL_ON)
        `uvm_field_int(data,     UVM_ALL_ON)
        `uvm_field_int(valid,    UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "output_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("port[%0d] data=0x%02h valid=%0b", port_idx, data, valid);
    endfunction

endclass

`endif
