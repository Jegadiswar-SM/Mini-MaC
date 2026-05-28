module mem_subsystem (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        instr_req,
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_rdata,
    output logic        instr_rvalid,
    output logic        instr_gnt,

    input  logic        cpu_req,
    input  logic [31:0] cpu_addr,
    input  logic        cpu_we,
    input  logic [3:0]  cpu_be,
    input  logic [31:0] cpu_wdata,
    output logic [31:0] cpu_rdata,
    output logic        cpu_rvalid,

    input  logic        mac_req,
    input  logic [31:0] mac_addr,
    input  logic        mac_we,
    input  logic [31:0] mac_wdata,
    output logic [31:0] mac_rdata,
    output logic        mac_gnt,
    output logic        mac_rvalid,

    input  logic        dma_req,
    input  logic [31:0] dma_addr,
    input  logic        dma_we,
    input  logic [31:0] dma_wdata,
    output logic [31:0] dma_rdata,
    output logic        dma_gnt,
    output logic        dma_rvalid
);

    logic        arb_req;
    logic [31:0] arb_addr;
    logic        arb_we;
    logic [3:0]  arb_be;
    logic [31:0] arb_wdata;
    logic [31:0] arb_rdata;

    logic sel_rom;
    logic sel_ram;

    assign instr_gnt = instr_req;
    assign instr_rvalid = instr_req;

    assign mac_gnt = mac_req && !cpu_req;
    assign dma_gnt = dma_req && !cpu_req && !mac_req;

    always_comb begin
        if (cpu_req) begin
            arb_req   = 1'b1;
            arb_addr  = cpu_addr;
            arb_we    = cpu_we;
            arb_be    = cpu_be;
            arb_wdata = cpu_wdata;
        end else if (mac_req) begin
            arb_req   = 1'b1;
            arb_addr  = mac_addr;
            arb_we    = mac_we;
            arb_be    = 4'hF;
            arb_wdata = mac_wdata;
        end else if (dma_req) begin
            arb_req   = 1'b1;
            arb_addr  = dma_addr;
            arb_we    = dma_we;
            arb_be    = 4'hF;
            arb_wdata = dma_wdata;
        end else begin
            arb_req   = 1'b0;
            arb_addr  = 32'h0;
            arb_we    = 1'b0;
            arb_be    = 4'h0;
            arb_wdata = 32'h0;
        end
    end

    assign sel_rom = (instr_req || (arb_addr[31:12] == 20'h0));
    assign sel_ram = (arb_addr[31:20] == 12'h100);

    boot_rom u_rom (
        .clk(clk),
        .addr(instr_req ? instr_addr[11:2] : arb_addr[11:2]),
        .rdata(instr_rdata)
    );

    logic [31:0] ram_dout;
    sram_wrapper #(.DEPTH(2048)) u_ram (
        .clk(clk),
        .sram_cen(!(sel_ram && arb_req)),
        .sram_wen(!arb_we),
        .sram_addr(arb_addr[12:2]),
        .sram_wmask(arb_be),
        .sram_din(arb_wdata),
        .sram_dout(ram_dout)
    );

    assign arb_rdata = sel_rom ? instr_rdata : ram_dout;

    assign cpu_rdata = arb_rdata;
    assign mac_rdata = ram_dout;
    assign dma_rdata = ram_dout;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_rvalid <= 0;
            mac_rvalid <= 0;
            dma_rvalid <= 0;
        end else begin
            cpu_rvalid <= cpu_req;
            mac_rvalid <= mac_gnt;
            dma_rvalid <= dma_gnt;
        end
    end

endmodule
