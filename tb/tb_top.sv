`ifndef TB_TOP_SV
`define TB_TOP_SV

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "tests/router_pkg.svh"
import router_pkg::*;

module tb_top;
    logic clk, rst_n;

    initial begin 
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
    end


    dual_port_router_if vif (clk, rst_n);

    dual_port_router dut (
        .clk        (clk),
        .rst_n      (rst_n),

        //ctrl regs
        .reg_addr   (vif.reg_addr),
        .reg_wdata  (vif.reg_wdata),
        .reg_en     (vif.reg_en),
        .reg_we     (vif.reg_we),
        .reg_rdata  (vif.reg_rdata),

        //Port A signals
        .data_a     (vif.data_a),
        .addr_a     (vif.addr_a),
        .valid_a    (vif.valid_a),
        .ready_a    (vif.ready_a),
        
        //Port B Signals
        .data_b     (vif.data_b),
        .addr_b     (vif.addr_b),
        .valid_b    (vif.valid_b),
        .ready_b    (vif.ready_b),

        //output signals
        .data_out   (vif.data_out),
        .valid_out  (vif.valid_out)

    );


    initial begin
        uvm_config_db#(virtual dual_port_router_if)::set(null, "*", "vif", vif);

        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);

        run_test();
    end
endmodule

`endif 
