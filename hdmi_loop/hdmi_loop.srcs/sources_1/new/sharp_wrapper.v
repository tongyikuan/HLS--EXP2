`timescale 1ns / 1ps
// ==========================================================================
// sharp_wrapper : 3x3 gaussian HLS stream core + video glue
//   * input register   : {data, valid} for the ap_fifo source port
//   * frame aligned    : ap_start is armed after a vsync edge, so the core
//                        always starts at the first pixel of a frame
//   * output FIFO      : absorbs the 4-cycle pipeline spill at line end
//                        (the core stalls while waiting for the next line)
//   * sync delay       : hs/vs/de delayed by D clocks, so the output timing
//                        matches the output data
//   NOTE: D only sets the FIFO margin (must be a little larger than the
//         core latency ~2205). It does NOT change the picture alignment,
//         because the FIFO pops pixels in raster order, gated by de_out.
// ==========================================================================
module sharp_wrapper(
    input  wire        pixel_clk,
    input  wire        rst_n,       // active LOW reset -> connect ~rx_rst
    input  wire [7:0]  gray_in,     // 8bit gray pixel
    input  wire        de_in,
    input  wire        hs_in,
    input  wire        vs_in,

    output wire [7:0]  sharp_out,
    output wire        de_out,
    output wire        hs_out,
    output wire        vs_out
);

    // ---------------- signals ----------------
    reg  [7:0]  in_data_reg;
    reg         in_valid_reg;

    reg         vs_d1;
    reg         armed;

    wire        src_V_V_read;
    wire        dst_V_V_write;
    wire [7:0]  sharp_din;
    wire        ap_done, ap_idle, ap_ready;
    wire [11:0] y_V, x_V;
    wire        y_V_ap_vld, x_V_ap_vld;

    localparam  FD = 2048;          // output FIFO depth
    reg  [7:0]  fifo_mem [0:FD-1];
    reg  [10:0] wr_ptr, rd_ptr;
    reg  [11:0] fifo_cnt;
    wire        fifo_full, fifo_empty, fifo_wr, fifo_rd;

    // 0 = sync delayed by 1 cycle only  (used to reproduce the misalignment)
    // 1 = FIFO + D cycle sync delay     (normal operation)
    parameter   COMPENSATE = 1'b1;

    // D only needs to be larger than the core latency (~2205 cycles).
    // It does NOT change the picture alignment: the FIFO always pops the
    // pixels in raster order, gated by de_out. A larger D = larger margin.
    localparam  D = 3200;
    reg  [D-1:0] de_sr, hs_sr, vs_sr;
    reg          de_p1, hs_p1, vs_p1;

    // ---------------- input register ----------------
    always @(posedge pixel_clk) begin
        if (!rst_n) begin
            in_data_reg  <= 8'd0;
            in_valid_reg <= 1'b0;
        end else begin
            in_data_reg  <= gray_in;
            in_valid_reg <= de_in;
        end
    end

    // ---------------- frame aligned start ----------------
    // arm on a vsync edge, then keep ap_start high: the core starts during
    // vertical blanking and blocks on src until the first active pixel.
    always @(posedge pixel_clk) begin
        if (!rst_n) begin
            vs_d1 <= 1'b0;
            armed <= 1'b0;
        end else begin
            vs_d1 <= vs_in;
            if (vs_in & ~vs_d1)
                armed <= 1'b1;
        end
    end

    // ---------------- HLS sharpen core ----------------
    sharp u_sharp (
        .ap_clk         (pixel_clk),
        .ap_rst         (~rst_n),
        .ap_start       (armed),
        .ap_done        (ap_done),
        .ap_idle        (ap_idle),
        .ap_ready       (ap_ready),
        .src_V_V_dout   (in_data_reg),
        .src_V_V_empty_n(in_valid_reg),
        .src_V_V_read   (src_V_V_read),
        .dst_V_V_din    (sharp_din),
        .dst_V_V_full_n (~fifo_full),
        .dst_V_V_write  (dst_V_V_write),
        .y_V            (y_V),
        .y_V_ap_vld     (y_V_ap_vld),
        .x_V            (x_V),
        .x_V_ap_vld     (x_V_ap_vld),
        .w_V            (12'd1920),
        .h_V            (12'd1080)
    );

    // ---------------- output FIFO (show ahead) ----------------
    assign fifo_full  = (fifo_cnt >= FD);
    assign fifo_empty = (fifo_cnt == 12'd0);
    assign fifo_wr    = dst_V_V_write & ~fifo_full;
    assign fifo_rd    = de_out & ~fifo_empty;

    always @(posedge pixel_clk) begin
        if (fifo_wr)
            fifo_mem[wr_ptr] <= sharp_din;
    end

    always @(posedge pixel_clk) begin
        if (!rst_n) begin
            wr_ptr   <= 11'd0;
            rd_ptr   <= 11'd0;
            fifo_cnt <= 12'd0;
        end else begin
            if (fifo_wr) wr_ptr <= wr_ptr + 11'd1;
            if (fifo_rd) rd_ptr <= rd_ptr + 11'd1;
            fifo_cnt <= fifo_cnt + (fifo_wr ? 12'd1 : 12'd0)
                                  - (fifo_rd ? 12'd1 : 12'd0);
        end
    end

    // ---------------- sync delay (also start together with the core) ------
    always @(posedge pixel_clk) begin
        if (!rst_n | ~armed) begin
            de_sr <= {D{1'b0}};
            hs_sr <= {D{1'b0}};
            vs_sr <= {D{1'b0}};
        end else begin
            de_sr <= {de_sr[D-2:0], de_in};
            hs_sr <= {hs_sr[D-2:0], hs_in};
            vs_sr <= {vs_sr[D-2:0], vs_in};
        end
    end

    // 1-cycle pipeline (COMPENSATE = 0 demo build)
    always @(posedge pixel_clk) begin
        if (!rst_n) begin
            de_p1 <= 1'b0;
            hs_p1 <= 1'b0;
            vs_p1 <= 1'b0;
        end else begin
            de_p1 <= de_in;
            hs_p1 <= hs_in;
            vs_p1 <= vs_in;
        end
    end

    assign sharp_out = COMPENSATE ? fifo_mem[rd_ptr] : sharp_din;
    assign de_out    = COMPENSATE ? de_sr[D-1]      : de_p1;
    assign hs_out    = COMPENSATE ? hs_sr[D-1]      : hs_p1;
    assign vs_out    = COMPENSATE ? vs_sr[D-1]      : vs_p1;

endmodule
