############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2018 Xilinx, Inc. All Rights Reserved.
############################################################
open_project task2_gauss
set_top gray8_gauss2d_3x3
add_files gray8_gauss2d_3x3/gray8_gauss2d_3x3.cpp
add_files gray8_gauss2d_3x3/ht_video_mem.h
add_files -tb gray8_gauss2d_3x3/gray8_gauss2d_3x3_tb.cpp -cflags "-Wno-unknown-pragmas"
open_solution "solution1"
set_part {xc7a35tfgg484-2} -tool vivado
create_clock -period 6.734 -name default
config_export -format ip_catalog -rtl verilog -version 0.0.0
#source "./task2_gauss/solution1/directives.tcl"
csim_design
csynth_design
cosim_design
export_design -rtl verilog -format ip_catalog -version "0.0.0"
