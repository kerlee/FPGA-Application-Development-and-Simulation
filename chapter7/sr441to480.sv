`include "../common.sv"
`include "../chapter4/counter.sv"
`include "./dds.sv"
`include "./fir.sv"

`timescale 1ns/1ps
`default_nettype none

module TestSr441to480;
    import SimSrcGen::*;
    logic clk, rst;
    initial GenClk(clk, 25000, 35430.8);
    initial GenRst(clk, rst, 2, 2);
    logic signed [15:0] sig441, sig480;
    logic en441, en480;
    DDS #(24, 16, 18) theDDS(
        clk, rst, en441, 24'sd1_902_179, '0, sig441);
    SmpRate441to480 #(16) theSrCnvt(
        clk, rst, en441, en480, 16'(int'(sig441*0.9)), sig480);
endmodule

module SmpRate441to480 #( parameter W = 16 )(
    input wire clk, rst,    // clk @ 28.224MHz
    output logic signed en441, en480,
    input wire signed [W-1:0] in,
    output logic signed [W-1:0] out
);
    localparam logic FIR_INTERPDECI_HOLD = 0;
    logic en882, en1764, en3528;
    logic en70560, en3360;
    Counter #(4)  cnt70560(clk, rst, 1'b1, , en70560);
    Counter #(20) cnt3528(clk, rst, en70560, , en3528);
    Counter #(2) cnt1764(clk, rst, en3528, , en1764);
    Counter #(2) cnt882(clk, rst, en1764, , en882);
    Counter #(2) cnt441(clk, rst, en882, , en441);
    Counter #(21) cnt3360(clk, rst, en70560, , en3360);
    Counter #(7) cnt480(clk, rst, en3360, , en480);
    logic signed [W-1:0] int882, int1764, int3528;
    logic signed [W-1:0] fil882, fil1764, fil3528;
    logic signed [W-1:0] sig70560;
    logic signed [W-1:0] dec3360, fil3360, dec480;
    InterpDeci #(W, FIR_INTERPDECI_HOLD) intp1 (
        clk, rst, en441, en882, in, int882);
    FIR #(W, 79, '{
        -0.000166, 0,  0.000346, 0, -0.000607, 0,  0.000970, 0,
        -0.001457, 0,  0.002094, 0, -0.002910, 0,  0.003940, 0,
        -0.005226, 0,  0.006821, 0, -0.008796, 0,  0.011250, 0,
        -0.014333, 0,  0.018284, 0, -0.023514, 0,  0.030808, 0,
        -0.041848, 0,  0.061032, 0, -0.104514, 0,  0.317804, 0.5,
         0.317804, 0, -0.104514, 0,  0.061032, 0, -0.041848, 0,
         0.030808, 0, -0.023514, 0,  0.018284, 0, -0.014333, 0,
         0.011250, 0, -0.008796, 0,  0.006821, 0, -0.005226, 0,
         0.003940, 0, -0.002910, 0,  0.002094, 0, -0.001457, 0,
         0.000970, 0, -0.000607, 0,  0.000346, 0, -0.000166
        }) fir1(clk, rst, en882, int882, fil882);
    InterpDeci #(W, FIR_INTERPDECI_HOLD) intp2 (
        clk, rst, en882, en1764, FIR_INTERPDECI_HOLD ? fil882 : fil882 <<< 1, int1764);
    FIR #(W, 15, '{
        -0.000926, 0,  0.014119, 0, -0.064847, 0,  0.301819, 0.5,
         0.301819, 0, -0.064847, 0,  0.014119, 0, -0.000926
        }) fir2(clk, rst, en1764, int1764, fil1764);
    InterpDeci #(W, FIR_INTERPDECI_HOLD) intp3 (
        clk, rst, en1764, en3528, FIR_INTERPDECI_HOLD ? fil1764 : fil1764 <<< 1, int3528);
    FIR #(W, 11, '{
         0.001299, 0, -0.038595, 0,  0.287173,  0.500247,
         0.287173, 0, -0.038595, 0,  0.001299
        }) fir3(clk, rst, en3528, int3528, fil3528);
    CicUpSampler #(W, 20, 1, 3) cicUp(
        clk, rst, en3528, en70560, FIR_INTERPDECI_HOLD ? fil3528 : fil3528 <<< 1, sig70560);
    CicDownSampler #(W, 21, 1, 3) cicDown(
        clk, rst, en70560, en3360, sig70560, dec3360);
    FIR #(W, 154, '{
         0.000019,  0.000065,  0.000114,  0.000151,  0.000161,
         0.000130,  0.000054, -0.000062, -0.000197, -0.000323,
        -0.000404, -0.000409, -0.000316, -0.000126,  0.000139,
         0.000432,  0.000689,  0.000841,  0.000832,  0.000630,
         0.000246, -0.000268, -0.000815, -0.001279, -0.001539,
        -0.001500, -0.001121, -0.000432,  0.000465,  0.001402,
         0.002176,  0.002593,  0.002504,  0.001856,  0.000709,
        -0.000758, -0.002269, -0.003499, -0.004143, -0.003980,
        -0.002935, -0.001115,  0.001187,  0.003541,  0.005443,
         0.006427,  0.006158,  0.004533,  0.001721, -0.001830,
        -0.005457, -0.008395, -0.009924, -0.009529, -0.007033,
        -0.002680,  0.002865,  0.008593,  0.013314,  0.015876,
         0.015404,  0.011511,  0.004451, -0.004840, -0.014817,
        -0.023521, -0.028872, -0.029006, -0.022613, -0.009211,
         0.010694,  0.035598,  0.063149,  0.090432,  0.114368,
         0.132139,  0.141604,  0.141604,  0.132139,  0.114368,
         0.090432,  0.063149,  0.035598,  0.010694, -0.009211,
        -0.022613, -0.029006, -0.028872, -0.023521, -0.014817,
        -0.004840,  0.004451,  0.011511,  0.015404,  0.015876,
         0.013314,  0.008593,  0.002865, -0.002680, -0.007033,
        -0.009529, -0.009924, -0.008395, -0.005457, -0.001830,
         0.001721,  0.004533,  0.006158,  0.006427,  0.005443,
         0.003541,  0.001187, -0.001115, -0.002935, -0.003980,
        -0.004143, -0.003499, -0.002269, -0.000758,  0.000709,
         0.001856,  0.002504,  0.002593,  0.002176,  0.001402,
         0.000465, -0.000432, -0.001121, -0.001500, -0.001539,
        -0.001279, -0.000815, -0.000268,  0.000246,  0.000630,
         0.000832,  0.000841,  0.000689,  0.000432,  0.000139,
        -0.000126, -0.000316, -0.000409, -0.000404, -0.000323,
        -0.000197, -0.000062,  0.000054,  0.000130,  0.000161,
         0.000151,  0.000114,  0.000065,  0.000019
        }) fir4(clk, rst, en3360, dec3360, fil3360);
    InterpDeci #(W, FIR_INTERPDECI_HOLD) deci1(clk, rst, en3360, en480, fil3360, dec480);
    assign out = dec480;
endmodule
