// =============================================================================
//  tb_branch_predictor.v  —  Testbench for the 2-bit Branch Predictor
//  Repository: rtl-to-gdsii-flow-v1
//  Version:    1.0
//  Author:     Surya Venu Teja B
// =============================================================================
//
//  PURPOSE
//  -------
//  This testbench drives the branch_predictor module with a set of test vectors
//  and checks that the output 'prediction' matches the expected value for every
//  input combination. It covers all state transitions in the FSM.
//
//  HOW TO RUN
//  ----------
//  From the repository root directory:
//      xrun example_design/rtl/branch_predictor.v \
//           example_design/rtl/tb_branch_predictor.v \
//           -timescale 1ns/1ps
//
//  IMPORTANT: Both files must be listed on the command line.
//  If you only pass the testbench, xrun cannot find the branch_predictor
//  module and will give "Module not found" error.
//
//  WHAT TO CHECK IN THE OUTPUT
//  ---------------------------
//  If all checks pass, you will see:
//      CHECK PASS: prediction=0 (state=SNT, taken=0)
//      CHECK PASS: prediction=0 (state=SNT, taken=1)
//      ... (one line per test vector)
//      ALL TESTS PASSED.
//
//  If a check fails, you will see:
//      CHECK FAIL: expected=X, got=Y at time T
//  which tells you exactly which test vector produced the wrong output.
//
// =============================================================================

`timescale 1ns/1ps

module tb_branch_predictor;

    // ── DUT (Design Under Test) signal declarations ────────────────────────
    reg        clk;
    reg        rst_n;
    reg        branch_taken;
    wire       prediction;

    // ── Integer for tracking test failures ────────────────────────────────
    integer    fail_count;

    // ── Instantiate the DUT ────────────────────────────────────────────────
    branch_predictor dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .branch_taken (branch_taken),
        .prediction   (prediction)
    );

    // ── Clock generation: 10 ns period = 100 MHz ──────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ── Helper task: apply one cycle and check the output ─────────────────
    task apply_and_check;
        input taken;          // value to drive on branch_taken
        input exp_pred;       // expected value of prediction BEFORE this clock edge
        input [127:0] label;  // descriptive label for the printout
        begin
            // Check the prediction BEFORE applying the new input
            if (prediction !== exp_pred) begin
                $display("CHECK FAIL at time %0t: expected prediction=%0b, got=%0b  [%s]",
                         $time, exp_pred, prediction, label);
                fail_count = fail_count + 1;
            end else begin
                $display("CHECK PASS: prediction=%0b  [%s]", prediction, label);
            end
            // Now apply the new branch_taken input and wait one clock cycle
            branch_taken = taken;
            @(posedge clk);
            #1; // small delay past the clock edge so we read stable outputs
        end
    endtask

    // ── Main test sequence ─────────────────────────────────────────────────
    initial begin
        fail_count   = 0;
        branch_taken = 0;
        rst_n        = 0;    // assert reset

        // Hold reset for two clock cycles
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;           // release reset — design should now be in SNT state
        @(posedge clk); #1;

        // ── TEST GROUP 1: Counting UP from SNT to ST ──────────────────────
        // After reset, state = SNT, prediction should be 0 (not taken)
        // We will drive branch_taken=1 four times to walk up all four states.

        apply_and_check(1, 0, "SNT state, taken=1 → expect prediction=0");
        // State is now WNT after this edge
        apply_and_check(1, 0, "WNT state, taken=1 → expect prediction=0");
        // State is now WT after this edge
        apply_and_check(1, 1, "WT  state, taken=1 → expect prediction=1");
        // State is now ST after this edge
        apply_and_check(1, 1, "ST  state, taken=1 → expect prediction=1 (saturated)");
        // State stays ST (saturation check)

        // ── TEST GROUP 2: Saturation at ST ────────────────────────────────
        // Driving taken=1 repeatedly should keep us in ST forever
        apply_and_check(1, 1, "ST  state, taken=1 → saturate, prediction=1");
        apply_and_check(1, 1, "ST  state, taken=1 → saturate, prediction=1");

        // ── TEST GROUP 3: Counting DOWN from ST to SNT ────────────────────
        // Now drive branch_taken=0 to walk back down
        apply_and_check(0, 1, "ST  state, taken=0 → prediction=1, move to WT");
        // State is now WT
        apply_and_check(0, 1, "WT  state, taken=0 → prediction=1, move to WNT");
        // State is now WNT
        apply_and_check(0, 0, "WNT state, taken=0 → prediction=0, move to SNT");
        // State is now SNT
        apply_and_check(0, 0, "SNT state, taken=0 → prediction=0 (saturated)");
        // State stays SNT (saturation check)
        apply_and_check(0, 0, "SNT state, taken=0 → saturate, prediction=0");

        // ── TEST GROUP 4: Asymmetric transitions ──────────────────────────
        // From SNT, one 'taken' moves to WNT (not straight to WT)
        apply_and_check(1, 0, "SNT→WNT: one taken, prediction=0");
        // WNT: one 'not taken' should go back to SNT
        apply_and_check(0, 0, "WNT→SNT: one not-taken, prediction=0");
        // Back to SNT; two consecutive 'taken' should reach WT
        apply_and_check(1, 0, "SNT→WNT: taken=1");
        apply_and_check(1, 0, "WNT→WT:  taken=1, prediction=0 before edge");
        apply_and_check(0, 1, "WT state: prediction should now be 1");

        // ── TEST GROUP 5: Reset in the middle of operation ────────────────
        // Assert reset from the WT state and check we go back to SNT
        rst_n = 0;
        @(posedge clk); #1;
        if (prediction !== 0) begin
            $display("CHECK FAIL: prediction should be 0 after mid-flow reset, got=%0b", prediction);
            fail_count = fail_count + 1;
        end else begin
            $display("CHECK PASS: mid-flow reset correctly returns prediction=0");
        end
        rst_n = 1;
        @(posedge clk); #1;

        // ── SUMMARY ───────────────────────────────────────────────────────
        if (fail_count == 0)
            $display("\n===========================");
            $display(" ALL TESTS PASSED.");
            $display("===========================\n");
        else begin
            $display("\n===========================");
            $display(" %0d TEST(S) FAILED.", fail_count);
            $display("===========================\n");
        end

        $finish;
    end

endmodule
