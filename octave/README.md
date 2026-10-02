# MIDAS core solver - GNU Octave version

This folder is a GNU Octave-compatible, fully self-contained port of the MIDAS crystal-growth solver and its analysis/export scripts, for anyone without a MATLAB license. It covers the same physics and outputs as `../matlab/`, either from the command line (`Run_MIDAS`) or through `MIDAS_GUI.m`, a plain-`uicontrol` interactive front-end covering the same fields as `../GUI/MIDAS.m`'s MATLAB App Designer app (which Octave cannot open at all - see [`docs/gui.md`](https://github.com/AnStroh/MIDAS/blob/main/docs/gui.md#octave-gui) for the full guide and how it differs).

**MIDAS was originally written for and developed in MATLAB.** `../matlab/`/`../GUI/` are the mature, primary implementation; this folder is a port, only recently run under a real Octave interpreter for the first time. A number of Octave-only compatibility bugs (functions MATLAB has that Octave doesn't, or that behave differently) have already been found and fixed this way - see [CHANGELOG.md](../CHANGELOG.md) for the running list - and more may still surface as this port sees more real-world use. If something misbehaves here but works fine in `matlab/`, it's very likely a porting gap rather than a physics/numerics issue - please report it.

## Requirements

- GNU Octave 8.x (developed/tested against 8.4 and, on Windows, 11.3.0). Octave 7.1+ should work but is untested.
- Two Octave Forge packages, only needed for specific features:
  - `io` - for the `.xlsx` export in `export_results_excel.m`. Without it, export falls back to one `.csv` file per sheet automatically.
  - `image` - for `params.make_movie = 1` (writing the `.gif`). Only loaded if a movie is actually requested; everything else works without it.

Install once - **Linux**:
```bash
sudo apt-get install -y octave
octave --eval "pkg install -forge io image"
```
**Windows**: install Octave first (the official installer from [octave.org/download](https://octave.org/download), or `winget install --id GNU.Octave` - both were verified to produce the same result: no `qt` toolkit, see below), then the same package-install line works from PowerShell/cmd:
```bash
octave --eval "pkg install -forge io image"
```
**macOS** (via [Homebrew](https://brew.sh)):
```bash
brew install octave
octave --eval "pkg install -forge io image"
```

### Graphics toolkit

`qt` is strongly recommended if available (`graphics_toolkit('qt')`, or check `available_graphics_toolkits()`). Verified on Windows: neither the `winget install GNU.Octave` package nor the official `octave.org` Windows installer (11.3.0) ships `qt` - only `fltk`/`gnuplot`, both of which Octave itself flags as unmaintained. `print()`/`exportgraphics` always route through `fltk` for rasterization regardless of which toolkit is set active.

- **LaTeX label rendering**: `fltk` fails its own startup self-test and silently disables the `'latex'` interpreter, so `octave/` no longer requests it at all - every label now uses Octave's default `'tex'` interpreter instead, with `$` delimiters stripped from the strings (`\Delta`, `\tau`, `\max`, `^{...}`, `_{...}`, `^o` all render correctly under `'tex'` with no further changes; `\%` doesn't and was unescaped to a plain `%`). `matlab/`/`GUI/` are unaffected by this Octave-specific issue and keep `'latex'` throughout. See [CHANGELOG.md](../CHANGELOG.md) for the confirmed before/after.
- **Figure export still hangs** for any 2-D color-mapped content (`print()`/`exportgraphics` to PNG/PDF, e.g. via `saveCheckpoints`): `GL2PS warning: Unknown token in buffer`, then no further progress. Confirmed this is **not** specific to `contourf` - `pcolor` and `imagesc` were tested as substitutes and hang identically, so this is a broader `fltk`/GL2PS limitation, not something a different plotting function can route around. Still unresolved; avoid exporting the phase-diagram panels (or any color-mapped plot) under Octave on Windows until a working `qt` toolkit is available.

The full plotting/export pipeline (everything `.github/scripts/smoke_test.m` exercises) has since been run end-to-end under this Octave install; several further Octave-only bugs it surfaced (a `legend()` crash, a `make_movie`/`rgb2ind` failure, missing `parula`/`sgtitle`) have been fixed - see [CHANGELOG.md](../CHANGELOG.md) for the details. Only the export-hang limitation above remains open.

## Usage

```octave
octave
>> Run_MIDAS
```

Or, for the interactive GUI instead:
```octave
octave
>> MIDAS_GUI
```
(see [`docs/gui.md`](https://github.com/AnStroh/MIDAS/blob/main/docs/gui.md#octave-gui) for the full guide.)

`MIDAS_Params.m` is the default input file - edit numbers there before running, or swap in one of the six standalone examples under `examples/` to see a different capability of the model (each is a complete parameter set; whatever a given example does NOT use is set to `NaN` so it's obvious at a glance what matters for that run):

| File | Demonstrates |
|---|---|
| `examples/Example1_Baseline.m` | Fully automated, phase-diagram-driven (recommended starting point) |
| `examples/Example2_PolyEquilibrium.m` | No phase-diagram file needed at all (polynomial equilibrium fit, manual Mn) |
| `examples/Example3_ThermalBump.m` | Older, simpler P-T parameterization (`PTmode='Tbump'`) |
| `examples/Example4_ManualPartitioning.m` | Phase-diagram majors + user-specified Mn partitioning (hybrid) |
| `examples/Example5_PlanarGeometry.m` | Planar growth geometry (`ndim=1`) |
| `examples/Example6_CylindricalGeometry.m` | Cylindrical growth geometry (`ndim=2`) |

Open `Run_MIDAS.m` and change the `params = MIDAS_Params();` line to call whichever one you want (`addpath('examples')` is already set up at the top of the file); it then runs `MIDAS_Main.m` and saves/exports figures + data the same way regardless of which params file was used.

## Differences from the MATLAB version

- `MIDAS_GUI.m` here is a from-scratch rebuild (plain `uicontrol`), not a port of `../GUI/MIDAS.m` (a MATLAB App Designer file Octave can't open at all) - see [`docs/gui.md`](https://github.com/AnStroh/MIDAS/blob/main/docs/gui.md#octave-gui) for what differs (no dark/light toggle yet, plus the toolkit caveats below).
- Octave has no `griddedInterpolant` - the P-T path lookup in `MIDAS_Main.m` uses `interp1(...,'extrap')` anonymous functions instead.
- Octave has no `tiledlayout`/`nexttile` - `tiledlayout.m`/`nexttile.m` (this folder) are small local shims backed by `subplot`, so the plotting scripts that use them are otherwise unchanged from `../matlab/`.
- MATLAB's dot-notation graphics-property access (`cb.Label.Interpreter = ...`, `lgd.FontSize = ...`) isn't supported on Octave's plain-double graphics handles - replaced with `get`/`set` calls where needed.
- `round(x,n)` (MATLAB's round-to-n-decimals form) isn't supported by this Octave's `round` - replaced with `round(x*10^n)/10^n` where used.
- `export_results_excel.m` builds sheets with `writecell` instead of `table`/`writetable` (Octave's table support is less mature); output is the same header-row-plus-data layout either way. Column-name sanitizing (previously `matlab.lang.makeValidName`/`makeUniqueStrings`, which don't exist in Octave) is reimplemented locally in the same file. **Confirmed on this install:** `writecell` itself is undefined (the `io` Forge package doesn't provide it, or isn't loading), so every `.xlsx` export currently falls back to the designed CSV-per-sheet fallback rather than actually producing an `.xlsx` - gracefully, with a clear note printed, but always rather than only when something's genuinely broken.
- `export_pub_fig.m` tries `exportgraphics` first and falls back to the older `print()` if that fails, so figure export degrades gracefully across Octave versions - see the graphics-toolkit note above for a real limitation this can't work around (the `contourf` export hang).

## Status

Actually run under a real Octave interpreter (11.3.0, Windows) end-to-end - all six examples plus the full live-plotting and post-run export pipeline - surfacing and fixing several real bugs the original MATLAB-only logic-verification missed (see [CHANGELOG.md](../CHANGELOG.md)). The `contourf`/LaTeX limitations noted above are believed to be specific to the `fltk` graphics toolkit, not the MIDAS code itself, but haven't been re-verified under `qt` - if you have `qt` available, please report whether they still reproduce there.
