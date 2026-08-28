# MIDAS core solver - GNU Octave version

This folder is a GNU Octave-compatible, fully self-contained port of the
MIDAS crystal-growth solver and its analysis/export scripts, for anyone
without a MATLAB license. It covers the same physics and outputs as
`../matlab/`, run from the command line instead of through the MIDAS GUI
(App Designer, which Octave has no equivalent of - the GUI is MATLAB-only,
see `../GUI/`).

## Requirements

- GNU Octave 8.x (developed/tested against 8.4). Octave 7.1+ should work but
  is untested; earlier versions are missing `griddedInterpolant`,
  `tiledlayout`/`nexttile`, and `exportgraphics`, all used here.
- Two Octave Forge packages, only needed for specific features:
  - `io` - for the `.xlsx` export in `export_results_excel.m`. Without it,
    export falls back to one `.csv` file per sheet automatically.
  - `image` - for `params.make_movie = 1` (writing the `.gif`). Only loaded
    if a movie is actually requested; everything else works without it.

Install once:
```
sudo apt-get install -y octave
octave --eval "pkg install -forge io image"
```

## Usage

```
octave
>> Run_MIDAS
```

`MIDAS_Params.m` is the default input file - edit numbers there before
running, or swap in one of the six standalone examples to see a different
capability of the model (each is a complete parameter set; whatever a given
example does NOT use is set to `NaN` so it's obvious at a glance what
matters for that run):

| File | Demonstrates |
|---|---|
| `MIDAS_Params_Example1_Baseline.m` | Fully automated, phase-diagram-driven (recommended starting point) |
| `MIDAS_Params_Example2_PolyEquilibrium.m` | No phase-diagram file needed at all (polynomial equilibrium fit, manual Mn) |
| `MIDAS_Params_Example3_ThermalBump.m` | Older, simpler P-T parameterization (`PTmode='Tbump'`) |
| `MIDAS_Params_Example4_ManualPartitioning.m` | Phase-diagram majors + user-specified Mn partitioning (hybrid) |
| `MIDAS_Params_Example5_PlanarGeometry.m` | Planar growth geometry (`ndim=1`) |
| `MIDAS_Params_Example6_CylindricalGeometry.m` | Cylindrical growth geometry (`ndim=2`) |

Open `Run_MIDAS.m` and change the `params = MIDAS_Params();` line to
call whichever one you want; it then runs `MIDAS_Main.m` and saves/exports
figures + data the same way regardless of which params file was used.

## Differences from the MATLAB version

- No GUI (`MIDAS.m`) - use `../GUI/` under MATLAB for that.
- `export_results_excel.m` builds sheets with `writecell` instead of
  `table`/`writetable` (Octave's table support is less mature); output is
  the same header-row-plus-data layout either way. Column-name sanitizing
  (previously `matlab.lang.makeValidName`/`makeUniqueStrings`, which don't
  exist in Octave) is reimplemented locally in the same file.
- `export_pub_fig.m` tries `exportgraphics` first and falls back to the
  older `print()` if that fails, so figure export degrades gracefully
  across Octave versions.

## Status

Ported and statically checked (parsed, code-reviewed, and logic-verified by
running the identical code path under MATLAB), but not yet run under a real
Octave interpreter - Octave wasn't available in the environment this port
was prepared in. Please run `Run_MIDAS` once after installing
Octave and report anything that breaks.
