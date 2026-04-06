# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project uses
semantic versioning (MAJOR.MINOR.PATCH).

---

## [v1.0] — 2026-03-29

### Summary
First release. Establishes the complete baseline RTL-to-GDSII flow using
Cadence Genus (synthesis), Cadence Innovus (place and route), and GPDK045 (45 nm).
The example design is a 2-bit saturating counter branch predictor FSM.

### What is Included
- Genus synthesis script with full comments (`scripts/synthesis/genus_synth.tcl`)
- Innovus place-and-route script covering all 14 P&R stages (`scripts/pnr/innovus_pnr.tcl`)
- MMMC multi-corner timing setup (`scripts/pnr/mmmc_setup.tcl`)
- Conformal LEC equivalence checking script (`scripts/lec/lec_rtl_vs_synth.do`)
- Complete example design: branch predictor RTL + testbench + SDC constraints
- Documentation: errors and fixes, tool setup guide, references

### Verified Results on GPDK045
- Zero DRC violations
- Zero timing violations at 100 MHz (WNS = +7.342 ns)
- All Conformal LEC compare points: EQUIVALENT

### Known Limitations in v1
- Scripts are written specifically for Cadence Genus + Innovus. OpenROAD/Yosys
  support is planned for a future version.
- Only the GPDK045 PDK is supported out of the box. Other PDKs require manual
  path and cell name changes (see `docs/TOOL_SETUP.md`).
- The flow is tested in Innovus **legacy mode** only. Stylus mode (newer command
  syntax) is not yet covered.
- No power analysis (Voltus) or formal timing sign-off (Tempus) scripts yet.
- No post-route gate-level simulation script with SDF back-annotation yet.

---

## [v2.0] — Planned

### Planned Additions
- OpenROAD + Yosys open-source flow alongside the Cadence flow
- SkyWater SKY130 PDK support
- Post-route gate-level simulation script with SDF back-annotation
- A more complex example design (8-bit ALU or simple RISC-V pipeline stage)
- Innovus Stylus mode scripts (side by side with legacy mode scripts)
- Cadence Tempus standalone timing sign-off script
- Automated Makefile to run the full flow with a single command

---

## How to Contribute

If you use this repository and find an error not documented in `docs/ERRORS_AND_FIXES.md`,
or if you add support for a new PDK or tool, please open a Pull Request or an Issue
on GitHub. Include the exact error message, your tool version, and the fix.
