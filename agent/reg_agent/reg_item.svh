`ifndef REG_ITEM_SVH
`define REG_ITEM_SVH

class reg_item extends uvm_sequence_item;

    // inputs are rand

    rand bit [3:0] reg_addr;
    rand bit [31:0] reg_wdata;
    rand bit reg_en;
    rand bit reg_we;

    // Responses
    bit [31:0] reg_rdata;


    `uvm_object_utils_begin(reg_item)
        `uvm_field_int(reg_addr,    UVM_ALL_ON)
        `uvm_field_int(reg_wdata,   UVM_ALL_ON)
        `uvm_field_int(reg_en,      UVM_ALL_ON)
        `uvm_field_int(reg_we,      UVM_ALL_ON)
        `uvm_field_int(reg_rdata,   UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "reg_item");
        super.new(name);
    endfunction

    // Valid register addresses: 0x0 (ctrl), 0x4 (status), 0x8 (collision cnt)
    constraint valid_addr {
        reg_addr inside {4'h0, 4'h4, 4'h8};
    }

    // Enable should be on for valid transactions
    constraint enable_on {
        reg_en == 1;
    }

    // Don't write to read-only collision counter (0x8)
    constraint no_write_to_ro {
        (reg_addr == 4'h8) -> (reg_we == 0);
    }

    function bit is_enabled();
        return reg_en == 1;
    endfunction

    function bit is_write_enabled();
        return reg_we == 1;
    endfunction

    function bit is_read();
        return (reg_en == 1) && (reg_we == 0);
    endfunction

    function bit is_write();
        return (reg_en == 1) && (reg_we == 1);
    endfunction

    function string convert2string();
        return $sformatf("%s addr=0x%01h wdata=0x%08h rdata=0x%08h", 
                         is_write() ? "WR" : "RD", reg_addr, reg_wdata, reg_rdata);
    endfunction

endclass
`endif 