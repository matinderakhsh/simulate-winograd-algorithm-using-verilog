module top_module #(parameter WIDTH = 12)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    // Input tile (4×4)
    input signed [WIDTH-1:0] X11, X12, X13, X14,
                             X21, X22, X23, X24,
                             X31, X32, X33, X34,
                             X41, X42, X43, X44,

    // Kernel (3×3)
    input signed [WIDTH-1:0] W11, W12, W13,
                             W21, W22, W23,
                             W31, W32, W33,

    // Output 2×2 tile Y
    output wire signed [WIDTH-1:0] Y11, Y12,
                                   Y21, Y22,

    output reg done
);

    ///////////////////////////////////////////////////////////////////////
    // Winograd constant module
    ///////////////////////////////////////////////////////////////////////
    wire signed [WIDTH-1:0]
        Bt11,Bt12,Bt13,Bt14,
        Bt21,Bt22,Bt23,Bt24,
        Bt31,Bt32,Bt33,Bt34,
        Bt41,Bt42,Bt43,Bt44;

    wire signed [WIDTH-1:0]
        G11,G12,G13,
        G21,G22,G23,
        G31,G32,G33,
        G41,G42,G43;

    wire signed [WIDTH-1:0]
        At11,At12,At13,At14,
        At21,At22,At23,At24;

    winograd_constants #(.WIDTH(WIDTH)) CONST (
        .Bt11(Bt11), .Bt12(Bt12), .Bt13(Bt13), .Bt14(Bt14),
        .Bt21(Bt21), .Bt22(Bt22), .Bt23(Bt23), .Bt24(Bt24),
        .Bt31(Bt31), .Bt32(Bt32), .Bt33(Bt33), .Bt34(Bt34),
        .Bt41(Bt41), .Bt42(Bt42), .Bt43(Bt43), .Bt44(Bt44),

        .G11(G11), .G12(G12), .G13(G13),
        .G21(G21), .G22(G22), .G23(G23),
        .G31(G31), .G32(G32), .G33(G33),
        .G41(G41), .G42(G42), .G43(G43),

        .At11(At11), .At12(At12), .At13(At13), .At14(At14),
        .At21(At21), .At22(At22), .At23(At23), .At24(At24)
    );


    ///////////////////////////////////////////////////////////////////////
    // Intermediate Mats: V , U , M
    ///////////////////////////////////////////////////////////////////////
    wire signed [WIDTH-1:0]
        V11,V12,V13,V14,
        V21,V22,V23,V24,
        V31,V32,V33,V34,
        V41,V42,V43,V44;

    wire signed [WIDTH-1:0]
        U11,U12,U13,U14,
        U21,U22,U23,U24,
        U31,U32,U33,U34,
        U41,U42,U43,U44;

    wire signed [WIDTH-1:0]
        M11,M12,M13,M14,
        M21,M22,M23,M24,
        M31,M32,M33,M34,
        M41,M42,M43,M44;


    ///////////////////////////////////////////////////////////////////////
    // Control signals (1-cycle pulses)
    ///////////////////////////////////////////////////////////////////////
    reg start_input_t;
    reg start_weight_t;
    reg start_hadamard;
    reg start_output_t;

    wire done_input_t;
    wire done_weight_t;
    wire done_hadamard;
    wire done_output_t;


    ///////////////////////////////////////////////////////////////////////
    // Stage 1: Input Transform
    ///////////////////////////////////////////////////////////////////////
    input_transform #(.WIDTH(WIDTH)) INPUT_T (
        .clk(clk), .rst(rst),
        .start(start_input_t),
        .done(done_input_t),

        .B11(Bt11), .B12(Bt12), .B13(Bt13), .B14(Bt14),
        .B21(Bt21), .B22(Bt22), .B23(Bt23), .B24(Bt24),
        .B31(Bt31), .B32(Bt32), .B33(Bt33), .B34(Bt34),
        .B41(Bt41), .B42(Bt42), .B43(Bt43), .B44(Bt44),

        .X11(X11), .X12(X12), .X13(X13), .X14(X14),
        .X21(X21), .X22(X22), .X23(X23), .X24(X24),
        .X31(X31), .X32(X32), .X33(X33), .X34(X34),
        .X41(X41), .X42(X42), .X43(X43), .X44(X44),

        .V11(V11), .V12(V12), .V13(V13), .V14(V14),
        .V21(V21), .V22(V22), .V23(V23), .V24(V24),
        .V31(V31), .V32(V32), .V33(V33), .V34(V34),
        .V41(V41), .V42(V42), .V43(V43), .V44(V44)
    );


    ///////////////////////////////////////////////////////////////////////
    // Stage 2: Weight Transform
    ///////////////////////////////////////////////////////////////////////
    transform_U #(.WIDTH(WIDTH)) WEIGHT_T (
        .clk(clk), .rst(rst),
        .start(start_weight_t),
        .done(done_weight_t),

        .G11(G11), .G12(G12), .G13(G13),
        .G21(G21), .G22(G22), .G23(G23),
        .G31(G31), .G32(G32), .G33(G33),
        .G41(G41), .G42(G42), .G43(G43),

        .W11(W11), .W12(W12), .W13(W13),
        .W21(W21), .W22(W22), .W23(W23),
        .W31(W31), .W32(W32), .W33(W33),

        .U11(U11), .U12(U12), .U13(U13), .U14(U14),
        .U21(U21), .U22(U22), .U23(U23), .U24(U24),
        .U31(U31), .U32(U32), .U33(U33), .U34(U34),
        .U41(U41), .U42(U42), .U43(U43), .U44(U44)
    );


    ///////////////////////////////////////////////////////////////////////
    // Stage 3: Hadamard Product
    ///////////////////////////////////////////////////////////////////////
    hadamard_product #(.WIDTH(WIDTH)) HADAMARD (
        .clk(clk), .rst(rst),
        .start(start_hadamard),
        .done(done_hadamard),

        .U11(U11), .U12(U12), .U13(U13), .U14(U14),
        .U21(U21), .U22(U22), .U23(U23), .U24(U24),
        .U31(U31), .U32(U32), .U33(U33), .U34(U34),
        .U41(U41), .U42(U42), .U43(U43), .U44(U44),

        .V11(V11), .V12(V12), .V13(V13), .V14(V14),
        .V21(V21), .V22(V22), .V23(V23), .V24(V24),
        .V31(V31), .V32(V32), .V33(V33), .V34(V34),
        .V41(V41), .V42(V42), .V43(V43), .V44(V44),

        .M11(M11), .M12(M12), .M13(M13), .M14(M14),
        .M21(M21), .M22(M22), .M23(M23), .M24(M24),
        .M31(M31), .M32(M32), .M33(M33), .M34(M34),
        .M41(M41), .M42(M42), .M43(M43), .M44(M44)
    );


    ///////////////////////////////////////////////////////////////////////
    // Stage 4: Output Transform (PIPELINED)
    ///////////////////////////////////////////////////////////////////////
    output_transform #(.WIDTH(WIDTH)) OUTPUT_T (
        .clk(clk), .rst(rst),
        .start(start_output_t),
        .done(done_output_t),

        .M11(M11), .M12(M12), .M13(M13), .M14(M14),
        .M21(M21), .M22(M22), .M23(M23), .M24(M24),
        .M31(M31), .M32(M32), .M33(M33), .M34(M34),
        .M41(M41), .M42(M42), .M43(M43), .M44(M44),

        .At11(At11), .At12(At12), .At13(At13), .At14(At14),
        .At21(At21), .At22(At22), .At23(At23), .At24(At24),

        .Y11(Y11), .Y12(Y12),
        .Y21(Y21), .Y22(Y22)
    );


    ///////////////////////////////////////////////////////////////////////
    // Finite State Machine
    ///////////////////////////////////////////////////////////////////////
    reg [2:0] state;
    localparam S_IDLE   = 3'd0,
               S_INPUT  = 3'd1,
               S_WEIGHT = 3'd2,
               S_HADAM  = 3'd3,
               S_OUTPUT = 3'd4,
               S_FINISH = 3'd5;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 0;
            start_input_t   <= 0;
            start_weight_t  <= 0;
            start_hadamard  <= 0;
            start_output_t  <= 0;
        end else begin
            case (state)

                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        start_input_t <= 1;
                        state <= S_INPUT;
                    end
                end

                S_INPUT: begin
                    start_input_t <= 0;
                    if (done_input_t) begin
                        start_weight_t <= 1;
                        state <= S_WEIGHT;
                    end
                end

                S_WEIGHT: begin
                    start_weight_t <= 0;
                    if (done_weight_t) begin
                        start_hadamard <= 1;
                        state <= S_HADAM;
                    end
                end

                S_HADAM: begin
                    start_hadamard <= 0;
                    if (done_hadamard) begin
                        start_output_t <= 1;
                        state <= S_OUTPUT;
                    end
                end

                S_OUTPUT: begin
                    start_output_t <= 0;
                    if (done_output_t) begin
                        state <= S_FINISH;
                    end
                end

                S_FINISH: begin
                    done <= 1;
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule
