module process_Element #(
	parameter DATA_WIDTH = 24,        // Q4.20 定点
	parameter FRAC  = 17
)(clk,reset,valid,floatA,floatB,result);

input clk, reset, valid;
input signed [DATA_WIDTH-1:0] floatA, floatB;
output wire signed [DATA_WIDTH-1:0] result;

wire signed [2*DATA_WIDTH-1:0] mult_full;
wire signed [DATA_WIDTH-1:0] addResult;
wire signed [DATA_WIDTH-1:0] mult_q;
reg  sclr;

assign mult_q = mult_full[FRAC + DATA_WIDTH - 1 : FRAC];

always @(posedge clk or posedge reset) begin
        if (reset) begin
            sclr <= 1'd0;end 
        else begin
            sclr <= ~valid;end
    end

// --------------------- 实例化 Multiplier IP ---------------------
    mult_gen_1 FM (
        .CLK(clk),
        .A(floatA),
        .B(floatB),
        .CE(valid),
        .SCLR(sclr),
        .P(mult_full)
    );
    f_adder FADD (
        .A(mult_q),
        .B(result),
        .CLK(clk),
        .CE(valid),
        .SCLR(sclr),
        .S(addResult)
    );
assign  result = addResult;

endmodule
