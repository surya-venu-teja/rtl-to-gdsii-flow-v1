# Errors and Fixes

This file documents every error encountered while developing and running this
flow in v1. Each entry includes the exact error message (so you can search for
it), the root cause, and the complete fix. If you hit an error that is not
listed here, please open a GitHub Issue so it can be added.

---

## Error 1 — Xcelium: Module Not Found

**Tool:** Cadence Xcelium (`xrun`)  
**Stage:** RTL Simulation (before synthesis)

**Error message:**
```
ERROR (CXDB-007): Module 'branch_predictor' not found.
```

**Root cause:**  
The `xrun` command was given only the testbench file on the command line. The
testbench instantiates the `branch_predictor` module, but because the RTL
source file was never passed to the simulator, the tool cannot find that
module definition.

This is a very common first mistake because in some simulators you can run
a testbench by itself and it will search for modules in the current directory.
`xrun` does not do this — you must explicitly list every file that contains a
module you need.

**Fix:**
```bash
# WRONG — only the testbench, RTL file is missing:
xrun example_design/rtl/tb_branch_predictor.v

# CORRECT — both files, RTL listed first:
xrun example_design/rtl/branch_predictor.v \
     example_design/rtl/tb_branch_predictor.v \
     -timescale 1ns/1ps
```

**Rule to remember:** Always list all the Verilog files your simulation needs.
The RTL file first, then the testbench. If you have sub-modules, list those too.

---

## Error 2 — Innovus: Layer Name Not Found (Case-Sensitivity)

**Tool:** Cadence Innovus  
**Stage:** Place and Route

**Error message:**
```
ERROR: Layer 'metal3' not found in the technology file.
ERROR: Layer 'metal4' not found in the technology file.
```

**Root cause:**  
GPDK045 defines its metal layer names with a capital first letter: `Metal1`,
`Metal2`, `Metal3`, and so on. The scripts were originally written with all
lowercase (`metal3`, `metal4`). TCL and the LEF/DEF formats are both
case-sensitive, so `metal3` and `Metal3` are completely different names.

This error is particularly tricky because it is silent until a step explicitly
uses a layer name — you will not see it until routing or a DRC check tries to
reference a specific layer.

**Fix:**  
Change all layer name references in your TCL scripts to use capitalised names:
```tcl
# WRONG:
-layer {metal3 metal4}

# CORRECT for GPDK045:
-layer {Metal3 Metal4}
```

If you are using a different PDK, find the correct layer names by running:
```bash
grep -i "LAYER " your_library.lef | grep "ROUTING" | head -20
```

---

## Error 3 — Innovus: Missing Power and Ground Pin Connections

**Tool:** Cadence Innovus  
**Stage:** Just before `placeDesign` / connectivity check

**Error message:**
```
WARNING: No connect rules found for net 'VDD'.
WARNING: No connect rules found for net 'VSS'.
ERROR (IMPPP-8023): Power connection not established.
```

**Root cause:**  
Every standard cell has dedicated VDD (power) and VSS (ground) pins. Innovus
does not automatically assume that the global net called `VDD` connects to
these pins — it needs explicit instructions. Without the `globalNetConnect`
commands, the cells are placed and routed without any power connections. The
design will appear to complete successfully, but the final GDSII will have cells
with no power, which would cause the chip to do nothing.

Think of it like wiring a house: just because you have electrical sockets
does not mean they are connected to the main circuit breaker — someone has to
explicitly run the wires.

**Fix:**  
Add these two lines immediately after `init_design` and before `placeDesign`:
```tcl
globalNetConnect VDD -type pgpin -pin VDD -all
globalNetConnect VSS -type pgpin -pin VSS -all
```

---

## Error 4 — Innovus: Running in Physical-Only Mode

**Tool:** Cadence Innovus  
**Stage:** `init_design` and beyond

**Error message:**
```
WARNING: No timing libraries loaded. Running in physical-only mode.
WARNING: Timing optimisation will be skipped.
```

