module sram_wrapper #(
    parameter ADDR_WIDTH = 11,
    parameter DEPTH = 2048
)(
    input  wire        clk,
    input  wire        sram_cen,   // Active Low
    input  wire        sram_wen,   // Active Low
    input  wire [ADDR_WIDTH-1:0] sram_addr,
    input  wire [3:0]  sram_wmask,
    input  wire [31:0] sram_din,
    output reg  [31:0] sram_dout
);
    // NOTE: For ASIC physical design, this behavioral model must be replaced
    // with a foundry SRAM macro (e.g., sky130 SRAM compiler). The interface
    // (sram_cen, sram_wen, sram_addr, sram_wmask, sram_din, sram_dout)
    // is designed to match the standard SRAM macro interface.
    reg [31:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (!sram_cen) begin
            if (!sram_wen) begin
                if (sram_wmask[0]) mem[sram_addr][7:0]   <= sram_din[7:0];
                if (sram_wmask[1]) mem[sram_addr][15:8]  <= sram_din[15:8];
                if (sram_wmask[2]) mem[sram_addr][23:16] <= sram_din[23:16];
                if (sram_wmask[3]) mem[sram_addr][31:24] <= sram_din[31:24];
            end
            sram_dout <= mem[sram_addr];
        end
    end
endmodule
