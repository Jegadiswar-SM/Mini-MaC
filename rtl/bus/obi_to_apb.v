module obi_to_apb (
    input  wire        clk,
    input  wire        rst_n,

    // OBI Port
    input  wire        obi_req,
    output wire        obi_gnt,    // Combinational fix
    input  wire [31:0] obi_addr,
    input  wire        obi_we,
    input  wire [31:0] obi_wdata,
    output reg         obi_rvalid,
    output wire [31:0] obi_rdata,

    // APB Port
    output reg  [31:0] paddr,
    output reg         psel,
    output reg         penable,
    output reg         pwrite,
    output reg  [31:0] pwdata,
    input  wire [31:0] prdata,
    input  wire        pready
);

    typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
    state_t state;

    // CPU always gets an immediate grant if we are idle
    assign obi_gnt = (state == IDLE) && obi_req;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            psel <= 0; penable <= 0; obi_rvalid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    obi_rvalid <= 0;
                    if (obi_req) begin
                        paddr  <= obi_addr;
                        pwrite <= obi_we;
                        pwdata <= obi_wdata;
                        psel   <= 1;
                        state  <= SETUP;
                    end
                end
                SETUP: begin
                    penable <= 1;
                    state   <= ACCESS;
                end
                ACCESS: begin
                    if (pready) begin
                        psel <= 0;
                        penable <= 0;
                        obi_rvalid <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
    assign obi_rdata = prdata;
endmodule
