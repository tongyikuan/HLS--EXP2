#include <stdio.h>
#include "rgb2gray.h"
int main() {
    int r, g, b;
    unsigned char hls_gray, ref_gray;
    int pass = 1;
    int test_rgb[4] = {0xFFFFFF, 0xFF0000, 0x00FF00, 0x0000FF};
    for(int i=0; i<4; i++) {
        r = (test_rgb[i] >> 16) & 0xFF;
        g = (test_rgb[i] >> 8) & 0xFF;
        b = test_rgb[i] & 0xFF;
        rgb2gray(test_rgb[i], hls_gray);
        ref_gray = (66 * r + 129 * g + 25 * b + 128) >> 8;
        if(hls_gray != ref_gray) { printf("FAIL at %d\n", i); pass=0; }
    }
    if(pass) printf("PASS\n");
    return 0;
}
