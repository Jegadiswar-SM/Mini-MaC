module mem_subsystem (
    input  wire        clk,
    input  wire        rst_n,

    // Instruction Port
    input  wire        instr_req,
    input  wire [31:0] instr_addr,
    output wire [31:0] instr_rdata,
    output wire        instr_rvalid,
    output wire        instr_gnt,

    // CPU Data Port
    input  wire        cpu_req,
    input  wire [31:0] cpu_addr,
    input  wire        cpu_we,
    input  wire [3:0]  cpu_be,
    input  wire [31:0] cpu_wdata,
    output wire [31:0] cpu_rdata,
    output reg         cpu_rvalid,

    // MAC Master Port
    input  wire        mac_req,
    input  wire [31:0] mac_addr,
    input  wire        mac_we,
    input  wire [31:0] mac_wdata,
    output wire [31:0] mac_rdata,
    output wire        mac_gnt,
    output reg         mac_rvalid,

    // DMA Master Port
    input  wire        dma_req,
    input  wire [31:0] dma_addr,
    input  wire        dma_we,
    input  wire [31:0] dma_wdata,
    output wire [31:0] dma_rdata,
    output wire        dma_gnt,
    output reg         dma_rvalid
);
    // Arbitration: CPU > MAC > DMA
    assign instr_gnt = instr_req;
    assign mac_gnt   = mac_req && !cpu_req;
    assign dma_gnt   = dma_req && !cpu_req && !mac_req;

    // Address and Data Muxing
    wire [31:0] addr  = cpu_req ? cpu_addr  : (mac_gnt ? mac_addr  : dma_addr);
    wire [31:0] wdata = cpu_req ? cpu_wdata : (mac_gnt ? mac_wdata : dma_wdata);
    wire        we    = cpu_req ? cpu_we    : (mac_gnt ? mac_we    : dma_we);
    
    wire sel_rom = (instr_req || (addr[31:12] == 20'h0));
    wire sel_ram = (addr[31:20] == 12'h100);

    boot_rom u_rom ( .clk(clk), .addr(instr_req ? instr_addr[11:2] : addr[11:2]), .rdata(instr_rdata) );
    
    wire [31:0] ram_dout;
    sram_wrapper #(.DEPTH(2048)) u_ram (
        .clk(clk), .sram_cen(!(sel_ram && (cpu_req || mac_gnt || dma_gnt))),
        .sram_wen(!we), .sram_addr(addr[12:2]), .sram_wmask(4'hF),
        .sram_din(wdata), .sram_dout(ram_dout)
    );

    assign cpu_rdata = sel_rom ? instr_rdata : ram_dout;
    assign mac_rdata = ram_dout;
    assign dma_rdata = ram_dout;
    assign instr_rvalid = instr_req;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin cpu_rvalid <= 0; mac_rvalid <= 0; dma_rvalid <= 0; end
        else begin
            cpu_rvalid <= cpu_req;
            mac_rvalid <= mac_gnt;
            dma_rvalid <= dma_gnt;
        end
    end
endmodule
