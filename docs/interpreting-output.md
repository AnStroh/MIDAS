---
layout: page
title: Interpreting Output
permalink: /interpreting-output/
---

`MIDAS_Main` returns everything in one struct `R` (see [API Reference]({{ '/api-reference/' | relative_url }}) for the full field list). This page is about what to actually *look at* once you have it, and what each diagnostic is telling you.

## Did the run finish the way you expect?

Check `R.stoppedEarly` first. If `true`, `R.t_final` is less than `R.params.t_tot` (times `checkFinT_Eq` if used) and `R.stopReason` holds the error message that ended the run early - most commonly a trace-element boundary value going negative at an extreme `DamA`/`DRG` corner of parameter space (see [Configuration Options]({{ '/configuration-options/' | relative_url }})). The state returned is the last fully self-consistent step, not a partial or corrupted one - safe to use, just shorter than requested.

Separately, a run can end with a hard error rather than a graceful `R.stoppedEarly=true` - most notably `'better stop here (crystal becomes negligible)'` if the crystal resorbs below 5% of the domain. Since this happens *before* `R` is packaged, nothing is returned at all in that case; see [Benchmarks]({{ '/benchmarks/' | relative_url }}#fixed-all-six-examples-now-complete-at-full-resolution) for the P-T-path mechanism that can drive this and how the shipped examples avoid it.

## Apparent age vs. true age: the core diagnostic

`R.tALuHf1_final` is the single-point apparent-age profile across phase A at the final step - what you'd calculate at every point if you (naively) assumed no diffusive resetting had occurred (see [Equations]({{ '/equations/' | relative_url }}#apparent-age-determination)). Compare it against `R.t_final` (the actual model time): where they agree, that part of the crystal has preserved its age record; where `tALuHf1` diverges below `t_final`, diffusion has reset it. `R.misfitApparent_final` is exactly this gap, reduced to one worst-case number ($\max_x \lvert \tau(x) - t\rvert$); its full time evolution is in `R.misfitApparentH` if you want to plot it yourself. `plot_velocity_age.m` shows the same misfit spatially (vs. position and time) rather than reduced to a single curve.


If you're using **isochron ages** instead (`R.t_rimA_final`/ `R.t_coreA_final`/`R.t_bulkA_final`/`R.t_maxA_final`), remember these depend on `isoRefMode` (which "second mineral" point they're regressed against) - two runs with different `isoRefMode` are not directly comparable unless you know which reference point each used.

## Is the run numerically trustworthy?

The mass-balance fields (`R.dMB_max`, `R.dMBMn_max`, `R.dMBHfr_max` - peak drift over the whole run for MgO/MnO/Hfr, species with no physical source or sink) are the main numerical-integrity check. See [Benchmarks]({{ '/benchmarks/' | relative_url }}) for what "small" means in practice.

## History fields, if `store_history = 1`

Every `<field>rec` array (`R.Srec`, `R.Vrec`, `R.Trec`, `R.Prec`, `R.CArec`, ...) is one row per recorded step, in the same order as `R.trec`. `R.tA1`/`R.tB1` are the exception to the naming pattern - the full apparent-age history, phase A and phase B (not `R.tALuHf1rec`). Use these for anything time-resolved that isn't already a dedicated `plot_*.m` function - e.g. `plot(R.trec, R.Srec)` for growth/resorption history, or indexing `R.CArec(i,:)` against `R.xArec(i,:)` for the composition profile at a specific recorded step `i`.

## Which plot function answers which question

| Question | Function |
|---|---|
| How does apparent age compare to true age, everywhere and always? | `plot_velocity_age(R)` |
| Is mass conserved (numerical sanity check)? | `plot_massbalance_MgO(R)` |
| What does the crystal look like now, all elements at once? | `plot_all_composition_profiles(R)` |
| How does age/composition evolve at a few fixed depths? | `plot_age_at_fixed_positions(R)` / `plot_conc_at_fixed_positions(R)` |
| Where's the closure temperature? | `plot_age_vs_temperature(R)` |

See [API Reference]({{ '/api-reference/' | relative_url }}#plotting-functions) for the complete list.
