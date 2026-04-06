# Tool Setup Guide

This document explains how to configure the scripts in this repository for your
own environment. It also explains how to adapt the flow for a different design or
a different PDK (Process Design Kit). Read this before running the scripts for
the first time.

---

## Reference Configuration (What the Scripts Are Pre-Configured For)

The scripts in this repository were written and tested with the following setup:

**Machine:** College workstation at Hochschule Ravensburg-Weingarten (RWU), running Red Hat Enterprise Linux (RHEL).

**Tool versions:** Cadence Genus 23.33, Cadence Innovus 23.33, Cadence Xcelium 23.33, Cadence Conformal LEC 23.33.

**PDK:** GPDK045 (Cadence Generic 45 nm PDK, version 6.0), located at:
```
/eda/cadence/2024-25/RHELx86/DDIEXPORT_23.33.000/INNOVUS231/share/
    FoundationFlows/EXAMPLES/INNOVUS/DESIGN/GPDK/LIBS/GPDK045/
```

**Innovus mode:** Legacy mode (camelCase commands).

If your setup matches this, you only need to confirm the PDK path variable is
correct and then you can run the scripts immediately. If your setup differs,
follow the sections below.

---

## Adapting the PDK Path

Every script that calls a PDK file (`.lib`, `.lef`) uses a variable called
`PDK_PATH` defined at the very top of the script in the "User Configuration"
section. You need to set this to match your installation. Open
`scripts/synthesis/genus_synth.tcl` and `scripts/pnr/mmmc_setup.tcl` and
change the one line:

```tcl
set PDK_PATH /your/path/to/GPDK045
```

To find where your GPDK045 is installed, try:
```bash
find /eda -name "slow.lib" 2>/dev/null
find /home -name "gsclib045.lef" 2>/dev/null
```

---

## Running on a Different PDK (Non-GPDK045)

If you are using a different PDK, you need to update four things across the scripts.

**1. Library file names** — Inside `mmmc_setup.tcl`, change `slow.lib`,
`fast.lib`, and `typical.lib` to the actual filenames your PDK provides. Some
PDKs name their corners differently (e.g., `tt_025C_1v8.lib` for typical at
25°C and 1.8V). Check your PDK documentation to understand the available corners.

**2. LEF file name** — In both `genus_synth.tcl` and `innovus_pnr.tcl`, change
`gsclib045.lef` to your PDK's LEF file name. Some PDKs provide separate LEF
files for different cell groups; in that case, list all of them in the `[list]`:
```tcl
-lef [list ${PDK_PATH}/cells.lef ${PDK_PATH}/io.lef]
```

**3. Core site name** — In `innovus_pnr.tcl`, the `floorPlan -site CoreSite`
command references the site name from the LEF file. Different PDKs use different
site names. To find yours:
```bash
grep "^SITE " your_library.lef
```
Then replace `CoreSite` with the name you find.

**4. Filler cell names** — The `addFiller -cell {FILL64 FILL32 ...}` command
uses GPDK045 filler cell names. Your PDK will have different names. Check the
cell library or search the LEF:
```bash
grep -i "fill" your_library.lef | grep "CLASS CORE SPACER"
```

---

## Running on a Different Design

To use these scripts for a different Verilog module, you only need to change the
variable block at the top of each script. The three variables that must change are
the design name, the RTL file path, and the SDC file path. Everything else in the
flow stays the same for any single-clock design on the same PDK.

In `genus_synth.tcl`, change:
```tcl
set DESIGN    your_module_name
set RTL_FILES [list ../../example_design/rtl/your_module.v]
set SDC_FILE  ../../example_design/constraints/your_module.sdc
```

In `innovus_pnr.tcl`, change:
```tcl
set DESIGN  your_module_name
set NETLIST ../../example_design/synthesis/output/your_module_synth.v
set SDC     ../../example_design/synthesis/output/your_module_synth.sdc
```

In `mmmc_setup.tcl`, change:
```tcl
set SDC_FILE ../../example_design/constraints/your_module.sdc
```

For more complex designs that have multiple clock domains, scan chains, memories,
or I/O pads, you will also need to add timing exceptions (false paths, multi-cycle
paths) to the SDC file, and adjust the floorplan dimensions in `innovus_pnr.tcl`.

---

## Innovus Mode: Legacy vs. Stylus

Innovus has two command interfaces that use different naming conventions. The
scripts in this repository use **legacy mode** syntax. If your Innovus defaults
to Stylus mode, the commands will fail with "unknown command" errors.

To check which mode your Innovus uses, start it interactively and run:
```tcl
version
```

If you are in Stylus mode and need to switch to legacy, you can try:
```tcl
setDesignMode -db_path_style legacy
```

Or you can convert the scripts yourself using the mapping table in
`docs/ERRORS_AND_FIXES.md` Error 5. A fully updated Stylus-mode script set is
planned for v2.0 of this repository.

---

## Creating Output Directories

The `.gitignore` file intentionally excludes all tool-generated output directories
(synthesis outputs, P&R outputs, logs) from version control. These directories
do not exist when you first clone the repository — you need to create them before
running the scripts. Run the following from the repository root:

```bash
mkdir -p example_design/synthesis/output
mkdir -p example_design/synthesis/reports
mkdir -p example_design/PnR/outputs
mkdir -p example_design/PnR/reports
```

You only need to do this once. After that, the tool scripts will write their
outputs to these directories automatically.

---

## Verifying Your Tool Installation

Before running the full flow, it is worth checking that all four tools are
accessible in your shell. Run these commands and confirm each one launches
without a "command not found" error:

```bash
genus    -version      # should print version number
innovus  -version      # should print version number
xrun     -version      # should print version number
lec      -version      # should print version number
```

If any tool is not found, you likely need to source a setup script that adds
the Cadence tools to your `$PATH`. On the RWU workstation, this is handled
automatically. On other machines, you typically run something like:
```bash
source /eda/cadence/setup.sh
# or
module load cadence/genus
module load cadence/innovus
```

Ask your system administrator for the correct command on your workstation.
