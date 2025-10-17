`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/05 17:38:55
// Design Name: 
// Module Name: top_784_20_10
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module top_784_20_10 #(
	parameter WIDTH = 24,        // Q7.17 定点
	parameter FRAC  = 17,
	parameter INPUT_NODES  = 784,
	parameter FC1_NODES  = 20,
	parameter OUTPUT_NODES = 10
)(
	input  wire clk,
    input  wire reset,
    input  wire fc1_addra_valid,//全连接层读权有效//fc_addra_valid需要在时钟上升沿开始，保持785个时钟周期
    input  wire signed [WIDTH-1:0] input_fc_array,         // 每个输入单独一位宽
    output wire spk_2 [0:OUTPUT_NODES-1]//神经元脉冲输出
);
wire spk_1 [0:FC1_NODES-1];//连接FC层输出
wire spk_1_wire [0:FC1_NODES];//串行脉冲数为21个，包含一个固定的1输入
wire start;//计数器开始标志
reg  [4:0] spk_cnt;//计数器记到0-20（）21个数
reg  done;//计数完成清零信号

reg  fc2_valid_reg;
reg  fc2_input_valid;//串行输入脉冲有效
reg  fc2_input_spk;//串行输入脉冲

	// ----------------------------
    // 状态寄存器：是否正在计数
    // ----------------------------
    reg counting;//继续计数标志位

    // 计数启动逻辑
    always @(posedge clk or posedge reset) begin
        if (reset)
            counting <= 1'b0;
        else if (start && !counting)
            counting <= 1'b1;   // 检测到 start 启动计数
        else if (done)
            counting <= 1'b0;   // 计满自动清零，结束计数
    end

    // ----------------------------
    // 计数逻辑
    // ----------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            spk_cnt <= 4'd0;
        else if (start && !counting)
            spk_cnt <= 4'd0;               // 启动时清零
        else if (counting) begin
            if (spk_cnt == FC1_NODES)
                spk_cnt <= 4'd0;           // 计满 20 归零
            else
                spk_cnt <= spk_cnt + 1'b1;     // 正常计数
        end
    end

    // ----------------------------
    // 完成标志逻辑
    // ----------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            done <= 1'b0;
        else if (counting && spk_cnt == FC1_NODES)
            done <= 1'b1;              // 计到 20 拉高
        else
            done <= 1'b0;
    end


    // =============================
    // FC1 + LIF 神经元层例化
    // =============================
    FC1_LIF1 #(
        .WIDTH(WIDTH),          // Q7.17 定点
        .FRAC(FRAC),
        .INPUT_NODES(INPUT_NODES),   // 输入节点数
        .OUTPUT_NODES(FC1_NODES)    // 输出节点数
    ) fc1_lif1_inst (
        .clk(clk),
        .reset(reset),
        .fc_addra_valid(fc1_addra_valid),
        .input_fc_array(input_fc_array),     // 输入单个像素或特征值
        .spk1_en(start),
        .spk_1(spk_1)              // 输出 20 个 LIF 脉冲
    );

    // =============================
    // 生成FC2激励
    // =============================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fc2_valid_reg <= 1'd0;
            fc2_input_valid <= 1'd0;end
        else if (start && !counting)begin
            fc2_valid_reg <= ~fc2_valid_reg;
            fc2_input_valid <= fc2_valid_reg;end              
        else if (spk_cnt == FC1_NODES)begin
            fc2_valid_reg <= ~fc2_valid_reg;
            fc2_input_valid <= fc2_valid_reg;end
        else begin
            fc2_valid_reg <= fc2_valid_reg;
            fc2_input_valid <= fc2_valid_reg;end
    end
    // =============================
    // 串行化 spk_1_wire → fc2_input_spk
    // =============================
    genvar k;
    generate
        for (k = 0; k < FC1_NODES; k = k + 1) begin
            assign spk_1_wire[k] = spk_1[k];
        end
    endgenerate
    assign spk_1_wire[FC1_NODES] = 1'b1;  // 固定输入

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            fc2_input_spk <= 1'b0;
        end 
        else if(fc2_valid_reg)begin
            // 根据计数器选择对应的脉冲
            fc2_input_spk <= spk_1_wire[spk_cnt];
        end
        else begin
            fc2_input_spk <= fc2_input_spk;
        end
    end
    // =============================
    // FC2 + LIF2 神经元层例化
    // =============================
    FC2_LIF2 #(
        .WIDTH(WIDTH),          // Q7.17 定点
        .FRAC(FRAC),
        .INPUT_NODES(FC1_NODES),   // 输入节点数
        .OUTPUT_NODES(OUTPUT_NODES)    // 输出节点数
    ) fc2_lif2_inst (
        .clk(clk),
        .reset(reset),
        .fc_addra_valid(fc2_valid_reg),
        .input_fc_array(fc2_input_spk),     // 输入单个像素或特征值
        .spk_2(spk_2)                    // 输出 10 个 LIF 脉冲
    );

endmodule