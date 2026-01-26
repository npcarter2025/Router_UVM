`ifndef REG_BASE_SEQUENCE_SVH
`define REG_BASE_SEQUENCE_SVH

class reg_base_sequence extends uvm_sequence #(reg_item);
    `uvm_object_utils(reg_base_sequence)

    // Configuration - can be set before starting
    bit [3:0]  target_addr  = 4'h0;
    bit [31:0] write_data   = 32'h0;
    bit        do_write     = 1;  // 1 = write, 0 = read

    function new(string name = "reg_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        reg_item item;

        `uvm_do_with(item, {
            reg_addr  == target_addr;
            reg_wdata == write_data;
            reg_en    == 1;
            reg_we    == do_write;
        })

        if (do_write) begin
            `uvm_info(get_type_name(), $sformatf("WRITE addr=0x%01h data=0x%08h", 
                      target_addr, write_data), UVM_MEDIUM)
        end else begin
            `uvm_info(get_type_name(), $sformatf("READ addr=0x%01h returned=0x%08h", 
                      target_addr, item.reg_rdata), UVM_MEDIUM)
        end
    endtask

endclass

`endif