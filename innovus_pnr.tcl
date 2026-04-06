# =============================================================================
#  innovus_pnr.tcl  —  Cadence Innovus Place and Route Script
#  Repository: rtl-to-gdsii-flow-v1
#  Version:    1.0
#  Author:     Surya Venu Teja B
# =============================================================================
#
#  PURPOSE
#  -------
#  This script drives Cadence Innovus through the complete place-and-route (P&R)
#  flow, from reading the synthesised netlist to writing the final GDSII file.
#
#  IMPORTANT — LEGACY MODE NOTE
#  This script uses Innovus LEGACY MODE command syntax (camelCase commands like
#  optDesign, checkPlace, clock_opt_design). This is the mode that Innovus uses
#  by default in versions up to and including 23.x on the tested workstation.
#  If you are running a newer Innovus that defaults to Stylus mode, commands
#  will use underscore syntax (opt_design, check_place, ccopt_design). See
#  docs/ERRORS_AND_FIXES.md Error 5 for the full mapping table.
#
#  USAGE
#  -----
#  Run from the scripts/pnr/ directory:
#      innovus -init innovus_pnr.tcl -log innovus_run.log
#
#  OUTPUTS (written to example_design/PnR/)
#  -------
#      outputs/branch_predictor.gds   FINAL GDSII — the goal of the whole flow
#      outputs/branch_predictor.def   physical layout in DEF format
#      outputs/branch_predictor.v     gate-level netlist after routing
#      reports/timing_pnr.rpt         setup + hold timing report
#
#  THE 14 STAGES OF THIS SCRIPT
#  ----------------------------
#  Stage 1  — Load MMMC timing setup
#  Stage 2  — Read design (LEF + netlist)
#  Stage 3  — Connect power/ground nets
#  Stage 4  — Create floorplan
#  Stage 5  — Place standard cells
#  Stage 6  — Pre-CTS timing optimisation
#  Stage 7  — Clock Tree Synthesis (CTS)
#  Stage 8  — Post-CTS timing optimisation
#  Stage 9  — Route all nets
#  Stage 10 — Post-route timing optimisation
#  Stage 11 — Add filler cells
#  Stage 12 — Verify (DRC + connectivity)
#  Stage 13 — Generate timing reports
#  Stage 14 — Write output files (GDSII, DEF, Verilog)
#
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 1: USER CONFIGURATION
#  Change the variables in this block for your design and machine.
# ─────────────────────────────────────────────────────────────────────────────

set PDK_PATH /eda/cadence/2024-25/RHELx86/DDIEXPORT_23.33.000/INNOVUS231/share/FoundationFlows/EXAMPLES/INNOVUS/DESIGN/GPDK/LIBS/GPDK045

# Top-level module name. Must match the 'module' keyword in your Verilog.
set DESIGN  branch_predictor

# Paths to the synthesis outputs (these are inputs to Innovus).
set NETLIST ../../example_design/synthesis/output/${DESIGN}_synth.v
set SDC     ../../example_design/synthesis/output/${DESIGN}_synth.sdc
set LEF     ${PDK_PATH}/gsclib045.lef

# Output directories
set OUT_DIR ../../example_design/PnR/outputs
set RPT_DIR ../../example_design/PnR/reports

