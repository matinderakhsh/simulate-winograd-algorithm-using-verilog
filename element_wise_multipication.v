module hadamard_product #(
    parameter WIDTH = 12
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  done,

    // U matrix
    input signed [WIDTH-1:0] U11,U12,U13,U14,
                             U21,U22,U23,U24,
                             U31,U32,U33,U34,
                             U41,U42,U43,U44,

    // V matrix
    input signed [WIDTH-1:0] V11,V12,V13,V14,
                             V21,V22,V23,V24,
                             V31,V32,V33,V34,
                             V41,V42,V43,V44,

    // Output M
    output reg signed [WIDTH-1:0] M11,M12,M13,M14,
                                  M21,M22,M23,M24,
                                  M31,M32,M33,M34,
                                  M41,M42,M43,M44
);

    //----------------------------------------------------------
    // Stage1 registers (Q8.16)
    //----------------------------------------------------------
    reg signed [2*WIDTH-1:0] P11,P12,P13,P14;
    reg signed [2*WIDTH-1:0] P21,P22,P23,P24;
    reg signed [2*WIDTH-1:0] P31,P32,P33,P34;
    reg signed [2*WIDTH-1:0] P41,P42,P43,P44;

    reg stage1_valid;
    reg stage2_valid;

    //----------------------------------------------------------
    // Stage1: element-wise multiply
    //----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 0;
        end else if (start) begin
            stage1_valid <= 1;

            P11 <= U11 * V11;
            P12 <= U12 * V12;
            P13 <= U13 * V13;
            P14 <= U14 * V14;

            P21 <= U21 * V21;
            P22 <= U22 * V22;
            P23 <= U23 * V23;
            P24 <= U24 * V24;

            P31 <= U31 * V31;
            P32 <= U32 * V32;
            P33 <= U33 * V33;
            P34 <= U34 * V34;

            P41 <= U41 * V41;
            P42 <= U42 * V42;
            P43 <= U43 * V43;
            P44 <= U44 * V44;
        end
    end

    //----------------------------------------------------------
    // Stage2: scaling (same quantization style)
    //----------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 0;
            done <= 0;
        end else if (stage1_valid) begin
            stage2_valid <= stage1_valid;
            done <= stage1_valid;

			M11 <= {P11[23], P11[20:10]};
			M12 <= {P12[23], P12[20:10]};
			M13 <= {P13[23], P13[20:10]};
			M14 <= {P14[23], P14[20:10]};

			M21 <= {P21[23], P21[20:10]};
			M22 <= {P22[23], P22[20:10]};
			M23 <= {P23[23], P23[20:10]};
			M24 <= {P24[23], P24[20:10]};

			M31 <= {P31[23], P31[20:10]};
			M32 <= {P32[23], P32[20:10]};
			M33 <= {P33[23], P33[20:10]};
			M34 <= {P34[23], P34[20:10]};

			M41 <= {P41[23], P41[20:10]};
			M42 <= {P42[23], P42[20:10]};
			M43 <= {P43[23], P43[20:10]};
			M44 <= {P44[23], P44[20:10]};

        end
    end

endmodule
