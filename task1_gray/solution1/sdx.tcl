# ==============================================================
# File generated on Tue Nov 10 20:14:27 +0800 2026
# Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2018.3 (64-bit)
# SW Build 2405991 on Thu Dec  6 23:38:27 MST 2018
# IP Build 2404404 on Fri Dec  7 01:43:56 MST 2018
# Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
# ==============================================================
add_files -tb ../tb.cpp -cflags { -Wno-unknown-pragmas}
add_files task1_gray/rgb2gray.h
add_files task1_gray/rgb2gray.cpp
set_part xc7a35tfgg484-2
create_clock -name default -period 6.734
config_export -format=ip_catalog
config_export -rtl=verilog
config_export -version=0.0.0
