# =============================================================================
#  branch_predictor.sdc  —  SDC Timing Constraints
#  Repository: rtl-to-gdsii-flow-v1
#  Version:    1.0
#  Author:     Surya Venu Teja B
# =============================================================================
#
#  WHAT IS AN SDC FILE?
#  --------------------
#  SDC stands for Synopsys Design Constraints. Even though the name says
#  "Synopsys", this format is an industry standard used by all EDA tools,
#  including Cadence Genus and Innovus. An SDC file is the way you tell the
#  synthesis and P&R tools what timing they need to meet.
#
#  WHY IS THIS FILE IMPORTANT?
#  ---------------------------
#  Without an SDC file, Genus and Innovus have no idea how fast your circuit
#  needs to run. They will synthesise and place/route the design, but they will
#  not try to meet any specific timing target. The result may be correct logic,
#  but it might only run at 10 MHz when you needed 100 MHz.
#
#  The SDC file is the "contract" you give to the tools: here is my clock,
#  here are my timing requirements — meet them.
#
#  UNDERSTANDING SETUP AND HOLD CONSTRAINTS
#  ----------------------------------------
#  For a flip-flop to work correctly, two timing rules must always be satisfied:
#
#  SETUP time: Data must arrive at the flip-flop's D input BEFORE the clock
#  edge. Specifically, it must be stable for at least 'setup_time' nanoseconds
#  before the clock edge. The set_input_delay and set_output_delay commands
#  reserve a portion of the clock period for I/O delays, effectively tightening
#  the internal timing budget.
#
#  HOLD time: Data must remain stable at the D input for 'hold_time' nanoseconds
#  AFTER the clock edge. This prevents data from changing too quickly (which
#  would mean the flip-flop could catch the new data instead of the old data).
#  Hold time is more important after routing, because real wire delays affect
#  how quickly data propagates from one flip-flop to the next.
#
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
#  CLOCK DEFINITION
#
#  create_clock defines a clock signal on a port.
#    -name      : a label used in timing reports to identify this clock
#    -period    : the time between rising edges, in nanoseconds
#                 Period = 1 / Frequency
#                 10.0 ns = 100 MHz
#    [get_ports]: which port the clock arrives on
#
#  The waveform is 50% duty cycle by default (5 ns high, 5 ns low).
#  To change duty cycle: -waveform {rise_time fall_time}, e.g. -waveform {0 3}
# ─────────────────────────────────────────────────────────────────────────────

create_clock -name clk -period 10.0 [get_ports clk]


# ─────────────────────────────────────────────────────────────────────────────
#  INPUT DELAY
#
#  set_input_delay tells the tools how long it takes for input signals to
#  arrive AFTER the clock edge. In other words, by the time the clock fires,
#  the input has already been travelling for 'delay' nanoseconds.
#
#  This reduces the available time for internal logic. If the clock period is
#  10 ns and input delay is 2 ns, only 8 ns remains for the combinational
#  logic between the input pin and the first flip-flop.
#
#  -max sets the constraint for setup timing (worst case — data arrives late).
#  If you only specify a value without -max/-min, it applies to both.
# ─────────────────────────────────────────────────────────────────────────────

set_input_delay 2.0 -clock clk [all_inputs]


# ─────────────────────────────────────────────────────────────────────────────
#  OUTPUT DELAY
#
#  set_output_delay tells the tools that after the circuit produces an output,
#  that output must arrive at its destination with 'delay' ns to spare before
#  the next clock edge. This accounts for the setup time of the receiving
#  flip-flop in the next chip or board component.
#
#  Again, this tightens the internal timing budget by 2 ns.
# ─────────────────────────────────────────────────────────────────────────────

set_output_delay 2.0 -clock clk [all_outputs]


# ─────────────────────────────────────────────────────────────────────────────
#  WHAT THE TOOLS SEE
#  ------------------
#  With the constraints above, for a 100 MHz clock (10 ns period):
#
#    Available time for internal setup paths = 10 - 2 - 2 = 6 ns
#    (minus input delay, minus output delay, minus cell setup times)
#
#  This is a comfortable constraint for GPDK045. The final result was:
#    WNS = +7.342 ns (positive = timing is MET with 7.342 ns to spare)
# ─────────────────────────────────────────────────────────────────────────────
