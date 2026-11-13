#include "rgb2gray.h"
void rgb2gray(unsigned int rgb, unsigned char &gray) {
    #pragma HLS INTERFACE ap_ctrl_none port=return
    #pragma HLS INTERFACE ap_none port=rgb
    #pragma HLS INTERFACE ap_none port=gray
    unsigned char r = (rgb >> 16) & 0xFF;
    unsigned char g = (rgb >> 8) & 0xFF;
    unsigned char b = rgb & 0xFF;
    // BT.601 »Ò¶È¹«Ê½
    gray = (66 * r + 129 * g + 25 * b + 128) >> 8;
}
