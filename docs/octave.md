---
layout: page
title: Octave Notes
permalink: /octave/
---

The `octave/` folder is a fully self-contained, GNU Octave-compatible port of the model, for anyone without a MATLAB license. It covers the same physics and outputs as `matlab/`, run from the command line instead of through the MATLAB-only [GUI](gui).

## Requirements

- GNU Octave 8.x (developed/tested against 8.4). Octave 7.1+ should work  but is untested; earlier versions are missing `griddedInterpolant`,  `tiledlayout`/`nexttile`, and `exportgraphics`, all used here.
- Two Octave Forge packages, only needed for specific features:
  - `io` - for the `.xlsx` export in `export_results_excel.m`. Without it,  export falls back to one `.csv` file per sheet automatically.
  - `image` - for `params.make_movie = 1` (writing the `.gif`). Only loaded if a movie is actually requested; everything else works without it.

```bash
sudo apt-get install -y octave
octave --eval "pkg install -forge io image"
```

## Usage

```
octave
>> Run_MIDAS
```

Same workflow as [`matlab/`](getting-started) - `MIDAS_Params.m` is the default, or swap in any of the six [example configurations](examples).

## Differences from the MATLAB version

- No GUI - use [`GUI/`](gui) under MATLAB for that.
- `export_results_excel.m` builds sheets with `writecell` instead of   `table`/`writetable` (Octave's table support is less mature); output is   the same header-row-plus-data layout either way. Column-name sanitizing   (previously `matlab.lang.makeValidName`/`makeUniqueStrings`, which don't   exist in Octave) is reimplemented locally in the same file.
- `export_pub_fig.m` tries `exportgraphics` first and falls back to the  older `print()` if that fails, so figure export degrades gracefully  across Octave versions.

## Status

Logic-verified by running the identical code path under MATLAB, and exercised by the Octave CI workflow (`.github/workflows/ci-octave.yml`) on every push - see the repository's Actions tab for current status.
