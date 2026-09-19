% SMOKE_TEST  CI smoke check, shared between the MATLAB and Octave
% workflows: runs every examples/ExampleN.m with a small/fast grid,
% confirms each produces a finite real S_final, then runs the full
% plotting + export pipeline once (Example1). This is NOT a substitute for
% real unit tests (none exist yet) - it's just a guard against the whole
% pipeline silently breaking on a change.
%
% Run with the target folder (matlab/ or octave/) as the working directory:
%   matlab -batch "run('../.github/scripts/smoke_test.m')"
%   octave --eval "run('../.github/scripts/smoke_test.m')"
%
% Exits with a non-zero status if anything fails, so CI catches it.
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
addpath('examples', 'plotting', 'export');
exampleFns = {'Example1_Baseline', 'Example2_PolyEquilibrium', ...
              'Example3_ThermalBump', 'Example4_ManualPartitioning', ...
              'Example5_PlanarGeometry', 'Example6_CylindricalGeometry'};

ok = true;
for k = 1:numel(exampleFns)
    fname = exampleFns{k};
    fprintf('=== %s ===\n', fname);
    try
        params = feval(fname);
        params.doPlot = false; params.make_movie = false; params.save_data = false;
        params.store_history = true; params.t_tot = 1; params.nx_A = 15; params.nx_B = 15;
        outDir = tempname(); mkdir(outDir); params.outDir = outDir;
        R = MIDAS_Main(params);
        if ~isfinite(R.S_final) || ~isreal(R.S_final)
            error('S_final is not a finite real number (%g)', R.S_final);
        end
        % S_final alone isn't enough: a degenerate configuration (e.g. a
        % NaN eqMode='poly' calibration) can leave S_final looking normal
        % while the fields that actually matter scientifically - final
        % compositions and apparent ages - are NaN. Check those directly.
        if any(isnan(R.CA_final)) || any(isnan(R.CB_final)) || any(isnan(R.tALuHf1_final))
            error('S_final is finite (%g) but CA_final/CB_final/tALuHf1_final contain NaN - the run only looks like it succeeded.', R.S_final);
        end
        fprintf('  OK, S_final = %.4g\n', R.S_final);
    catch ME
        fprintf('  FAILED: %s\n', ME.message);
        ok = false;
    end
end

fprintf('=== Full plotting + export pipeline (Example1) ===\n');
try
    params = Example1_Baseline();
    params.doPlot = false; params.make_movie = false; params.save_data = false;
    params.store_history = true; params.t_tot = 1; params.nx_A = 15; params.nx_B = 15;
    outDir = tempname(); mkdir(outDir); params.outDir = outDir;
    R = MIDAS_Main(params);
    [figRelErrLog,figABOnly] = plot_velocity_age(R); %#ok<ASGLU>
    plot_misfit(R); plot_massbalance_MgO(R);
    plot_age_at_fixed_positions(R); plot_conc_at_fixed_positions(R);
    plot_age_vs_temperature(R); plot_all_composition_profiles(R);
    export_pub_fig(figRelErrLog, fullfile(outDir,'ci_test'));
    export_results_excel(R, fullfile(outDir,'ci_test.xlsx'));
    fprintf('  OK\n');
catch ME
    fprintf('  FAILED: %s\n', ME.message);
    ok = false;
end

if ok
    fprintf('\nAll smoke checks passed.\n');
else
    fprintf('\nSome smoke checks FAILED - see above.\n');
    exit(1)
end
