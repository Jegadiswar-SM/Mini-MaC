module mac_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] paddr,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic        pready,
    output logic        done_o,
    output logic [2:0]  fsm_state_o,

    output logic        m_req_o,
    input  logic        m_gnt_i,
    output logic [31:0] m_addr_o,
    output logic        m_we_o,
    output logic [31:0] m_wdata_o,
    input  logic        m_rvalid_i,
    input  logic [31:0] m_rdata_i,

    output logic [31:0] result_hold_o_0,
    output logic [31:0] result_hold_o_1,
    output logic [31:0] result_hold_o_2,
    output logic [31:0] result_hold_o_3
);

    logic       start;
    logic [7:0] reg_m, reg_k, reg_n;
    logic [31:0] wgt_addr, act_addr, res_addr;

    mac_regs u_regs (
        .clk(clk), .rst_n(rst_n),
        .paddr(paddr), .psel(psel), .penable(penable),
        .pwrite(pwrite), .pwdata(pwdata),
        .prdata(prdata), .pready(pready),
        .start_o(start),
        .fsm_state_i(fsm_state_o),
        .done_i(done_o),
        .reg_m_o(reg_m), .reg_k_o(reg_k), .reg_n_o(reg_n),
        .wgt_addr_o(wgt_addr),
        .act_addr_o(act_addr),
        .res_addr_o(res_addr),
        .result_hold_i_0(result_hold_o_0),
        .result_hold_i_1(result_hold_o_1),
        .result_hold_i_2(result_hold_o_2),
        .result_hold_i_3(result_hold_o_3)
    );

    logic [7:0] wgt_buf [0:3][0:3];
    logic [7:0] weight_in [0:3][0:3];
    assign weight_in[0][0] = wgt_buf[0][3];
    assign weight_in[0][1] = wgt_buf[0][0];
    assign weight_in[0][2] = wgt_buf[0][1];
    assign weight_in[0][3] = wgt_buf[0][2];
    assign weight_in[1][0] = wgt_buf[1][3];
    assign weight_in[1][1] = wgt_buf[1][0];
    assign weight_in[1][2] = wgt_buf[1][1];
    assign weight_in[1][3] = wgt_buf[1][2];
    assign weight_in[2][0] = wgt_buf[2][3];
    assign weight_in[2][1] = wgt_buf[2][0];
    assign weight_in[2][2] = wgt_buf[2][1];
    assign weight_in[2][3] = wgt_buf[2][2];
    assign weight_in[3][0] = wgt_buf[3][3];
    assign weight_in[3][1] = wgt_buf[3][0];
    assign weight_in[3][2] = wgt_buf[3][1];
    assign weight_in[3][3] = wgt_buf[3][2];

    logic [7:0]  act_buf [0:3];
    logic [31:0] res_buf [0:3];

    logic        load_wgt;
    logic [7:0]  row_in [0:3];
    logic [31:0] col_in [0:3];
    logic [31:0] col_out [0:3];

    systolic_array u_array (
        .clk(clk), .rst_n(rst_n),
        .load_wgt(load_wgt),
        .row_in_0(row_in[0]), .row_in_1(row_in[1]), .row_in_2(row_in[2]), .row_in_3(row_in[3]),
        .w_in_0_0(weight_in[0][0]), .w_in_0_1(weight_in[0][1]), .w_in_0_2(weight_in[0][2]), .w_in_0_3(weight_in[0][3]),
        .w_in_1_0(weight_in[1][0]), .w_in_1_1(weight_in[1][1]), .w_in_1_2(weight_in[1][2]), .w_in_1_3(weight_in[1][3]),
        .w_in_2_0(weight_in[2][0]), .w_in_2_1(weight_in[2][1]), .w_in_2_2(weight_in[2][2]), .w_in_2_3(weight_in[2][3]),
        .w_in_3_0(weight_in[3][0]), .w_in_3_1(weight_in[3][1]), .w_in_3_2(weight_in[3][2]), .w_in_3_3(weight_in[3][3]),
        .col_in_0(col_in[0]), .col_in_1(col_in[1]), .col_in_2(col_in[2]), .col_in_3(col_in[3]),
        .col_out_0(col_out[0]), .col_out_1(col_out[1]), .col_out_2(col_out[2]), .col_out_3(col_out[3])
    );

    localparam [3:0]
        IDLE        = 4'd0,
        WGT_LOAD    = 4'd1,
        WGT_PRESENT = 4'd2,
        ACT_LOAD    = 4'd3,
        FEED        = 4'd4,
        DRAIN       = 4'd5,
        RES_STORE   = 4'd6,
        ROW_NEXT    = 4'd7,
        DONE_ST     = 4'd8;

    logic [3:0] state, next_state;
    logic [1:0] wgt_cnt;
    logic [1:0] res_cnt;
    logic [7:0] row_cnt;
    logic [3:0] feed_cnt;
    logic [3:0] drain_cnt;
    logic       wgt_done_r;
    logic       res_done_r;

    logic [31:0] result_hold [0:3];

    logic       m_req_c;
    logic [31:0] m_addr_c;
    logic       m_we_c;
    logic [31:0] m_wdata_c;

    assign m_req_o   = m_req_c;
    assign m_addr_o  = m_addr_c;
    assign m_we_o    = m_we_c;
    assign m_wdata_o = m_wdata_c;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wgt_cnt    <= 2'd0;
            res_cnt    <= 2'd0;
            row_cnt    <= 8'd0;
            feed_cnt   <= 4'd0;
            drain_cnt  <= 4'd0;
            wgt_done_r <= 1'b0;
            res_done_r <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    wgt_cnt    <= 2'd0;
                    res_cnt    <= 2'd0;
                    row_cnt    <= 8'd0;
                    feed_cnt   <= 4'd0;
                    drain_cnt  <= 4'd0;
                    wgt_done_r <= 1'b0;
                    res_done_r <= 1'b0;
                end

                WGT_LOAD: begin
                    if (m_rvalid_i) begin
                        wgt_buf[wgt_cnt][0] <= m_rdata_i[7:0];
                        wgt_buf[wgt_cnt][1] <= m_rdata_i[15:8];
                        wgt_buf[wgt_cnt][2] <= m_rdata_i[23:16];
                        wgt_buf[wgt_cnt][3] <= m_rdata_i[31:24];
                        wgt_cnt    <= wgt_cnt + 2'd1;
                        if (wgt_cnt == 2'd3)
                            wgt_done_r <= 1'b1;
                    end
                end

                ACT_LOAD: begin
                    if (m_rvalid_i) begin
                        act_buf[0] <= m_rdata_i[7:0];
                        act_buf[1] <= m_rdata_i[15:8];
                        act_buf[2] <= m_rdata_i[23:16];
                        act_buf[3] <= m_rdata_i[31:24];
                    end
                end

                FEED: begin
                    feed_cnt <= feed_cnt + 4'd1;
                end

                DRAIN: begin
                    drain_cnt <= drain_cnt + 4'd1;
                    if (drain_cnt == 4'd1) result_hold[0] <= col_out[0];
                    if (drain_cnt == 4'd3) result_hold[1] <= col_out[1];
                    if (drain_cnt == 4'd5) result_hold[2] <= col_out[2];
                    if (drain_cnt == 4'd7) result_hold[3] <= col_out[3];
                end

                RES_STORE: begin
                    res_cnt <= res_cnt + 2'd1;
                    if (res_cnt == 2'd3)
                        res_done_r <= 1'b1;
                end

                ROW_NEXT: begin
                    row_cnt    <= row_cnt + 8'd1;
                    res_cnt    <= 2'd0;
                    feed_cnt   <= 4'd0;
                    drain_cnt  <= 4'd0;
                    wgt_done_r <= 1'b0;
                    res_done_r <= 1'b0;
                end

                default: ;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        m_req_c    = 1'b0;
        m_addr_c   = 32'h0;
        m_we_c     = 1'b0;
        m_wdata_c  = 32'h0;
        load_wgt   = 1'b0;
        row_in[0]  = 8'h0; row_in[1]  = 8'h0; row_in[2]  = 8'h0; row_in[3]  = 8'h0;
        col_in[0]  = 32'h0; col_in[1] = 32'h0; col_in[2] = 32'h0; col_in[3] = 32'h0;

        case (state)
            IDLE: begin
                if (start)
                    next_state = WGT_LOAD;
            end

            WGT_LOAD: begin
                m_req_c  = 1'b1;
                m_addr_c = wgt_addr + {28'd0, wgt_cnt, 2'b00};
                m_we_c   = 1'b0;
                if (wgt_done_r)
                    next_state = WGT_PRESENT;
            end

            WGT_PRESENT: begin
                load_wgt  = 1'b1;
                next_state = ACT_LOAD;
            end

            ACT_LOAD: begin
                m_req_c  = 1'b1;
                m_addr_c = act_addr + {28'd0, row_cnt[1:0], 2'b00};
                m_we_c   = 1'b0;
                if (m_rvalid_i)
                    next_state = FEED;
            end

            FEED: begin
                row_in[0] = act_buf[0];
                row_in[1] = act_buf[1];
                row_in[2] = act_buf[2];
                row_in[3] = act_buf[3];
                if (feed_cnt == 4'd11)
                    next_state = DRAIN;
            end

            DRAIN: begin
                row_in[0] = act_buf[0];
                row_in[1] = act_buf[1];
                row_in[2] = act_buf[2];
                row_in[3] = act_buf[3];
                if (drain_cnt == 4'd10)
                    next_state = RES_STORE;
            end

            RES_STORE: begin
                m_req_c   = 1'b1;
                m_addr_c  = res_addr + {20'd0, row_cnt, 4'b0000} + {28'd0, res_cnt, 2'b00};
                m_we_c    = 1'b1;
                m_wdata_c = result_hold[res_cnt];
                if (res_done_r)
                    next_state = ROW_NEXT;
            end

            ROW_NEXT: begin
                if (row_cnt == reg_m - 8'd1)
                    next_state = DONE_ST;
                else
                    next_state = ACT_LOAD;
            end

            DONE_ST: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    assign done_o      = (state == DONE_ST);
    assign fsm_state_o = state[2:0];

    assign result_hold_o_0 = result_hold[0];
    assign result_hold_o_1 = result_hold[1];
    assign result_hold_o_2 = result_hold[2];
    assign result_hold_o_3 = result_hold[3];

endmodule
