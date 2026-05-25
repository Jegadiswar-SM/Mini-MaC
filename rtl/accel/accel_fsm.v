module accel_fsm (
    input  wire        clk,
    input  wire        rst_n,
    
    input  wire        start_i,
    output reg         done_o,
    output reg [2:0]   state_o,
    
    output reg         load_wgt_o,
    output reg         feed_act_o,
    
    input  wire        wgt_done_i,
    input  wire        act_done_i,
    input  wire        store_done_i
);

    localparam IDLE         = 3'b000;
    localparam LOAD_WGT     = 3'b001;
    localparam LOAD_ACT     = 3'b010; // Pass-through
    localparam FEED_ARRAY   = 3'b011; // Wait for counter
    localparam DRAIN        = 3'b100;
    localparam STORE_RESULT = 3'b101;
    localparam SIGNAL_DONE  = 3'b110;

    reg [2:0] state_q, state_d;
    reg [3:0] drain_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= IDLE;
            drain_cnt <= 0;
        end else begin
            state_q <= state_d;
            if (state_q == DRAIN) drain_cnt <= drain_cnt + 1;
            else drain_cnt <= 0;
        end
    end

    always @(*) begin
        state_d = state_q;
        case (state_q)
            IDLE:         if (start_i)    state_d = LOAD_WGT;
            LOAD_WGT:     if (wgt_done_i) state_d = LOAD_ACT;
            LOAD_ACT:     state_d = FEED_ARRAY; // Pass-through
            FEED_ARRAY:   if (act_done_i) state_d = DRAIN;
            DRAIN:        if (drain_cnt == 4'd8) state_d = STORE_RESULT; // Wait for pipeline (4+4 cycles)
            STORE_RESULT: if (store_done_i) state_d = SIGNAL_DONE;
            SIGNAL_DONE:  state_d = IDLE;
            default:      state_d = IDLE;
        endcase
    end

    always @(*) begin
        state_o    = state_q;
        load_wgt_o = (state_q == LOAD_WGT);
        feed_act_o = (state_q == FEED_ARRAY);
        done_o     = (state_q == SIGNAL_DONE);
    end
endmodule
