module transform_U #(
    parameter WIDTH = 12
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  done,

    // G 4×3
    input signed [WIDTH-1:0] G11, G12, G13,
                             G21, G22, G23,
                             G31, G32, G33,
                             G41, G42, G43,

    // W 3×3
    input signed [WIDTH-1:0] W11, W12, W13,
                             W21, W22, W23,
                             W31, W32, W33,

    // U 4×4 output
    output reg signed [WIDTH-1:0] U11, U12, U13, U14,
                                  U21, U22, U23, U24,
                                  U31, U32, U33, U34,
                                  U41, U42, U43, U44
);

    //----------------------------------------------------------
    // Stage 1 registers: GW_tmp = G × W     (Q8.16)
    //----------------------------------------------------------
    reg signed [2*WIDTH:0] GW1_1, GW1_2, GW1_3;
    reg signed [2*WIDTH:0] GW2_1, GW2_2, GW2_3;
    reg signed [2*WIDTH:0] GW3_1, GW3_2, GW3_3;
    reg signed [2*WIDTH:0] GW4_1, GW4_2, GW4_3;

    reg stage1_valid, stage2_valid, stage3_valid;

    //----------------------------------------------------------
    // Stage 1: Compute GW_tmp = G × W   (Q8.16)
    //----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 0;
        end else if (start) begin
            stage1_valid <= 1;

            GW1_1 <= G11*W11 + G12*W21 + G13*W31;
            GW1_2 <= G11*W12 + G12*W22 + G13*W32;
            GW1_3 <= G11*W13 + G12*W23 + G13*W33;

            GW2_1 <= G21*W11 + G22*W21 + G23*W31;
            GW2_2 <= G21*W12 + G22*W22 + G23*W32;
            GW2_3 <= G21*W13 + G22*W23 + G23*W33;

            GW3_1 <= G31*W11 + G32*W21 + G33*W31;
            GW3_2 <= G31*W12 + G32*W22 + G33*W32;
            GW3_3 <= G31*W13 + G32*W23 + G33*W33;

            GW4_1 <= G41*W11 + G42*W21 + G43*W31;
            GW4_2 <= G41*W12 + G42*W22 + G43*W32;
            GW4_3 <= G41*W13 + G42*W23 + G43*W33;
        end
    end

    //----------------------------------------------------------
    // Stage1 ? Stage2 scaling: Q8.16 ? Q4.8   >>14
    //----------------------------------------------------------
    reg signed [WIDTH-1:0] GW2_11, GW2_12, GW2_13;
    reg signed [WIDTH-1:0] GW2_21, GW2_22, GW2_23;
    reg signed [WIDTH-1:0] GW2_31, GW2_32, GW2_33;
    reg signed [WIDTH-1:0] GW2_41, GW2_42, GW2_43;

    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 0;
        end else if (stage1_valid) begin
            stage2_valid <= stage1_valid;

            GW2_11 <= {GW1_1[24], GW1_1[22:12]};
            GW2_12 <= {GW1_2[24], GW1_2[22:12]};
            GW2_13 <= {GW1_3[24], GW1_3[22:12]};

            GW2_21 <= {GW2_1[24], GW2_1[22:12]};
            GW2_22 <= {GW2_2[24], GW2_2[22:12]};
            GW2_23 <= {GW2_3[24], GW2_3[22:12]};

            GW2_31 <= {GW3_1[24], GW3_1[22:12]};
            GW2_32 <= {GW3_2[24], GW3_2[22:12]};
            GW2_33 <= {GW3_3[24], GW3_3[22:12]};

            GW2_41 <= {GW4_1[24], GW4_1[22:12]};
            GW2_42 <= {GW4_2[24], GW4_2[22:12]};
            GW2_43 <= {GW4_3[24], GW4_3[22:12]};
        end
    end

    //----------------------------------------------------------
    // Stage 2: compute U_tmp = GW2 × G?    (Q4.8 × Q4.8 ? Q8.16)
    //----------------------------------------------------------
    reg signed [2*WIDTH:0] Utmp11, Utmp12, Utmp13, Utmp14;
    reg signed [2*WIDTH:0] Utmp21, Utmp22, Utmp23, Utmp24;
    reg signed [2*WIDTH:0] Utmp31, Utmp32, Utmp33, Utmp34;
    reg signed [2*WIDTH:0] Utmp41, Utmp42, Utmp43, Utmp44;

    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 0;
        end else if (stage2_valid) begin
            stage3_valid <= stage2_valid;

            // row1
            Utmp11 <= GW2_11*G11 + GW2_12*G12 + GW2_13*G13;
            Utmp12 <= GW2_11*G21 + GW2_12*G22 + GW2_13*G23;
            Utmp13 <= GW2_11*G31 + GW2_12*G32 + GW2_13*G33;
            Utmp14 <= GW2_11*G41 + GW2_12*G42 + GW2_13*G43;

            // row2
            Utmp21 <= GW2_21*G11 + GW2_22*G12 + GW2_23*G13;
            Utmp22 <= GW2_21*G21 + GW2_22*G22 + GW2_23*G23;
            Utmp23 <= GW2_21*G31 + GW2_22*G32 + GW2_23*G33;
            Utmp24 <= GW2_21*G41 + GW2_22*G42 + GW2_23*G43;

            // row3
            Utmp31 <= GW2_31*G11 + GW2_32*G12 + GW2_33*G13;
            Utmp32 <= GW2_31*G21 + GW2_32*G22 + GW2_33*G23;
            Utmp33 <= GW2_31*G31 + GW2_32*G32 + GW2_33*G33;
            Utmp34 <= GW2_31*G41 + GW2_32*G42 + GW2_33*G43;

            // row4
            Utmp41 <= GW2_41*G11 + GW2_42*G12 + GW2_43*G13;
            Utmp42 <= GW2_41*G21 + GW2_42*G22 + GW2_43*G23;
            Utmp43 <= GW2_41*G31 + GW2_42*G32 + GW2_43*G33;
            Utmp44 <= GW2_41*G41 + GW2_42*G42 + GW2_43*G43;
        end
    end

    //----------------------------------------------------------
    // Stage 3: scaling Utmp ? U    (same quantization as module1)
    //----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
        end else if (stage3_valid) begin
            done <= stage3_valid;

            U11 <= {Utmp11[24], Utmp11[22:12]};
            U12 <= {Utmp12[24], Utmp12[22:12]};
            U13 <= {Utmp13[24], Utmp13[22:12]};
            U14 <= {Utmp14[24], Utmp14[22:12]};

            U21 <= {Utmp21[24], Utmp21[22:12]};
            U22 <= {Utmp22[24], Utmp22[22:12]};
            U23 <= {Utmp23[24], Utmp23[22:12]};
            U24 <= {Utmp24[24], Utmp24[22:12]};

            U31 <= {Utmp31[24], Utmp31[22:12]};
            U32 <= {Utmp32[24], Utmp32[22:12]};
            U33 <= {Utmp33[24], Utmp33[22:12]};
            U34 <= {Utmp34[24], Utmp34[22:12]};

            U41 <= {Utmp41[24], Utmp41[22:12]};
            U42 <= {Utmp42[24], Utmp42[22:12]};
            U43 <= {Utmp43[24], Utmp43[22:12]};
            U44 <= {Utmp44[24], Utmp44[22:12]};
        end
    end

endmodule
