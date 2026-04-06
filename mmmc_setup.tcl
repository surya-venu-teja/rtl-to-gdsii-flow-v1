# =============================================================================
#  mmmc_setup.tcl  —  Multi-Mode Multi-Corner (MMMC) Timing Setup for Innovus
#  Repository: rtl-to-gdsii-flow-v1
#  Version:    1.0
#  Author:     Surya Venu Teja B
# =============================================================================
#
#  PURPOSE
#  -------
#  This script defines all timing corners and analysis views that Innovus will
#  use during place and route. It must be sourced BEFORE init_design (before
#  reading the netlist). If you source it after init_design, Innovus will run
#  in "physical-only mode" — it will still place and route, but it will not
#  check or optimise timing at all. That is a silent and serious mistake.
#
#  WHAT IS MMMC?
#  -------------
#  In the real world, silicon chips are not manufactured perfectly. Each chip
#  comes out slightly "slow" or slightly "fast" depending on the manufacturing
#  conditions. Temperature and voltage also affect speed. MMMC (Multi-Mode
#  Multi-Corner) analysis checks the design against multiple combinations of
#  these conditions — called "corners" — to make sure the chip works correctly
#  in all of them.
#
#  The two corners we care about most are:
#
#    SLOW corner  (worst-case slow):  process slow + high temp + low voltage
#      → Used to check SETUP time. If data arrives too late at a flip-flop in
#        the slow corner, it will definitely be late in all conditions.
#
#    FAST corner  (best-case fast):  process fast + low temp + high voltage
#      → Used to check HOLD time. If data arrives too early at a flip-flop in
#        the fast corner, it will definitely arrive too early in all conditions.
#
#  Using only one corner would miss half the timing problems.
#
#  USAGE
#  -----
#  This file is sourced automatically from innovus_pnr.tcl. You do not need
#  to run it directly.
#
# =============================================================================


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 1: USER CONFIGURATION
#  Update PDK_PATH and SDC_FILE to match your environment.
# ─────────────────────────────────────────────────────────────────────────────

# Full path to your GPDK045 library directory.
set PDK_PATH /eda/cadence/2024-25/RHELx86/DDIEXPORT_23.33.000/INNOVUS231/share/FoundationFlows/EXAMPLES/INNOVUS/DESIGN/GPDK/LIBS/GPDK045

# Path to the SDC constraints file (relative to PnR/scripts/ where Innovus runs).
set SDC_FILE ../../example_design/constraints/branch_predictor.sdc


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 2: LIBRARY SETS
#  A library set is simply a named group of .lib files for one corner.
#  You can add multiple .lib files to a single set (e.g., if your design has
#  two different IP blocks with different timing models).
# ─────────────────────────────────────────────────────────────────────────────

create_library_set -name slow_libs \
    -timing [list ${PDK_PATH}/slow.lib]

create_library_set -name fast_libs \
    -timing [list ${PDK_PATH}/fast.lib]

create_library_set -name typ_libs \
    -timing [list ${PDK_PATH}/typical.lib]


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 3: TIMING CONDITIONS
#  A timing condition links a library set to a named operating condition.
#  The operating condition name (like "slow" or "fast") must match the name
#  defined inside the .lib file. For GPDK045, the default names work directly.
# ─────────────────────────────────────────────────────────────────────────────

create_timing_condition -name slow_cond \
    -library_sets {slow_libs}

create_timing_condition -name fast_cond \
    -library_sets {fast_libs}

create_timing_condition -name typ_cond \
    -library_sets {typ_libs}


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 4: DELAY CORNERS
#  A delay corner combines a timing condition with a parasitics model (the
#  electrical model of wire resistance and capacitance). For a simple flow
#  without an extracted parasitics file (QRC/SPEF), we use ideal wires.
#  A more advanced flow would use a .captable or .qrc file here.
# ─────────────────────────────────────────────────────────────────────────────

create_delay_corner -name slow_corner \
    -timing_condition slow_cond

create_delay_corner -name fast_corner \
    -timing_condition fast_cond

create_delay_corner -name typ_corner \
    -timing_condition typ_cond


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 5: CONSTRAINT MODE
#  A constraint mode defines which SDC file applies. If your design had
#  multiple modes (e.g., "functional mode" vs. "test/scan mode"), you would
#  define a separate constraint mode for each. For this simple single-clock
#  design, one mode is enough.
# ─────────────────────────────────────────────────────────────────────────────

create_constraint_mode -name func_mode \
    -sdc_files [list ${SDC_FILE}]


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 6: ANALYSIS VIEWS
#  An analysis view = one corner + one constraint mode. This is the unit that
#  Innovus actually uses during timing analysis and optimisation.
#
#  setup_view  → slow corner + functional mode  (checks setup violations)
#  hold_view   → fast corner + functional mode  (checks hold violations)
# ─────────────────────────────────────────────────────────────────────────────

create_analysis_view -name setup_view \
    -constraint_mode func_mode \
    -delay_corner    slow_corner

create_analysis_view -name hold_view \
    -constraint_mode func_mode \
    -delay_corner    fast_corner


# ─────────────────────────────────────────────────────────────────────────────
#  SECTION 7: ACTIVATE THE VIEWS
#  Tell Innovus which view to use for setup checking and which for hold checking.
#  This is the line that "turns on" MMMC-aware timing optimisation.
# ─────────────────────────────────────────────────────────────────────────────

set_analysis_view \
    -setup {setup_view} \
    -hold  {hold_view}

puts "INFO: MMMC setup complete. Two analysis views active:"
puts "      Setup check → setup_view  (slow corner)"
puts "      Hold  check → hold_view   (fast corner)"
