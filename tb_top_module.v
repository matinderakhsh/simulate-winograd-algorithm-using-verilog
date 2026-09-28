`timescale 1ns/1ps

module tb_top_module();

    parameter WIDTH = 12;

    reg clk, rst, start;

    // Input tile X (4×4)
    reg signed [WIDTH-1:0]
        X11, X12, X13, X14,
        X21, X22, X23, X24,
        X31, X32, X33, X34,
        X41, X42, X43, X44;

    // Kernel W (3×3)
    reg signed [WIDTH-1:0]
        W11, W12, W13,
        W21, W22, W23,
        W31, W32, W33;

    // Outputs
    wire signed [WIDTH-1:0] Y11, Y12, Y21, Y22;
    wire done;

    // Helper function: Q3.8 encoding
    function signed [WIDTH-1:0] Q;
        input real x;
        begin
            Q = $rtoi(x * 256.0); // convert float ? fixed Q3.8
        end
    endfunction

    // Instantiate DUT
    top_module #(.WIDTH(WIDTH)) DUT (
        .clk(clk),
        .rst(rst),
        .start(start),

        .X11(X11), .X12(X12), .X13(X13), .X14(X14),
        .X21(X21), .X22(X22), .X23(X23), .X24(X24),
        .X31(X31), .X32(X32), .X33(X33), .X34(X34),
        .X41(X41), .X42(X42), .X43(X43), .X44(X44),

        .W11(W11), .W12(W12), .W13(W13),
        .W21(W21), .W22(W22), .W23(W23),
        .W31(W31), .W32(W32), .W33(W33),

        .Y11(Y11), .Y12(Y12),
        .Y21(Y21), .Y22(Y22),

        .done(done)
    );

    ////////////////////////////////////////////////////////
    // Clock generator
    ////////////////////////////////////////////////////////
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz
    end

    ////////////////////////////////////////////////////////
    // Test
    ////////////////////////////////////////////////////////
    initial begin
        $display("\n--- Winograd Testbench (Q3.8 Inputs) ---\n");

        rst = 1;
        start = 0;

        // Zero all inputs
        X11=0; X12=0; X13=0; X14=0;
        X21=0; X22=0; X23=0; X24=0;
        X31=0; X32=0; X33=0; X34=0;
        X41=0; X42=0; X43=0; X44=0;
        W11=0; W12=0; W13=0;
        W21=0; W22=0; W23=0;
        W31=0; W32=0; W33=0;

        #20 rst = 0;

        ////////////////////////////////////////////////////////////
        // Test Case 1 (real-value friendly)
        ////////////////////////////////////////////////////////////
        $display("Applying test input (Q3.8 converted)...");

        // Input tile (4×4) real values
        X11 = Q(1.0);  X12 = Q(2.0);  X13 = Q(3.0);  X14 = Q(4.0);
        X21 = Q(5.0);  X22 = Q(6.0);  X23 = Q(7.0);  X24 = Q(1.0);
        X31 = Q(2.0);  X32 = Q(3.0);  X33 = Q(4.0);  X34 = Q(5.0);
        X41 = Q(6.0);  X42 = Q(1.0);  X43 = Q(5.0);  X44 = Q(7.0);

        // Kernel (3×3)
        W11 = Q(1.0); W12 = Q(0.0); W13 = Q(1.0);
        W21 = Q(0.0); W22 = Q(1.0); W23 = Q(0.0);
        W31 = Q(1.0); W32 = Q(0.0); W33 = Q(1.0);

        // Start
        #10 start = 1;
        #10 start = 0;

        // Wait
        wait(done);

        #5;
        $display("\n--- Output Y (Q3.8 raw) ---");
        $display("Y11 = %d", Y11);
        $display("Y12 = %d", Y12);
        $display("Y21 = %d", Y21);
        $display("Y22 = %d", Y22);

        // Convert back to float for readability
        $display("\n--- Output Y (real values) ---");
        $display("Y11 = %f", Y11 / 256.0);
        $display("Y12 = %f", Y12 / 256.0);
        $display("Y21 = %f", Y21 / 256.0);
        $display("Y22 = %f", Y22 / 256.0);

        $display("\n---------------------------\n");

        $finish;
    end

endmodule
