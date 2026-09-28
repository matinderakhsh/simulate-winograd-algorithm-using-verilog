module output_transform #(
    parameter WIDTH = 12
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  done,

    // M 4×4
    input signed [WIDTH-1:0] M11, M12, M13, M14,
                             M21, M22, M23, M24,
                             M31, M32, M33, M34,
                             M41, M42, M43, M44,

    // At 2×4
    input signed [WIDTH-1:0] At11, At12, At13, At14,
                             At21, At22, At23, At24,

    // Y 2×2
    output reg signed [WIDTH-1:0] Y11, Y12,
                                  Y21, Y22
);

    //----------------------------------------------------------
    // Stage valid flags
    //----------------------------------------------------------
    reg stage1_valid;
    reg stage2_valid;
    reg stage3_valid;

    always @(posedge clk) begin
        if(rst) begin
            stage1_valid <= 0;
            stage2_valid <= 0;
            stage3_valid <= 0;
            done <= 0;
        end else begin
            stage1_valid <= start;
            stage2_valid <= stage1_valid;
            stage3_valid <= stage2_valid;
            done <= stage3_valid;
        end
    end

    //----------------------------------------------------------
    // Stage 1: Ttmp = At × M      (Q8.16)
    //----------------------------------------------------------
    reg signed [2*WIDTH+1:0] T11_tmp, T12_tmp, T13_tmp, T14_tmp;
    reg signed [2*WIDTH+1:0] T21_tmp, T22_tmp, T23_tmp, T24_tmp;

    always @(posedge clk) begin
        if(rst) begin
            T11_tmp<=0; T12_tmp<=0; T13_tmp<=0; T14_tmp<=0;
            T21_tmp<=0; T22_tmp<=0; T23_tmp<=0; T24_tmp<=0;
        end else if(start) begin
            T11_tmp <= At11*M11 + At12*M21 + At13*M31 + At14*M41;
            T12_tmp <= At11*M12 + At12*M22 + At13*M32 + At14*M42;
            T13_tmp <= At11*M13 + At12*M23 + At13*M33 + At14*M43;
            T14_tmp <= At11*M14 + At12*M24 + At13*M34 + At14*M44;

            T21_tmp <= At21*M11 + At22*M21 + At23*M31 + At24*M41;
            T22_tmp <= At21*M12 + At22*M22 + At23*M32 + At24*M42;
            T23_tmp <= At21*M13 + At22*M23 + At23*M33 + At24*M43;
            T24_tmp <= At21*M14 + At22*M24 + At23*M34 + At24*M44;
        end
    end

    //----------------------------------------------------------
    // Stage 2: scale Ttmp ? T     (Q8.16 ? Q4.8)
    //----------------------------------------------------------
    reg signed [WIDTH-1:0] T11, T12, T13, T14;
    reg signed [WIDTH-1:0] T21, T22, T23, T24;

    always @(posedge clk) begin
        if(rst) begin
            T11<=0; T12<=0; T13<=0; T14<=0;
            T21<=0; T22<=0; T23<=0; T24<=0;
        end else if(stage1_valid) begin
            T11 <= {T11_tmp[25], T11_tmp[22:12]};
            T12 <= {T12_tmp[25], T12_tmp[22:12]};
            T13 <= {T13_tmp[25], T13_tmp[22:12]};
            T14 <= {T14_tmp[25], T14_tmp[22:12]};

            T21 <= {T21_tmp[25], T21_tmp[22:12]};
            T22 <= {T22_tmp[25], T22_tmp[22:12]};
            T23 <= {T23_tmp[25], T23_tmp[22:12]};
            T24 <= {T24_tmp[25], T24_tmp[22:12]};
        end
    end

    //----------------------------------------------------------
    // Stage 3: Ytmp = T × At?     (Q8.16)
    //----------------------------------------------------------
    reg signed [2*WIDTH+1:0] Y11_tmp, Y12_tmp;
    reg signed [2*WIDTH+1:0] Y21_tmp, Y22_tmp;

    always @(posedge clk) begin
        if(rst) begin
            Y11_tmp<=0; Y12_tmp<=0;
            Y21_tmp<=0; Y22_tmp<=0;
        end else if(stage2_valid) begin
            Y11_tmp <= T11*At11 + T12*At12 + T13*At13 + T14*At14;
            Y12_tmp <= T11*At21 + T12*At22 + T13*At23 + T14*At24;

            Y21_tmp <= T21*At11 + T22*At12 + T23*At13 + T24*At14;
            Y22_tmp <= T21*At21 + T22*At22 + T23*At23 + T24*At24;
        end
    end

    //----------------------------------------------------------
    // Final quantization ? Y    (Q8.16 ? Q4.8)
    //----------------------------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            Y11<=0; Y12<=0;
            Y21<=0; Y22<=0;
        end else if(stage3_valid) begin
            Y11 <= {Y11_tmp[25], Y11_tmp[22:12]};
            Y12 <= {Y12_tmp[25], Y12_tmp[22:12]};
            Y21 <= {Y21_tmp[25], Y21_tmp[22:12]};
            Y22 <= {Y22_tmp[25], Y22_tmp[22:12]};
        end
    end

endmodule
