module boot_rom (
    input  wire        clk,
    input  wire [9:0]  addr, // 1024 words = 4KB
    output reg  [31:0] rdata
);
    reg [31:0] rom [0:1023];

    // During simulation, we load the firmware here
    initial begin
        $readmemh("firmware.hex", rom);
    end

    always @(posedge clk) begin
        rdata <= rom[addr];
    end
endmodule
