---
layout: page
title: MIDAS
permalink: /
---

**MIDAS** (**M**ineral **I**nterface **D**ynamics and apparent-**A**ge **S**imulation) is a crystal-growth model that couples interface kinetics and diffusion across an explicit moving boundary (a chemical Stefan/moving-boundary problem), for a mineral (phase A) growing or resorbing in a matrix phase (phase B), with major- and trace-element diffusion and partitioning tracked between the two. The example used throughout this repository is a garnet-biotite pair (major elements Mg-Fe; trace elements Lu, Hf, Mn), built for modeling Lu-Hf garnet geochronology, apparent and isochron ages, and interface (growth/resorption) velocities over a metamorphic P-T-t path.

"A" indicates the parameters and variables with respect to the crystal, whereas "B" refers to the matrix.

**Note:** MIDAS is under active development (currently v1.0.0) - interfaces, defaults, and file formats may still change between versions, and known limitations exist (see [CHANGELOG.md](../CHANGELOG.md)). Feedback and bug reports are welcome - see [CONTRIBUTING.md](../CONTRIBUTING.md).

**Also note:** MIDAS was originally written for and developed in MATLAB - `matlab/`/`GUI/` are the mature, primary implementation, while `octave/` is a port only recently run under real Octave for the first time. Several Octave-only compatibility bugs have been found and fixed this way (see [CHANGELOG.md](../CHANGELOG.md)), and more may still surface. Something that misbehaves under Octave but works fine in MATLAB is likely a porting gap, not a physics/numerics issue - please report it.

## Three ways to run it

| | |
|---|---|
| **[Getting started](getting-started)** | Run it from MATLAB or Octave in a few lines |
| **[GUI guide](gui)** | The interactive front-end - MATLAB App Designer, or the Octave rebuild |
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

<p align="center">
  <img src="{{ '/assets/diagrams/model_schematic.svg' | relative_url }}" width="100%" alt="Schematic: phase A (crystal) and phase B (matrix) sharing a moving interface S(t), with a diffusion profile C(x,t) across both.">
</p>

- Growth/resorption of a crystal in a surrounding matrix via coupled interface kinetics and diffusion, with an explicit moving boundary (not a fixed-grid approximation).
- Major-element (Mg-Fe) diffusion and equilibrium partitioning, sourced either from a Perplex phase diagram or a 3-point polynomial fit.
- Trace-element/minor-element (Lu, Hf, Mn) diffusion and partitioning, feeding a Lu-Hf  apparent-age calculation at every point in the crystal, at every recorded  time step.
- Configurable P-T-t paths (an explicit peak, or a simpler thermal-pulse  parameterization), and planar/cylindrical/spherical growth geometry.

## Quick example

```matlab
addpath('examples');
params = Example1_Baseline();               % fully automated, phase-diagram-driven
R = MIDAS_Main(params);
plot_all_composition_profiles(R);           % every element/isotope, phase A vs phase B
```

See **[Examples](examples)** for all six included configurations, and **[API reference](api-reference)** for every parameter and every plotting function.

## Citing

If you use MIDAS in your research, please cite it - see [`CITATION.cff`](https://github.com/AnStroh/MIDAS/blob/main/CITATION.cff) in the repository root.

## Funding

The development of this package is supported by the DFG project 524829125 (VECTOR).

## AI use

We used Claude to help find and fix bugs, restructure the code into the `matlab/`/`GUI/`/`octave/` layout used here, and build a clearer, user-friendly version of it, including the GUI and logo. Based on the authors' own instructions and content, Claude created the documentation - both the in-code function documentation and this documentation site. Furthermore, Claude helped with visualizations as well as translation and readability. Claude was not used to develop, derive, or validate any of the model's underlying physics or numerics - that work is the authors' own. All AI-assisted output was reviewed and is approved by the authors.

## Main authors

Annalena Stroh, Evangelos Moulas - Johannes Gutenberg University Mainz (JGU), 2026

## License

MIT - see [`LICENSE`](https://github.com/AnStroh/MIDAS/blob/main/LICENSE).
