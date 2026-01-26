`ifndef PORT_A_BASE_SEQUENCE_SVH
`define PORT_A_BASE_SEQUENCE_SVH

class port_a_base_sequence extends uvm_sequence #(port_a_item);

    `uvm_object_utils(port_a_base_sequence)

    // Configuration
    int num_items = 1;  // Number of items to send

    function new(string name = "port_a_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        port_a_item item;

        repeat (num_items) begin
            `uvm_do(item)
            `uvm_info(get_type_name(), $sformatf("Sent: %s", item.convert2string()), UVM_MEDIUM)
        end
    endtask

endclass

`endif