module seq_comb #(parameter WIDTH=18,parameter RSTTYPE="SYNC" )(in,out,clk,en,rst,REG);

input [WIDTH-1:0] in;
input REG,en,rst,clk;
output wire[WIDTH-1:0]out;
reg [WIDTH-1:0] S_seq,A_seq;  //A stands for async
generate
    if(RSTTYPE=="SYNC") begin
        always @(posedge clk) begin
            if(rst) begin
                S_seq<='b0;
            end
            else begin
                if(en) begin
                    S_seq<=in;
                end
            end
        end
        assign out=(REG)? S_seq:in;
        end
    else if (RSTTYPE=="ASYNC") begin
        assign out=(REG)? A_seq:in;
        always @(posedge clk or posedge rst) begin
            if(rst) begin
                A_seq<='b0;
            end
            else begin
                if(en) begin
                    A_seq<=in;
                end
            end
        end
    end
endgenerate
endmodule