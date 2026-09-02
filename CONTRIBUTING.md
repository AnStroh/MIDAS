# Contributing to MIDAS

Thanks for considering contributing! Bug reports, feature requests, and pull requests are all welcome.

## Reporting a bug

Open an issue with:
- Which folder you're using (`matlab/`, `GUI/`, or `octave/`) and version (MATLAB release, or `octave --version`).
- The parameter configuration that triggers it (attach the file, or list which fields you changed from an example/default).
- The full error message/stack trace, if there is one.

## Proposing a feature or a new example configuration

Open an issue describing what you want to model and why the current examples/parameters don't cover it. If you already have a working parameter set, feel free to open a pull request directly instead - new example configurations are especially welcome (see `docs/examples.md` for the pattern the existing six follow: a complete, standalone parameter file with every unused field set to `NaN`).

## Making changes

1. Fork the repository and create a branch of `main`.
2. Since `matlab/`, `GUI/`, and `octave/` are independent copies of the same code, a change to shared logic (`MIDAS_Main.m`, a `plot_*.m` function, `export_pub_fig.m`, etc.) needs to be applied to **all three** folders that contain it, unless it's genuinely MATLAB- or Octave-specific.
3. Run the smoke checks locally before opening a PR:
   ```matlab
   cd matlab   % or GUI, or octave
   addpath('../.github/scripts')
   smoke_test
   ```
   (There's no formal unit test suite yet - this just confirms the six examples and the full plotting/export pipeline still run without erroring.)
4. Open a pull request against `main`. CI (MATLAB and Octave, see the badges in `README.md`) runs automatically.

## Code style

- Comments should explain **why**, not what the code already makes obvious from good naming - see the existing files for the convention.
- A parameter that's only meaningful under one mode of another parameter (e.g. `delT` only under `PTmode='Tbump'`) should say so in its inline comment, and any example configuration that doesn't use it should set it to `NaN` rather than leaving a stale value in place.
- Keep `matlab/`, `GUI/`, and `octave/` in sync for anything not legitimately platform-specific (see point 2 above).
