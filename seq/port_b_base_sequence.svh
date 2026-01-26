`ifndef PORT_B_BASE_SEQUENCE_SVH
`define PORT_B_BASE_SEQUENCE_SVH

class port_b_base_sequence extends uvm_sequence #(port_b_item);

    `uvm_object_utils(port_b_base_sequence)

    // Configuration
    int num_items = 1;  // Number of items to send

    function new(string name = "port_b_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        port_b_item item;

        repeat (num_items) begin
            `uvm_do(item)
            `uvm_info(get_type_name(), $sformatf("Sent: %s", item.convert2string()), UVM_MEDIUM)
        end
    endtask

endclass

`endif