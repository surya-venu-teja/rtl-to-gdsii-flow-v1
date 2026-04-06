// =============================================================================
//  lec_rtl_vs_synth.do  —  Cadence Conformal LEC Equivalence Checking Script
//  Repository: rtl-to-gdsii-flow-v1
//  Version:    1.0
//  Author:     Surya Venu Teja B
// =============================================================================
//
//  PURPOSE
//  -------
//  This script uses Cadence Conformal LEC (Logical Equivalence Checker) to
//  formally prove that the synthesised gate-level netlist is logically identical
//  to the original RTL. This is NOT simulation — it is formal verification,
//  which means it exhaustively checks all possible input combinations using
//  mathematical Boolean reasoning.
//
//  WHY IS THIS THE STRONGEST FORM OF VERIFICATION?
//  Simulation can only check the inputs you think to test. If you miss a corner
//  case, simulation will not catch it. Formal equivalence checking has no such
//  limitation — it proves the two designs are identical for ALL possible inputs
//  and ALL possible states. If this passes, you have mathematical certainty
//  (not just confidence) that synthesis did not change the logic.
//
//  TERMINOLOGY
//  -----------
//  Golden design  : the design you TRUST as correct — in this case, the RTL.
//  Revised design : the design you are CHECKING — in this case, the synthesis
//                   output netlist.
//  Key points     : the comparison points. These are typically primary inputs,
//                   primary outputs, and the D and Q pins of all flip-flops.
//                   LEC proves that for every key point, golden == revised.
//
//  USAGE
//  -----
//  Run from the scripts/lec/ directory:
//      lec -xl -dofile lec_rtl_vs_synth.do -log lec_run.log
//
//  EXPECTED OUTPUT
//  ---------------
//  If the flow passes, you will see:
//      Equivalence checking PASSED.
//      All 6 compare points are EQUIVALENT.
//  If it fails, it will say NOT EQUIVALENT and show a counterexample (an input
//  vector that causes different outputs). Use the graphical schematic viewer in
//  Conformal to trace the failure back to its root cause.
//
// =============================================================================


// ─────────────────────────────────────────────────────────────────────────────
//  STEP 1: READ THE GOLDEN DESIGN (RTL)
//
//  The golden design is your original Verilog RTL. This is the reference —
//  the design that you trust and want to verify against.
// ─────────────────────────────────────────────────────────────────────────────

read design -golden -verilog \
    ../../example_design/rtl/branch_predictor.v


// ─────────────────────────────────────────────────────────────────────────────
//  STEP 2: READ THE REVISED DESIGN (SYNTHESIS OUTPUT)
//
//  The revised design is the gate-level netlist produced by Genus. This is the
//  design you want to check. If the comparison passes, you know synthesis
//  did not accidentally introduce any logic errors.
// ─────────────────────────────────────────────────────────────────────────────

read design -revised -verilog \
    ../../example_design/synthesis/output/branch_predictor_synth.v


// ─────────────────────────────────────────────────────────────────────────────
//  STEP 3: READ THE CELL LIBRARY
//
//  The gate-level netlist uses cells from the GPDK045 library (e.g., NAND2,
//  DFF_X1). Conformal needs the functional descriptions of these cells to know
//  what they do logically. Without this, it cannot reason about the netlist.
//
//  We read the library for BOTH the golden and revised designs (-both flag).
//  Typically the library is only needed for the revised (gate-level) design,
//  but using -both avoids issues if the RTL uses any library primitives.
// ─────────────────────────────────────────────────────────────────────────────

read library \
    -both \
    /eda/cadence/2024-25/RHELx86/DDIEXPORT_23.33.000/INNOVUS231/share/FoundationFlows/EXAMPLES/INNOVUS/DESIGN/GPDK/LIBS/GPDK045/slow.lib


// ─────────────────────────────────────────────────────────────────────────────
//  STEP 4: MAP KEY POINTS
//
//  Conformal identifies corresponding "key points" between the two designs.
//  A key point is any node that must be logically equivalent:
//    - Primary inputs  (clk, rst_n, branch_taken)
//    - Primary outputs (prediction)
//    - Flip-flop D inputs (data arriving at each register)
//    - Flip-flop Q outputs (data leaving each register)
//
//  This mapping is the "translation" step — Conformal figures out which node
//  in the RTL corresponds to which node in the gate-level netlist.
// ─────────────────────────────────────────────────────────────────────────────

map key points


// ─────────────────────────────────────────────────────────────────────────────
//  STEP 5: VERIFY
//
//  This is the main equivalence proof. For each key point, Conformal proves
//  (or disproves) that the Boolean function computed by the golden design
//  equals the Boolean function computed by the revised design.
//
//  If any key point is NOT EQUIVALENT, Conformal will generate a diagnostic
//  counterexample — a specific input vector where the two designs differ.
// ─────────────────────────────────────────────────────────────────────────────

verify


// ─────────────────────────────────────────────────────────────────────────────
//  STEP 6: REPORT
//
//  Print the verification summary. Every key point should say EQUIVALENT.
//  The report also shows the total number of compare points and any failures.
// ─────────────────────────────────────────────────────────────────────────────

report verification

// Expected output for a passing run:
//   Equivalence checking PASSED.
//   All compare points are EQUIVALENT.
//
// If you see NOT EQUIVALENT:
//   1. Check that the correct RTL file and netlist file paths are set above.
//   2. Make sure the library file path points to the correct .lib file.
//   3. Run 'diagnose' after 'verify' to get a failing pattern, then
//      open the graphical viewer to trace the mismatch.
