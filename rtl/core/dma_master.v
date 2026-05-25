module dma_master (
    input  wire        clk,
    input  wire        rst_n,

    // From Regs
    input  wire [31:0] src_addr_i,
    input  wire [31:0] dst_addr_i,
    input  wire [15:0] length_i,
    input  wire        start_i,
    output reg         busy_o,
    output reg         done_o,
    output reg         err_o,

    // Master Bus Interface (OBI-like)
    output reg         req_o,
    input  wire        gnt_i,
    output reg  [31:0] addr_o,
    output reg         we_o,
    output reg  [31:0] wdata_o,
    input  wire        rvalid_i,
    input  wire [31:0] rdata_i
);

    typedef enum logic [2:0] {IDLE, FETCH, WAIT_R, STORE, DONE} state_t;
    state_t state;

    reg [31:0] curr_src, curr_dst, data_buffer;
    reg [15:0] bytes_left;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy_o <= 0; done_o <= 0; err_o <= 0;
            req_o <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done_o <= 0;
                    if (start_i) begin
                        // Alignment Check (§6.1)
                        if (src_addr_i[1:0] != 0 || dst_addr_i[1:0] != 0) begin
                            err_o <= 1;
                        end else begin
                            curr_src   <= src_addr_i;
                            curr_dst   <= dst_addr_i;
                            bytes_left <= length_i;
                            busy_o     <= 1;
                            state      <= FETCH;
                        end
                    end
                end

                FETCH: begin
                    req_o  <= 1;
                    we_o   <= 0;
                    addr_o <= curr_src;
                    if (gnt_i) begin
                        state <= WAIT_R;
                        req_o <= 0;
                    end
                end

                WAIT_R: begin
                    if (rvalid_i) begin
                        data_buffer <= rdata_i;
                        state       <= STORE;
                    end
                end

                STORE: begin
                    req_o   <= 1;
                    we_o    <= 1;
                    addr_o  <= curr_dst;
                    wdata_o <= data_buffer;
                    if (gnt_i) begin
                        req_o <= 0;
                        curr_src <= curr_src + 4;
                        curr_dst <= curr_dst + 4;
                        if (bytes_left <= 4) begin
                            state <= DONE;
                        end else begin
                            bytes_left <= bytes_left - 4;
                            state <= FETCH;
                        end
                    end
                end

                DONE: begin
                    busy_o <= 0;
                    done_o <= 1;
                    state  <= IDLE;
                end
            endcase
        end
    end
endmodule
