module dual_port_router (
    input  logic        clk,
    input  logic        rst_n,

    // Control Plane (Register Interface - Simple APB-like)
    input  logic [3:0]  reg_addr,
    input  logic [31:0] reg_wdata,
    input  logic        reg_en,
    input  logic        reg_we,
    output logic [31:0] reg_rdata,

    // Data Plane: Port A
    input  logic [7:0]  data_a,
    input  logic [1:0]  addr_a,
    input  logic        valid_a,
    output logic        ready_a,

    // Data Plane: Port B
    input  logic [7:0]  data_b,
    input  logic [1:0]  addr_b,
    input  logic        valid_b,
    output logic        ready_b,

    // Outputs
    output logic [7:0]  data_out [4],
    output logic        valid_out [4]
);

    // Internal Registers
    // 0x0: Control Reg [0=Global Enable, 1=Priority (0:PortA, 1:PortB)]
    // 0x4: Status Reg  [0=Busy]
    // 0x8: Collision Counter (Read-Only)
    logic [31:0] ctrl_reg;
    logic [31:0] collision_cnt;

    // --- Register Logic (For RAL practice) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 32'h1; // Default: Enabled, Port A priority
        end else if (reg_en && reg_we) begin
            if (reg_addr == 4'h0) ctrl_reg <= reg_wdata;
        end
    end
    assign reg_rdata = (reg_addr == 4'h0) ? ctrl_reg : 
                       (reg_addr == 4'h8) ? collision_cnt : 32'h0;

    // --- Arbitration Logic (For Virtual Sequencer practice) ---
    logic use_a;
    always_comb begin
        ready_a = 1'b0;
        ready_b = 1'b0;
        use_a   = 1'b0;

        if (ctrl_reg[0]) begin // If Global Enable is set
            if (valid_a && valid_b) begin
                use_a = !ctrl_reg[1]; // Use priority bit to decide
                ready_a = use_a;
                ready_b = !use_a;
            end else if (valid_a) begin
                use_a = 1'b1;
                ready_a = 1'b1;
            end else if (valid_b) begin
                use_a = 1'b0;
                ready_b = 1'b1;
            end
        end
    end

    // --- Data Path ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i=0; i<4; i++) begin
                data_out[i] <= 8'h0;
                valid_out[i] <= 1'b0;
            end
            collision_cnt <= 32'h0;
        end else begin
            // Default: clear valid bits
            for (int i=0; i<4; i++) valid_out[i] <= 1'b0;
            
            // Increment collision counter if both try to send
            if (valid_a && valid_b) collision_cnt <= collision_cnt + 1;

            if (use_a) begin
                data_out[addr_a]  <= data_a;
                valid_out[addr_a] <= 1'b1;
            end else if (ready_b) begin
                data_out[addr_b]  <= data_b;
                valid_out[addr_b] <= 1'b1;
            end
        end
    end

endmodule

