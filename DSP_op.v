module DSP#(
    parameter A0REG=0,parameter A1REG=1,parameter B0REG=0, parameter B1REG=1,
    parameter CREG=1,parameter DREG=1,parameter MREG=1,parameter PREG=1,parameter CARRYINREG=1,
    parameter CARRYOUTREG=1,parameter OPMODEREG=1,parameter CARRYINSEL= "OPMODE5",
    parameter B_INPUT="DIRECT",parameter RSTTYPE="SYNC")
    (
        A,B,C,D,CARRYIN,M,P,CARRYOUT,CARRYOUTF,CLK,OPMODE,CEA,CEB,CEC,CED,CECARRYIN,CEM,CEOPMODE,CEP,
        RSTA,RSTB,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,RSTP,RSTM,BCOUT,BCIN,PCIN,PCOUT
    );

// I/P ports
input [17:0]A,B,BCIN,D;
input [47:0]C,PCIN;
input [7:0]OPMODE;
input RSTA,RSTB,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,RSTP,RSTM,CEA,CEB,CEC,CED,CECARRYIN,CEM,CEOPMODE,CEP,CLK,CARRYIN;
output [17:0]BCOUT;
output[47:0] PCOUT,P;
output CARRYOUT,CARRYOUTF;
output [35:0]M;

//internal signals
wire [7:0]OPMODE_reg;
wire [17:0]D_sig,B_sig0,A_sig0,A_sig1,BD_sig;
wire[47:0]C_sig,P_sig;
wire[35:0]MP_sig;
wire CIN_sig,CO;
reg[47:0] X_mux,Z_mux;
reg[48:0]AR_OP;
reg[35:0]MP;
reg [17:0]BD;

//instantiate the sequential/combinational blocks
//#(parameter WIDTH=18,parameter RSTTYPE="SYNC",parameter REG=1)(in,out,clk,en,rst);
seq_comb #(18,"SYNC") A0_REG(A,A_sig0,CLK,CEA,RSTA,A0REG);
seq_comb #(18,"SYNC") A1_REG(A_sig0,A_sig1,CLK,CEA,RSTA,A1REG);
seq_comb #(48,"SYNC") C_REG(C,C_sig,CLK,CEC,RSTC,CREG);
seq_comb #(18,"SYNC") D_REG(D,D_sig,CLK,CED,RSTD,DREG);
seq_comb #(8,"SYNC") OP_MODE_REG(OPMODE,OPMODE_reg,CLK,CEOPMODE,RSTOPMODE,OPMODEREG);
seq_comb #(18,"SYNC") B1_REG(BD,BD_sig,CLK,CEB,RSTB,B1REG);
seq_comb #(48,"SYNC") P_REG(P_sig,P,CLK,CEP,RSTP,PREG);
seq_comb #(1,"SYNC") CYO(CO,CARRYOUT,CLK,CECARRYIN,RSTCARRYIN,CARRYINREG);
seq_comb #(36,"SYNC") MP_REG(MP,MP_sig,CLK,CEM,RSTM,MREG);

//instantiation blocks that depend on a parameters
generate
    if (B_INPUT == "DIRECT") begin
        seq_comb #(18, "SYNC") B0_REG(B, B_sig0, CLK, CEB, RSTB,B0REG);
    end
    else if (B_INPUT == "CASCADE") begin
        seq_comb #(18, "SYNC") B0_REG(BCIN, B_sig0, CLK, CEB, RSTB,B0REG);
    end
    else begin
        wire [17:0] zero_wire = 18'b0;
        seq_comb #(18, "SYNC") B0_REG(zero_wire, B_sig0, CLK, CEB, RSTB,B0REG);
    end
endgenerate
generate
    if (CARRYINSEL == "OPMODE5") begin
        seq_comb #(1, "SYNC") CARRY_IN(OPMODE_reg[5], CIN_sig, CLK, CECARRYIN, RSTCARRYIN,CARRYINREG);
    end
    else if (CARRYINSEL == "CARRYIN") begin
        seq_comb #(1, "SYNC") CARRY_IN(CARRYIN, CIN_sig, CLK,  CECARRYIN, RSTCARRYIN,CARRYINREG);
    end
    else begin
        wire zero_wire = 1'b0;
        seq_comb #(1, "SYNC") CARRY_IN(zero_wire,CIN_sig, CLK,  CECARRYIN, RSTCARRYIN,CARRYINREG);
    end
endgenerate

//assign statements
assign PCOUT = P;
assign BCOUT = BD_sig;
assign M = MP_sig;
assign P_sig=AR_OP[47:0];
assign CARRYOUTF=CARRYOUT;
assign CO = AR_OP[48];

always @(*) begin
    case(OPMODE_reg[4])
        1'b0: BD=B_sig0;
        1'b1:begin
            case(OPMODE_reg[6])
                1'b1: BD=D_sig-B_sig0;
                1'b0: BD=D_sig+B_sig0;
            endcase
        end 
    endcase
    MP = BD_sig*A_sig1;
    case (OPMODE_reg[1:0])
        2'b00: X_mux='b0;
        2'b01: X_mux={12'b0,MP_sig};
        2'b10: X_mux=P;
        2'b11: X_mux={D[11:0], A[17:0],B[17:0]};
    endcase
    case(OPMODE_reg[3:2])
        2'b00: Z_mux='b0;
        2'b01: Z_mux=PCIN;
        2'b10: Z_mux=P;
        2'b11: Z_mux={30'b0,C_sig};
    endcase
    case (OPMODE_reg[7])
        2'b0: begin
            AR_OP=Z_mux+X_mux+CIN_sig;
        end
        2'b1: begin
            AR_OP=Z_mux-(X_mux+CIN_sig);
        end
    endcase
end
endmodule