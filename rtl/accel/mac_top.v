module mac_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] paddr,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output wire [31:0] prdata,
    output wire        pready,
    output wire        done_o,
    output wire [2:0]  fsm_state_o,

    // Master Interface (Autonomous Data Fetch)
    output wire        m_req_o,
    input  wire        m_gnt_i,
    output wire [31:0] m_addr_o,
    output wire        m_we_o,
    output wire [31:0] m_wdata_o,
    input  wire        m_rvalid_i,
    input  wire [31:0] m_rdata_i
);
    assign pready = 1'b1;
    assign m_req_o = 1'b0; // Place actual autonomous fetch logic here
    assign m_addr_o = 0; assign m_we_o = 0; assign m_wdata_o = 0;

    mac_regs u_regs (
        .clk(clk), .rst_n(rst_n), .paddr(paddr), .psel(psel), .penable(penable), 
        .pwrite(pwrite), .pwdata(pwdata), .prdata(prdata), .pready(pready),
        .start_o(start), .fsm_state_i(fsm_state_o), .done_i(done_o),
        .reg_m_o(), .reg_k_o(), .reg_n_o()
    );

    accel_fsm u_fsm (
        .clk(clk), .rst_n(rst_n), .start_i(start), .done_o(done_o), .state_o(fsm_state_o),
        .load_wgt_o(), .feed_act_o(), .wgt_done_i(1'b1), .act_done_i(1'b1), .store_done_i(1'b1)
    );
endmodule
