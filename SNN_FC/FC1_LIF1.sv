module FC1_LIF1 #(
	parameter WIDTH = 24,        // Q7.17 定点
	parameter FRAC  = 17,
  parameter STEP = 25,
	parameter INPUT_NODES  = 784,
	parameter OUTPUT_NODES = 20
)(
	  input  wire clk,
    input  wire reset,
    input  wire fc_addra_valid,//全连接层读权有效//fc_addra_valid需要在时钟上升沿开始，保持785个时钟周期
    input  wire signed [WIDTH-1:0] input_fc_array,         // 每个输入单独一位宽
    output wire spk1_en,//输出脉冲序有效信号，等同于PE计算完成信号
    output wire spk_1 [0:OUTPUT_NODES-1]//神经元脉冲输出
);
wire   signed   [WIDTH-1:0]   weight_array   [0:OUTPUT_NODES-1];//输出权重20个
wire signed [WIDTH-1:0] output_fc [0:OUTPUT_NODES-1];//输出全连接计算结果
reg [9:0] addra;//寻址索引
reg  input_valid;//地址或输入有效
reg  input_valid_reg;//输入有效寄存一个时钟周期
reg  output_valid;//PE或FC1_layer输出有效//输入有效寄存两个时钟周期
wire p_valid;//计算模块的有效信号
reg  p_valid_reg0,p_valid_reg1;//延时两个时钟周期，推导神经元计算有效信号
wire neuron_p_flg;//神经元计算信号
reg  neuron_p_finish;//神经元计算完成信号
reg  signed [WIDTH-1:0] mem_record [0:OUTPUT_NODES-1];//记录膜电位
reg  [4:0]  cnt_spk;//step_numb计数器，到STEP清零
assign  spk1_en = neuron_p_finish;

always @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_spk <= 10'd0;end 
        else if (cnt_spk == (STEP-1) && neuron_p_finish) begin
            cnt_spk <= 10'd0;end
        else if(neuron_p_finish)begin
            cnt_spk <= cnt_spk+1'd1;end
        else begin
            cnt_spk <= cnt_spk;end
    end

always @(posedge clk or posedge reset) begin
        if (reset) begin
            addra <= 10'd0;
            input_valid <= 1'd0;end 
        else if (addra == INPUT_NODES && fc_addra_valid == 1'd1) begin
            addra <= 10'd0;
            input_valid <= 1'd0;end
        else if(fc_addra_valid == 1'd1)begin
		        addra <= addra+1'd1;
		        input_valid <= 1'd1;end
        else begin
            addra <= addra;
            input_valid <= 1'd0;end
    end

always @(posedge clk or posedge reset) begin//PE的计算需要两个时钟周期，output有效时，输出的output_fc有效
        if (reset) begin
            input_valid_reg <= 1'd0;
            output_valid    <= 1'd0;end 
        else begin
            input_valid_reg <= input_valid;
            output_valid    <= input_valid_reg;end
    end

assign p_valid = input_valid || output_valid;//计算有效信号比地址有效多两个时钟周期

always @(posedge clk or posedge reset) begin//延时两个时钟周期，推导神经元计算有效信号
        if (reset) begin
            p_valid_reg0 <= 1'd0;
            p_valid_reg1 <= 1'd0;end 
        else begin
            p_valid_reg0 <= p_valid;
            p_valid_reg1 <= p_valid_reg0;end
    end

assign neuron_p_flg = p_valid_reg1 & (~p_valid_reg0);//神经元计算信号
always @(posedge clk or posedge reset) begin//延时一个时钟周期，生成神经元计算完成或有效信号
        if (reset) begin
            neuron_p_finish <= 1'd0;end 
        else begin
            neuron_p_finish <= neuron_p_flg;end
    end


FC1_layer#(
    .WIDTH        (WIDTH       ),        // 
    .FRAC         (FRAC        ),
    .INPUT_NODES  (INPUT_NODES ),
    .OUTPUT_NODES (OUTPUT_NODES))
FC1_layer_inst(
    .clk                (clk),
    .reset              (reset),
    .valid              (p_valid),
    .addra              (addra), //地址输入
    .input_fc_array     (input_fc_array), // 每个输入单独一位宽
    .weights_array      (weight_array), // 二维数组存储权重
    .output_fc          (output_fc)  // 每个全连接单元输出
);

// generate 循环例化 20 个 lif_neuron_cell
    genvar i;
    generate
        for (i = 0; i < OUTPUT_NODES; i = i + 1) begin : LIF_ARRAY1
            lif_neuron_cell #(
                .WIDTH(WIDTH),
                .FRAC(FRAC)
            ) lif_inst (
                .clk(clk),
                .rst(reset),
                .input_cur(output_fc[i]),
                .input_en(neuron_p_flg),
                .spike_out(spk_1[i]),
                .mem_out(mem_record[i])
            );
        end
    endgenerate


rom_n0 rom_n0_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addra
  .douta(weight_array[0])  // output wire [23 : 0] douta
);

rom_n1 rom_n1_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[1])  // output wire [23 : 0] douta
);

rom_n2 rom_n2_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[2])  // output wire [23 : 0] douta
);

rom_n3 rom_n3_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[3])  // output wire [23 : 0] douta
);

rom_n4 rom_n4_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[4])  // output wire [23 : 0] douta
);

rom_n5 rom_n5_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[5])  // output wire [23 : 0] douta
);

rom_n6 rom_n6_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addra
  .douta(weight_array[6])  // output wire [23: 0] douta
);

rom_n7 rom_n7_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[7])  // output wire [23: 0] douta
);

rom_n8 rom_n8_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[8])  // output wire [23: 0] douta
);

rom_n9 rom_n9_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[9])  // output wire [23: 0] douta
);

rom_n10 rom_n10_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[10])  // output wire [23 : 0] douta
);

rom_n11 rom_n11_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[11])  // output wire [23 : 0] douta
);

rom_n12 rom_n12_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] add
  .douta(weight_array[12])  // output wire [23 : 0] douta
);

rom_n13 rom_n13_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addr
  .douta(weight_array[13])  // output wire [23 : 0] douta
);

rom_n14 rom_n14_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addr
  .douta(weight_array[14])  // output wire [23 : 0] douta
);

rom_n15 rom_n15_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addr
  .douta(weight_array[15])  // output wire [23 : 0] douta
);

rom_n16 rom_n16_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addr
  .douta(weight_array[16])  // output wire [23 : 0] douta
);

rom_n17 rom_n17_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addr
  .douta(weight_array[17])  // output wire [23 : 0] douta
);

rom_n18 rom_n18_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addr
  .douta(weight_array[18])  // output wire [23 : 0] douta
);

rom_n19 rom_n19_inst (
  .clka(clk),    // input wire clka
  .addra(addra),  // input wire [9 : 0] addr
  .douta(weight_array[19])  // output wire [23 : 0] douta
);
endmodule