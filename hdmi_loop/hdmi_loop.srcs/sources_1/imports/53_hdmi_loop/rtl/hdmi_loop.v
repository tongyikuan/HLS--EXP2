`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：http://www.openedv.com/forum.php
//淘宝店铺：https://zhengdianyuanzi.tmall.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2023-2033
//All rights reserved                                  
//----------------------------------------------------------------------------------------
// File name:           hdmi_loop
// Created by:          正点原子
// Created date:        2023年2月3日14:17:02
// Version:             V1.0
// Descriptions:        HDMI环回实验
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
module hdmi_loop(
    input               sys_clk,               //50M系统时钟
    input               rst_n,                 //系统复位，低有效
    input  [0:0]        key,
    output [1:0]        led,
    //hdmi in
    input               hdmi_ddc_scl_io,       //IIC时钟
    inout               hdmi_ddc_sda_io,       //IIC数据
    output              hdmi_in_hpd,           //热插拔信号
    output [0:0]        hdmi_in_oen,           //输入输出切换信号 
    input               clk_hdmi_in_n,         //输入差分时钟
    input               clk_hdmi_in_p,         //输入差分时钟
    input  [2:0]        data_hdmi_in_n,        //输入差分数据
    input  [2:0]        data_hdmi_in_p,        //输入差分数据
    //hdmi out
    output [0:0]        hdmi_out_oen,          //输入输出切换信号 
    output              clk_hdmi_out_n,        //输出差分时钟
    output              clk_hdmi_out_p,        //输出差分时钟
    output [2:0]        data_hdmi_out_n,       //输出差分数据
    output [2:0]        data_hdmi_out_p        //输出差分数据
);

//wire define
wire        clk_10m;           //10m时钟
wire        clk_200m;          //200m时钟
wire        rx_rst;            //复位信号，高有效
wire        pixel_clk;         //像素时钟
wire        pixel_clk_5x;      //5倍像素时钟
wire        video_hs;          //行信号
wire        video_vs;          //场信号
wire        video_de;          //数据有效使能
wire        hdmi_in_oen;       //输入输出切换信号 
wire        hdmi_in_hpd;       //热插拔信号
wire        hdmi_out_oen;      //输入输出切换信号 
wire [23:0] video_rgb;         //像素数据

//*****************************************************
//**                    main code
//*****************************************************      
//时钟模块
mmcm u_mmcm(
.clk_out1           (clk_10m),  // output clk_out1
.clk_out2           (clk_200m),  // output clk_out1
.locked             (       ),  // output locked
.clk_in1            (sys_clk)   // input clk_in1
);      
    
//读edid模块    
i2c_edid u_i2c_edid (
	.clk(clk_10m),
	.rst(~rst_n),
	.scl(hdmi_ddc_scl_io),
	.sda(hdmi_ddc_sda_io)
);    
    
//hdmi解码模块    
hdmi_rx u_hdmi_rx(
    .clk_10m       (clk_10m),
    .clk_200m      (clk_200m),
    //input
    .tmdsclk_p     (clk_hdmi_in_p),     
    .tmdsclk_n     (clk_hdmi_in_n),      
    .blue_p        (data_hdmi_in_p[0]), 
    .green_p       (data_hdmi_in_p[1]),  
    .red_p         (data_hdmi_in_p[2]),  
    .blue_n        (data_hdmi_in_n[0]),  
    .green_n       (data_hdmi_in_n[1]), 
    .red_n         (data_hdmi_in_n[2]), 
    .rst_n         (rst_n),              
    //output       
    .reset         (rx_rst),             
    .pclk          (pixel_clk),         
    .pclkx5        (pixel_clk_5x),       
    .hsync         (video_hs),          
    .vsync         (video_vs),          
    .de            (video_de),          
    .rgb_data      (video_rgb),         
    .hdmi_in_en    (hdmi_in_oen),    
    .hdmi_in_hpd   (hdmi_in_hpd)  
  );      
   
    // ==========================================
    // 插入任务一：RGB转灰度模块
    // ==========================================
    wire [7:0]  hls_gray_out; 
    wire [23:0] gray_rgb;
    
    // 实例化刚才加进来的 HLS 灰度核
    rgb2gray u_rgb2gray (
        .ap_clk   ( pixel_clk             ),  // 接刚才截图里的 pixel_clk
        .ap_rst   ( ~rx_rst               ),  // 复位信号，HLS默认高电平复位，所以取反
        .rgb      ( {8'd0, video_rgb}     ),  // 截图中原本的24位视频信号，前面补8个0凑成32位
        .gray     ( hls_gray_out          )   // 输出 8 位灰度数据
    );
    
        // 2. 调用高斯平滑包装模块
    wire [7:0] gauss_val;
    wire gauss_de, gauss_hs, gauss_vs;
    
    gauss_wrapper u_gauss_wrapper (
        .pixel_clk(pixel_clk),
        .rst_n    (~rx_rst),        // 你之前截图里的复位信号
        .gray_in  (hls_gray_out),  // 接上面灰度核的输出！
        .de_in    (video_de),      
        .hs_in    (video_hs),
        .vs_in    (video_vs),
        .gauss_out(gauss_val),
        .de_out   (gauss_de),
        .hs_out   (gauss_hs),
        .vs_out   (gauss_vs)
    );

       // ==========================================
    // 插入任务三：锐化模块
    // ==========================================
    wire [7:0] sharp_val;
    wire sharp_de, sharp_hs, sharp_vs;
    
    sharp_wrapper u_sharp_wrapper (
        .pixel_clk(pixel_clk),
        .rst_n    (~rx_rst),        // 你截图里的复位信号
        .gray_in  (hls_gray_out),  // 接灰度核的输出！
        .de_in    (video_de),      
        .hs_in    (video_hs),
        .vs_in    (video_vs),
        .sharp_out(sharp_val),
        .de_out   (sharp_de),
        .hs_out   (sharp_hs),
        .vs_out   (sharp_vs)
    );

    // 拼成 24位RGB (黑白画面)
    wire [23:0] sharp_rgb = {sharp_val, sharp_val, sharp_val};
   
   
   
    // 3. 把8位灰度拼成24位RGB (黑白画面)
    wire [23:0] gauss_rgb = {gauss_val, gauss_val, gauss_val};
    
    // 把 8 位灰度复制到 RGB 三个通道，变成黑白画面
    assign gray_rgb = {hls_gray_out, hls_gray_out, hls_gray_out};
    // ==========================================
 
 // HDMI解码封装层模块      
    // ==========================================================
    // key debounce + mode counter (0..3) + 4:1 video mux
    //   mode 0 : passthrough
    //   mode 1 : gray
    //   mode 2 : gaussian
    //   mode 3 : sharpen (TODO: task 3, placeholder = passthrough)
    // ==========================================================
    parameter KEY_ACTIVE_LOW  = 1'b1;   // pressed = 0
    parameter LED_ACTIVE_HIGH = 1'b1;   // if LEDs are active low, set to 0

    reg        key_sync0, key_sync1;
    reg [21:0] db_cnt;
    reg        key_stable, key_stable_d;
    reg [1:0]  mode;
    reg [1:0]  mode_show;
    reg        vs_q;

    wire key_pressed = KEY_ACTIVE_LOW ? ~key_sync1 : key_sync1;

    always @(posedge pixel_clk) begin
        if (rx_rst) begin
            key_sync0    <= 1'b0;
            key_sync1    <= 1'b0;
            db_cnt       <= 22'd0;
            key_stable   <= 1'b0;
            key_stable_d <= 1'b0;
            mode         <= 2'd0;
        end else begin
            key_sync0 <= key[0];
            key_sync1 <= key_sync0;

            if (key_pressed == key_stable)
                db_cnt <= 22'd0;
            else if (db_cnt == 22'd2000000) begin   // ~13.5ms @ 148.5MHz
                db_cnt     <= 22'd0;
                key_stable <= key_pressed;
            end else
                db_cnt <= db_cnt + 22'd1;

            key_stable_d <= key_stable;
            if (key_stable & ~key_stable_d)
                mode <= mode + 2'd1;
        end
    end

    // switch takes effect at the frame boundary (vsync rising edge)
    always @(posedge pixel_clk) begin
        if (rx_rst) begin
            vs_q      <= 1'b0;
            mode_show <= 2'd0;
        end else begin
            vs_q <= video_vs;
            if (video_vs & ~vs_q)
                mode_show <= mode;
        end
    end

    assign led = LED_ACTIVE_HIGH ? mode_show : ~mode_show;


    wire [23:0] mux_rgb;
    wire        mux_de, mux_hs, mux_vs;

    assign mux_rgb = (mode_show == 2'd0) ? video_rgb :
                     (mode_show == 2'd1) ? gray_rgb  :
                     (mode_show == 2'd2) ? gauss_rgb : sharp_rgb;

    assign mux_de  = (mode_show == 2'd0) ? video_de :
                     (mode_show == 2'd1) ? video_de :
                     (mode_show == 2'd2) ? gauss_de : sharp_de;

    assign mux_hs  = (mode_show == 2'd0) ? video_hs :
                     (mode_show == 2'd1) ? video_hs :
                     (mode_show == 2'd2) ? gauss_hs : sharp_hs;

    assign mux_vs  = (mode_show == 2'd0) ? video_vs :
                     (mode_show == 2'd1) ? video_vs :
                     (mode_show == 2'd2) ? gauss_vs : sharp_vs;
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (pixel_clk),
    .pclk_x5        (pixel_clk_5x),
    .reset_n        (~rx_rst),
                
    .video_din      ( mux_rgb ),
    .video_hsync    ( mux_hs ),
    .video_vsync    ( mux_vs ),
    .video_de       ( mux_de ),
                
    .tmds_clk_p     (clk_hdmi_out_p),
    .tmds_clk_n     (clk_hdmi_out_n),
    .tmds_data_p    (data_hdmi_out_p),
    .tmds_data_n    (data_hdmi_out_n), 
    .tmds_oen       (hdmi_out_oen)
    );  
endmodule