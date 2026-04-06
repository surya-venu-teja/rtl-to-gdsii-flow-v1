// =============================================================================
//  branch_predictor.v  —  2-Bit Saturating Counter Branch Predictor
//  Repository: rtl-to-gdsii-flow-v1
//  Version:    1.0
//  Author:     Surya Venu Teja B
// =============================================================================
//
//  WHAT IS A BRANCH PREDICTOR?
//  ---------------------------
//  Inside a modern processor, instructions are executed one after another in
//  a pipeline — like a factory conveyor belt. When the processor hits a
//  conditional branch instruction (like an "if" statement), it does not know
//  whether the branch will be taken or not until several pipeline stages later.
//  Rather than stall the pipeline and wait, it GUESSES (predicts) the outcome
//  and keeps executing. If the guess is wrong, it throws away the work done
//  and restarts from the correct path. A good predictor reduces wasted work.
//
//  THE 2-BIT SATURATING COUNTER APPROACH
//  ----------------------------------------
//  This design remembers the last two branch outcomes using a 2-bit counter.
//  "Saturating" means the counter stays at its maximum (11) or minimum (00)
//  and does not wrap around. The design has four states:
//
//    State 00 — Strongly Not Taken (SNT) : predict NOT taken
//    State 01 — Weakly Not Taken   (WNT) : predict NOT taken
//    State 10 — Weakly Taken       (WT)  : predict TAKEN
//    State 11 — Strongly Taken     (ST)  : predict TAKEN
//
//  Each time a branch IS taken   → counter increments (moves toward ST)
//  Each time a branch is NOT taken → counter decrements (moves toward SNT)
//
//  This is better than a 1-bit predictor because it requires TWO consecutive
//  mispredictions to change the dominant prediction. For loops (which branch
//  the same way many times in a row), this is much more accurate.
//
//  PORTS
//  -----
//  clk          : system clock (positive edge triggered)
//  rst_n        : asynchronous active-low reset
//  branch_taken : 1 = the branch was actually taken this cycle
//  prediction   : 1 = predict branch will be taken, 0 = predict not taken
//
// =============================================================================

module branch_predictor (
    input  wire clk,
    input  wire rst_n,          // active-low reset (0 = reset, 1 = normal)
    input  wire branch_taken,   // actual branch outcome from the pipeline
    output reg  prediction      // prediction for the NEXT branch (based on current state)
);

    // State encoding as 2-bit values
    localparam SNT = 2'b00;   // Strongly Not Taken
    localparam WNT = 2'b01;   // Weakly Not Taken
    localparam WT  = 2'b10;   // Weakly Taken
    localparam ST  = 2'b11;   // Strongly Taken

    // State registers: 'state' holds the current state, 'next_state' holds
    // what the state should be after the next clock edge.
    reg [1:0] state;
    reg [1:0] next_state;

    // ─────────────────────────────────────────────────────────
    //  SEQUENTIAL BLOCK: state register update
    //  This block runs on every rising clock edge.
    //  On reset, the counter starts at Strongly Not Taken (SNT).
    // ─────────────────────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= SNT;       // reset to the most conservative prediction
        else
            state <= next_state;
    end

    // ─────────────────────────────────────────────────────────
    //  COMBINATIONAL BLOCK: next state logic and output
    //
    //  This block defines the FSM transitions:
    //    If branch was taken    → increment (saturate at ST)
    //    If branch was not taken → decrement (saturate at SNT)
    //
    //  The 'prediction' output is also computed here: it is 1
    //  whenever the current state is WT or ST (the "taken" half).
    // ─────────────────────────────────────────────────────────
    always @(*) begin
        case (state)
            SNT: next_state = branch_taken ? WNT : SNT;   // saturates at SNT when not taken
            WNT: next_state = branch_taken ? WT  : SNT;
            WT : next_state = branch_taken ? ST  : WNT;
            ST : next_state = branch_taken ? ST  : WT;    // saturates at ST when taken
            default: next_state = SNT;                    // safe default for undefined states
        endcase

        // Output is purely based on current state (Moore-type output)
        prediction = (state == WT || state == ST) ? 1'b1 : 1'b0;
    end

endmodule
