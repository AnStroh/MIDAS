---
layout: page
title: GUI Guide
permalink: /gui/
---

The `GUI/` folder has a fully independent copy of the model plus `MIDAS.m`,an interactive MATLAB App Designer front-end. MATLAB only - GNU Octave has no App Designer equivalent (use [`octave/`](octave) for a command-line workflow instead).

## Launching it

```matlab
cd GUI
MIDAS
```

## Layout

- **Dark/light toggle**: top-right of the header, next to the logo. Swaps  the app's backgrounds, panel titles, and field labels between the light  and dark palettes, and swaps the logo image - individual input controls  (edit fields, dropdowns, checkboxes) keep their normal light appearance in both modes, since MATLAB's own theming API for those only exists from  R2022b onward and this app targets R2019b+.
- **Left sidebar**: tabs matching `MIDAS_Params.m`'s own sections, science  inputs first and bookkeeping last (Physics, Time & P-T, Thermodynamics,  Numerics, Numerics Flags, Output & Plotting) - every field is exposed as its own control (numeric box, dropdown, checkbox, or a small vector of boxes), with the same explanatory text as the source file's inline comments available as a hover tooltip.
- **Run / Reset**: Run executes `MIDAS_Main` with whatever's currently in  the form and shows every post-run figure (progress bar tracks each one).  Reset restores every field to `MIDAS_Params()`'s defaults.
- **Load Example**: pick any of the six [example configurations](examples)  (or plain `MIDAS_Params`) from the dropdown and click Load to populate  every field from it - a starting point, not a locked-in choice, since  every field stays freely editable afterwards, so you can dial in your own configuration without typing all ~60 values by hand.
- **Save/Load Preset**: save the current form to a `.mat` file, or load a  previously saved one back in.
- **Export Data / Export Figures panels**: after a run, export `R`'s  scalar/summary data to Excel, or export any of the figures from that run  as a vector PDF + 300 dpi PNG (both with and without their title).
- **Results list**: browse, refresh, or delete previous runs' output  folders (each run gets its own timestamped folder under `results/`).

## Notes

- The GUI dynamically reads its default values from `MIDAS_Params()` at  startup - editing that file changes what the GUI shows next time it  launches, no GUI code changes needed.
- Every field's tooltip is generated from the same metadata table the GUI  uses to build its own controls, so it can't drift out of sync with what  the field actually does.
- The Load Example dropdown reads the six `MIDAS_Params_ExampleN.m` files  directly - it needs them (and `MIDAS_Params.m`) to be on the MATLAB path,  which is automatic when launching from `GUI/` itself.