**Root cause:**  
The MMMC (Multi-Mode Multi-Corner) setup file `mmmc_setup.tcl` was sourced
*after* `init_design`, or was never sourced at all. Once Innovus calls
`init_design` without MMMC information available, it initialises the design
in a mode that has no timing awareness. Even if you source MMMC later in the
session, the tool is already in physical-only mode and will not switch to
timing-aware mode.

This is a silent error — the tool does not crash. It continues to place and
route the design, but it makes no attempt to meet timing. The final GDSII
will be geometrically correct (it will pass DRC), but timing will not be met.

**Fix:**  
The `source mmmc_setup.tcl` command must come *before* `init_design`:
```tcl
# CORRECT order:
source mmmc_setup.tcl        # FIRST: load timing libraries and corner definitions

init_design \                # SECOND: read the netlist (now in timing-aware mode)
    -top_cell $DESIGN \
    -netlist  $NETLIST \
    -lef      [list $LEF]  \
    -mode     timing
```

Think of it as: you must tell the tool the rules before you hand it the design.

---

## Error 5 — Innovus Legacy Mode: Command Not Recognised

**Tool:** Cadence Innovus  
**Stage:** Any timing optimisation or verification step

**Error message:**
```
ERROR: Unknown command 'check_place'.
       Did you mean 'checkPlace'?

ERROR: Unknown command 'opt_design'.
       Did you mean 'optDesign'?
```

**Root cause:**  
Innovus supports two different command-line interfaces that have different
naming conventions:

- **Stylus mode** (newer): uses underscores — `opt_design`, `check_place`,
  `ccopt_design`
- **Legacy mode** (older, default on the tested workstation): uses camelCase —
  `optDesign`, `checkPlace`, `clock_opt_design`

The version of Innovus installed on the tested workstation (v23.33) defaults to
legacy mode. Stylus commands simply do not exist in this mode.

**Fix:**  
Use the correct legacy-mode command names. Here is the full mapping table:

| Stylus Mode (newer) | Legacy Mode (this version) |
|---------------------|---------------------------|
| `opt_design -preCTS` | `optDesign -preCTS` |
| `opt_design -postCTS` | `optDesign -postCTS` |
| `opt_design -postRoute` | `optDesign -postRoute` |
| `check_place` | `checkPlace` |
| `ccopt_design` | `clock_opt_design` |
| `set_db` | `setMultiCpuUsage`, `setDesignMode` (context-dependent) |

To check which mode your Innovus installation defaults to, run:
```tcl
get_db design_mode   ;# Stylus
# or
version              ;# check version string for "Stylus" or "Legacy"
```

---

## Error 6 — Innovus: ccopt_design Fails with PODv2 Database Error

**Tool:** Cadence Innovus  
**Stage:** Clock Tree Synthesis

**Error message:**
```
ERROR (CTS-437): ccopt_design requires PODv2 database format.
                 Current database format is PODv1.
                 Use 'clock_opt_design' for this flow.
```

**Root cause:**  
`ccopt_design` is the Concurrent Clock and Data Optimisation command in
Innovus's Stylus mode. It requires the database to be in PODv2 (Platform Object
Data version 2) format. When Innovus runs in legacy mode, it uses PODv1 format.
These two database formats are not compatible.

The correct CTS command for legacy mode is `clock_opt_design`, which does
traditional hierarchical CTS and is fully compatible with the PODv1 database.

**Fix:**
```tcl
# WRONG (Stylus mode, PODv2 required):
ccopt_design

# CORRECT (Legacy mode, PODv1 compatible):
clock_opt_design
```

**How to recognise this class of error more generally:**  
If you ever see an error that mentions "PODv2" or "PODv1 database format",
the root cause is always the same: you are using a Stylus-mode command in
a legacy-mode session. Check the mapping table in Error 5 above and replace
the command accordingly.

---

## How to Add New Errors

If you encounter an error not listed here while using this repository, please
do the following so it can be added for others:

1. Copy the exact error message from the tool log file (not from memory).
2. Note the tool name, version, and the stage of the flow where it occurred.
3. Describe what you were trying to do just before the error appeared.
4. Describe what you changed to fix it, and confirm the fix worked.
5. Open a GitHub Issue or Pull Request with this information.
