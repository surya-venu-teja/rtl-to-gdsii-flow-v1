# RTL-to-GDSII Physical Design Flow

**Version:** v1.0  
**Author:** Surya Venu Teja B  
**Institution:** Hochschule Ravensburg-Weingarten (RWU)  
**Tools Used:** Cadence Genus (Synthesis) + Cadence Innovus (Place & Route)  
**PDK:** GPDK045 (45 nm Generic Process Design Kit)  
**Status:** Complete — v1 baseline. Future versions planned.

---

## What Is This Repository?

This repository contains a complete, working **RTL-to-GDSII physical design flow** using Cadence EDA tools. The goal is to take a digital circuit written in Verilog and convert it all the way into a **GDSII file** — the final physical layout file that a chip foundry reads to manufacture the chip.

It is written to be a **learning resource first, a template second**. Every script is heavily commented so you understand not just *what* each command does, but *why* it is there. Every known error from running this flow is documented with its exact fix.

The example design used throughout is a **2-bit saturating counter branch predictor FSM** — small enough to understand in one sitting, but complex enough to exercise the full flow end to end.

> **Note for future versions:** This is v1 of the flow, built around Cadence Genus + Innovus + GPDK045. Future versions (v2+) are planned to cover alternative flows (OpenROAD/OpenLane), different PDKs (SkyWater 130nm, ASAP7), and more complex designs. See `CHANGELOG.md` for the version history.

---

## The Big Picture: What Does the Flow Do?

Before looking at any files, it helps to understand the journey at a high level. You start with *behavioural* Verilog code — text that describes what your circuit should do. You end with a GDSII file — a database of shapes (polygons, rectangles) on different layers of silicon, describing the exact physical location of every transistor and wire. The steps in between are:

```
Your Verilog (RTL)
      │
      ▼
[Step 1]  RTL Simulation       ← verify the logic works
      │
      ▼
[Step 2]  Logic Synthesis      ← Cadence Genus maps RTL → real gates
      │
      ▼
[Step 3]  Equivalence Check    ← Cadence Conformal proves gates == RTL
      │
      ▼
[Step 4]  Floorplanning        ← Cadence Innovus defines chip boundaries
      │
      ▼
[Step 5]  Placement            ← Innovus places gates on the floor
      │
      ▼
[Step 6]  Clock Tree Synthesis ← balanced clock network
      │
      ▼
[Step 7]  Routing              ← Innovus connects gates with wires
      │
      ▼
[Step 8]  Sign-off Checks      ← DRC, timing, connectivity
      │
      ▼
[Output]  GDSII File           ← ready for the foundry
```

---

## Repository Structure

```
rtl-to-gdsii-flow-v1/
│
├── README.md                        ← you are here
├── CHANGELOG.md                     ← version history and what changed
├── LICENSE                          ← MIT license
├── .gitignore                       ← tells git to ignore tool log files
│
├── scripts/                         ← reusable flow scripts (tool-specific)
│   ├── synthesis/
│   │   └── genus_synth.tcl          ← Cadence Genus synthesis script
│   ├── pnr/
│   │   ├── mmmc_setup.tcl           ← multi-corner timing setup for Innovus
│   │   └── innovus_pnr.tcl          ← Cadence Innovus place-and-route script
│   └── lec/
│       └── lec_rtl_vs_synth.do      ← Cadence Conformal LEC script
│
├── example_design/                  ← self-contained example you can run
│   ├── rtl/
│   │   ├── branch_predictor.v       ← the design under test (Verilog RTL)
│   │   └── tb_branch_predictor.v    ← testbench for simulation
│   └── constraints/
│       └── branch_predictor.sdc     ← SDC timing constraints (100 MHz)
│
└── docs/
    ├── ERRORS_AND_FIXES.md          ← every error hit during development + fix
    ├── TOOL_SETUP.md                ← how to configure tools and PDK paths
    └── REFERENCES.md                ← books, links, course materials
```

---

## Quick Start

### Prerequisites

You need the following tools installed and accessible in your `$PATH`. This flow was tested on the versions listed, but later versions of Genus and Innovus should also work.

| Tool | Command | Version Tested | Purpose |
|------|---------|----------------|---------|
| Cadence Genus | `genus` | 23.33 | Logic synthesis |
| Cadence Innovus | `innovus` | 23.33 | Place and route |
| Cadence Xcelium | `xrun` | 23.33 | RTL simulation |
| Cadence Conformal | `lec` | 23.33 | Equivalence checking |
| GPDK045 PDK | — | v6.0 | 45 nm standard cells |

