---
layout: page
title: API Reference
permalink: /api-reference/
---

## Core functions

### `MIDAS_Params()`
Returns the default `params` struct. Every field is documented inline in the file itself; the tables below summarize them by section. Call with no arguments for defaults, then override individual fields, or call one of the `examples/ExampleN.m` functions instead for a ready-made configuration (see [Examples](examples)).

### `R = MIDAS_Main(params)`
Runs the model once. Returns a struct `R` with: 

| Field | Contents |
|---|---|
| `R.params` | The params struct actually used for this run |
| `R.S_final`, `R.v_final` | Final crystal size (mm) and growth velocity (mm/Myr) |
| `R.xA_final`, `R.xB_final` | Final-state node positions, phase A / phase B |
| `R.CA_final`, `R.CAMn_final`, `R.CALu_final`, `R.CAHf_final` | Final-state MgO/MnO/Lu/Hf profiles, phase A (and `CB_*` equivalents for phase B) |
| `R.tALuHf1_final` | Final-state apparent Lu-Hf age profile, phase A |
| `R.trec`, `R.Srec`, `R.Vrec`, `R.Trec`, `R.Prec` | Full time history (only if `params.store_history = 1`): time, size, velocity, T, P |
| `R.tA1`, `R.tB1` | Full time-history apparent-age profiles, phase A / phase B |

### `Run_MIDAS.m`
Not a function - a script. Loads `MIDAS_Params()` (or swap in an example), runs `MIDAS_Main`, shows every post-run figure, and optionally exports each one. See [Getting Started](getting-started).

See [Configuration Options](configuration-options) for a narrative walkthrough of the mode switches below (which combinations are valid, how they interact), [Equations](equations) for the physics/numerics behind them, [Mesh & Time-Step Refinement](mesh-refinement) for choosing `nx_A`/`nx_B`/`CFL`, and [Interpreting Output](interpreting-output) for what to do with `R` once you have it.

## Parameters, by section

### Output / plotting
`outDir`, `data_name`, `save_data`, `make_movie`, `doPlot`, `saveCheckpoints`, `plot_kind`, `FSS` (font size), `LWW` (line width).

### Programming flags and options
`checkmaxT_Eq`, `checkFinT_Eq` (relaxation at constant final P-T), `store_history`, `nout`/`recordMode`/`recordDT` (recording cadence: every N iterations or every N Myr), `CFL`, `nStepsMin`, `microStepTol`.

### Physics (diffusion and growth)
`lxA`, `lxB_factor` (crystal/matrix size), `DRG`/`DRG_LuHf`/`DRG_Mn` (diffusivity ratios), `DamA`/`DamB` (Damköhler II, interface kinetics), `KDLu`/`KDHf`/`KDMn` (partition coefficients), `MnMode` (fixed vs phase-diagram-derived KD_Mn), `LuiB`/`HfiB`/`HfiBref` (initial matrix trace-element contents), `MniBMode`/`MniB` (initial matrix Mn, manual vs phase-diagram-derived), `isoRefMode`/`isoNskip`/`isoShowProfile` (isochron-age diagnostics).

### Time and P-T path
`t_tot`, `PTmode` (`'Tbump'` vs `'peak'`), `Tstart`/`Tstop`/`delT` (Tbump-only), `Tpeak`/`T_peak_frac`/`Ppeak`/`P_peak_frac` (peak-only), `Pstart`/`Pstop`, `Trange`/`Prange` (visualization only).

### Thermodynamics (major elements)
`eqMode` (`'poly'` vs `'PD'`), `Tar`/`Par`/`Car_G`/`Car_B` (poly-only 3-point fit), `PD` (Perplex table filename, PD-only).

### Numerics
`ndim` (1 planar / 2 cylindrical / 3 spherical), `NBC`, `nx_A`, `nx_B` (grid resolution).

## Plotting functions

Every function below takes the `R` struct returned by `MIDAS_Main` and produces one figure (a few produce more than one - noted).

| Function | Shows |
|---|---|
| `plot_velocity_age(R)` | 2 figures: relative-misfit heatmap (signed-log color scale) vs. crystal size and time (with interface velocity vs. time alongside it), and a standalone apparent-age-only panel |
| `plot_misfit(R)` | Worst-case apparent-age and isochron-age misfit vs. true time |
| `plot_massbalance_MgO(R)` | Mass-balance drift, MgO only |
| `plot_age_at_fixed_positions(R)` | Apparent age vs. time, tracked at fixed distances from the core |
| `plot_conc_at_fixed_positions(R)` | Lu, Hf concentrations vs. time at the same fixed positions |
| `plot_age_vs_temperature(R)` | Closure-temperature diagnostic: apparent age vs. T |
| `plot_all_composition_profiles(R)` | Every element/isotope's final-state profile, phase A vs. phase B, one figure |

## Export functions

| Function | Does |
|---|---|
| `export_pub_fig(fig, filename)` | Saves a figure as a vector PDF + 300 dpi PNG, both with and without its title |
| `export_results_excel(R, filepath)` | Writes scalar/summary fields of `R` to an Excel file (one sheet per group of same-length vector fields); falls back to CSV under Octave without the `io` package |
