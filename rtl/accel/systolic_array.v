module systolic_array (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        load_wgt,
    input  wire [7:0]  row_in_0,
    input  wire [7:0]  row_in_1,
    input  wire [7:0]  row_in_2,
    input  wire [7:0]  row_in_3,
    input  wire [7:0]  w_in_0_0, w_in_0_1, w_in_0_2, w_in_0_3,
    input  wire [7:0]  w_in_1_0, w_in_1_1, w_in_1_2, w_in_1_3,
    input  wire [7:0]  w_in_2_0, w_in_2_1, w_in_2_2, w_in_2_3,
    input  wire [7:0]  w_in_3_0, w_in_3_1, w_in_3_2, w_in_3_3,
    input  wire [31:0] col_in_0,
    input  wire [31:0] col_in_1,
    input  wire [31:0] col_in_2,
    input  wire [31:0] col_in_3,
    output wire [31:0] col_out_0,
    output wire [31:0] col_out_1,
    output wire [31:0] col_out_2,
    output wire [31:0] col_out_3
);
    wire [7:0]  row_in [0:3];
    wire [7:0]  weight_in [0:3][0:3];
    wire [31:0] col_in [0:3];
    wire [31:0] col_out [0:3];
    assign row_in[0] = row_in_0;
    assign row_in[1] = row_in_1;
    assign row_in[2] = row_in_2;
    assign row_in[3] = row_in_3;
    assign weight_in[0][0] = w_in_0_0; assign weight_in[0][1] = w_in_0_1; assign weight_in[0][2] = w_in_0_2; assign weight_in[0][3] = w_in_0_3;
    assign weight_in[1][0] = w_in_1_0; assign weight_in[1][1] = w_in_1_1; assign weight_in[1][2] = w_in_1_2; assign weight_in[1][3] = w_in_1_3;
    assign weight_in[2][0] = w_in_2_0; assign weight_in[2][1] = w_in_2_1; assign weight_in[2][2] = w_in_2_2; assign weight_in[2][3] = w_in_2_3;
    assign weight_in[3][0] = w_in_3_0; assign weight_in[3][1] = w_in_3_1; assign weight_in[3][2] = w_in_3_2; assign weight_in[3][3] = w_in_3_3;
    assign col_in[0] = col_in_0;
    assign col_in[1] = col_in_1;
    assign col_in[2] = col_in_2;
    assign col_in[3] = col_in_3;
    assign col_out_0 = col_out[0];
    assign col_out_1 = col_out[1];
    assign col_out_2 = col_out[2];
    assign col_out_3 = col_out[3];

    wire [7:0]  h_wire [0:3][0:4];
    wire [31:0] v_wire [0:4][0:3];

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_rows
            assign h_wire[i][0] = row_in[i];
            for (j = 0; j < 4; j = j + 1) begin : gen_cols
                if (i == 0) begin : gen_col_init
                    assign v_wire[0][j] = col_in[j];
                end
                pe #(.ROW(i), .COL(j)) inst_pe (
                    .clk(clk), .rst_n(rst_n), .load_wgt(load_wgt),
                    .a_in(h_wire[i][j]),
                    .w_in(weight_in[i][j]),
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
