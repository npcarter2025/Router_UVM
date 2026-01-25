`ifndef PORT_B_ITEM_SVH
`define PORT_B_ITEM_SVH


class port_b_item extends uvm_sequence_item;

    rand bit [7:0] data_b;
    rand bit [1:0] addr_b;
    rand bit       valid_b;


    // Response signals
    bit ready_b;

    `uvm_object_utils_begin(port_b_item)
        `uvm_field_int(data_b,  UVM_ALL_ON)
        `uvm_field_int(addr_b,  UVM_ALL_ON)
        `uvm_field_int(valid_b, UVM_ALL_ON)
        `uvm_field_int(ready_b, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "port_b_item");
        super.new(name);
    endfunction

    // Constraints
    constraint addr_const {
        addr_b inside {[0:3]};
    }

    constraint valid_on {
        valid_b == 1;
    }

    function bit is_valid();
        return valid_b == 1;
    endfunction

    // function string convert2string();
    //     return $sformatf("data_a=0x%02h addr_a=0x%01h", data_a, addr_a);
    // endfunction

    function string convert2string();
        return $sformatf("data_b=0x%02h addr_b=%0d valid_b=%0b ready_b=%0b", 
                     data_b, addr_b, valid_b, ready_b);
    endfunction

endclass

`endif