---
layout: page
title: Benchmarks
permalink: /benchmarks/
---

MIDAS's main self-consistency check is **total mass balance**: MgO, MnO, and the non-radiogenic Hf reference field (`Hfr`) have no physical source or sink in this model (no decay, no reaction with anything outside the crystal/matrix pair), so under a closed system their volume-weighted total should stay constant throughout a run - any drift is purely numerical (discretization error, and the `pchip` regridding step after each interface move; see [Equations](equations#numerical-implementation)). This is the same benchmark used in the project's own technical documentation (Stroh et al., in prep.).

## The check

$$
\overline{M}(t) = \frac{\int C(t)\, dV}{\int dV}, \qquad \delta M(t) = \frac{\overline{M}(t) - \overline{M}(0)}{\overline{M}(0)}
$$

computed by trapezoidal quadrature over both phases together (`calc_mass_vol`), for a **closed system** (`NBC = 1` and/or `ndim = 1` - see [Configuration Options](configuration-options#outer-boundary-condition-nbc) for when the outer boundary is actually closed). $\delta M$ is tracked every recorded step for MgO (`R.dMB`), MnO (`R.dMBMn`), and Hfr (`R.dMBHfr`), with the run's peak drift also summarized as `R.dMB_max`/`R.dMBMn_max`/`R.dMBHfr_max`. To reproduce:

```matlab
R = MIDAS_Main(params);       % params.store_history = 1
plot_massbalance_MgO(R)       % MgO drift only
plot_massbalance(R)           % MgO, MnO, and Hfr together
```

## Results (full-resolution, full-duration runs)

Peak absolute drift over the whole run (including the `checkFinT_Eq` relaxation tail), at each example's own shipped grid resolution and total time - not the coarser/shorter grid the CI smoke test uses:

| Example | $S_{final}$ (% of $S_0$) | $\max\lvert\delta M_{\mathrm{MgO}}\rvert$ | $\max\lvert\delta M_{\mathrm{MnO}}\rvert$ | $\max\lvert\delta M_{\mathrm{Hfr}}\rvert$ |
|---|---|---|---|---|
| Example1_Baseline | 202% | $6.4\times10^{-3}$ | $4.6\times10^{0}$ | $3.5\times10^{-1}$ |
| Example2_PolyEquilibrium | 161% | $1.2\times10^{-4}$ | $1.0\times10^{-1}$ | $9.3\times10^{-4}$ |
| Example3_ThermalBump | 193% | $6.5\times10^{-3}$ | $4.5\times10^{0}$ | $2.1\times10^{-1}$ |
| Example4_ManualPartitioning | 202% | $6.4\times10^{-3}$ | $3.4\times10^{0}$ | $3.5\times10^{-1}$ |
| Example5_PlanarGeometry | 100% | $5.6\times10^{-3}$ | $1.2\times10^{0}$ | $1.6\times10^{-1}$ |
| Example6_CylindricalGeometry | 137% | $5.5\times10^{-3}$ | $3.7\times10^{0}$ | $1.6\times10^{-1}$ |

**MgO** stays small (0.01-0.65%) across all six, consistent with the "negligible, changes in the fourth digit" description in the project's own technical write-up, and is the metric [`plot_massbalance_MgO.m`](../matlab/plot_massbalance_MgO.m) was added specifically to visualize.

**MnO is not well conserved** in these full-length runs - up to 460% peak drift for `Example1`/`Example4`, far larger than MgO's. Investigated further (`Example1_Baseline`, full history):

- The drift isn't noise - it tracks crystal size almost exactly: it grows   from 0 to +449% while the crystal grows (t=0-14 Myr), then *shrinks* back down (+449% to +52%) while the crystal resorbs afterwards, and keeps changing smoothly even after `KDMn` goes perfectly constant (t>15.8 Myr, once $T,P$ reach `Tstop`/`Pstop`). So this isn't really "noise accumulating over time" - it's tied to *interface movement* itself, not to elapsed time or to `KDMn` varying per se.
- Every species goes through the identical `pchip` regridding call, on the  same grid, at the same instants - so the *mechanism* isn't species-specific. But `pchip` is shape-preserving, not mass-conservative, and MgO's crystal/matrix concentration jump at the interface is mild (ratio ~3-8x) compared to Mn's (`KDMn`~35-40x) and Hfr's (`1/KDHf`=25x).
- **Jump size confirmed as a real driver, by direct test**: rerunning `Example1_Baseline` with `MnMode` forced to `'fixed'` and `KDMn=5` (matching MgO's own ~3-9x ratio range, instead of the phase-diagram-derived ~35-40x) drops `dMBMn_max` from 4.63 (463%) to 0.46 (46%) - a **10x reduction** from changing one parameter. Isolating further: changing only `DRG_Mn` from `1e3` to `500` (matching `DRG`) left `dMBMn_max` at 4.61 - essentially no effect; changing only `KDMn` reproduced almost the entire drop alone (0.457). The partition-coefficient jump size drives this, not the diffusivity contrast. (Parameter-only experiment - no solver code changed to produce it.)
- **But the `pchip` regridding step itself turned out not to be where the mass actually goes.** Tested directly: in a scratch copy (never applied to the real repo), added a mass-conservative rescale right after every `pchip` resample, for every species, in both the growth and resorption branches - the textbook fix for exactly this kind of non-conservative remap. Result: `dMBMn_max` barely moved (4.633 to 4.625), `dMBHfr_max` barely moved (0.347 to 0.342). MgO's own (already small) drift *did* improve consistently (~20% smaller across all six examples), confirming the correction itself works - it just isn't where most of Mn/Hfr's drift comes from. Extending the same correction to the `microStepTol` in-place-update branch changed nothing further (that branch never actually fires in these runs, at this resolution).
- **Phase-diagram data quality ruled out**: checked `Pelite_avg_1.dat`'s MnO fields directly against MgO's - not meaningfully rougher (normalized curvature 0.003-0.005 vs. 0.001-0.004), and along the actual P-T path, `KDMn`'s relative step-to-step variability is *smaller* than MgO's own equilibrium ratio's (13% as jumpy, not more). If the phase-diagram table itself were the problem, `KDMn` should look choppier than MgO's ratio - it doesn't.
- **Correlates strongly with interface velocity `v` instead**: `corr(|v|, |step-change in dMBMn|) = 0.80`; `corr(v, step-change in dMBHfr) = -0.64` (signed, and systematically so - not noise). During growth (`v>0`), Hfr's drift goes *negative* while Mn's goes strongly *positive*; the moment `v` flips negative (resorption), both reverse. They respond to growth/resorption in **opposite directions**, consistent with their partition coefficients sitting on opposite sides of 1 (`KDMn`~40 pulls Mn into the crystal; `1/KDHf`=25 keeps Hfr in the matrix), and both tracking `v` directly.

Taken together, this now points back at **`solveBC`'s own boundary-value formula** - specifically its dependence on the externally-fixed, major-element-derived velocity `v` - rather than the regridding/interface-tracking bookkeeping the first round of testing targeted. That was the original hypothesis before the regridding lead looked more promising; today's evidence (regrid correction insufficient, phase-diagram ruled out, strong `v` correlation) shifts it back. **Not yet fixed, and investigation paused here for now** (at the authors' request, to pick back up later) - see [`CHANGELOG.md`](../CHANGELOG.md). No solver code has been changed in the real repo at any point during this investigation - every test above ran against a disposable scratch copy.

## Fixed: all six examples now complete at full resolution

Earlier testing found `Example1_Baseline`, `Example3_ThermalBump`, and `Example4_ManualPartitioning` hit `error('better stop here (crystal becomes negligible)')` before reaching `t_tot` at their own shipped grid resolution - the crystal resorbed to under 5% of the domain during the `checkFinT_Eq` relaxation tail. Root cause: at `checkFinT_Eq=4.5`, the model holds $T,P$ constant at `Tstop`/`Pstop` for $3.5\times t_{tot}$ past nominal peak conditions - and the phase-diagram-derived MgO equilibrium composition at `Tstop`/`Pstop` is *lower* than at peak conditions, so the crystal (grown to reflect the peak) keeps resorbing for as long as that tail runs, with no sign of approaching a new steady size within it (all six examples show the same trend - `ndim=3` combined with `eqMode='PD'` is what let three of them cross the 5%-of-domain floor before the others). Fixed by shortening `checkFinT_Eq` from `4.5` to `2.5` in all six examples and in `MIDAS_Params.m`'s own default - long enough to still show meaningful post-peak relaxation, short enough that every example now completes cleanly with a physically sensible net-growth result (see the $S_{final}$ column above) instead of continuing indefinitely toward zero.

## Known limitation: `octave/MIDAS_Params.m`'s defaults diverge from `matlab/`'s

While fixing the above, `octave/MIDAS_Params.m` (the Octave port's own default parameter file, independent of the six examples) turned out to differ from `matlab/MIDAS_Params.m` in more than just `checkFinT_Eq` (already a safe `1.5` there) - `lxA`, `DRG`, `KDLu`, `KDMn`, `Tstop`, `Pstop`, `T_peak_frac`, and the poly-mode fit fields (`Tar`/`Par`/`Car_G`/ `Car_B`) all carry different, non-`NaN` values even though `eqMode='PD'` means the poly-mode fields aren't used - contradicting both the "unused fields are `NaN`" convention used everywhere else in this project and the documented claim that `octave/` mirrors `matlab/`'s defaults. Left untouched here rather than guessed at, since it's unclear whether this was a deliberate, separately-tuned default or drift from an earlier version of `matlab/MIDAS_Params.m` - needs a decision from the authors on which set of numbers is the intended default before reconciling.