# Floorplan parameters:
#   floorPlan -r <aspect_ratio> <utilisation> <left> <bottom> <right> <top> margin
#   aspect_ratio = 1.0 means square core
#   utilisation  = 0.40 means cells fill 40% of core area (60% is routing space)
set FP_ASPECT_RATIO 1.0
set FP_UTILISATION  0.40
set FP_MARGIN       2.0


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 1: LOAD MMMC TIMING SETUP
#
#  WHY FIRST?
#  This must come before init_design. Think of it like this: before Innovus reads
#  your design, it needs to know the "rules of the game" — what corners to check,
#  what the clock period is, what the timing libraries are. If you load MMMC after
#  init_design, Innovus will have already started in physical-only mode (no timing
#  awareness), and it is too late to switch.
#
#  See mmmc_setup.tcl for a detailed explanation of what MMMC is and why we
#  need two corners (slow for setup, fast for hold).
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 1: Loading MMMC timing setup..."
source mmmc_setup.tcl


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 2: READ THE DESIGN
#
#  init_design reads the gate-level netlist (Verilog from Genus), the LEF file
#  (physical cell descriptions), and sets up the design in timing-aware mode.
#  The '-mode timing' flag tells Innovus to use the MMMC views we just loaded.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 2: Reading design netlist and LEF..."
init_design \
    -top_cell $DESIGN \
    -netlist  $NETLIST \
    -lef      [list $LEF] \
    -mode     timing


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 3: CONNECT POWER AND GROUND NETS
#
#  WHY IS THIS NEEDED?
#  Every standard cell has VDD and VSS pins. These are the power supply pins.
#  Innovus needs to be explicitly told: "the global net called VDD connects to
#  the VDD pin of every standard cell". Without these two commands, none of the
#  cells will be connected to power, and the design will fail connectivity checks.
#
#  This is one of the most common beginner mistakes — the tool will happily
#  continue placing and routing without power connections, and you will only
#  discover the problem at the DRC/connectivity check stage.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 3: Connecting VDD and VSS global nets to all cell pins..."
globalNetConnect VDD -type pgpin -pin VDD -all
globalNetConnect VSS -type pgpin -pin VSS -all


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 4: CREATE THE FLOORPLAN
#
#  The floorplan defines the core area — the rectangular space where standard
#  cells will be placed. Cells are placed in rows on a manufacturing grid called
#  a "site". The site name 'CoreSite' is specific to GPDK045.
#
#  For a different PDK, find the correct site name in the LEF file:
#      grep -i "SITE" your_library.lef | head -20
#
#  The utilisation (0.40 = 40%) controls how densely cells are packed. Lower
#  utilisation leaves more room for routing wires. For small designs, even 40%
#  is plenty; larger designs may use 60-70%.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 4: Creating floorplan (aspect=${FP_ASPECT_RATIO}, util=${FP_UTILISATION})..."
floorPlan -site CoreSite \
    -r ${FP_ASPECT_RATIO} ${FP_UTILISATION} \
       ${FP_MARGIN} ${FP_MARGIN} ${FP_MARGIN} ${FP_MARGIN}


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 5: PLACE STANDARD CELLS
#
#  placeDesign assigns every standard cell a physical (x, y) location on the
#  chip. It uses timing information from the MMMC views to try to place cells
#  that communicate frequently close together, reducing wire delay.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 5: Placing standard cells..."
placeDesign


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 6: PRE-CTS TIMING OPTIMISATION
#
#  After placement, timing may not be perfectly met because placement decisions
#  were made before real clock delays were known. This optimisation step uses
#  ideal clock assumptions (all flip-flops receive the clock at time zero) to
#  fix setup timing violations by resizing or buffering critical paths.
#
#  LEGACY MODE NOTE: use 'optDesign', not 'opt_design'.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 6: Pre-CTS timing optimisation (ideal clocks)..."
optDesign -preCTS


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 7: CLOCK TREE SYNTHESIS (CTS)
#
#  CTS builds the clock distribution network. The clock signal must reach every
#  flip-flop at nearly the same time. Without CTS, some flip-flops would receive
#  the clock much earlier or later than others, causing hold or setup violations.
#  CTS inserts clock buffers and inverters in a balanced tree structure.
#
#  LEGACY MODE NOTE: use 'clock_opt_design', NOT 'ccopt_design'.
#  The ccopt_design command requires the PODv2 database format, which is only
#  available in Stylus mode. Legacy mode uses PODv1, so clock_opt_design is
#  the correct command. See docs/ERRORS_AND_FIXES.md Error 6.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 7: Clock Tree Synthesis..."
clock_opt_design


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 8: POST-CTS TIMING OPTIMISATION
#
#  Now that real clock delays are known (from CTS), we re-run timing optimisation.
#  This finds and fixes any setup or hold violations that appeared because of
#  clock skew introduced during CTS. Hold violations are particularly common
#  at this stage.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 8: Post-CTS timing optimisation (real clocks)..."
optDesign -postCTS


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 9: ROUTE ALL NETS
#
#  routeDesign connects all cell pins with physical metal wires on the chip
#  layers (Metal1 through Metal8 in GPDK045). After this step, every logical
#  connection from the netlist has a physical wire. The router also adds vias
#  where wires transition between different metal layers.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 9: Routing all nets..."
routeDesign


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 10: POST-ROUTE TIMING OPTIMISATION
#
#  Routing adds real wire resistance and capacitance to every connection. These
#  real delays are slightly different from the estimates used during placement.
#  Post-route optimisation performs final timing fixes using the actual wire
#  parasitics, often inserting small buffers on long wires.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 10: Post-route timing optimisation (real wire delays)..."
optDesign -postRoute


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 11: ADD FILLER CELLS
#
#  After placement and routing, there are small gaps between standard cells in
#  each row. These gaps must be filled with "filler cells" — dummy cells that
#  have no logic function, but maintain the continuous power rails (VDD/VSS)
#  that run through each row, and satisfy the density rules of the PDK.
#
#  Filler cells are listed from largest to smallest so Innovus fills large gaps
#  first, then uses smaller ones for remaining spaces.
#
#  For GPDK045: filler cell names are FILL1, FILL2, FILL4, FILL8, ..., FILL64.
#  For a different PDK: check the cell library for the correct filler cell names.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 11: Adding filler cells to empty row spaces..."
addFiller \
    -cell   {FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1} \
    -prefix FILL


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 12: VERIFY
#
#  Three verification checks:
#
#  checkDesign -all : general design integrity check (overlap, missing cells, etc.)
#  verify_drc      : Design Rule Check — verifies all physical geometry obeys
#                    the foundry's manufacturing rules (minimum width, spacing,
#                    enclosure, density). Zero violations is the required target.
#  verify_connectivity : checks that all logical connections from the netlist
#                        exist as physical wires. Detects opens and shorts.
#
#  If DRC violations are found, they are written to the report file. Common
#  DRC violations in a standard cell flow come from routing (wire too close to
#  another wire) or missing antenna rule fixes.
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 12: Running design checks (DRC, connectivity)..."
checkDesign -all
verify_drc
verify_connectivity


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 13: GENERATE TIMING REPORTS
#
#  report_timing generates a full setup and hold timing path report.
#  Check this report carefully:
#    Setup: all paths should have positive slack (data arrives before deadline)
#    Hold:  all paths should have positive slack (data does not arrive too early)
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 13: Generating timing reports..."
report_timing -path_type full             > ${RPT_DIR}/timing_pnr.rpt
report_timing -check_type hold           >> ${RPT_DIR}/timing_pnr.rpt