If you are using a **different PDK** (e.g., SkyWater SKY130, ASAP7, or a commercial PDK), read `docs/TOOL_SETUP.md` first — you will need to update the library paths, filler cell names, and layer names in the scripts.

### Step 1 — Configure your paths

Open `scripts/synthesis/genus_synth.tcl` and `scripts/pnr/mmmc_setup.tcl`. At the top of each file you will find a clearly marked `USER CONFIGURATION` section with variables. Set `PDK_PATH` to point to your GPDK045 installation. Everything else in the scripts can stay unchanged for the branch predictor example.

### Step 2 — Set up directories and run simulation

```bash
# Clone and enter the repository
git clone https://github.com/YOUR_USERNAME/rtl-to-gdsii-flow-v1.git
cd rtl-to-gdsii-flow-v1

# Create output directories (not tracked by git)
mkdir -p example_design/synthesis/{output,reports}
mkdir -p example_design/PnR/{outputs,reports}

# Simulate the RTL first — always verify logic before synthesis
xrun example_design/rtl/branch_predictor.v \
     example_design/rtl/tb_branch_predictor.v \
     -timescale 1ns/1ps
```

### Step 3 — Run synthesis

```bash
cd scripts/synthesis
genus -f genus_synth.tcl -log genus_run.log
# Check example_design/synthesis/reports/timing_genus.rpt
# Worst Negative Slack (WNS) should be >= 0
```

### Step 4 — Run place and route

```bash
cd scripts/pnr
innovus -init innovus_pnr.tcl -log innovus_run.log
# Check example_design/PnR/reports/ for DRC and timing results
# Final GDSII: example_design/PnR/outputs/branch_predictor.gds
```

### Step 5 — Run equivalence check

```bash
cd scripts/lec
lec -xl -dofile lec_rtl_vs_synth.do -log lec_run.log
# All compare points should show: EQUIVALENT
```

---

## Adapting This Flow for a Different Design

One of the main purposes of this repository is to provide **reusable scripts**. The scripts are written so that only a small block of variables at the top needs to change when you switch to a different Verilog module. See `docs/TOOL_SETUP.md` for a detailed explanation of what to change and what stays the same.

As a quick summary:

**Change these (design-specific):**  `DESIGN` name, `RTL_FILES` list, `SDC_FILE` path, floorplan dimensions, and any timing exceptions in the SDC.

**Keep these (PDK-specific, same for all designs on GPDK045):** Library paths, filler cell names (`FILL1`–`FILL64`), core site name (`CoreSite`), MMMC corner definitions, and layer names (`Metal1`–`Metal8`).

---

## Known Errors and Fixes

A dedicated file `docs/ERRORS_AND_FIXES.md` documents every error encountered during development of this flow, with the exact error message, the root cause, and the fix. If you hit an error while running the scripts, check that file first. The six errors documented in v1 are:

1. `xrun` module not found (missing RTL file on command line)
2. Innovus layer name not found (lowercase vs. capitalised layer names in GPDK045)
3. Missing power/ground connections (`globalNetConnect` not called)
4. Innovus physical-only mode (MMMC setup sourced after `init_design`)
5. `check_place` not recognised (Stylus vs. legacy mode command naming)
6. `ccopt_design` PODv2 database error (use `clock_opt_design` in legacy mode)

---

## Results (v1 — Branch Predictor on GPDK045)

| Metric | Result |
|--------|--------|
| Target Frequency | 100 MHz |
| Worst Negative Slack (Setup) | **+7.342 ns — MET** |
| Hold Slack | **MET** |
| DRC Violations | **0** |
| Standard Cells Placed | 8 |
| Filler Cells Added | 18 |
| Placement Density | 39.77% |
| Final GDSII | `example_design/PnR/outputs/branch_predictor.gds` |

---

## Version History

See `CHANGELOG.md` for full details.

| Version | Date | Summary |
|---------|------|---------|
| v1.0 | 2026-03-29 | Initial release — branch predictor, Cadence Genus + Innovus, GPDK045 |

---

## License

This project is released under the MIT License. See `LICENSE` for details.

---

## Acknowledgements

This flow was developed as part of the Digital VLSI Physical Design course at Hochschule Ravensburg-Weingarten, under the guidance of Prof. SiggelKow. References and learning materials are listed in `docs/REFERENCES.md`.
