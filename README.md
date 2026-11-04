# Low-Power RISC-V (Ibex) SoC with UPF Power Gating — RTL to GDSII

Power-gated version of an Ibex RV32IMC SoC (2 × 4 KB SRAM macros), taken from RTL through
UPF-aware synthesis, multi-supply physical design and signoff in a 45 nm flow at 200 MHz.

**Tools:** Cadence Xcelium · Genus · Conformal Low Power · Innovus (Stylus) · Tempus · Voltus · Pegasus
**Tech:** GPDK045 (gsclib045, 1.2 V), IEEE 1801 UPF 2.0

---

## Key results

| Area | Result |
|---|---|
| Power-aware simulation (Xcelium `-lps_1801`) | RUN → SLEEP → RUN sequence passes; core outputs `x` while off, isolated outputs clamped to 0; DMEM data retained across power cycle |
| Power-intent check (Conformal Low Power) | Netlist + UPF consistent: 2,024 key points equivalent, 0 LP rule violations |
| Power switches | 262 HSWX1 header switches, 4 daisy-chained columns (checkerboard) |
| Isolation | 80 ISOLX1_ON cells on used core outputs (157 redundant PnR-inserted cells audited and removed) |
| Signoff STA (Tempus, SPEF, OCV + CPPR + SI) | Setup WNS **+115 ps**, hold WNS **+64 ps**, no max-tran / max-cap violations |
| Power (Voltus, 1.08 V / 125 °C) | CPU-domain sleep leakage **1.41 µW → 0.26 µW (−81 %)**; 2.44 mW core active power removed in sleep |
| DRC (Pegasus) | 0 violations in the implemented design (SRAM-abstract corner results waived) |
| LVS (Pegasus) | 112,931 / 112,931 devices and 83 / 83 ports matched; VDD / VDD_CORE / VSS topology verified |

> SRAM macros are black boxes (no SRAM GDS available). Nets ending on SRAM pins cannot be
> fully verified in LVS, and the SRAM `.lib` has placeholder leakage — power savings are quoted
> for the CPU domain only.

---

## Architecture

```
                      always-on domain PD_TOP (VDD)
 ┌──────────────────────────────────────────────────────────────┐
 │  PMU FSM ──pso──► [HSWX1 × 262, daisy chain] ──► VDD_CORE      │
 │     │  └─iso──► [ISOLX1_ON × 80] ◄── core outputs              │
 │     └─rst                                                      │
 │  IMEM 4 KB   DMEM 4 KB   GPIO   loader       ┌───────────────┐ │
 │                                              │ PD_CORE        │ │
 │                                              │ (VDD_CORE)     │ │
 │                                              │ Ibex RV32IMC   │ │
 │                                              └───────────────┘ │
 └──────────────────────────────────────────────────────────────┘
```

**PMU sequence:** core sleeps (WFI) → isolate outputs → hold core in reset → switch off
→ … `wake_i` → switch on → 16-cycle ramp → de-isolate → release reset → core reboots.

---

## Flow

1. **RTL** – `ibex_pmu.sv` (sequencing FSM), SoC wrapper with `wake_i` / `core_off_o`
2. **UPF** – power domains, switch, isolation strategy, power-state table (`upf/`)
3. **Simulation** – functional + power-aware (Xcelium `-lps_1801`)
4. **Synthesis** – Genus with `read_power_intent` / `commit_power_intent`, isolation insertion
5. **LP verification** – Conformal Low Power, native 1801 (`compare power consistency`)
6. **Floorplan** – power-domain fence for the core, SRAM placement
7. **Power switches** – `addPowerSwitch` columns, checkerboard, enable daisy chain
8. **Power grid** – always-on VDD/VSS ring + stripes, switched VDD_CORE followpins/stripes,
   VDD straps over switch pins to feed the always-on ExtVDD input
9. **Place / CTS / route** – domain-aware placement and clock tree, OCV + SI post-route opt
10. **Signoff** – SPEF extraction, Tempus STA, Voltus power, GDS stream-out, Pegasus DRC/LVS

---

## Problems solved (highlights)

- **Double isolation risk:** Innovus inserted 157 isolation cells on unloaded core outputs that
  Genus skipped → audited (chained vs dangling) and removed, re-verified with `verifyPowerDomain`.
- **Switch never powered:** HSWX1's always-on `ExtVDD` is an internal Metal1 pin, not on a rail →
  stripes over the switch pins with vias allowed on std-cell pins (2,620 vias).
- **Floating VSS grid:** stripes stopped 0.5 µm short of the outer ring — caught only by connectivity check.
- **Signal-to-PG shorts:** std cells placed under the always-on Metal2 switch straps → placement blockages.
- **3,444 well/implant DRCs:** missing filler cells → 17,125 fillers inserted.
- **Stacked-via DRCs:** 143 nets capped at Metal5 and rerouted.
- **Multi-supply LVS:** v2cdl wrote `.GLOBAL VDD`, silently merging VDD_CORE into VDD in the schematic →
  removed; the internal switched net must not be labeled as a top-level port.

---

## Repository layout

```
rtl/          ibex_pmu.sv, ibex_soc.sv (Ibex core itself: lowRISC, Apache-2.0 – not included)
sim/          testbench, file list, power-aware run script
upf/          ibex_soc.upf (simulation), ibex_soc_syn.upf (synthesis, cell mapping)
constraints/  SDC (implementation + signoff)
syn/          Genus low-power synthesis script, Conformal LP dofile
pnr/          Innovus scripts: floorplan, switches, power grid, place, CTS, route, ECOs, stream
              + Python helpers (GDS labels, black-box SRAM stub, DRC result parser)
sta/          Tempus signoff scripts + reports
power/        Voltus static power script
scripts/      common setup (paths)
```

PDK / library files (`.lib`, `.lef`, `.gds`, CDL, rule decks) are licensed and are **not** included.

---

## Author
Nikshitha N Shetty — M.E. VLSI, MSIS Manipal
