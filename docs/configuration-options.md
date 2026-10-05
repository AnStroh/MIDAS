---
layout: page
title: Configuration Options
permalink: /configuration-options/
---

`MIDAS_Params.m` is organized into six sections; this page walks through the mode switches in each - the fields whose *meaning* changes depending on another field's value, or whose choice changes which other fields matter. For a flat list of every field, see [API Reference]({{ '/api-reference/' | relative_url }}); for six ready-made combinations of all of these, see [Examples]({{ '/examples/' | relative_url }}).

Three combinations come up often enough that the project's own technical documentation gives them names, used below:

- **Case 1 (prograde path)**: `checkmaxT_Eq = 1` - the model stops advancing once maximum $T$ is reached, so only the prograde (burial/  heating) leg is simulated.
- **Case 2 (full clockwise path)**: `checkmaxT_Eq = 0` - prograde and   retrograde legs are both simulated, tracing out the full P-T-t loop.
- **Case 3 (thermodynamic equilibrium data)**: `eqMode = 'PD'` - major- element equilibrium compositions come from a Perplex phase diagram instead of a fitted polynomial. Independent of cases 1/2 above; combine freely with either.

## Flags and general input

Whether to record a movie (`make_movie`), whether/what to plot (`doPlot`, `plot_kind`), whether to save results (`save_data`, `store_history`), the output base name (`data_name`), and cosmetic figure settings (`FSS`, `LWW`). None of these affect the physics - safe to change freely, including mid-experimentation.

## P-T path shape: `PTmode`

- **`'Tbump'`** - the older, simpler parameterization: $T$ follows a   parabola through `Tstart`/`Tstop` with amplitude set by `delT` (the   thermal maximum during decompression), while $P$ is linear between   `Pstart`/`Pstop`. $T$ and $P$ necessarily peak at related times.
- **`'peak'`** - $T$ and $P$ each follow their own shape-preserving PCHIP  curve through three anchor points (start, peak, end), with **independent**  peak timing (`T_peak_frac` vs. `P_peak_frac`) - lets burial and heating  peak at different times, as in a typical clockwise orogenic P-T-t path.  This is the more general option and what all six shipped examples use  except `Example3_ThermalBump`.

`checkmaxT_Eq` and `checkFinT_Eq` then modify *how much* of that path gets run: `checkmaxT_Eq = 1` truncates the run at the thermal peak (case 1, above); `checkFinT_Eq > 1` (e.g. `4.5`) instead extends the run to `checkFinT_Eq * t_tot` at constant final P-T, letting the system relax toward equilibrium after nominal peak conditions are reached. The two can combine: peak-truncate the prograde path, then relax for a bit at that peak. **Caveat**: setting `checkFinT_Eq` to exactly `1` currently errors (`griddedInterpolant: Sample points must be unique`) since the appended relaxation-tail timestamp duplicates the path's own last time sample - use `0` (no extension) or a value `> 1` instead.

## Major-element equilibrium source: `eqMode`

- **`'poly'`** - a 3-point bilinear fit (`Tar`/`Par`/`Car_G`/`Car_B`, three T-P-composition anchor points, least-squares fit) - no external file needed, extrapolates smoothly (never errors) outside the fitted range.
- **`'PD'`** (case 3, above) - equilibrium compositions are bilinearly   interpolated from a Perplex phase-diagram table (`params.PD`, a filename   resolved relative to the current working directory) - see [Phase Diagrams]({{ '/phase-diagrams/' | relative_url }}) for the required format and how to generate one. Raises an explicit error if the requested $(T,P)$ falls outside the table's range, rather than silently extrapolating.

If `eqMode = 'PD'` but `params.PD` isn't found, MIDAS falls back to `'poly'` automatically (and does the equivalent fallback for `MnMode`/ `MniBMode` below) - useful for keeping an example runnable even without the phase-diagram file present, but worth knowing about if a run behaves unexpectedly different from what you configured.

## Mn partitioning: `MnMode` and `MniBMode`

- **`MniBMode`** sets the matrix's initial Mn reservoir: `'manual'` (use  `params.MniB` directly) or `'PD'` (read it from the phase diagram at  `Tstart`/`Pstart`).
- **`MnMode`** sets the crystal/matrix Mn partition coefficient: `'fixed'`  (constant `params.KDMn`) or `'PD'` (temperature/pressure-dependent,  derived from the phase-diagram's own Grt/Bt Mn ratio at each step).

These two interact: if `MniBMode = 'manual'` while `MnMode = 'PD'`, MIDAS overrides `MnMode` to `'fixed'` automatically (a user-specified matrix reservoir combined with a phase-diagram-derived $K_D$ would be internally inconsistent) and prints a note explaining why.

## Geometry: `ndim`

`1` planar, `2` cylindrical, `3` spherical - the exponent in the geometry-dependent diffusion equation (see [Equations]({{ '/equations/' | relative_url }})). Purely geometric; doesn't otherwise change any other switch's meaning, except its interaction with `NBC` below.

## Outer boundary condition: `NBC`

`1`: Neumann (no-flux), appropriate for a closed system. `0`: Dirichlet, fixing the outer boundary composition at its initial value - simulating an open system backed by an infinite reservoir. The domain has two boundaries, handled independently (`implicitDiffusionSolver.m`):

- **Left (x=0)** - the center of the domain for cylindrical/spherical   geometry (`ndim` = 2/3): always Neumann there, regardless of `NBC` - a  no-flux condition is physically required by symmetry at the center of a  cylinder or sphere, not a free choice. For planar geometry (`ndim` = 1),  this boundary is a real physical edge, not a center, so it follows `NBC`  like the right boundary does.
- **Right (outer edge of phase B)** - always follows `NBC` directly,  independent of geometry: Neumann if `NBC=1`, Dirichlet if `NBC=0`, for  every `ndim`.

So for `ndim` = 2/3, `NBC` only controls the *outer* edge - the center is always closed. For `ndim` = 1, `NBC` controls both boundaries together.

## Isochron reference point: `isoRefMode`

Which "second mineral" phase A's isochron age is regressed against: `'bulk'` (phase B's volume-weighted average), `'core'` (phase B's node farthest from the interface - least diffusively disturbed), or `'wholerock'` (volume-weighted average of phase A + phase B together, a whole-rock-style comparison). `isoNskip`/`isoShowProfile` add extra profile-point isochrons on top of the always-computed core/rim/bulk/max set
- see [Equations]({{ '/equations/' | relative_url }}#apparent-age-determination).

## Recording cadence: `recordMode`

`'iteration'`: record every `nout` iterations - simple, but since `dt` is adaptive, this is *not* evenly spaced in time. `'time'`: record every `recordDT` Myr instead - evenly spaced in model time, at the cost of occasionally recording sub-steps more or less often depending on how `dt` happens to align. Most example configurations use `'time'`.

## Plotting: `plot_kind`

`1`: MgO profile + phase diagram with P-T path + apparent ages + isochrons.`2`: all concentration profiles + apparent ages + isochrons (no phase diagram panel). `3`: everything. Purely cosmetic - doesn't affect the computed result, only what `doPlot = true` draws each recorded step.
