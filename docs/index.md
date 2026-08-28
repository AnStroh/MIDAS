---
layout: page
title: MIDAS
permalink: /
---

**MIDAS** is an interface-limited crystal-growth model (a moving-boundary problem) for a garnet crystal (phase A) growing/resorbing in a matrix (phase B), coupled to major-element (Mg-Fe-Mn) and trace-element (Lu, Hf, Mn) diffusion and partitioning - built for modeling Lu-Hf garnet geochronology.

"A" indicates the parameters and variables with respect to the crystal, whereas "B" refers to the matrix.

## Three ways to run it

| | |
|---|---|
| **[Getting started](getting-started)** | Run it from MATLAB or Octave in a few lines |
| **[GUI guide](gui)** | The interactive MATLAB App Designer front-end |
| **[Octave notes](octave)** | Setup and differences for the GNU Octave port |

## Background and reference

| | |
|---|---|
| **[Equations](equations)** | The physics and numerics MIDAS actually solves |
| **[Configuration options](configuration-options)** | Every mode switch, what it changes, how they interact |
| **[Mesh & time-step refinement](mesh-refinement)** | Choosing `nx_A`/`nx_B`/`CFL`, and what to do if a run errors |
| **[Interpreting output](interpreting-output)** | What to look at in `R`, and what it means |
| **[Benchmarks](benchmarks)** | Mass-balance conservation checks (and open items found so far) |
| **[Phase diagrams](phase-diagrams)** | Building a Perplex look-up table for `eqMode='PD'` |
| **[References](references)** | Every citation used across this documentation, in one place |

## What it models

- Interface-limited growth/resorption of a crystal in a surrounding matrix, with an explicit moving boundary (not a fixed-grid approximation).
- Major-element (Mg-Fe-Mn) diffusion and equilibrium partitioning, sourced either from a Perplex phase diagram or a 3-point polynomial fit.
- Trace-element (Lu, Hf, Mn) diffusion and partitioning, feeding a Lu-Hf  apparent-age calculation at every point in the crystal, at every recorded  time step.
- Configurable P-T-t paths (an explicit peak, or a simpler thermal-pulse  parameterization), and planar/cylindrical/spherical growth geometry.

## Quick example

```matlab
params = MIDAS_Params_Example1_Baseline();  % fully automated, phase-diagram-driven
R = MIDAS_Main(params);
plot_all_composition_profiles(R);           % every element/isotope, phase A vs phase B
```

See **[Examples](examples)** for all six included configurations, and **[API reference](api-reference)** for every parameter and every plotting function.

## Citing

If you use MIDAS in your research, please cite it - see [`CITATION.cff`](https://github.com/AnStroh/MIDAS/blob/main/CITATION.cff) in the repository root.

## License

MIT - see [`LICENSE`](https://github.com/AnStroh/MIDAS/blob/main/LICENSE).
