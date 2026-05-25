module systolic_array (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load_wgt,     // ADDED THIS PIN
    input  wire [7:0]  row_in [0:3],
    input  wire [7:0]  weight_in [0:3][0:3],
    input  wire [31:0] col_in [0:3],
    output wire [31:0] col_out [0:3]
);
    wire [7:0]  h_wire [0:3][0:4];
    wire [31:0] v_wire [0:4][0:3];

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_rows
            assign h_wire[i][0] = row_in[i];
            for (j = 0; j < 4; j = j + 1) begin : gen_cols
                if (i == 0) assign v_wire[0][j] = col_in[j];
                pe inst_pe (
                    .clk(clk), .rst_n(rst_n), .load_wgt(load_wgt),
                    .a_in(h_wire[i][j]), .w_in(weight_in[i][j]),
                    .acc_in(v_wire[i][j]), .a_out(h_wire[i][j+1]),
                    .acc_out(v_wire[i+1][j])
                );
            end
        end
    endgenerate

    for (j = 0; j < 4; j = j + 1) begin : gen_outputs
        assign col_out[j] = v_wire[4][j];
    end
endmodule
