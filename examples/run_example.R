##############################################################################
# examples/run_example.R
# =======================
# End-to-end demo of the Wadhams NCA modules on a single-subject IV bolus
# profile. Run from the repo root:
#
#   Rscript examples/run_example.R
##############################################################################

source("R/nca_units.R")
source("R/nca_format.R")
source("R/nca_compute.R")

# ── A raw single-subject IV bolus profile ─────────────────────────────────────
# Dose given in mg, concentrations in ng/mL, time in hours. Note the first
# sample is post-dose (0.083 h) — C0 will be back-extrapolated automatically.
raw <- data.frame(
  Subject = 1,
  Time_hr = c(0,    0.083, 1,       3,     6,    24, 48),
  Conc    = c(NA,   2909.56, 1036.26, 23.78, 6.84, 0,  0),
  Dose_mg = c(14.1, NA,    NA,      NA,    NA,   NA, NA),
  Route   = c("iv", NA,    NA,      NA,    NA,   NA, NA)
)

cat("=== RAW INPUT ===\n"); print(raw)

# ── Phase 1: format to the standardised table ─────────────────────────────────
mapping <- list(id = "Subject", time = "Time_hr",
                conc = "Conc", dose = "Dose_mg", route = "Route")
units   <- list(time = "h", conc = "ng/mL", dose = "mg")

formatted <- format_nca_data(
  raw, mapping, units,
  lloq     = 1.0,            # flag concentrations < 1 ng/mL as BLQ
  blq_rule = "half_lloq"     # set BLQ values to LLOQ/2
)

cat("\n=== STANDARDISED TABLE (hours / ng·mL / ng) ===\n")
print(formatted)
cat(sprintf("\n%d subject(s), %d dose(s), %d observation(s), %d BLQ, %d > ULOQ\n",
            attr(formatted, "n_subj"), attr(formatted, "n_dose"),
            attr(formatted, "n_obs"),  attr(formatted, "n_blq"),
            attr(formatted, "n_alq")))

# ── Phase 2: run NCA ──────────────────────────────────────────────────────────
if (!nca_available()) {
  cat("\nPKNCA not installed — install with install.packages('PKNCA') to compute results.\n")
} else {
  out <- run_nca(formatted)
  if (length(out$messages) > 0) cat("\nNotes:", paste(out$messages, collapse = " | "), "\n")
  cat("\n=== NCA RESULTS ===\n")
  print(out$results)
  # Sanity check: CL should equal dose / AUCinf
  cl   <- out$results[["CL (mL/h)"]]
  auc  <- out$results[["AUCinf (ng·h/mL)"]]
  cat(sprintf("\nCheck: dose/AUCinf = %.0f mL/h  (reported CL = %.0f mL/h)\n",
              14.1e6 / auc, cl))
}
