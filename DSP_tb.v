module DSP_tb();

reg [17:0]A,B,BCIN,D;
reg [47:0]C,PCIN;
reg [7:0]OPMODE;
reg RSTA,RSTB,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,RSTP,RSTM,CEA,CEB,CEC,CED,CECARRYIN,CEM,CEOPMODE,CEP,CLK,CARRYIN;
wire [17:0]BCOUT;
wire[47:0] PCOUT,P;
wire CARRYOUT,CARRYOUTF;
wire [35:0]M;

DSP #(0,1,0,1,1,1,1,1,1,1,1,"OPMODE5","DIRECT","SYNC") DUT(
    A,B,C,D,CARRYIN,M,P,CARRYOUT,CARRYOUTF,CLK,OPMODE,CEA,CEB,CEC,CED,CECARRYIN,CEM,CEOPMODE,CEP,
    RSTA,RSTB,RSTC,RSTD,RSTCARRYIN,RSTOPMODE,RSTP,RSTM,BCOUT,BCIN,PCIN,PCOUT
);

initial begin
    CLK=0;
    forever begin
        #10 CLK=~CLK;
    end
end

initial begin
//RESET check 
    RSTA=1;
    RSTB=1;
    RSTC=1;
    RSTD=1;
    RSTCARRYIN=1;
    RSTOPMODE=1;
    RSTP=1;
    RSTM=1;
    repeat(10) begin
        A=$random;
        B=$random;
        BCIN=$random;
        D=$random;
        C=$random;
        PCIN=$random;
        OPMODE=$random;
        CEA=$random;
        CEB=$random;
        CEC=$random;
        CED=$random;
        CECARRYIN=$random;
        CEM=$random;
        CEOPMODE=$random;
        CEP=$random;
        CARRYIN=$random;

        @(negedge CLK);
        if(M!=0 && CARRYOUT!=0 && CARRYOUTF!=0 && P!=0 && PCOUT!=0 && BCOUT!=0) begin
            $display("Error in RESET");
            $stop;
        end    
    end
//Deactivate RESET
    RSTA=0;
    RSTB=0;
    RSTC=0;
    RSTD=0;
    RSTCARRYIN=0;
    RSTOPMODE=0;
    RSTP=0;
    RSTM=0;
//Activate enable signals 
    CEA=1;
    CEB=1;
    CEC=1;
    CED=1;
    CECARRYIN=1;
    CEM=1;
    CEOPMODE=1;
    CEP=1;

//verify path 1
    OPMODE=8'b11011101; //multiplier product,using the C port,use pre adder/sub ,carry with 0,using subtraction
    A = 20;
    B = 10;
    C = 350; //we expect 350-((25-10)*20)=50
    D = 25;
    repeat(10)begin
        BCIN=$random;
        PCIN=$random;
        CARRYIN=$random;
        repeat(4) @(negedge CLK);
        if(BCOUT!='hf && M!='h12c && P!='h32 && PCOUT!='h32 && CARRYOUT!=0 && CARRYOUTF!=0) begin
            $display("Error in PATH 1");
            $stop;
        end
    end

//verify path 2
    OPMODE=8'b00010000; //using the zeros for the post add/sub,use pre adder/sub ,carry with 0,using addition
    A = 20;
    B = 10;
    C = 350; 
    D = 25;
    repeat(10)begin
        BCIN=$random;
        PCIN=$random;
        CARRYIN=$random;
        repeat(3) @(negedge CLK);
        if(BCOUT!='h23 && M!='h2bc && P!='h0 && PCOUT!='h0 && CARRYOUT!=0 && CARRYOUTF!=0) begin
            $display("Error in PATH 2");
            $stop;
        end
    end

//verify path 3
    OPMODE=8'b00001010; //using p for X and Z MUX for the post add/sub,use B directly,carry with 0,using addition, no pre add/sub
    A = 20;
    B = 10;
    C = 350; 
    D = 25;
    repeat(10)begin
        BCIN=$random;
        PCIN=$random;
        CARRYIN=$random;
        repeat(3) @(negedge CLK);
        if(BCOUT!='ha && M!='hc8 && P!=PCOUT && CARRYOUT!=CARRYOUTF) begin//recheck////////////
            $display("Error in PATH 3");
            $stop;
        end
    end

//verify path 4
    OPMODE=8'b10100111; //concatenated DBA,PCIN,no pre add/sub, subtracting conc DAB and PCIN,
    A=5;
    B=6; 
    C=350; 
    D=25;
    PCIN=3000;
    repeat(10)begin
        BCIN=$random;
        CARRYIN=$random;
        repeat(3) @(negedge CLK);
        if(BCOUT!='h6 && M!='h1e && P!='hfe6fffec0bb1 &&PCOUT!='hfe6fffec0bb1 && CARRYOUT!=1 && CARRYOUTF!=1) begin
            $display("Error in PATH 4");
            $stop;
        end
    end
$stop;
end
endmodule