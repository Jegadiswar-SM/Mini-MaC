module mac_regs (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] paddr,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,
    output reg         start_o,
    input  wire [2:0]  fsm_state_i,
    input  wire        done_i,
    output reg [7:0]   reg_m_o, reg_k_o, reg_n_o,
    output reg [31:0]  reg_scale_o,
    output reg [31:0]  reg_cfg_o,
    input  wire [31:0] pe_result_i,
    output reg [7:0]   pe_addr_o
);
    assign pready = 1'b1;
    reg sticky_done;
    reg [31:0] reg_irq;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_o     <= 0; 
            sticky_done <= 0;
            reg_m_o     <= 4; 
            reg_k_o     <= 4; 
            reg_n_o     <= 4;
            reg_scale_o <= 32'h0000_0001;
            reg_cfg_o   <= 32'h0;
            reg_irq     <= 32'h0;
            pe_addr_o   <= 8'h0;
        end else begin
            start_o <= 0;
            if (done_i) sticky_done <= 1;
            
            if (psel && penable && pwrite) begin
                case (paddr[7:0])
                    8'h00: start_o <= pwdata[0];
                    8'h08: {reg_m_o, reg_k_o, reg_n_o} <= pwdata[23:0];
                    8'h0C: reg_scale_o <= pwdata;
                    8'h10: reg_cfg_o   <= pwdata;
                    8'h14: reg_irq     <= pwdata; // Simple IRQ status/ack
                    8'h18: pe_addr_o   <= pwdata[7:0];
                    default: ;
                endcase
                if (paddr[7:0] == 8'h04 && pwdata[3]) sticky_done <= 0; // Clear done bit
            end
        end
    end

    always @(*) begin
        case (paddr[7:0])
            8'h00:   prdata = 32'h0; // CTRL is WO or self-clearing
            8'h04:   prdata = {28'd0, sticky_done, fsm_state_i};
            8'h08:   prdata = {8'd0, reg_m_o, reg_k_o, reg_n_o};
            8'h0C:   prdata = reg_scale_o;
            8'h10:   prdata = reg_cfg_o;
            8'h14:   prdata = reg_irq;
            8'h18:   prdata = {24'd0, pe_addr_o};
            8'h1C:   prdata = pe_result_i;
            default: prdata = 32'hdeadbeef;
        endcase
    end
endmodule
