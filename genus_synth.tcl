# =============================================================================
#  genus_synth.tcl  —  Cadence Genus Logic Synthesis Script
#  Repository: rtl-to-gdsii-flow-v1
#  Version:    1.0
#  Author:     Surya Venu Teja B
# =============================================================================
#
#  PURPOSE
#  -------
#  This script drives the Cadence Genus synthesis tool to convert a Verilog
#  RTL description into a gate-level netlist using cells from a standard cell
#  library. It is written to be reusable: only the USER CONFIGURATION block
#  at the top needs to change when you switch to a different design or PDK.
#
#  USAGE
#  -----
#  Run from the scripts/synthesis/ directory:
#      genus -f genus_synth.tcl -log genus_run.log
#
#  OUTPUTS (written to example_design/synthesis/)
#  -------
#      output/<DESIGN>_synth.v      gate-level netlist
#      output/<DESIGN>_synth.sdc    updated timing constraints
#      reports/timing_genus.rpt     timing report — check WNS >= 0
#      reports/area_genus.rpt       area report
#      reports/power_genus.rpt      power report
#
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 1: USER CONFIGURATION
#  Change the variables in this section for your setup.
#  Everything below this section should work without changes for any simple
#  single-clock RTL design using GPDK045.
# ─────────────────────────────────────────────────────────────────────────────

# Full path to your PDK library directory.
# For the college workstation at RWU, this is the path below.
# For a different machine, replace this with your own PDK path.
set PDK_PATH /eda/cadence/2024-25/RHELx86/DDIEXPORT_23.33.000/INNOVUS231/share/FoundationFlows/EXAMPLES/INNOVUS/DESIGN/GPDK/LIBS/GPDK045

# Top-level module name. This must exactly match the 'module' name in your Verilog.
set DESIGN branch_predictor

# Path(s) to your RTL Verilog file(s). For a single file, just one path.
# For multiple files, separate them with spaces inside the list:
#   set RTL_FILES [list file1.v file2.v file3.v]
set RTL_FILES [list ../../example_design/rtl/branch_predictor.v]

# Path to the SDC timing constraints file.
set SDC_FILE ../../example_design/constraints/branch_predictor.sdc

# Output directory (relative to this script's location).
set OUT_DIR  ../../example_design/synthesis/output
set RPT_DIR  ../../example_design/synthesis/reports


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 2: LIBRARY SETUP
#  Read the timing library (.lib) and physical library (.lef).
#
#  WHY TWO FILES?
#  The .lib file tells Genus about cell timing (how fast each gate is, how much
#  power it uses). The .lef file tells Genus about cell geometry (how big each
#  gate is physically). Both are needed for a synthesis that is aware of both
#  timing and physical constraints.
#
#  For setup timing (checking that data arrives before the clock edge), we use
#  the SLOW corner library. This represents worst-case conditions: slow silicon
#  process, high temperature, low voltage. If setup timing passes in slow
#  conditions, it will pass in any real-world condition.
# ─────────────────────────────────────────────────────────────────────────────

puts "INFO: Reading timing library (slow corner for setup timing)..."
read_libs ${PDK_PATH}/slow.lib

puts "INFO: Reading physical library (LEF)..."
read_physical -lef ${PDK_PATH}/gsclib045.lef


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 3: READ AND ELABORATE THE DESIGN
#
#  'read_hdl' reads the Verilog source files into Genus's memory.
#  'elaborate' builds the internal netlist database from those files.
#   It also resolves module hierarchy (if you have sub-modules) and
#   creates the design object that all later commands will operate on.
# ─────────────────────────────────────────────────────────────────────────────

puts "INFO: Reading RTL files..."
read_hdl $RTL_FILES

puts "INFO: Elaborating design: $DESIGN ..."
elaborate $DESIGN


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 4: APPLY TIMING CONSTRAINTS
#
#  The SDC file defines the clock (period, waveform) and sets up input/output
#  timing requirements. Genus will try to meet these constraints during synthesis
#  by choosing faster or smaller cells as needed.
#
#  If you do NOT have an SDC file, you can create a basic one with:
#      create_clock -name clk -period 10.0 [get_ports clk]
#  But it is always better to use a proper SDC file.
# ─────────────────────────────────────────────────────────────────────────────

puts "INFO: Reading SDC constraints from: $SDC_FILE ..."
read_sdc $SDC_FILE


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 5: SYNTHESISE
#
#  'synthesize -to_mapped' is the core command. It does three things in one:
#   1. Generic synthesis  — converts RTL to a technology-independent Boolean
#                           network (AND/OR/NOT gates without specific cells)
#   2. Technology mapping — maps that network to real cells from the .lib file,
#                           choosing cells that meet the timing constraints
#   3. Optimisation       — improves area and power while keeping timing met
#
#  After this command, you have a gate-level netlist using GPDK045 cells.
# ─────────────────────────────────────────────────────────────────────────────

puts "INFO: Running synthesis (generic + mapping + optimisation)..."
synthesize -to_mapped

puts "INFO: Synthesis complete."


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 6: WRITE OUTPUT FILES
#
#  write_hdl writes the synthesised netlist as Verilog. This file will be the
#  input to Innovus for place and route.
#
#  write_sdc writes an updated SDC file. Genus may have refined some timing
#  constraints during synthesis (e.g., adding generated clocks), so the output
#  SDC is a more accurate version to pass forward to Innovus.
# ─────────────────────────────────────────────────────────────────────────────

puts "INFO: Writing synthesised netlist and SDC to: $OUT_DIR ..."

write_hdl > ${OUT_DIR}/${DESIGN}_synth.v
write_sdc > ${OUT_DIR}/${DESIGN}_synth.sdc


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 7: GENERATE REPORTS
#
#  IMPORTANT: Always check timing_genus.rpt before running Innovus.
#  The key number to look at is WNS (Worst Negative Slack):
#    WNS > 0  →  PASS.  Design meets your clock target.
#    WNS = 0  →  PASS (just barely).
#    WNS < 0  →  FAIL. The circuit is too slow. Either relax the clock period
#                in your SDC, or use a higher-effort synthesis strategy.
# ─────────────────────────────────────────────────────────────────────────────

puts "INFO: Writing reports to: $RPT_DIR ..."

report_timing > ${RPT_DIR}/timing_genus.rpt
report_area   > ${RPT_DIR}/area_genus.rpt
report_power  > ${RPT_DIR}/power_genus.rpt

puts "======================================================================"
puts "  Synthesis DONE."
puts "  Netlist   : ${OUT_DIR}/${DESIGN}_synth.v"
puts "  Timing    : ${RPT_DIR}/timing_genus.rpt   <-- check WNS >= 0"
puts "  Area      : ${RPT_DIR}/area_genus.rpt"
puts "======================================================================"
