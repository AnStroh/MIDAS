# Changelog

All notable changes to MIDAS are documented here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[CITATION.cff](CITATION.cff).

## [0.1.0] - 2026-08-28

Initial version.

### Added

- Three independent, self-contained copies of the model: `matlab/`
  (command-line/scripts), `GUI/` (interactive MATLAB App Designer
  front-end, `MIDAS.m`), and `octave/` (GNU Octave port) - identical
  physics and identical default parameters across all three.
- Six standalone example configurations (`MIDAS_Params_Example1_Baseline`
  through `Example6_CylindricalGeometry`), each a complete, self-contained
  parameter set with every field it doesn't use set to `NaN`, exercising
  every mode switch in the model. All six run to completion at full grid
  resolution with physically sensible (net-growth) results.
- GUI: **Load Example** dropdown + button - pick any of the six examples
  (or plain `MIDAS_Params`) and populate every field from it as a starting
  point; every field stays freely editable afterwards. Plus a
  **dark/light toggle** (header, next to the logo) that re-colors
  backgrounds, panel titles, and field labels and swaps the logo image.
- Boundary conditions (`implicitDiffusionSolver.m`): the center of the
  domain (x=0) is always Neumann for cylindrical/spherical geometry
  (`ndim` = 2/3), as required by symmetry, regardless of `NBC`; the outer
  edge of phase B always follows `NBC` freely (Neumann or Dirichlet), for
  every geometry.
- `plot_initial_conditions.m` - every element/isotope's initial ($t=0$)
  profile, phase A vs. phase B, one figure (the "before" to
  `plot_all_composition_profiles`'s "after").
- Figures export as a vector PDF + a lossless 300 dpi PNG, both a titled
  and an untitled version, with a small attribution stamp
  (`export_pub_fig.m`). Nothing is written to disk by default otherwise -
  `save_data`, `make_movie`, and every per-figure `save_*` flag in
  `Run_MIDAS.m` start off; opt in per field.
- CI: `ci-matlab.yml`, `ci-gui.yml`, `ci-octave.yml` (smoke-test all six
  examples plus the full plotting/export pipeline on every push -
  `.github/scripts/smoke_test.m`), `docs.yml` (GitHub Pages), and
  `spellcheck.yml`.
- Full documentation site (`docs/`): getting started, examples,
  configuration options, equations/theory, mesh & time-step refinement,
  interpreting output, benchmarks, phase-diagram (Perplex) setup,
  references, API reference, GUI guide, and Octave notes - with the MIDAS
  logo (light/dark-aware) on every page.
- `LICENSE` (MIT), `CITATION.cff`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `SECURITY.md`.

### Known limitations

- No formal unit test suite yet - CI runs the six examples as a smoke
  check only (see [Testing](README.md#testing)).
- Mass-balance drift (a numerical-integrity check with no expected physical
  source/sink) is small for MgO but unexpectedly large for MnO/Hfr in
  full-length runs. Investigated in depth; not yet fixed, paused for now.
  Confirmed: the partition-coefficient *jump size* at the interface is a
  real driver (forcing `KDMn` to `5`, MgO's own ratio range, cuts
  `dMBMn_max` 10x; `DRG_Mn` alone has no effect). But a mass-conservative
  correction added to the `pchip` regridding step (tested in a scratch
  copy only - real repo never touched) barely moved `dMBMn_max`/`dMBHfr_max`,
  ruling that step out as the dominant cause despite the jump-size
  correlation; phase-diagram data quality was checked and ruled out too
  (`KDMn` is proportionally *smoother* along the P-T path than MgO's own
  ratio, not noisier). The drift instead correlates strongly with
  interface velocity `v` (0.80 with `|v|` for Mn; -0.64 signed for Hfr,
  opposite-sign response to growth vs. resorption for the two species) -
  pointing at `solveBC`'s own boundary-value formula and its dependence on
  the externally-fixed, major-element-derived `v`. This is core solver
  numerics, and the authors want to confirm the approach before any change
  is made. See
  [Benchmarks](docs/benchmarks.md#results-full-resolution-full-duration-runs)
  for the full write-up.
- The GUI's Load Example feature and dark-mode toggle were built and
  confirmed to construct/run without error, but not yet visually
  inspected in an interactive session - please eyeball both once, and if
  the dark-mode contrast/colors need adjusting, the palette is three
  properties at the top of `MIDAS.m` (`DarkBg`/`DarkPanel`/`DarkText`).
