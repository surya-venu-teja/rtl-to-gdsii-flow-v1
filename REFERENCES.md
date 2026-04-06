# References

This file lists all the learning materials, documentation, and papers that were
consulted during the development of this flow. They are grouped by category so
you can easily find resources for a specific topic.

---

## Official Cadence Documentation and Training

The most authoritative source for Genus and Innovus is Cadence's own documentation
and training portal. Most detailed user guides are available through the Cadence
Online Support portal (login required), but several free resources are publicly
accessible.

Cadence Design Systems. *RTL-to-GDSII Flow Training Course (Course 86136)*.
Cadence Training, 2023. A free 16-hour course covering Genus, Innovus, Conformal,
and Tempus end-to-end. Highly recommended as a starting point.
<https://www.cadence.com/en_US/home/training/all-courses/86136.html>

Cadence Design Systems. *Genus Synthesis Solution Product Page*.
<https://www.cadence.com/en_US/home/tools/digital-design-and-signoff/synthesis/genus-synthesis-solution.html>

Cadence Design Systems. *Innovus Implementation System Product Page*.
<https://www.cadence.com/en_US/home/tools/digital-design-and-signoff/soc-implementation-and-floorplanning/innovus-implementation-system.html>

Cadence Design Systems. *Digital Physical Design Domain Certification (Course 86354)*.
<https://www.cadence.com/en_US/home/training/all-courses/86354.html>

Cadence Design Systems. *Conformal Equivalence Checker Datasheet (PDF)*.
<https://www.cadence.com/content/dam/cadence-www/global/en_US/documents/tools/digital-design-signoff/conformal-equivalence-checker-ds.pdf>

Cadence Online Support Portal (login required for full documentation).
<https://support.cadence.com/>

Cadence Community Forums.
<https://community.cadence.com/>

Cadence University Program (free tool access for students and faculty).
<https://www.cadence.com/en_US/home/company/cadence-academic-network/university-program.html>

---

## GPDK045 PDK Documentation

Cadence Design Systems. *GPDK045 Generic 45 nm PDK Reference Manual*, version 6.0.
A mirror hosted by Princeton University.
<http://www.princeton.edu/~nverma/cadence_23.1/gpdk045_v_6_0/docs/gpdk045_pdk_referenceManual.pdf>

---

## Video Tutorials

Teman, A. *RTL2GDS Demo Course*. eNICS Lab, Bar-Ilan University.
The best freely available video series walking through the complete Cadence Genus +
Innovus flow with downloadable lecture slides. Highly recommended.
YouTube: <https://www.youtube.com/playlist?list=PLZU5hLL_713zf_i38C7uLu5pUz5wTjKul>
Slides and materials: <https://enicslabs.com/academic-courses/rtl2gds-demo/>

Cadence Design Systems. *Digital Design and Signoff Academic Curriculum (Course 86398)*.
A formal 15-week academic course by Prof. Teman, available through Cadence's
university program.
<https://www.cadence.com/en_US/home/training/all-courses/86398.html>

---

## University Course Materials

Cornell University. *ECE 5745 Tutorial 5: Synopsys/Cadence ASIC Tools*.
One of the most detailed and well-written publicly available ASIC tools tutorials.
Uses Innovus for back-end physical design.
<https://cornell-ece5745.github.io/ece5745-tut5-asic-tools/>

Cornell University. *ECE 5745 Tutorial 6: Automated ASIC Block Flow*.
<https://cornell-ece5745.github.io/ece5745-tut6-asic-flow/>

Cornell University. *ECE 5745 Section 2: ASIC Flow Back-End (Innovus Deep Dive)*.
<https://cornell-ece5745.github.io/ece5745-S02-back-end/>

University of California, Berkeley. *EECS 151/251A — ASIC Lab 3: Logic Synthesis*.
Uses Cadence Genus with the ASAP7 process.
<https://github.com/EECS150/asic_labs_fa21/blob/main/lab3/spec.md>

Iowa State University. *EE 330 Lab 9: ASIC Design Flow with Genus and Innovus
on GPDK045*. Directly relevant as it uses the same PDK as this repository.
<http://class.ece.iastate.edu/ee330/labs/EE%20330%20Lab%209%20Fall%202024.pdf>

---

## Reference GitHub Repositories

Abdelazeem, A. *Cadence RTL-to-GDSII Flow Tutorial*. GitHub, 2023.
The most complete freely available scripted example of the full Cadence flow.
<https://github.com/abdelazeem201/Cadence-RTL-to-GDSII-Flow>

VardhanSuroshi. *VLSI ASIC Design Flow (open-source tools)*.
<https://github.com/VardhanSuroshi/VLSI-ASIC-Design-Flow>

The OpenROAD Project. *OpenROAD — Open-Source RTL-to-GDS Flow*.
The leading open-source alternative to the Cadence flow, used for 600+ tapeouts.
<https://github.com/The-OpenROAD-Project/OpenROAD>

Efabless. *OpenLane 2 — RTL-to-GDS with SkyWater 130nm*.
The most beginner-friendly open-source flow, with detailed getting-started guides.
<https://github.com/efabless/openlane2>

---

## Conceptual Background and Blog Resources

eInfochips. *Layout Versus Schematic (LVS) Flow and Debug in ASIC Physical
Implementation*.
<https://www.einfochips.com/blog/layout-versus-schematic-lvs-flow-and-their-debug-in-asic-physical-verification/>

eInfochips. *A Guide on Logical Equivalence Checking Flow, Challenges and Benefits*.
<https://www.einfochips.com/blog/a-guide-on-logical-equivalence-checking-flow-challenges-and-benefits/>

Barua, P. *RTL to GDSII Flow: A Step-by-Step Guide*.
<https://www.prasunbarua.com/2025/03/rtl-to-gdsii-flow-step-by-step-guide.html>

VLSIGuru. *Physical Design in VLSI: A Complete Beginner's Guide to Core Concepts*.
<https://vlsiguru.com/blog/physical-design-in-vlsi-beginners-guide>

DigitalSystemDesign.in. *Placement and Routing Using Innovus with Scripts*.
<https://digitalsystemdesign.in/pnr-using-innovus-with-scripts/>

---

## Textbooks

Weste, N. H. and Harris, D. M. *CMOS VLSI Design: A Circuits and Systems
Perspective*, 4th edition. Addison-Wesley, 2010.
The standard reference textbook for CMOS circuit design and physical implementation.

Rabaey, J. M., Chandrakasan, A., and Nikolic, B. *Digital Integrated Circuits:
A Design Perspective*, 2nd edition. Prentice Hall, 2003.
A foundational reference for understanding how digital gates work at the transistor level.
