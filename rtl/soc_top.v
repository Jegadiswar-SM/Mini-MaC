/* verilator lint_off PINMISSING */
/* verilator lint_off UNUSED */
/* verilator lint_off UNOPTFLAT */

module soc_top (
    input  wire        clk,
    input  wire        rst_n
);

    // --- 1. TELEMETRY (For C++ Dashboard) ---
    logic [31:0] instr_addr      /* verilator public_flat_rd */;
    logic        dma_busy        /* verilator public_flat_rd */;
    logic        mac_done        /* verilator public_flat_rd */;
    logic [2:0]  mac_fsm_state   /* verilator public_flat_rd */;

    // --- 2. Internal CPU Wires (Handshake) ---
    wire instr_req, instr_gnt, instr_rvalid;
    wire [31:0] instr_rdata;
    wire cpu_req, cpu_gnt, cpu_rvalid, cpu_we;
    wire [3:0]  cpu_be;
    wire [31:0] cpu_addr, cpu_wdata, cpu_rdata;

    // Master Ports
    wire mac_m_req, mac_m_gnt, mac_m_rvalid, mac_m_we;
    wire [31:0] mac_m_addr, mac_m_wdata, mac_m_rdata;
    wire dma_m_req, dma_m_gnt, dma_m_rvalid, dma_m_we;
    wire [31:0] dma_m_addr, dma_m_wdata, dma_m_rdata;

    // Bus Matrix
    wire [31:0] apb_paddr, apb_pwdata, apb_bus_data, cpu_rdata_apb;
    wire        apb_psel, apb_penable, apb_pwrite, apb_pready, cpu_gnt_apb, cpu_rvalid_apb;
    wire [5:0]  s_psel;
    wire [31:0] s0_prdata, s1_prdata;
    wire [31:0] d_src, d_dst; wire [15:0] d_len; wire d_start;

    // Decoding logic
    wire sel_periph = (cpu_addr[31:16] == 16'h4000);
    wire sel_mem    = !sel_periph;

    // --- 3. Ibex CPU Core (Fixed Port Suffixes) ---
    ibex_top #(.RV32M(ibex_pkg::RV32MFast), .RV32B(ibex_pkg::RV32BNone), .SecureIbex(1'b0)) u_core (
        .clk_i(clk), .rst_ni(rst_n), .test_en_i(1'b0), .hart_id_i(32'h0), .boot_addr_i(32'h0),
        // Instruction Interface (Using correct suffixes)
        .instr_req_o(instr_req), .instr_gnt_i(instr_gnt), .instr_addr_o(instr_addr),
        .instr_rdata_i(instr_rdata), .instr_rvalid_i(instr_rvalid),
        .instr_err_i(1'b0), .instr_rdata_intg_i(7'h0),
        // Data Interface (Using correct suffixes)
        .data_req_o(cpu_req), .data_gnt_i(cpu_gnt), .data_we_o(cpu_we), .data_be_o(cpu_be),
        .data_addr_o(cpu_addr), .data_wdata_o(cpu_wdata), .data_rdata_i(cpu_rdata), .data_rvalid_i(cpu_rvalid),
        .data_err_i(1'b0), .data_rdata_intg_i(7'h0), .data_wdata_intg_o(),
        // Security / Tie-offs
        .fetch_enable_i(4'hA), .debug_req_i(1'b0), .scan_rst_ni(1'b1), .irq_nm_i(1'b0),
        .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(1'b0), .irq_fast_i(15'h0),
        .scramble_key_valid_i(1'b0), .scramble_key_i(128'h0), .scramble_nonce_i(64'h0), .scramble_req_o(),
        .ram_cfg_icache_tag_i(10'h0), .ram_cfg_icache_data_i(10'h0), .ram_cfg_rsp_icache_tag_o(), .ram_cfg_rsp_icache_data_o(),
        .alert_minor_o(), .alert_major_internal_o(), .alert_major_bus_o(), .core_sleep_o(),
        .crash_dump_o(), .double_fault_seen_o(), .lockstep_cmp_en_o(), .data_req_shadow_o(),
        .data_we_shadow_o(), .data_be_shadow_o(), .data_addr_shadow_o(), .data_wdata_shadow_o(),
        .data_wdata_intg_shadow_o(), .instr_req_shadow_o(), .instr_addr_shadow_o()
    );

    // --- 4. 3-Master Memory Subsystem ---
    mem_subsystem u_mem (
        .clk(clk), .rst_n(rst_n),
        .instr_req(instr_req), .instr_addr(instr_addr), .instr_rdata(instr_rdata), .instr_rvalid(instr_rvalid), .instr_gnt(instr_gnt),
        .cpu_req(cpu_req && sel_mem), .cpu_addr(cpu_addr), .cpu_we(cpu_we), .cpu_be(cpu_be), .cpu_wdata(cpu_wdata), .cpu_rdata(cpu_rdata_mem), .cpu_rvalid(cpu_rvalid_mem),
        .mac_req(mac_m_req), .mac_addr(mac_m_addr), .mac_we(mac_m_we), .mac_wdata(mac_m_wdata), .mac_rdata(mac_m_rdata), .mac_gnt(mac_m_gnt), .mac_rvalid(mac_m_rvalid),
        .dma_req(dma_m_req), .dma_addr(dma_m_addr), .dma_we(dma_m_we), .dma_wdata(dma_m_wdata), .dma_rdata(dma_m_rdata), .dma_gnt(dma_m_gnt), .dma_rvalid(dma_m_rvalid)
    );

    // --- 5. Bus Matrix (APB) ---
    obi_to_apb u_bridge (
        .clk(clk), .rst_n(rst_n),
        .obi_req(cpu_req && sel_periph), .obi_gnt(cpu_gnt_apb), .obi_addr(cpu_addr), .obi_we(cpu_we), .obi_wdata(cpu_wdata),
        .obi_rvalid(cpu_rvalid_apb), .obi_rdata(cpu_rdata_apb), .paddr(apb_paddr), .psel(apb_psel), .penable(apb_penable), .pwrite(apb_pwrite), .pwdata(apb_pwdata), .pready(apb_pready), .prdata(apb_bus_data)
    );

    apb_bus u_bus (
        .m_paddr(apb_paddr), .m_psel(apb_psel), .m_penable(apb_penable), .m_pwrite(apb_pwrite), .m_pwdata(apb_pwdata), .m_prdata(apb_bus_data), .m_pready(apb_pready), .s_psel(s_psel),
        .s0_prdata(s0_prdata), .s0_pready(1'b1), .s1_prdata(s1_prdata), .s1_pready(1'b1), .s2_prdata(32'h0), .s2_pready(1'b1), .s3_prdata(32'h0), .s3_pready(1'b1), .s4_prdata(32'h0), .s4_pready(1'b1), .s5_prdata(32'h0), .s5_pready(1'b1)
    );

    // --- 6. Peripherals ---
    dma_regs u_dma_regs ( .clk(clk), .rst_n(rst_n), .psel(s_psel[0]), .penable(apb_penable), .paddr(apb_paddr), .pwrite(apb_pwrite), .pwdata(apb_pwdata), .prdata(s0_prdata), .busy_i(dma_busy), .start_o(dma_start), .src_addr_o(d_src), .dst_addr_o(d_dst), .length_o(d_len), .done_i(1'b0) );
    dma_master u_dma_core ( .clk(clk), .rst_n(rst_n), .start_i(d_start), .busy_o(dma_busy), .src_addr_i(d_src), .dst_addr_i(d_dst), .length_i(d_len), .req_o(dma_m_req), .gnt_i(dma_m_gnt), .addr_o(dma_m_addr), .we_o(dma_m_we), .wdata_o(dma_m_wdata), .rvalid_i(dma_m_rvalid), .rdata_i(dma_m_rdata) );

    mac_top u_mac (
        .clk(clk), .rst_n(rst_n), .psel(s_psel[1]), .penable(apb_penable), .paddr(apb_paddr), .pwrite(apb_pwrite), .pwdata(apb_pwdata), .prdata(s1_prdata), .pready(),
        .done_o(mac_done), .fsm_state_o(mac_fsm_state),
        .m_req_o(mac_m_req), .m_gnt_i(mac_m_gnt), .m_addr_o(mac_m_addr), .m_we_o(mac_m_we), .m_wdata_o(mac_m_wdata), .m_rvalid_i(mac_m_rvalid), .m_rdata_i(mac_m_rdata)
    );

    assign cpu_gnt    = sel_periph ? cpu_gnt_apb    : 1'b1;
    assign cpu_rvalid = sel_periph ? cpu_rvalid_apb : cpu_rvalid_mem;
    assign cpu_rdata  = sel_periph ? cpu_rdata_apb  : cpu_rdata_mem;

endmodule
