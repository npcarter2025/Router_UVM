
interface dual_port_router_if#(
    parameter REG_W = 32
)(
    input logic clk,
    input logic rst_n
);

    // Control Plane (Register Interface - Simple APB-like)
    logic [3:0]  reg_addr;
    logic [REG_W-1:0] reg_wdata;
    logic        reg_en;
    logic        reg_we;
    logic [REG_W-1:0] reg_rdata;

    // Data Plane: Port A
    logic [7:0]  data_a;
    logic [1:0]  addr_a;
    logic        valid_a;
    logic        ready_a;

    // Data Plane: Port B
    logic [7:0]  data_b;
    logic [1:0]  addr_b;
    logic        valid_b;
    logic        ready_b;

    // Outputs
    logic [7:0]  data_out [4];
    logic        valid_out [4];

    clocking drv_cb_Ctrl @(posedge clk);
        default input #1ns output #1ns;
        output reg_addr, reg_wdata, reg_en, reg_we;
        input reg_rdata;
    endclocking

    clocking drv_cb_Port_A @(posedge clk);
        default input #1ns output #1ns;
        output data_a, addr_a, valid_a;
        input ready_a;
    endclocking

    clocking drv_cb_Port_B @(posedge clk);
        default input #1ns output #1ns;
        output data_b, addr_b, valid_b;
        input ready_b;
    endclocking

    // This should be passive, since its just the outputs
    clocking mon_cb @(posedge clk);
        default input #1ns output #1ns;
        input data_out, valid_out;
        input ready_a, ready_b;
    endclocking


    modport DRV_CTRL (clocking drv_cb_Ctrl, input clk, input rst_n);
    modport DRV_PORT_A (clocking drv_cb_Port_A, input clk, input rst_n);
    modport DRV_PORT_B (clocking drv_cb_Port_B, input clk, input rst_n);

    modport MON (clocking mon_cb, input clk, input rst_n);


endinterface

