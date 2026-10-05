---
layout: page
title: Getting Started
permalink: /getting-started/
---

## Requirements

- **MATLAB**: R2019b or newer (uses `tiledlayout`/`nexttile` and  `exportgraphics`). No additional toolboxes required.
- **GNU Octave**: 8.x (see [Octave notes]({{ '/octave/' | relative_url }}) for setup and package  requirements).

## 1. Pick a folder

| Folder | Use it if... |
|---|---|
| [`matlab/`](https://github.com/AnStroh/MIDAS/tree/main/matlab) | You want to run everything from the MATLAB command line/scripts |
| [`GUI/`](https://github.com/AnStroh/MIDAS/tree/main/GUI) | You want the interactive front-end instead |
| [`octave/`](https://github.com/AnStroh/MIDAS/tree/main/octave) | You're on GNU Octave, no MATLAB license needed |

Each is fully self-contained - no cross-folder dependencies. Pick one and `cd` into it.

## 2. Run a calculation

From `matlab/` or `octave/`:
```matlab
Run_MIDAS
```
This loads `MIDAS_Params.m` (the default configuration), runs the model, and shows every post-run figure - nothing is written to disk by default (`save_data`, `make_movie`, and every per-figure `save_*` flag at the top of `Run_MIDAS.m` start off `false`/`0`); flip whichever ones you want to keep to `true`/`1`.

From `GUI/`, instead:
```matlab
MIDAS
```
This launches the interactive app - every field of `MIDAS_Params.m` is exposed as an editable control, grouped into tabs.

## 3. Try a different configuration

Open `Run_MIDAS.m` and change the line
```matlab
params = MIDAS_Params();
```
to any of the six example configurations, e.g.
```matlab
params = Example2_PolyEquilibrium();
```
See **[Examples]({{ '/examples/' | relative_url }})** for what each one demonstrates.

## 4. Write your own configuration

The cleanest way is to copy `MIDAS_Params.m` (or whichever example is closest to what you want) to a new file, give its function the same name as the file, and edit the numbers. Every field is documented inline with what it does and, where relevant, which mode it only applies under.

```matlab
% params = MIDAS_Params();
% params.DamA = 1e-2;      % or override individual fields directly instead
R = MIDAS_Main(params);
```

## 5. Look at the results

`MIDAS_Main` returns a single struct `R` holding the full time history (if `params.store_history = 1`) and final-state profiles for every tracked quantity. Every `plot_*.m` function in the folder takes `R` and produces one figure - see **[API reference]({{ '/api-reference/' | relative_url }})** for the full list.

To export a figure as a publication-ready vector PDF + 300 dpi PNG (both a titled and an untitled version):
```matlab
export_pub_fig(gcf, 'my_figure_name')
```
