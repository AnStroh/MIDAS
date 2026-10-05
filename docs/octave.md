---
layout: page
title: Octave Notes
permalink: /octave/
---

The `octave/` folder is a fully self-contained, GNU Octave-compatible port of the model, for anyone without a MATLAB license. It covers the same physics and outputs as `matlab/`, either from the command line (`Run_MIDAS`) or through its own interactive [GUI]({{ '/gui/' | relative_url }}#octave-gui) (`MIDAS_GUI`) - a rebuild covering the same fields as the MATLAB App Designer app, since Octave can't open that file format at all.

**MIDAS was originally written for and developed in MATLAB.** `matlab/`/`GUI/` are the mature, primary implementation; this port was only recently run under a real Octave interpreter for the first time, surfacing (and fixing) a number of Octave-only compatibility bugs - see [CHANGELOG.md](https://github.com/AnStroh/MIDAS/blob/main/CHANGELOG.md) - with more possibly still to find. Something that misbehaves under Octave but works fine in MATLAB is likely a porting gap, not a physics/numerics issue - please report it. If you have a MATLAB license, prefer it when runtime matters - Octave measured about 4.5x slower here even with plotting off entirely, after a since-applied fix cut what was originally a much larger gap (see [Performance](#performance) below), and the GUI's live-updating plot is slower still (see [Performance]({{ '/gui/' | relative_url }}#performance)).

## Requirements

- GNU Octave 8.x (developed/tested against 8.4 and, on Windows, 11.3.0). Octave 7.1+ should work but is untested.
- Two Octave Forge packages, only needed for specific features:
  - `io` - for the `.xlsx` export in `export_results_excel.m`. Without it, export falls back to one `.csv` file per sheet automatically.
  - `image` - for `params.make_movie = 1` (writing the `.gif`). Only loaded if a movie is actually requested; everything else works without it.

**Linux**:
```bash
sudo apt-get install -y octave
octave --eval "pkg install -forge io image"
```
**Windows**: install Octave first ([octave.org/download](https://octave.org/download), or `winget install --id GNU.Octave` - both verified to give the same result: no `qt` toolkit, see below), then:
```bash
octave --eval "pkg install -forge io image"
```
**macOS** ([Homebrew](https://brew.sh)):
```bash
brew install octave
octave --eval "pkg install -forge io image"
```

### Graphics toolkit

`qt` is strongly recommended if available. Verified on Windows: neither the `winget install GNU.Octave` package nor the official octave.org Windows installer (11.3.0) ships `qt` - only `fltk`/`gnuplot`, both flagged by Octave itself as unmaintained. `fltk`'s broken LaTeX self-test is worked around (`octave/` no longer requests the `'latex'` interpreter at all - see [Differences from the MATLAB version](#differences-from-the-matlab-version) below). Figure export still hangs for any 2-D color-mapped content, not specific to one plotting function (`contourf` and `pcolor` both hang identically) - see [`octave/README.md`](https://github.com/AnStroh/MIDAS/blob/main/octave/README.md#graphics-toolkit) for the full detail. This looks like a broader `fltk`/GL2PS limitation, not a MIDAS bug; until `qt` is available, avoid exporting the phase-diagram panels (or any color-mapped plot) under Octave on Windows.

The full plotting/export pipeline has since been run end-to-end under Octave; several further compatibility bugs it surfaced (a `legend()` crash, a `make_movie`/GIF failure, missing `parula`/`sgtitle`) have been fixed - see [CHANGELOG.md](https://github.com/AnStroh/MIDAS/blob/main/CHANGELOG.md).

## Usage

```octave
octave
>> Run_MIDAS
```

Same workflow as [`matlab/`]({{ '/getting-started/' | relative_url }}) - `MIDAS_Params.m` is the default, or swap in any of the six [example configurations]({{ '/examples/' | relative_url }}).

## Performance

**If you have a MATLAB license, prefer it for anything beyond a quick check** - Octave is still slower than MATLAB here, independent of plotting (see also the GUI-specific redraw cost in [Performance]({{ '/gui/' | relative_url }}#performance)), though far less than it used to be.

Originally (before the `thomasSolve` fix below), measured directly on this machine at full resolution, `doPlot = false` (pure numerics, no plotting at all): `Example1_Baseline` took 48.2 s under MATLAB vs. 1040.5 s under Octave - about 21.6x slower. Profiling a shorter Octave run (same full grid, `t_tot = 1`) traced the large majority of this to one function: `thomasSolve` (`MIDAS_Main.m`'s hand-written tridiagonal solver, called once per phase per implicit diffusion step) accounted for 42 of 69 seconds - 61% of total runtime - across 6,360 calls, each running a ~200-iteration scalar for-loop twice (forward sweep, then back-substitution). MATLAB's JIT compiles this kind of tight indexed-scalar loop efficiently; Octave's interpreter does not, so the same algorithm that is cheap under MATLAB dominated the whole run under Octave.

**Fixed** (`octave/` only - see [Differences from the MATLAB version](#differences-from-the-matlab-version)): `octave/MIDAS_Main.m`'s `thomasSolve` now solves the same tridiagonal system via a sparse-matrix backslash (`\`) instead of that hand-written loop, handing the work to a compiled solver instead of the interpreter. Verified to still agree with `matlab`/`GUI` within the documented `1e-9` tolerance (`tests/compare_results.m`). Re-measured at full resolution after the fix: `Example1_Baseline` dropped from 1040.5 s to **214.7 s - a 4.85x speedup**, bringing Octave from 21.6x down to **about 4.5x slower than MATLAB's 48.2 s** for the same run. (`Example3_ThermalBump` - 90.0 s under MATLAB - still didn't complete under Octave within the time available even after the fix, so no post-fix ratio is reported for it; treat the Example1 figure as representative, not universal.)

## Differences from the MATLAB version

- `octave/MIDAS_GUI.m` is a from-scratch rebuild (plain `uicontrol`), not a port of `GUI/MIDAS.m` (a MATLAB App Designer file Octave can't open at all) - see the [Octave GUI section]({{ '/gui/' | relative_url }}#octave-gui) of the GUI guide for what differs.
- Octave has no `griddedInterpolant` - the P-T path lookup in `MIDAS_Main.m` uses `interp1(...,'extrap')` anonymous functions instead.
- Octave has no `tiledlayout`/`nexttile` - `tiledlayout.m`/`nexttile.m` (in `octave/`) are small local shims backed by `subplot`, so the plotting scripts that use them are otherwise unchanged from `matlab/`.
- Octave's colorbar is an axes object with no `Ticks`/`TickLabels` property (`plot_velocity_age.m` sets `YTick`/`YTickLabel`), older releases have no `xline`/`yline` (reference lines are drawn with `plot()`), and there is no `parula` - `plotting/parula.m` is a small approximation of it, so the colormaps match the MATLAB figures.- The phase-diagram panels (`plot_them_1.m`, `plot_them_3.m`) use `pcolor` instead of `contourf`: Octave's `contourf` drew scrambled polygons for this grid, which contains NaN regions.- To look like the MATLAB version's LaTeX-rendered figures, `plotting/matlabStyle.m` (called from `plotting/fitFigure.m` and at the end of each plot function) sets a serif font, italic variable symbols (`x`, `t`, `T`, `P`, `D`), plain panel letters, a light grid and at most ~5 tick labels per axis, and `fitFigure.m` scales the text to the actual window size. Figure windows open at Octave's default size and are never forced to a fixed size. Both files are cosmetic and guarded: if something in them fails, the figure is drawn unstyled and a single warning is printed.
- The phase-diagram panels (`plot_them_1.m`, `plot_them_3.m`) use `pcolor` instead of `contourf`: Octave's `contourf` drew scrambled polygons for this grid, which contains NaN regions.
- To look like the MATLAB version's LaTeX-rendered figures, `plotting/matlabStyle.m` (called from `plotting/fitFigure.m` and at the end of each plot function) sets a serif font, italic variable symbols (`x`, `t`, `T`, `P`, `D`), plain panel letters, a light grid and at most ~5 tick labels per axis, and `fitFigure.m` scales the text to the actual window size. Figure windows open at Octave's default size and are never forced to a fixed size. Both files are cosmetic and guarded: if something in them fails, the figure is drawn unstyled and a single warning is printed.
- `thomasSolve` (`MIDAS_Main.m`'s tridiagonal solver) uses a sparse-matrix backslash (`\`) in `octave/`, instead of the hand-written Thomas-algorithm loop `matlab/`/`GUI/` use - performance-motivated (see [Performance](#performance) above), not a capability gap: Octave's interpreter has no comparable JIT for tight scalar loops, so the loop that's fastest under MATLAB is markedly slower under Octave. Same tridiagonal system, same result within the documented tolerance.
- MATLAB's dot-notation graphics-property access (`cb.Label.Interpreter = ...`) isn't supported on Octave's plain-double graphics handles - replaced with `get`/`set` calls where needed, as is MATLAB's `round(x,n)` two-argument form.
- No plotting call anywhere in `octave/` uses `'interpreter','latex'` (unlike `matlab/`/`GUI/`, which do throughout) - `fltk`'s LaTeX renderer fails its own startup self-test on this install, so labels default to Octave's `'tex'` interpreter instead, with `$` delimiters stripped from every label string. `\Delta`, `\tau`, `\max`, `^{...}`, `_{...}`, and `^o` all render correctly under `'tex'` unchanged; `\%` does not (not a recognized `'tex'` escape) and was unescaped to a plain `%` wherever it appeared.
- `export_results_excel.m` builds sheets with `writecell` instead of `table`/`writetable` (Octave's table support is less mature); output is the same header-row-plus-data layout either way. Column-name sanitizing (previously `matlab.lang.makeValidName`/`makeUniqueStrings`, which don't exist in Octave) is reimplemented locally in the same file.
- `export_pub_fig.m` tries `exportgraphics` first and falls back to the older `print()` if that fails, so figure export degrades gracefully across Octave versions - except for the color-mapped export hang noted above, which no fallback avoids.

## Status

Actually run under a real Octave interpreter (11.3.0, Windows) end-to-end - all six examples plus the full live-plotting and post-run export pipeline - surfacing and fixing several real bugs that MATLAB-only logic-verification had missed (see [CHANGELOG.md](https://github.com/AnStroh/MIDAS/blob/main/CHANGELOG.md)). Note: `.github/scripts/smoke_test.m` (run by `ci-octave.yml`) sets `doPlot = false` throughout, so CI does not exercise `MIDAS_Main.m`'s own live-plotting branch - the verification above was done manually, not by CI.
