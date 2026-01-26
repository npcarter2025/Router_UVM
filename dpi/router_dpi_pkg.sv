`ifndef ROUTER_DPI_PKG_SV
`define ROUTER_DPI_PKG_SV

package router_dpi_pkg;

    // import DPI-C functions
    import "DPI-C" function void router_model_init();
    import "DPI-C" function void router_model_write_ctrl(int unsigned data);
    import "DPI-C" function void router_model_port_a(byte unsigned data, byte unsigned addr);
    import "DPI-C" function void router_model_port_b(byte unsigned data, byte unsigned addr);
    import "DPI-C" function int router_mode_get_output(byte unsigned port, output byte unsigned data);
    
endpackage

`endif