# ─────────────────────────────────────────────────────────────────────────────
#  STAGE 14: WRITE OUTPUT FILES
#
#  streamOut  writes the GDSII file — this is the main deliverable of the
#             entire flow. The foundry reads this file to manufacture the chip.
#             -mapFile "" means no layer name remapping (use PDK layer names).
#             -units 1000 sets the database units to 1 nm (1000 units per micron).
#
#  defOut     writes the DEF (Design Exchange Format) file — useful for re-reading
#             the layout back into Innovus or other tools later.
#
#  saveNetlist writes the final gate-level Verilog netlist — useful for post-route
#             simulation and for Conformal LEC (to verify no changes after routing).
# ─────────────────────────────────────────────────────────────────────────────

puts "STAGE 14: Writing output files (GDSII, DEF, Verilog)..."

streamOut ${OUT_DIR}/${DESIGN}.gds \
    -mapFile "" \
    -units   1000 \
    -mode    ALL

defOut      ${OUT_DIR}/${DESIGN}.def
saveNetlist ${OUT_DIR}/${DESIGN}.v

puts "======================================================================"
puts "  Place and Route DONE."
puts ""
puts "  GDSII (main output) : ${OUT_DIR}/${DESIGN}.gds"
puts "  DEF                 : ${OUT_DIR}/${DESIGN}.def"
puts "  Final netlist       : ${OUT_DIR}/${DESIGN}.v"
puts "  Timing report       : ${RPT_DIR}/timing_pnr.rpt"
puts ""
puts "  Check timing report for WNS >= 0 (setup) and hold slack >= 0."
puts "  Check DRC report: zero violations required before tapeout."
puts "======================================================================"
