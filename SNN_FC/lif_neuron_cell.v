`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 基于 Q4.12 定点表示的 Leaky Integrate-and-Fire (LIF) 神经元单元
// 功能：用于描述 snnTorch 中的 LIF 模型，支持输入电流积分、漏电衰减和阈值触发
//////////////////////////////////////////////////////////////////////////////////

module lif_neuron_cell #(
    // -------------------- 参数定义 --------------------
    parameter WIDTH = 24,                  // Q4.20 定点数总位宽
    parameter FRAC  = 17,                  // 小数位宽
    parameter signed [WIDTH-1:0] BETA     = 24'sd0,  // 漏电系数 beta0.875
    parameter signed [WIDTH-1:0] VTH      = 24'sh20000  // 阈值电压 Vth=1.0=24'sd131072
)(
    // -------------------- 接口定义 --------------------
    input  wire                      clk,       // 时钟
    input  wire                      rst,     // 复位（gao有效）
    input  wire signed [WIDTH-1:0]   input_cur, // 输入电流（Q4.20 格式）
    input  wire                      input_en,//输入信号有效|计算开始
    output wire                      spike_out,     // 输出脉冲
    output wire signed [WIDTH-1:0]   mem_out    // 膜电位（Q4.20 格式）
);

    // -------------------- 内部变量 --------------------
    reg signed [2*WIDTH-1:0] mem;   //计算膜电位

    // -------------------- 膜电位更新逻辑 --------------------
    always @(posedge clk or negedge rst) begin
        if (rst) begin
            // 复位：清零
            mem <= 0;
        end 
        else if(input_en)
            mem <= (mem - (mem >>> 3)) - ((mem>=VTH)?VTH:'sd0) + input_cur;
        else
            mem <= mem; 
    end

    assign mem_out = {mem[2*WIDTH-1] , mem[WIDTH-2 : 0]};
    assign spike_out = (mem_out>=VTH) ? 1'd1 : 1'd0;

endmodule
