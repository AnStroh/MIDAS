% ============================== Run_MIDAS ===================================
% Single-run driver for the MIDAS interface-limited growth model.
%
% Structure:
%   MIDAS_Params.m          - default input parameters (edit numbers there,
%                              or swap in one of the MIDAS_Params_ExampleN.m
%                              files below to see a different capability)
%   MIDAS_Main.m             - main function + all helper functions
%   Run_MIDAS.m (this file) - loads params, applies any overrides
%       below, and runs the model once.
%
% Examples (each a complete, standalone parameter set - swap the line below
% to try one): MIDAS_Params_Example1_Baseline, _Example2_PolyEquilibrium,
% _Example3_ThermalBump, _Example4_ManualPartitioning, _Example5_PlanarGeometry,
% _Example6_CylindricalGeometry. See each file's own header for what it shows.
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%=============================================================================
clc, clear all%, close all

params            = MIDAS_Params();          % or e.g. MIDAS_Params_Example2_PolyEquilibrium();
params.doPlot     = true;    % show figures for this single run
%params.make_movie = 0;       % also write a .gif of figure(1) over the run

% Override any field here, e.g.:
% params.DamA = 1e-2;
% params.DRG  = 1e2;

% One timestamped folder per run: everything below lands here, and re-running
% never overwrites a previous run's results.
params.outDir = fullfile('results',[params.data_name,'_',datestr(now,'yyyymmdd_HHMMSS')]);

R = MIDAS_Main(params);

% Post-processing--------------------------------------------------------------
% Each plot is always shown; only the ones flagged true here get saved
% (PDF+PNG) to outDir, instead of toggling this by commenting lines.
% Kept off by default (nothing written to disk from a first, out-of-the-box
% run) - flip whichever ones you want to keep to true.
save_velocity_age = false;
save_misfit       = false;
save_massbalance  = false;
save_massbalance_MgO = false;
save_Lu_profile   = false;
save_Mn_profile   = false;
save_ageFixedPos  = false;
save_concFixedPos = false;
save_ageVsT       = false;
save_allComp      = false;
save_initial      = false;

[figAB,figErr,figRelErr,figErrLog,figRelErrLog,figABOnly] = plot_velocity_age(R);   % Length/time/age heatmap + velocity vs time, + signed/relative/log-scale age-misfit heatmaps (+ standalone panel-only apparent-age version)
if save_velocity_age
    export_pub_fig(figAB,        fullfile(R.params.outDir,'Fig_velocity_age'))
    export_pub_fig(figErr,       fullfile(R.params.outDir,'Fig_velocity_age_misfit'))
    export_pub_fig(figRelErr,    fullfile(R.params.outDir,'Fig_velocity_age_relmisfit'))
    export_pub_fig(figErrLog,    fullfile(R.params.outDir,'Fig_velocity_age_misfit_log'))
    export_pub_fig(figRelErrLog, fullfile(R.params.outDir,'Fig_velocity_age_relmisfit_log'))
    export_pub_fig(figABOnly,    fullfile(R.params.outDir,'Fig_velocity_age_AB_only'))
end

plot_misfit(R)                                              % Apparent-age / isochron-age misfit vs time
if save_misfit, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_misfit')); end

plot_massbalance(R)                                         % Mass-balance drift vs time (numerical check)
if save_massbalance, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_massbalance')); end

plot_massbalance_MgO(R);                                    % Mass-balance drift, MgO only
if save_massbalance_MgO, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_massbalance_MgO')); end

plot_Lu_profile(R)                                          % Distance vs Lu in phase A, final state
if save_Lu_profile, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_Lu_profile')); end

plot_Mn_profile(R)                                          % Distance vs Mn in phase A, final state
if save_Mn_profile, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_Mn_profile')); end

plot_age_at_fixed_positions(R);                             % Apparent age vs time, tracked at fixed positions up to min(S)
if save_ageFixedPos, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_age_fixed_positions')); end

plot_conc_at_fixed_positions(R);                            % Lu, Hf vs time at the same fixed positions - what the age curves are built from
if save_concFixedPos, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_conc_fixed_positions')); end

plot_age_vs_temperature(R);                                 % Closure-temperature diagnostic: apparent age vs T at fixed positions
if save_ageVsT, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_age_vs_temperature')); end

plot_all_composition_profiles(R);                           % Every element/isotope, phase A (left) vs phase B (right), final state
if save_allComp, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_all_composition_profiles')); end

plot_initial_conditions(R);                                 % Every element/isotope, phase A (left) vs phase B (right), t=0 state
if save_initial, export_pub_fig(gcf,fullfile(R.params.outDir,'Fig_initial_conditions')); end

anySaved = R.params.save_data || R.params.make_movie || save_velocity_age || save_misfit || ...
    save_massbalance || save_massbalance_MgO || save_Lu_profile || save_Mn_profile || ...
    save_ageFixedPos || save_concFixedPos || save_ageVsT || save_allComp || save_initial;
if anySaved
    disp(['all done - results saved in ',R.params.outDir])
else
    disp('all done - nothing written to disk (save_data/make_movie/save_* flags above are all off by default)')
end
