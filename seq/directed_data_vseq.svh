`ifndef DIRECTED_DATA_VSEQ_SVH
`define DIRECTED_DATA_VSEQ_SVH

// Directed sequence to test all data patterns on all ports
class directed_data_vseq extends router_base_vseq;
    `uvm_object_utils(directed_data_vseq)

    function new(string name = "directed_data_vseq");
        super.new(name);
    endfunction

    virtual task body();
        port_a_item pa_item;
        port_b_item pb_item;
        reg_item reg_itm;
        
        // Test data patterns: 0x00, 0x20 (low), 0x80 (mid), 0xE0 (high), 0xFF
        bit [7:0] test_data[] = '{8'h00, 8'h20, 8'h80, 8'hE0, 8'hFF};
        
        // Enable router first
        `uvm_do_on_with(reg_itm, p_reg_seqr, {
            reg_addr == 4'h0;
            reg_wdata == 32'h01;
            reg_en == 1;
            reg_we == 1;
        })
        #5000;
        
        `uvm_info(get_type_name(), "Sending directed data patterns to all ports", UVM_LOW)
        
        // Send test patterns to all 4 ports from both Port A and Port B
        foreach(test_data[i]) begin
            for(int port = 0; port < 4; port++) begin
                // Port A
                `uvm_do_on_with(pa_item, p_port_a_seqr, {
                    data_a == test_data[i];
                    addr_a == port;
                })
                #1000;
                
                // Port B  
                `uvm_do_on_with(pb_item, p_port_b_seqr, {
                    data_b == test_data[i];
                    addr_b == port;
                })
                #1000;
            end
        end
        
        `uvm_info(get_type_name(), "Directed data pattern test complete", UVM_LOW)
    endtask

endclass

`endif
