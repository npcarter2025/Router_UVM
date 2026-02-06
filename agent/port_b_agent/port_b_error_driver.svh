`ifndef PORT_B_ERROR_DRIVER_SVH
`define PORT_B_ERROR_DRIVER_SVH

class port_b_error_driver extends port_b_driver;
    `uvm_component_utils(port_b_error_driver)

    function new(string name = "port_b_error_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task drive_item(port_b_item item);
        port_b_item corrupted_item;

        if (m_cfg.error_injection_enable && ($urandom_range(0, 99) < m_cfg.error_rate)) begin
            
            // Clone item and corrupt it
            $cast(corrupted_item, item.clone());
            inject_error(corrupted_item);

            `uvm_warning("ERROR_INJECT", $sformatf("Injecting error into packet: orig_data=0x%0h, corrupt_data=0x%0h", item.data_b, corrupted_item.data_b))

            super.drive_item(corrupted_item);
        end else begin
            super.drive_item(item);
        end

    endtask

    virtual function void inject_error(port_b_item item);
        int error_type = $urandom_range(0, 3);

        case (error_type)
            0: begin // Corrupt Data
                item.data_b = item.data_b ^ 8'hFF;
                `uvm_info("ERROR_INJECT", "Error type: DATA_CORRUPTION", UVM_MEDIUM)
            end
            1: begin // Wrong Address
                item.addr_b = $urandom_range(0, 3);
                `uvm_info("ERROR_INJECT", "Error type: WRONG_ADDRESS", UVM_MEDIUM)
            end
            2: begin // Invalid Address
                item.addr_b = $urandom_range(4, 15);
                `uvm_info("ERROR_INJECT", "Error type: INVALID_ADDRESS", UVM_MEDIUM)
            end
            3: begin // Corrupt multiple bits
                item.data_b = $urandom();
                `uvm_info("ERROR_INJECT", "Error type: RANDOM_CORRUPTION", UVM_MEDIUM)
            end
        endcase
    endfunction

endclass

`endif 
