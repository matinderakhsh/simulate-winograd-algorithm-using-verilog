module input_transform #(
    parameter WIDTH = 12
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,

    input  wire signed [WIDTH-1:0]  B11, B12, B13, B14,
    input  wire signed [WIDTH-1:0]  B21, B22, B23, B24,
    input  wire signed [WIDTH-1:0]  B31, B32, B33, B34,
    input  wire signed [WIDTH-1:0]  B41, B42, B43, B44,

    input  wire signed [WIDTH-1:0]  X11, X12, X13, X14,
    input  wire signed [WIDTH-1:0]  X21, X22, X23, X24,
    input  wire signed [WIDTH-1:0]  X31, X32, X33, X34,
    input  wire signed [WIDTH-1:0]  X41, X42, X43, X44,

    output reg  [WIDTH-1:0]  V11, V12, V13, V14,
    output reg  [WIDTH-1:0]  V21, V22, V23, V24,
    output reg  [WIDTH-1:0]  V31, V32, V33, V34,
    output reg  [WIDTH-1:0]  V41, V42, V43, V44,

    output reg done
);

    // Stage 1
    reg signed [2*WIDTH+1:0] BX1_11, BX1_12, BX1_13, BX1_14;
    reg signed [2*WIDTH+1:0] BX1_21, BX1_22, BX1_23, BX1_24;
    reg signed [2*WIDTH+1:0] BX1_31, BX1_32, BX1_33, BX1_34;
    reg signed [2*WIDTH+1:0] BX1_41, BX1_42, BX1_43, BX1_44;

    // Stage1 ? Stage2
    reg signed [WIDTH-1:0] BX2_11, BX2_12, BX2_13, BX2_14;
    reg signed [WIDTH-1:0] BX2_21, BX2_22, BX2_23, BX2_24;
    reg signed [WIDTH-1:0] BX2_31, BX2_32, BX2_33, BX2_34;
    reg signed [WIDTH-1:0] BX2_41, BX2_42, BX2_43, BX2_44;

    // Stage2
    reg signed [2*WIDTH+1:0] VV11, VV12, VV13, VV14;
    reg signed [2*WIDTH+1:0] VV21, VV22, VV23, VV24;
    reg signed [2*WIDTH+1:0] VV31, VV32, VV33, VV34;
    reg signed [2*WIDTH+1:0] VV41, VV42, VV43, VV44;

    reg stage1_valid, stage2_valid, stage3_valid;
    //----------------------------------------------------------
    // Stage 1: compute BX1 = B * X   (Q8.16)
    //----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 0;
        end else if (start) begin
            stage1_valid <= 1;

            BX1_11 <= B11*X11 + B12*X21 + B13*X31 + B14*X41;
            BX1_12 <= B11*X12 + B12*X22 + B13*X32 + B14*X42;
            BX1_13 <= B11*X13 + B12*X23 + B13*X33 + B14*X43;
            BX1_14 <= B11*X14 + B12*X24 + B13*X34 + B14*X44;

            BX1_21 <= B21*X11 + B22*X21 + B23*X31 + B24*X41;
            BX1_22 <= B21*X12 + B22*X22 + B23*X32 + B24*X42;
            BX1_23 <= B21*X13 + B22*X23 + B23*X33 + B24*X43;
            BX1_24 <= B21*X14 + B22*X24 + B23*X34 + B24*X44;

            BX1_31 <= B31*X11 + B32*X21 + B33*X31 + B34*X41;
            BX1_32 <= B31*X12 + B32*X22 + B33*X32 + B34*X42;
            BX1_33 <= B31*X13 + B32*X23 + B33*X33 + B34*X43;
            BX1_34 <= B31*X14 + B32*X24 + B33*X34 + B34*X44;

            BX1_41 <= B41*X11 + B42*X21 + B43*X31 + B44*X41;
            BX1_42 <= B41*X12 + B42*X22 + B43*X32 + B44*X42;
            BX1_43 <= B41*X13 + B42*X23 + B43*X33 + B44*X43;
            BX1_44 <= B41*X14 + B42*X24 + B43*X34 + B44*X44;
        end
    end

    //----------------------------------------------------------
    // Scaling: convert Q8.16 ? Q4.8 by >> 14
    //----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 0;
        end else if(stage1_valid) begin
            stage2_valid <= stage1_valid;

            BX2_11 <= {BX1_11[25],BX1_11[22:12]};
			BX2_12 <= {BX1_12[25],BX1_12[22:12]};
			BX2_13 <= {BX1_13[25],BX1_13[22:12]};
			BX2_14 <= {BX1_14[25],BX1_14[22:12]};

			BX2_21 <= {BX1_21[25],BX1_21[22:12]};
			BX2_22 <= {BX1_22[25],BX1_22[22:12]};
			BX2_23 <= {BX1_23[25],BX1_23[22:12]};
			BX2_24 <= {BX1_24[25],BX1_24[22:12]};

			BX2_31 <= {BX1_31[25],BX1_31[22:12]};
			BX2_32 <= {BX1_32[25],BX1_32[22:12]};
			BX2_33 <= {BX1_33[25],BX1_33[22:12]};
			BX2_34 <= {BX1_34[25],BX1_34[22:12]};

			BX2_41 <= {BX1_41[25],BX1_41[22:12]};
			BX2_42 <= {BX1_42[25],BX1_42[22:12]};
			BX2_43 <= {BX1_43[25],BX1_43[22:12]};
			BX2_44 <= {BX1_44[25],BX1_44[22:12]};

        end
    end

    //----------------------------------------------------------
    // Stage 2: V = BX2 * B    (Q4.8 × Q4.8 = Q8.16 ? scale >>8)
    //----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 0;
        end else if(stage2_valid)begin
            stage3_valid <= stage2_valid;

             VV11 <= (BX2_11*B11 + BX2_12*B21 + BX2_13*B31 + BX2_14*B41) ;
             VV12 <= (BX2_11*B12 + BX2_12*B22 + BX2_13*B32 + BX2_14*B42) ;
             VV13 <= (BX2_11*B13 + BX2_12*B23 + BX2_13*B33 + BX2_14*B43) ;
             VV14 <= (BX2_11*B14 + BX2_12*B24 + BX2_13*B34 + BX2_14*B44) ;

             VV21 <= (BX2_21*B11 + BX2_22*B21 + BX2_23*B31 + BX2_24*B41) ;
             VV22 <= (BX2_21*B12 + BX2_22*B22 + BX2_23*B32 + BX2_24*B42) ;
             VV23 <= (BX2_21*B13 + BX2_22*B23 + BX2_23*B33 + BX2_24*B43) ;
             VV24 <= (BX2_21*B14 + BX2_22*B24 + BX2_23*B34 + BX2_24*B44) ;

             VV31 <= (BX2_31*B11 + BX2_32*B21 + BX2_33*B31 + BX2_34*B41) ;
             VV32 <= (BX2_31*B12 + BX2_32*B22 + BX2_33*B32 + BX2_34*B42) ;
             VV33 <= (BX2_31*B13 + BX2_32*B23 + BX2_33*B33 + BX2_34*B43) ;
             VV34 <= (BX2_31*B14 + BX2_32*B24 + BX2_33*B34 + BX2_34*B44) ;

             VV41 <= (BX2_41*B11 + BX2_42*B21 + BX2_43*B31 + BX2_44*B41) ;
             VV42 <= (BX2_41*B12 + BX2_42*B22 + BX2_43*B32 + BX2_44*B42) ;
             VV43 <= (BX2_41*B13 + BX2_42*B23 + BX2_43*B33 + BX2_44*B43) ;
             VV44 <= (BX2_41*B14 + BX2_42*B24 + BX2_43*B34 + BX2_44*B44) ;
        end
    end
	always @(posedge clk) begin
        if (rst) begin
            done <= 0;
        end else if(stage3_valid) begin
            done <= stage3_valid;

			V11 <= {VV11[25], VV11[22:12]};
			V12 <= {VV12[25], VV12[22:12]};
			V13 <= {VV13[25], VV13[22:12]};
			V14 <= {VV14[25], VV14[22:12]};

			V21 <= {VV21[25], VV21[22:12]};
			V22 <= {VV22[25], VV22[22:12]};
			V23 <= {VV23[25], VV23[22:12]};
			V24 <= {VV24[25], VV24[22:12]};

			V31 <= {VV31[25], VV31[22:12]};
			V32 <= {VV32[25], VV32[22:12]};
			V33 <= {VV33[25], VV33[22:12]};
			V34 <= {VV34[25], VV34[22:12]};

			V41 <= {VV41[25], VV41[22:12]};
			V42 <= {VV42[25], VV42[22:12]};
			V43 <= {VV43[25], VV43[22:12]};
			V44 <= {VV44[25], VV44[22:12]};

        end
    end


endmodule
