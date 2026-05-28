module mac_regs (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] paddr,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic        pready,
    output logic        start_o,
    input  logic [2:0]  fsm_state_i,
    input  logic        done_i,
    output logic [7:0]  reg_m_o, reg_k_o, reg_n_o,
    output logic [31:0] wgt_addr_o,
    output logic [31:0] act_addr_o,
    output logic [31:0] res_addr_o,
    input  wire  [31:0] result_hold_i_0,
    input  wire  [31:0] result_hold_i_1,
    input  wire  [31:0] result_hold_i_2,
    input  wire  [31:0] result_hold_i_3
);
    assign pready = 1'b1;
    logic       sticky_done;
    logic [3:0] pe_addr_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_o     <= 0;
            sticky_done <= 0;
            reg_m_o     <= 8'd4;
            reg_k_o     <= 8'd4;
            reg_n_o     <= 8'd4;
            wgt_addr_o  <= 32'h10000000;
            act_addr_o  <= 32'h10000010;
            res_addr_o  <= 32'h10000020;
            pe_addr_reg <= 4'd0;
        end else begin
            start_o <= 0;
            if (done_i) sticky_done <= 1;

            if (psel && penable && pwrite) begin
                case (paddr[7:0])
                    8'h00: start_o <= pwdata[0];
                    8'h08: {reg_m_o, reg_k_o, reg_n_o} <= pwdata[23:0];
                    8'h18: pe_addr_reg <= pwdata[3:0];
                    8'h20: wgt_addr_o <= pwdata;
                    8'h24: act_addr_o <= pwdata;
                    8'h28: res_addr_o <= pwdata;
                    default: ;
                endcase
                if (paddr[7:0] == 8'h04 && pwdata[3]) sticky_done <= 0;
            end
        end
    end

    always_comb begin
        case (paddr[7:0])
            8'h00:   prdata = 32'h0;
            8'h04:   prdata = {28'd0, sticky_done, fsm_state_i};
            8'h08:   prdata = {8'd0, reg_m_o, reg_k_o, reg_n_o};
            8'h18:   prdata = {28'd0, pe_addr_reg};
            8'h1C:   case (pe_addr_reg[1:0])
                         2'd0: prdata = result_hold_i_0;
                         2'd1: prdata = result_hold_i_1;
                         2'd2: prdata = result_hold_i_2;
                         2'd3: prdata = result_hold_i_3;
                     endcase
            8'h20:   prdata = wgt_addr_o;
            8'h24:   prdata = act_addr_o;
            8'h28:   prdata = res_addr_o;
            default: prdata = 32'h0;
        endcase
    end
endmodule
