module pe (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load_wgt,  
    input  wire [7:0]  a_in,
    input  wire [7:0]  w_in,
    input  wire [31:0] acc_in,
    output reg  [7:0]  a_out,
    output reg  [31:0] acc_out
);
    reg [7:0]  a_reg;
    reg [7:0]  w_reg; // STATIONARY WEIGHT
    reg [15:0] mul_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg   <= 8'd0;
            w_reg   <= 8'd0;
            mul_reg <= 16'd0;
            a_out   <= 8'd0;
            acc_out <= 32'd0;
        end else begin
            // Update Weight only during LOAD_WGT phase
            if (load_wgt) begin
                w_reg <= w_in;
            end

            // Pipeline
            a_reg   <= a_in;
            mul_reg <= $signed(a_reg) * $signed(w_reg);
            a_out   <= a_reg;
            acc_out <= acc_in + $signed({{16{mul_reg[15]}}, mul_reg});
        end
    end
endmodule
