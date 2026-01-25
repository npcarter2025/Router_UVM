`ifndef PORT_A_ITEM_SVH
`define PORT_A_ITEM_SVH


class port_a_item extends uvm_sequence_item;

    rand bit [7:0] data_a;
    rand bit [1:0] addr_a;
    rand bit       valid_a;


    // Response signals
    bit ready_a;

    `uvm_object_utils_begin(port_a_item)
        `uvm_field_int(data_a,  UVM_ALL_ON)
        `uvm_field_int(addr_a,  UVM_ALL_ON)
        `uvm_field_int(valid_a, UVM_ALL_ON)
        `uvm_field_int(ready_a, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "port_a_item");
        super.new(name);
    endfunction

    // Constraints // I think this is redundant LOL 
    constraint addr_const {
        addr_a inside {[0:3]};
    }

    // Maybe I could add a distribution for the valid_a
    // constraint valid_dist {
    //     valid_a dist {1 := 90, 0 := 10};
    // }


    constraint valid_on {
        valid_a == 1;
    }

    function bit is_valid();
        return valid_a == 1;
    endfunction

    // function string convert2string();
    //     return $sformatf("data_a=0x%02h addr_a=0x%01h", data_a, addr_a);
    // endfunction

    function string convert2string();
        return $sformatf("data_a=0x%02h addr_a=%0d valid_a=%0b ready_a=%0b", 
                     data_a, addr_a, valid_a, ready_a);
    endfunction

endclass

`endif