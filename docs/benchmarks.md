---
layout: page
title: Benchmarks
permalink: /benchmarks/
---

MIDAS's main self-consistency check is **total mass balance**: MgO has no physical source or sink in this model (no decay, no reaction with anything outside the crystal/matrix pair), so under a closed system its volume-weighted total should stay constant throughout a run - any drift is purely numerical (discretization error, and the `pchip` regridding step after each interface move; see [Equations](equations#numerical-implementation)). This is the same benchmark used in the project's own technical documentation (Stroh et al., in prep.).

## The check

$$
\overline{M}(t) = \frac{\int C(t)\, dV}{\int dV}, \qquad \delta M(t) = \frac{\overline{M}(t) - \overline{M}(0)}{\overline{M}(0)}
$$

computed by trapezoidal quadrature over both phases together (`calc_mass_vol`), for a **closed system** (`NBC = 1` and/or `ndim = 1` - see [Configuration Options](configuration-options#outer-boundary-condition-nbc) for when the outer boundary is actually closed). $\delta M$ is tracked every recorded step for MgO (`R.dMB`), with the run's peak drift also summarized as `R.dMB_max`. To reproduce:

```matlab
R = MIDAS_Main(params);       % params.store_history = 1
plot_massbalance_MgO(R)       % MgO drift only
```

## Results (full-resolution, full-duration runs)

Peak absolute drift over the whole run (including the `checkFinT_Eq` relaxation tail), at each example's own shipped grid resolution and total time - not the coarser/shorter grid the CI smoke test uses:

| Example | $S_{final}$ (% of $S_0$) | $\max\lvert\delta M_{\mathrm{MgO}}\rvert$ |
|---|---|---|
| Example1_Baseline | 202% | $6.4\times10^{-3}$ |
| Example2_PolyEquilibrium | 161% | $1.2\times10^{-4}$ |
| Example3_ThermalBump | 193% | $6.5\times10^{-3}$ |
| Example4_ManualPartitioning | 202% | $6.4\times10^{-3}$ |
| Example5_PlanarGeometry | 100% | $5.6\times10^{-3}$ |
| Example6_CylindricalGeometry | 137% | $5.5\times10^{-3}$ |

**MgO** stays small (0.01-0.65%) across all six, consistent with the "negligible, changes in the fourth digit" description in the project's own technical write-up, and is the metric [`plot_massbalance_MgO.m`](../matlab/plotting/plot_massbalance_MgO.m) was added specifically to visualize.

## Fixed: all six examples now complete at full resolution

Earlier testing found `Example1_Baseline`, `Example3_ThermalBump`, and `Example4_ManualPartitioning` hit `error('better stop here (crystal becomes negligible)')` before reaching `t_tot` at their own shipped grid resolution - the crystal resorbed to under 5% of the domain during the `checkFinT_Eq` relaxation tail. Root cause: at `checkFinT_Eq=4.5`, the model holds $T,P$ constant at `Tstop`/`Pstop` for $3.5\times t_{tot}$ past nominal peak conditions - and the phase-diagram-derived MgO equilibrium composition at `Tstop`/`Pstop` is *lower* than at peak conditions, so the crystal (grown to reflect the peak) keeps resorbing for as long as that tail runs, with no sign of approaching a new steady size within it (all six examples show the same trend - `ndim=3` combined with `eqMode='PD'` is what let three of them cross the 5%-of-domain floor before the others). Fixed by shortening `checkFinT_Eq` from `4.5` to `2.5` in all six examples and in `MIDAS_Params.m`'s own default - long enough to still show meaningful post-peak relaxation, short enough that every example now completes cleanly with a physically sensible net-growth result (see the $S_{final}$ column above) instead of continuing indefinitely toward zero.

## Known limitation: `octave/MIDAS_Params.m`'s defaults diverge from `matlab/`'s

While fixing the above, `octave/MIDAS_Params.m` (the Octave port's own default parameter file, independent of the six examples) turned out to differ from `matlab/MIDAS_Params.m` in more than just `checkFinT_Eq` (already a safe `1.5` there) - `lxA`, `DRG`, `KDLu`, `KDMn`, `Tstop`, `Pstop`, `T_peak_frac`, and the poly-mode fit fields (`Tar`/`Par`/`Car_G`/ `Car_B`) all carry different, non-`NaN` values even though `eqMode='PD'` means the poly-mode fields aren't used - contradicting both the "unused fields are `NaN`" convention used everywhere else in this project and the documented claim that `octave/` mirrors `matlab/`'s defaults. Left untouched here rather than guessed at, since it's unclear whether this was a deliberate, separately-tuned default or drift from an earlier version of `matlab/MIDAS_Params.m` - needs a decision from the authors on which set of numbers is the intended default before reconciling.
