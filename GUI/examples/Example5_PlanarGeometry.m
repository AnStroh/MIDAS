function params = Example5_PlanarGeometry()
% EXAMPLE5_PLANARGEOMETRY  Same fully automated, phase-
% diagram-driven configuration as Example1, but with planar growth
% geometry instead of spherical (ndim=1 instead of ndim=3) - e.g. for a
% tabular crystal or a 1-D approximation. Every field this configuration
% does NOT use is set to NaN.
%
% Usage:
%   params = Example5_PlanarGeometry();
%   R = MIDAS_Main(params);
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
% Physics (Diffusion and Growth) ---------------------------------------------
params.lxA               = 0.5;                                % Length of A (crystal, e.g. Grt) in mm
params.lxB_factor        = 7.5;                                % lxB = lxB_factor*lxA; length of B (matrix) in mm
params.DRG               = 500;                                % Diffusivity of B wrt A (major elements)
params.DRG_LuHf          = 8e3;                                % Diffusivity Lu/Hf in matrix (wrt A)
params.DRG_Mn            = 1e3;                                % Diffusivity Mn in matrix (wrt A)
params.DamA              = 1e3;                                % Damköhler_II for material A (interface kinetics)
params.DamB              = 1e3;                                % Damköhler_II for material B (interface kinetics)
params.KDLu              = 20;                                 % KD Lu (Xtl/Mtrx: pelites) (KD = 100; Kohn, 2009, p.171)
params.KDHf              = 0.040;                              % KD Hf (Xtl/Mtrx: pelites) (KD = 0.040 Kohn, 2009, p.171)
params.MnMode            = 'PD';                               % 'fixed': use constant params.KDMn below; 'PD': derive KD_Mn(T,P) from the phase diagram (params.PD)
params.KDMn              = NaN;                                % KD Mn (Xtl/Mtrx: pelites); used only if MnMode = 'fixed', or if MniBMode = 'manual' - unused here since MnMode = 'PD' and MniBMode = 'PD'
params.LuiB              = 1.2;                                % Initial amount in ppm of Lu (in B)
params.HfiB              = 1.0;                                % Initial amount in ppm of Hf (in B)
params.HfiBref           = 1.0;                                % Initial amount in ppm of Hf(ref) (in B); normalization reference (176Lu/177Hf ~0.279, Faure & Mensing, 2025)
params.MniBMode          = 'PD';                               % 'manual': use params.MniB below (the user's own input); 'PD': override it with MnO_Bt interpolated from the phase diagram at Tstart,Pstart
params.MniB              = NaN;                                % Initial amount in wt% of Mn (in B); used only if MniBMode = 'manual' - unused here since MniBMode = 'PD'
params.isoRefMode        = 'core';                             % Isochron reference point for phase A (crystal): 'bulk' (volume-weighted average of B), 'core' (B node farthest from the interface), or 'wholerock' (volume-weighted average of A+B together)
params.isoNskip          = 10;                                 % Isochron profile sampling: compute an age for every isoNskip-th node across phase A (in addition to rim/core/bulk)
params.isoShowProfile    = 0;                                  % 1: also plot the isoNskip-th profile points/lines (light gray) in the isochron panel; 0: show only core/rim/bulk/max

% Time and P-T path -----------------------------------------------------------
params.t_tot              = 15;                                 % Total time in Myr (growth & diffusion, before relaxation)
params.PTmode             = 'peak';                             % 'Tbump': old T-only bump (delT), P linear; 'peak': explicit Tpeak/Ppeak with independent peak timing for T and P
params.Tstart             = 540+273;                            % Starting T in K
params.Tstop              = 690+273;                            % Tstop in K
params.delT               = NaN;                                % Thermal max during decompression (changes peak T); used only if PTmode = 'Tbump' - unused here since PTmode = 'peak'
params.Tpeak              = 700+273;                            % Peak T in K; used only if PTmode = 'peak'
params.T_peak_frac        = 0.90;                               % Time of peak T, as a fraction of t_tot; used only if PTmode = 'peak'
params.Pstart             = 0.5;                                % Pstart in GPa
params.Pstop              = 0.4;                                % Pstop in GPa
params.Ppeak              = 0.96;                               % Peak P in GPa; used only if PTmode = 'peak'
params.P_peak_frac        = 0.35;                               % Time of peak P, as a fraction of t_tot; used only if PTmode = 'peak'
params.Trange             = [500,800]+273;                      % T range for visualization/phase diagram in K
params.Prange             = [0  ,1.2];                          % P range for visualization/phase diagram in GPa

% Thermodynamics (major elements) ---------------------------------------------
params.eqMode             = 'PD';                               % Equilibrium composition source: 'poly' (3-point bilinear fit) or 'PD' (Phase diagram)
% Define a P-T-X path based on 3 coordinates (used if eqMode = 'poly') - unused here since eqMode = 'PD'
params.Tar                = [NaN,NaN,NaN];                      % Temperatures in K at the 3 calibration points
params.Par                = [NaN,NaN,NaN];                      % Pressures in GPa at the 3 calibration points
params.Car_G              = [NaN,NaN,NaN];                      % Compositions of MgO in garnet (A) at the 3 points
params.Car_B              = [NaN,NaN,NaN];                      % Compositions of MgO in biotite (B) at the 3 points
% Define a P-T-X path based on a phase diagram (used if eqMode = 'PD')
params.PD                 = 'phasediagrams/Pelite_avg_1.dat';                 % Perplex table: cols [T(K), P(bar), ..., MgO_A(wt%), MgO_B(wt%), ...]

% Numerics ----------------------------------------------------------------------
params.ndim                = 1;                                % Geometry factor (1: planar, 2: cylindrical, 3: spherical)
params.NBC                 = 1;                                % Neumann (no-flux) outer boundary condition
params.nx_A                = 200;                              % Grid resolution in A
params.nx_B                = 200;                              % Grid resolution in B

% Programming flags and options ----------------------------------------------
params.checkmaxT_Eq     = 0;                                   % 1: stop advancing T once max T is reached (checks equilibrium there)
params.checkFinT_Eq     = 2.5;                                 % >1: extend run to checkFinT_Eq*t_tot at constant final P-T (relaxation) - kept well short of the point where the post-peak resorption trend would consume the whole crystal at full grid resolution (checkFinT_Eq=4.5 does, for this P-T path)
params.store_history    = 1;                                   % 1: store the full time history (needed for statistics below)
params.nout             = NaN;                                 % Plot/record every nout iterations; used only if recordMode = 'iteration' - unused here since recordMode = 'time'
params.recordMode       = 'time';                              % 'iteration': plot/record every nout iterations (dt is adaptive, so this is NOT evenly spaced in time); 'time': plot/record every recordDT Myr instead
params.recordDT         = 0.5;                                 % Plot/record every recordDT Myr; used only if recordMode = 'time'
params.CFL              = 500;                                 % CFL condition
params.nStepsMin        = 500;                                 % Minimum number of adaptive time steps across the run (caps dt at t_tot/nStepsMin); without this, near-stagnant regimes (growth velocity ~0) can take a single enormous step straight to t_final, leaving no recorded time history
params.microStepTol     = 1e-12;                               % mm; if the interface moves less than this in one step, update the boundary node in-place instead of doing a full mesh resample

% Output / plotting ---------------------------------------------------------
params.outDir           = '.';                                % Folder all saved figures/movie/data go into (created if missing)
params.data_name        = 'MIDAS_Example5_PlanarGeometry';    % Base name used when saving results/movie
params.save_data        = 0;                                  % 1: save workspace with data_name at the end (kept off by default here - flip to 1 if you want this example's output written to disk)
params.make_movie       = 0;                                  % 1: write a .gif while running (needs doPlot = true) - kept off by default here, see save_data above
params.doPlot           = 0;                                  % Master switch for figures (set false for silent/batch runs)
params.saveCheckpoints  = false;                              % 1: also save _initial/_snapN/_last figures to outDir while doPlot=true; 0: show them live only, don't write to disk
params.plot_kind        = 3;                                  % 1: profiles+phase diagram+ages, 2: profiles+apparent age, 3: all
params.FSS              = 14;                                 % FontSize
params.LWW               = 1.2;                               % LineWidth
end
