module winograd_constants #(
    parameter WIDTH = 12   // s3.8 format
)(
    // Bt matrix
    output reg signed [WIDTH-1:0] Bt11, Bt12, Bt13, Bt14,
                                  Bt21, Bt22, Bt23, Bt24,
                                  Bt31, Bt32, Bt33, Bt34,
                                  Bt41, Bt42, Bt43, Bt44,

    // G matrix
    output reg signed [WIDTH-1:0] G11, G12, G13,
                                  G21, G22, G23,
                                  G31, G32, G33,
                                  G41, G42, G43,

    // At matrix
    output reg signed [WIDTH-1:0] At11, At12, At13, At14,
                                  At21, At22, At23, At24
);

    // Fixed-point constants in HEX (s3.8)
    localparam signed [WIDTH-1:0] FP_1     = 12'h100; // +1.0
    localparam signed [WIDTH-1:0] FP_n1    = 12'hF00; // -1.0
    localparam signed [WIDTH-1:0] FP_HALF  = 12'h080; // +0.5
    localparam signed [WIDTH-1:0] FP_nHALF = 12'hF80; // -0.5
    localparam signed [WIDTH-1:0] FP_0     = 12'h000; // 0.0

    initial begin
        // Bt rows
        Bt11 = FP_1;   Bt12 = FP_0;    Bt13 = FP_n1;   Bt14 = FP_0;
        Bt21 = FP_0;   Bt22 = FP_1;    Bt23 = FP_1;    Bt24 = FP_0;
        Bt31 = FP_0;   Bt32 = FP_n1;   Bt33 = FP_1;    Bt34 = FP_0;
        Bt41 = FP_0;   Bt42 = FP_1;    Bt43 = FP_0;    Bt44 = FP_n1;

        // G rows
        G11 = FP_1;      G12 = FP_0;       G13 = FP_0;
        G21 = FP_HALF;   G22 = FP_HALF;    G23 = FP_HALF;
        G31 = FP_HALF;   G32 = FP_nHALF;   G33 = FP_HALF;
        G41 = FP_0;      G42 = FP_0;       G43 = FP_1;

        // At rows
        At11 = FP_1;   At12 = FP_1;    At13 = FP_1;    At14 = FP_0;
        At21 = FP_0;   At22 = FP_1;    At23 = FP_n1;   At24 = FP_n1;
    end

endmodule
