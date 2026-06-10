# Wadhams NCA

Reusable R modules that turn messy raw LCMS/bioanalytical output into a
PKNCA-ready dataset and run non-compartmental analysis (NCA) on it.

These modules power the **NCA** tab of the
[Wadhams pharmacometrics platform](https://github.com/fbatema1/FHB_Human_PK_From_Structure_RShiny),
but are dependency-light and usable on their own from any R session or Shiny app.

## What it does

The workflow is two phases, mirroring how a pharmacometrician actually works:

1. **Format** — take an arbitrary upload (any column names, any units) plus a
   column mapping, and produce a standardised NONMEM-style table:
   `ID | TIME | CONC | DOSE | EVID | ROUTE | BLQ | ALQ`.
   - Units are converted to a single basis: **hours / ng·mL⁻¹ / ng**.
   - BLQ values (below LLOQ) are flagged and handled (`zero`, `half_lloq`, or `exclude`).
   - Values above ULOQ are flagged.
   - The user reviews/edits this table before computing anything.

2. **Compute** — feed the standardised table into [PKNCA](https://cran.r-project.org/package=PKNCA)
   and return a tidy subject × parameter results table (Cmax, Tmax, AUClast,
   AUCinf, t½, CL, Vss, Vz, MRT, …).
   - For IV bolus data where the first sample is post-dose, C0 is log-linearly
     back-extrapolated so AUC integrates from the dose time.
   - Extravascular doses get C0 = 0.

## Modules

| File | Purpose |
|------|---------|
| `R/nca_units.R`   | Unit definitions + conversion functions (time/conc/dose → standard basis). Handles molar units (needs MW) and per-kg doses (needs body weight). |
| `R/nca_format.R`  | `format_nca_data()` — raw + mapping + units → standardised table. `guess_nca_columns()` pre-fills the mapping from column names. |
| `R/nca_compute.R` | `run_nca()` — standardised table → tidy NCA results via PKNCA. `nca_available()` checks the optional PKNCA dependency. |

## Quick start

```r
source("R/nca_units.R")
source("R/nca_format.R")
source("R/nca_compute.R")

raw <- read.csv("my_lcms_export.csv")

mapping <- list(id = "Subject", time = "Time_hr",
                conc = "Conc_ng_mL", dose = "Dose_mg", route = "Route")
units   <- list(time = "h", conc = "ng/mL", dose = "mg")

formatted <- format_nca_data(raw, mapping, units,
                             lloq = 1.0, blq_rule = "half_lloq")
out <- run_nca(formatted)
out$results        # subject × parameter table
```

See [`examples/run_example.R`](examples/run_example.R) for a complete runnable
example.

## Standardised unit basis

| Quantity | Unit | Notes |
|----------|------|-------|
| Time | h | |
| Concentration | ng/mL | |
| Dose | ng | same mass base as concentration |
| CL | mL/h | dose(ng) / AUC(ng·h/mL) |
| Vd | mL | |

Molar concentration/dose units (`µmol/L`, `nmol/L`, `µmol`, `nmol`) require a
molecular weight. Per-kg doses (`mg/kg`, `µg/kg`) require a body weight.

## Dependencies

- **PKNCA** (CRAN) — the NCA engine. `run_nca()` errors clearly if it is absent;
  `nca_available()` lets callers degrade gracefully.
- Base R otherwise. Excel reading (in the host app) uses `readxl`.

## Licence

MIT — see [LICENSE](LICENSE).

## Citation

Part of the Wadhams pharmacometrics platform (Bateman F. et al., in preparation).
