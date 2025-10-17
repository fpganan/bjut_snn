`timescale 1ns/1ps

module FC2_layer #(
    parameter WIDTH = 24,        // Q7.17 定点
    parameter FRAC  = 17,
    parameter INPUT_NODES  = 20,
    parameter OUTPUT_NODES = 10
)(
    input  wire clk,
    input  wire reset,
    input  wire valid,
    input  wire [9:0]  addra,//地址输入
    input  wire signed [WIDTH-1:0] input_fc_array ,         // 每个输入单独一位宽
    input  wire signed [WIDTH-1:0] weights_array [0:OUTPUT_NODES-1], // 二维数组存储权重
    output wire signed [WIDTH-1:0] output_fc [0:OUTPUT_NODES-1]              // 每个神经元输出
);


    wire signed [WIDTH-1:0] acc_wire [0:OUTPUT_NODES-1];

    genvar i;
    generate
        for (i = 0; i < OUTPUT_NODES; i = i + 1) begin: PE_ARRAY2
            process_Element #(.DATA_WIDTH(WIDTH), .FRAC(FRAC)) PE (
                .clk(clk),
                .reset(reset),
                .floatA(input_fc_array),
                .floatB(weights_array[i]),
                .valid(valid),
                .result(acc_wire[i])
            );
            assign output_fc[i] = acc_wire[i];
        end
    endgenerate


endmodule
