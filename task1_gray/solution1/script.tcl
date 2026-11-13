############################################################
## This file is generated automatically by Vivado HLS.
## Please DO NOT edit it.
## Copyright (C) 1986-2018 Xilinx, Inc. All Rights Reserved.
############################################################
open_project task1_gray
set_top rgb2gray
add_files task1_gray/rgb2gray.cpp
add_files task1_gray/rgb2gray.h
add_files -tb task1_gray/tb.cpp
open_solution "solution1"
set_part {xc7a35tfgg484-2} -tool vivado
create_clock -period 6.734 -name default
config_export -format ip_catalog -rtl verilog -version 0.0.0
#source "./task1_gray/solution1/directives.tcl"
csim_design
csynth_design
cosim_design
export_design -rtl verilog -format ip_catalog -version "0.0.0"
