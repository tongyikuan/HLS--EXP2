#include <ap_int.h>
#include <stdio.h>
#include <hls_stream.h>

#define IMG_ROWS (48)
#define IMG_COLS (64)
#define T1       ap_uint<8>

void sharp
(
    hls::stream<T1> &src ,
    hls::stream<T1> &dst ,
    ap_uint<12> &y ,
    ap_uint<12> &x ,
    ap_uint<12> w ,
    ap_uint<12> h
);

int main()
{
    hls::stream<T1> imgi("in");
    hls::stream<T1> imgo("out");
    T1 image[IMG_ROWS][IMG_COLS];
    ap_uint<12> w, h, r, c;
    int x, y, t;

    // test image: white rectangle + white border on black (same as gauss tb)
    for (y = 0; y < IMG_ROWS; y++)
        for (x = 0; x < IMG_COLS; x++)
            if ((x >= 16) && (x < 32) && (y >= 16) && (y < 32))
                image[y][x] = 255;
            else if ((x == 0) || (y == 0) || (x == IMG_COLS-1) || (y == IMG_ROWS-1))
                image[y][x] = 255;
            else
                image[y][x] = 0;

    w = IMG_COLS;
    h = IMG_ROWS;

    for (y = 0; y < IMG_ROWS; y++)
        for (x = 0; x < IMG_COLS; x++)
            imgi.write(image[y][x]);

    sharp(imgi, imgo, r, c, w, h);

    // CPU reference: out = 5*p - up - down - left - right, zero padding, clamp
    int err_cnt = 0;
    int max_err = 0;
    int expect, got, acc;
    for (y = 0; y < h; y++)
    {
        for (x = 0; x < w; x++)
        {
            acc = (int)image[y][x] * 5;
            acc -= (y > 0)            ? (int)image[y-1][x] : 0;
            acc -= (y < (int)h - 1)   ? (int)image[y+1][x] : 0;
            acc -= (x > 0)            ? (int)image[y][x-1] : 0;
            acc -= (x < (int)w - 1)   ? (int)image[y][x+1] : 0;

            if (acc < 0) acc = 0;
            else if (acc > 255) acc = 255;
            expect = acc;

            got = imgo.read();
            if (got != expect)
            {
                err_cnt++;
                t = (got > expect) ? (got - expect) : (expect - got);
                if (t > max_err) max_err = t;
                if (err_cnt <= 10)
                    printf("MISMATCH row=%d col=%d got=%d expect=%d\n", y, x, got, expect);
            }
        }
    }

    printf("Compared %d x %d = %d pixels.\n", (int)h, (int)w, (int)(h*w));
    if (err_cnt == 0)
        printf("PASS\n");
    else
        printf("FAIL: %d mismatches, max abs error = %d\n", err_cnt, max_err);
    return 0;
}
