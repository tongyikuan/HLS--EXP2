#include <ap_int.h>
#include "ht_video_mem.h"
#include <hls_stream.h>

#define MAX_COLS 2048
#define REF_ROWS 3
#define REF_COLS 3
#define T1       ap_uint<8>

// 3x3 sharpen (single-stage Laplacian):
//   out = 5*center - up - down - left - right, clamp 0..255
// Same stream interface / window buffering as the gaussian task.
void sharp
(
    hls::stream<T1> &src  ,
    hls::stream<T1> &dst  ,
    ap_uint<12> &y ,
    ap_uint<12> &x ,
    ap_uint<12> w ,
    ap_uint<12> h
)
{
    static HT_window_with_linebuffer< REF_ROWS, REF_COLS, MAX_COLS, T1 > wlb ;
#pragma HLS ARRAY_PARTITION variable=wlb.lb complete dim=1
#pragma HLS ARRAY_PARTITION variable=wlb.w complete dim=0
#pragma HLS DEPENDENCE variable=wlb array inter false

    int i,j,c;
    int d;

    wlb.set_size(w+REF_COLS/2);

    sharp_label0:for(i=0;i<h+REF_ROWS/2;i++)
    {
        y = i ;
        c = 0 ;
        for(j=0;j<w+REF_COLS/2;j++)
        {
#pragma HLS PIPELINE II=1
            // window: val[0][0] is the newest pixel, origin at bottom-right
            if( i < h && j < w )
                wlb.insert(src.read());
            else
                wlb.insert(0);

            // center (i-1,j-1) = val[1][1]
            d = (int)wlb.getval(1,1) * 5
              - (int)wlb.getval(2,1)   // up
              - (int)wlb.getval(0,1)   // down
              - (int)wlb.getval(1,2)   // left
              - (int)wlb.getval(1,0) ; // right

            if( d < 0 )
                d = 0 ;
            else if( d > 255 )
                d = 255 ;

            if( i >= REF_ROWS/2 && j >= REF_COLS/2 )
            {
                dst.write((T1)d) ;
                c = c + 1 ;
                x = c ;
            }
        }
    }
}
