function R = MIDAS_Main(params)
% MIDAS_MAIN  Interface-limited growth model (a moving-boundary problem) for
% a mineral (A) growing/resorbing in a matrix phase (B), coupled to major-
% and trace-element diffusion + partitioning between the two, for modeling
% geochronology, apparent ages and interface (growth/resorption) velocities
% over a metamorphic P-T-t path. Example here: a garnet-biotite pair (major
% elements Mg-Fe; trace elements Lu, Hf, Mn).
%
% PARAMS is read from a struct (see MIDAS_Params.m) instead of being
% hardcoded, and results are returned in R instead of being left in the
% base workspace.
%
% "A" indicates the parameters and variables with respect to the left
% material (crystal), whereas "B" refers to the right material (matrix).
%
% Usage:
%   params = MIDAS_Params();
%   R = MIDAS_Main(params);
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir,'plotting'), fullfile(thisDir,'export'));
if nargin < 1 || isempty(params)
    params = MIDAS_Params();
end
validateCoreParams(params);
outDir          = params.outDir;                              % Folder all saved figures/movie/data go into
data_name       = params.data_name;
save_data       = params.save_data;                           % Data Save
make_movie      = params.make_movie;                          % Flag for Movie making
plot_kind       = params.plot_kind;                           % Kind of plot (1: profiles+phase diagram+ages, 2: profiles+apparent age, 3: all)
doPlot          = params.doPlot;                              % Master switch for any plotting
saveCheckpoints = params.saveCheckpoints;                     % 1: also save _initial/_snapN/_last figures to outDir while doPlot=true; 0: show them live only, don't write to disk
% Only create outDir if something will actually be written into it: the
% .mat file (save_data), or - while plotting live - the checkpoint figures
% and/or the movie gif. Pure live-viewing (doPlot=true, everything else
% off) leaves no folder behind.
if (save_data || (doPlot && (saveCheckpoints || make_movie))) && ~exist(outDir,'dir')
    mkdir(outDir)
end
FSS             = params.FSS;                                 % FontSize
LWW             = params.LWW;                                 % LineWidth
% Programming flags and options---------------------------------------------
checkmaxT_Eq    = params.checkmaxT_Eq;                        % Check max T Equilibrium (simulation stops at max T)
checkFinT_Eq    = params.checkFinT_Eq;                        % Check Final Equilibrium >1 (t_tot*factor = end) -> relaxation
store_history   = params.store_history;                       % Store history variables
nout            = params.nout;                                % Plot/record every nout
recordMode      = params.recordMode;                          % 'iteration' or 'time'
recordDT        = params.recordDT;                            % Plot/record every recordDT Myr; used only if recordMode = 'time'
CFL             = params.CFL;                                 % CFL condition
nStepsMin       = params.nStepsMin;                           % Minimum number of adaptive time steps across the run (caps dt, see MIDAS_Params.m)
microStepTol    = params.microStepTol;                        % in mm; below-this-movement steps update the boundary node in-place instead of resampling (see MIDAS_Params.m)
% Physical constants -------------------------------------------------------
Myr      = 60*60*24*365.25*1e6;                               % 1 My in sec
Rgac     = 1.9872159;                                         % cal/mol/K
RgaJ     = Rgac*4.184;                                        % J/mol/K
l_Lu     = 1.867*1e-11;                                       % Lu decay constant in yr^(-1) (Söderlund et al. 2004)
% Physics (Diffusion and Growth)
lxA      = params.lxA;                                        % Length of A in mm
lxB      = params.lxB_factor*lxA;                             % Length of B in mm
DRG      = params.DRG;                                        % Diffusivity of B wrt A
DRG_LuHf = params.DRG_LuHf;                                   % Diffusivity Lu/Hf in matrix (wrt A)
DRG_Mn   = params.DRG_Mn;                                     % Diffusivity Mn in matrix (wrt A)
DamA     = params.DamA;                                       % Damköhler_II for 1st material (A)
DamB     = params.DamB;                                       % Damköhler_II for 2nd material (B)
lamLu    = l_Lu*1e6;                                          % Lu Decay in Myr^(-1)
KDLu     = params.KDLu;                                       % KD Lu (Xtl/Mtrx: pelites)
KDHf     = params.KDHf;                                       % KD Hf (Xtl/Mtrx: pelites)
KDMn     = params.KDMn;                                       % KD Mn (Xtl/Mtrx: pelites)
LuiB     = params.LuiB;                                       % Initial amount in ppm of Lu (in B)
HfiB     = params.HfiB;                                       % Initial amount in ppm of Hf (in B)
HfiBref  = params.HfiBref;                                    % Initial amount in ppm of Hf(ref) (in B); normalization ref
MniB     = params.MniB;                                       % Initial amount in wt% of Mn (in B)
isoRefMode = params.isoRefMode;                               % Isochron reference point for phase A: 'bulk' or 'core'
isoNskip   = params.isoNskip;                                 % Compute an age for every isoNskip-th node across phase A
isoShowProfile = params.isoShowProfile;                       % Plot the isoNskip-th profile points/lines in the isochron panel
% Time and Path
t_tot    = params.t_tot;                                      % Total time in Myr (for growth & diffusion without relaxation afterwards)
Tstart   = params.Tstart;                                     % Starting T in K
Tstop    = params.Tstop;                                      % Final T in K
Pstart   = params.Pstart;                                     % Starting P in GPa
Pstop    = params.Pstop;                                      % Final P in GPa
Trange   = params.Trange;                                     % T range for visualization in K
Prange   = params.Prange;                                     % P range for visualization in GPa
% Make P-T path (parametrized) ---------------------------------------------
PTmode   = params.PTmode;                                     % 'Tbump': T-only bump (delT), P linear; 'peak': explicit Tpeak/Ppeak with independent peak timing for T and P
tt       = linspace(0,t_tot,1000);                            % Time array
switch PTmode
    case 'Tbump'
        delT = params.delT;                                   % Thermal max during decompression (changes peak T)
        Tt   = linspace(Tstart,Tstop,length(tt));             % Linear temperaure array
        Tt   = Tt + 1*((t_tot - tt)/t_tot).*(tt./t_tot).*delT*4;  % Curved temperature array
        Pt   = linspace(Pstart,Pstop,length(tt));             % Pressure array (no peak)
    case 'peak'
        Tpeak       = params.Tpeak;                           % Peak T in K
        Ppeak       = params.Ppeak;                           % Peak P in GPa
        T_peak_frac = params.T_peak_frac;                     % Time of peak T, as a fraction of t_tot
        P_peak_frac = params.P_peak_frac;                     % Time of peak P, as a fraction of t_tot (independent of T_peak_frac)
        Tt = pathThreePoint(0,T_peak_frac*t_tot,t_tot,Tstart,Tpeak,Tstop,tt); % Prograde-retrograde T path through start/peak/stop
        Pt = pathThreePoint(0,P_peak_frac*t_tot,t_tot,Pstart,Ppeak,Pstop,tt); % Prograde-retrograde P path through start/peak/stop (own peak timing)
    otherwise
        error('params.PTmode must be ''Tbump'' or ''peak''.')
end
% Last Equilibration step --------------------------------------------------
% >1 only (not >0): checkFinT_Eq*t_tot must exceed t_tot (tt's existing
% last sample) for the appended point below to be valid - at exactly 1 it
% duplicates that sample (griddedInterpolant needs strictly increasing
% points), and below 1 it would come before it.
if checkFinT_Eq > 1
    tt      = [tt,checkFinT_Eq*t_tot];                        % Augment timestep
    Tt      = [Tt,Tt(end)];                                   % Force last T
    Pt      = [Pt,Pt(end)];                                   % Force last P
    t_tot   = tt(end);                                        % For checkFinT_Eq*t_tot; Linear interp in between
end
dt_max = t_tot/nStepsMin;   % Upper bound on dt so near-stagnant runs (v->0) still take enough steps to resolve a time history, instead of jumping straight to t_tot in one step
% Figure-saving checkpoints -------------------------------------------------
% Snapshots of figure(1) as vector PDFs: the first plot (t~0), one at every
% recorded step in between (same cadence as recordMode/recordDT or nout -
% whatever governs doRecord below), and the last step (saved separately
% after the loop, see below).
firstPlotSaved = false;
% Fast repeated-evaluation interpolants for the P-T path (built once, evaluated every timestep in the loop below)
Tinterp = griddedInterpolant(tt,Tt,'linear','linear');
Pinterp = griddedInterpolant(tt,Pt,'linear','linear');
% Thermodynamics (major elements) ------------------------------------------
eqMode    = params.eqMode;                                    % 'poly': 3-point bilinear fit; 'PD': Perplex phase diagram
MnMode    = params.MnMode;                                    % 'fixed': constant params.KDMn; 'PD': KD_Mn(T,P) from the Perplex phase diagram
MniBMode  = params.MniBMode;                                  % 'manual': use params.MniB (the user's own input); 'PD': override MniB from the phase diagram at Tstart,Pstart
if strcmp(MniBMode,'manual') && strcmp(MnMode,'PD')
    fprintf('Note: MniB is manually specified - using the fixed params.KDMn instead of the phase-diagram-derived KD.\n')
    MnMode = 'fixed';
end
needPD  = strcmp(eqMode,'PD') || strcmp(MnMode,'PD') || strcmp(MniBMode,'PD');
if needPD && ~isfile(params.PD)
    fprintf('Note: phase diagram file ''%s'' not found - continuing without it.\n',params.PD)
    if strcmp(eqMode,'PD')
        fprintf('  -> eqMode falls back to ''poly''.\n')
        eqMode = 'poly';
    end
    if strcmp(MnMode,'PD')
        fprintf('  -> MnMode falls back to ''fixed''.\n')
        MnMode = 'fixed';
    end
    if strcmp(MniBMode,'PD')
        fprintf('  -> MniBMode falls back to ''manual''.\n')
        MniBMode = 'manual';
    end
    needPD = false;
end
% Load the Perplex table and reshape it into grids ONCE (if needed by either
% switch below); every subsequent equilibrium lookup just interpolates on these.
if needPD
    PhaseDiagram                       = load(params.PD);
    [PGPa,TK,MgOA,MgOB,MnOA,MnOB]      = create_grid(PhaseDiagram);
end
switch eqMode
    case 'poly'
        %Bilinear Polynomial using three points [start, max T, final] (Fe-Mg)
        Tar     = params.Tar;                                 % Temperatures in K
        Par     = params.Par;                                 % Pressures in GPa
        Car_G   = params.Car_G;                               % Compositions of MgO in garnet
        Car_B   = params.Car_B;                               % Compositions of MgO in biotite
        if any(isnan([Tar(:); Par(:); Car_G(:); Car_B(:)]))
            error('MIDAS:InvalidPolyCalibration', ['eqMode is ''poly'' - chosen directly, or automatically because ', ...
                'params.PD (''%s'') could not be found - but params.Tar/Par/Car_G/Car_B are still the [NaN,NaN,NaN] ', ...
                'placeholders from MIDAS_Params.m, not real calibration points. Fitting a polynomial to NaN silently ', ...
                'produces a meaningless (but finite-looking) result rather than erroring, so this is checked explicitly. ', ...
                'Fix by either: (1) setting all four to real 3-point [T,P,composition] calibration values - see ', ...
                'examples/Example2_PolyEquilibrium.m for a worked example - or (2) pointing params.PD at a real, ', ...
                'existing phase-diagram file so eqMode=''PD'' can be used instead.'], params.PD);
        end
        [CAc]   = find_poly(Car_G,Tar,Par);                   % Coefficients for Major Elements in A
        [CBc]   = find_poly(Car_B,Tar,Par);                   % Coefficients for Major Elements in B
        eqFun        = @(T,P) TL(T,P,CAc,CBc);                % Equilibrium composition (silent: extrapolates smoothly)
        eqFunChecked = eqFun;                                 % 'poly' never raises an out-of-range error
    case 'PD'
        eqFun        = @(T,P) deal(interp2(PGPa,TK,MgOA,P,T), interp2(PGPa,TK,MgOB,P,T));         % Silent (for the background field)
        eqFunChecked = @(T,P) deal(interpolateC(PGPa,TK,MgOA,P,T), interpolateC(PGPa,TK,MgOB,P,T)); % Errors if P,T is outside the phase diagram range
    otherwise
        error('params.eqMode must be ''poly'' or ''PD''.')
end
switch MnMode
    case 'fixed'
        KDMnFun = @(T,P) params.KDMn;                                                              % Constant KD (Xtl/Mtrx), ignores T,P
    case 'PD'
        KDMnFun = @(T,P) interpolateC(PGPa,TK,MnOA,P,T)./interpolateC(PGPa,TK,MnOB,P,T);           % KD derived from the local Grt/Bt equilibrium composition
    otherwise
        error('params.MnMode must be ''fixed'' or ''PD''.')
end
switch MniBMode
    case 'manual'
        MniBFun = @(T,P) params.MniB;                         % User-provided matrix Mn reservoir, ignores T,P
    case 'PD'
        MniBFun = @(T,P) interpolateC(PGPa,TK,MnOB,P,T);      % Matrix (biotite) MnO taken from the phase diagram
    otherwise
        error('params.MniBMode must be ''manual'' or ''PD''.')
end
% Note that the compositions are not generally independent -> compare phase diagrams
%Calculate thermo field ---------------------------------------------------
[T2,P2,CA2,CB2] = load_TData(Trange,Prange,eqFun);
% Numerics ----------------------------------------------------------------
ndim     = params.ndim;                                       % Geometry factor (1: planar, 2: cylindrical, 3: spherical)
NBC      = params.NBC;                                        % Neumann boundary condition (outer BC)
nx_A     = params.nx_A;                                       % Resolution in A
nx_B     = params.nx_B;                                       % Resolution in B
dx_A     = lxA/(nx_A-1);
dx_B     = lxB/(nx_B-1);
% Grid
xA       = 0:dx_A:lxA;
xB       = lxA:dx_B:(lxA+lxB);
% X correction geometry
xcA     = 0.5*(xA(2:end)+xA(1:end-1));                        % Average at midpoints
xcB     = 0.5*(xB(2:end)+xB(1:end-1));                        % Average at midpoints
xAL     = (xcA(1:end-1)).^(ndim-1);                           % Correction for the diagonal (implicit code)
xAC     = xA(2:end-1).^(ndim-1);                              % Correction for the diagonal (implicit code)
xAR     = (xcA(2:end)).^(ndim-1);                             % Correction for the diagonal (implicit code)
xBL     = (xcB(1:end-1)).^(ndim-1);                           % Correction for the diagonal (implicit code)
xBC     = xB(2:end-1).^(ndim-1);                              % Correction for the diagonal (implicit code)
xBR     = (xcB(2:end)).^(ndim-1);                             % Correction for the diagonal (implicit code)
% Initial conditions Compositions
P               = Pstart;
T               = Tstart;
[CA_eq, CB_eq]  = eqFunChecked(Tstart,Pstart);
% Major Elements in A & B
CA              = ones(1,nx_A)*CA_eq;
CB              = ones(1,nx_B)*CB_eq;
CAb             = CA_eq;
CBb             = CB_eq;
% Trace elements in A & B: Lu/Hf
CALu            = ones(1,nx_A)*LuiB*KDLu;
CAHf            = ones(1,nx_A)*HfiB*KDHf;
CAHfr           = ones(1,nx_A)*HfiBref*KDHf;
KDMn            = KDMnFun(Tstart,Pstart);                     % Constant (MnMode='fixed') or from the phase diagram (MnMode='PD')
MniB            = MniBFun(Tstart,Pstart);                     % params.MniB (MniBMode='manual') or from the phase diagram (MniBMode='PD')
CAMn            = ones(1,nx_A)*MniB*KDMn;
CBLu            = ones(1,nx_B)*LuiB;
CBHf            = ones(1,nx_B)*HfiB;
CBHfr           = ones(1,nx_B)*HfiBref;
CBMn            = ones(1,nx_B)*MniB;                          % Initial Interface Position & store initial conditions
S               = lxA;
S0              = lxA;                                        % S is redefined every step as the interface moves, so snapshot the t=0 size here
Lx0             = [lxA,lxB];
xA0             = xA;                                         % xA/xB are resampled every step as the interface moves, so snapshot the t=0 grid here
xB0             = xB;
CA0             = CA;
CB0             = CB;
CALu0           = CALu;
CAHf0           = CAHf;
CAHfr0          = CAHfr;
CAMn0           = CAMn;
CBLu0           = CBLu;
CBHf0           = CBHf;
CBHfr0          = CBHfr;
CBMn0           = CBMn;
% Running y-axis ceilings for the live compositional-profile plots: only
% ever grow (never shrink), so the axis stays fixed most of the time instead
% of rescaling on every redraw, while still ending up bounding the full run.
% Both phases share this one axis in plotAB.m, so the ceiling must cover
% whichever of A (garnet) or B (biotite) is larger - using A alone clips B
% whenever biotite's concentration exceeds garnet's.
yMaxCA          = max([CA0(:);   CB0(:)])  *1.2;
yMaxCAMn        = max([CAMn0(:); CBMn0(:)])*1.2;
yMaxCALu        = max([CALu0(:); CBLu0(:)])*1.2;
yMaxCAHf        = max([CAHf0(:); CBHf0(:)])*1.2;
% Initialization ----------------------------------------------------------
t               = 0;                                          % Initial time
v               = 1e-23;                                      % Initialize very small initial velocity (will be recalculated)
it              = 0;                                          % Iteration counter
itp             = 0;                                          % Iteration counter record
lastRecordT     = -inf;                                       % Last time plotted/recorded; used only if recordMode = 'time'
% Sum MB ------------------------------------------------------------------
MB0    = calc_mass_vol(xA,xB,CA,CB,ndim);
MBLu0  = calc_mass_vol(xA,xB,CALu,CBLu,ndim);
MBHf0  = calc_mass_vol(xA,xB,CAHf,CBHf,ndim);
MBHfr0 = calc_mass_vol(xA,xB,CAHfr,CBHfr,ndim);
MBMn0  = calc_mass_vol(xA,xB,CAMn,CBMn,ndim);
%Prepare for Movie --------------------------------------------------------
if make_movie == 1 && doPlot
    filename = fullfile(outDir,[data_name,'.gif']);
    it_loc = 0;
end
% =============================== run loop ================================
stoppedEarly = false;                                         % set true if the trace-element BC solve fails (e.g. CB_BC<0 at an extreme DamA/DRG corner); the run then ends here, keeping the last self-consistent step's state instead of discarding it
stopReason   = '';
while t < t_tot
    it = it +1;
    % Snapshot of the state mutated below, before the trace-element BC
    % solve: if that fails, we revert to this (the last fully
    % self-consistent step) rather than keep a half-updated iteration.
    t_prev  = t;
    CA_prev = CA;   CB_prev = CB;   v_prev = v;
    % Update Diffusion coefficient -----------------------------
    [DMgFe]     = calc_diff_binary(CA,T,P,Rgac,Myr);
    [DALu,DAHf] = calc_diffLuHf(T,P,RgaJ,Myr);
    [DAMn]      = calc_diffMn(T,P,Rgac,Myr);
    DA          = DMgFe;                                      % Nonlinear approx
    DB          = mean(DA)*DRG;                               % Matrix is constant
    % Timesteppers------------------------------------------------
    % Major Elements
    kapA    = mean(DA)*DamA/(lxA+lxB)^2;                      % Relaxation from equilibrium (-> reaction)
    kapB    = mean(DB)*DamB/(lxA+lxB)^2;
    dtDA    = dx_A^2/max(DA)*CFL;                             % Diffusion timescale
    dtDB    = dx_B^2/max(DB)*CFL;
    dtlA    = 1/kapA*CFL;                                     % Reaction timescale
    dtlB    = 1/kapB*CFL;
    % Lutetium - kinetic parameters (same Dam numbers as in major)
    DBLu    = DALu*DRG_LuHf;
    kLuA    = DALu*DamA/(lxA+lxB)^2;
    kLuB    = DBLu*DamB/(lxA+lxB)^2;
    dtDA_Lu = dx_A^2/max(DALu)*CFL;
    dtDB_Lu = dx_B^2/max(DBLu)*CFL;
    dtlA_Lu = 1/kLuA*CFL;
    dtlB_Lu = 1/kLuB*CFL;
    % Hafnium - kinetics are the same for radiogenic or reference
    DBHf    = DAHf*DRG_LuHf;
    kHfA    = DAHf*DamA/(lxA+lxB)^2;
    kHfB    = DBHf*DamB/(lxA+lxB)^2;
    dtDA_Hf = dx_A^2/max(DAHf)*CFL;
    dtDB_Hf = dx_B^2/max(DBHf)*CFL;
    dtlA_Hf = 1/kHfA*CFL;
    dtlB_Hf = 1/kHfB*CFL;
    % Manganese
    DBMn    = DAMn*DRG_Mn;
    kMnA    = DAMn*DamA/(lxA+lxB)^2;
    kMnB    = DBMn*DamB/(lxA+lxB)^2;
    dtDA_Mn = dx_A^2/max(DAMn)*CFL;
    dtDB_Mn = dx_B^2/max(DBMn)*CFL;
    dtlA_Mn = 1/kMnA*CFL;
    dtlB_Mn = 1/kMnB*CFL;
    %-------------------------------------------------------------
    dtv     = min(dx_A,dx_B)/abs(v)*0.4;
    dt      = min([dtDA,dtDB,dtlA,dtlB,dtv,dtDA_Lu,dtDB_Lu,dtDA_Hf,dtDB_Hf,dtlA_Lu,dtlA_Hf,dtlB_Lu,dtlB_Hf,dtDA_Mn,dtDB_Mn,dtlA_Mn,dtlB_Mn,dt_max]);
    %-------------------------------------------------------------
    t    = t + dt;
    if t > t_tot
        dt = dt-(t-t_tot);
        t  = t_tot;
    end
    %Extract P,T and BC-----------------------------------------
    Pold            = P;
    Told            = T;
    P               = Pinterp(t);
    T               = Tinterp(t);
    if T<Told && checkmaxT_Eq == 1
        T = Told;
        P = Pold;
    end
    % Update equilibrium composition----------------------------
    % Exact solution of dC/dt = -kap*(C-C_eq) (C_eq held constant over dt)
    [CA_eq, CB_eq]  = eqFunChecked(T,P);
    CAb             = CA_eq + (CAb-CA_eq)*exp(-dt*kapA);
    CBb             = CB_eq + (CBb-CB_eq)*exp(-dt*kapB);
    % Interface composition ------------------------------------
    CA(end)         = CAb;
    CB(1)           = CBb;
        % Implicit diffusion Major Elements --------------------
        [CA, CB] = implicitDiffusionSolver(CA,DA,dt,dx_A,nx_A,CB,DB,dx_B,nx_B,NBC,xAC,xAL,xAR,xBC,xBL,xBR,ndim);
    % Growth Condition -----------------------------------------
    % (CB - CA)*v = JCB-JCA; J = -D*(dC/dx)
    JCB             = - DB(1)  *(CB(2)  -    CB(1))/dx_B;
    JCA             = - DA(end)*(CA(end)-CA(end-1))/dx_A;
    dC              = CBb - CAb;
    v               = (JCB-JCA)./dC;
    % Trace Elements -------------------------------------------
    try
        % Lutetium ~~~~~~~~~~~~~~~~~~~~~~~~~~~
        [CAn0Lu, CB1Lu] = solveBC(CALu(end),CBLu(1),CALu(end-1),CBLu(2),dx_A,dx_B,DALu,DBLu,KDLu,v,dt,kLuA,kLuB);
        CALu(end)       =  CAn0Lu;
        CBLu(1)         =  CB1Lu;
        [CALu, CBLu] = implicitDiffusionSolver(CALu,DALu,dt,dx_A,nx_A,CBLu,DBLu,dx_B,nx_B,NBC,xAC,xAL,xAR,xBC,xBL,xBR,ndim);
        % Hafnium ~~~~~~~~~~~~~~~~~~~~~~~~~~~
        [CAn0Hf, CB1Hf] = solveBC(CAHf(end),CBHf(1),CAHf(end-1),CBHf(2),dx_A,dx_B,DAHf,DBHf,KDHf,v,dt,kHfA,kHfB);
        CAHf(end)       =  CAn0Hf;
        CBHf(1)         =  CB1Hf;
        [CAHf, CBHf] = implicitDiffusionSolver(CAHf,DAHf,dt,dx_A,nx_A,CBHf,DBHf,dx_B,nx_B,NBC,xAC,xAL,xAR,xBC,xBL,xBR,ndim);
        % Hafnium (ref) ~~~~~~~~~~~~~~~~~~~~~~
        [CAn0Hfr, CB1Hfr] = solveBC(CAHfr(end),CBHfr(1),CAHfr(end-1),CBHfr(2),dx_A,dx_B,DAHf,DBHf,KDHf,v,dt,kHfA,kHfB);
        CAHfr(end)       =  CAn0Hfr;
        CBHfr(1)         =  CB1Hfr;
        [CAHfr, CBHfr] = implicitDiffusionSolver(CAHfr,DAHf,dt,dx_A,nx_A,CBHfr,DBHf,dx_B,nx_B,NBC,xAC,xAL,xAR,xBC,xBL,xBR,ndim);
        % Manganese ~~~~~~~~~~~~~~~~~~~~~~~~~~~
        KDMn            = KDMnFun(T,P);                            % Constant (MnMode='fixed') or from the phase diagram (MnMode='PD')
        [CAn0Mn, CB1Mn] = solveBC(CAMn(end),CBMn(1),CAMn(end-1),CBMn(2),dx_A,dx_B,DAMn,DBMn,KDMn,v,dt,kMnA,kMnB);
        CAMn(end)       =  CAn0Mn;
        CBMn(1)         =  CB1Mn;
        [CAMn, CBMn] = implicitDiffusionSolver(CAMn,DAMn,dt,dx_A,nx_A,CBMn,DBMn,dx_B,nx_B,NBC,xAC,xAL,xAR,xBC,xBL,xBR,ndim);
    catch MEbc
        % Trace-element BC solve failed (e.g. CB_BC/CA_BC < 0 at an extreme
        % DamA/DRG corner). Revert to the last fully self-consistent step
        % (this iteration's major-element/velocity update is discarded
        % along with it) and stop, instead of throwing the whole run away.
        t = t_prev;   CA = CA_prev;   CB = CB_prev;   v = v_prev;
        stoppedEarly = true;
        stopReason   = MEbc.message;
        break
    end
    % Isotopic Decay -------------------------------------------
    % C -> K => C0 + K0 = (C +K)' = 0 => dC/dt + dK/dt = 0 -> dC/dt = -dK/dt
    % Cn = C0*exp(-lam*(t-t0))
    CALu_n           =  CALu*exp(-lamLu*dt);
    CBLu_n           =  CBLu*exp(-lamLu*dt);
    dLuA             =  CALu - CALu_n;
    dLuB             =  CBLu - CBLu_n;
    CALu             =  CALu_n;
    CBLu             =  CBLu_n;
    CAHf             =  CAHf + dLuA;
    CBHf             =  CBHf + dLuB;
    %Calculate age ----------------------------------------------
    % t = 1/lam*ln((ND(t)-ND(0))/NR(t)+1)
    tALuHf1          =  1/lamLu*log((CAHf-CAHf0(1))./CALu + 1);
    tBLuHf1          =  1/lamLu*log((CBHf-CBHf0(end))./CBLu + 1);
    %Isochron age ---------------------------------------------
    % Interface node is excluded: it is re-equilibrated with the matrix at
    % every step (current-time BC), not part of the crystal's aged record,
    % and including it can dominate/destabilize the regression (e.g. during
    % resorption, when it can flip the fitted slope negative).
    % Phase A (crystal) is additionally anchored to a reference point:
    % B's bulk (matrix-only volume-weighted average), B's core (node
    % farthest from the interface, i.e. least disturbed by diffusion), or
    % the whole-rock composition (volume-weighted average of A+B together)
    % - mirroring a mineral-vs-whole-rock isochron.
    switch isoRefMode
        case 'bulk'
            [~,~,LuRef]  = calc_mass_vol(xA,xB,CALu,CBLu,ndim);
            [~,~,HfRef]  = calc_mass_vol(xA,xB,CAHf,CBHf,ndim);
            [~,~,HfrRef] = calc_mass_vol(xA,xB,CAHfr,CBHfr,ndim);
        case 'core'
            LuRef  = CBLu(end);
            HfRef  = CBHf(end);
            HfrRef = CBHfr(end);
        case 'wholerock'
            LuRef  = calc_mass_vol(xA,xB,CALu,CBLu,ndim);
            HfRef  = calc_mass_vol(xA,xB,CAHf,CBHf,ndim);
            HfrRef = calc_mass_vol(xA,xB,CAHfr,CBHfr,ndim);
        otherwise
            error('params.isoRefMode must be ''bulk'', ''core'', or ''wholerock''');
    end
    [t_rimA,t_coreA,t_bulkA,XdatA,YdatA,XfitA,YfitRimA,YfitCoreA,YfitBulkA,t_profA,Xprof,Yprof,YfitProf,t_maxA,XmaxA,YmaxA,YfitMaxA] = ...
        isochronsRef(CALu,CAHf,CAHfr,xA,ndim,LuRef,HfRef,HfrRef,lamLu,isoNskip);
    %Test for V magnitude --------------------------------------
    if abs(dC)<1e-5
        error('KD (for major elements) close to one - dC goes to zero - velocity will go to infinity')
    end
    % Decide whether this step gets recorded (used both by the normal
    % end-of-iteration recording further below and by the micro-step
    % "continue" fast paths just below, which would otherwise silently skip
    % recording entirely during long near-stagnant phases - a run can spend
    % many steps with interface movement under the microStepTol threshold).
    switch recordMode
        case 'iteration'
            doRecord = mod(it,nout) == 0;
        case 'time'
            doRecord = (t - lastRecordT) >= recordDT;
        otherwise
            error('params.recordMode must be ''iteration'' or ''time''')
    end
    doRecord = doRecord || it == 1;                     % it==1: also capture/save the (near-)initial state at t=0
    %Interface Condition----------------------------------------
    if v > 0
        if abs(dt*v) > dx_B
            error('Reduce CFL, growth >> dxB')
        end
        S          = S     + dt*v;                      % Move interface
        if max(abs(S-xA(end))) < microStepTol
            CA    = [CA(1:end-1),CAb];
            CB    = [CBb, CB(2:end)];
            CALu  = [CALu(1:end-1),CAn0Lu];
            CBLu  = [CB1Lu, CBLu(2:end)];
            CAHf  = [CAHf(1:end-1),CAn0Hf];
            CBHf  = [CB1Hf, CBHf(2:end)];
            CAHfr = [CAHfr(1:end-1),CAn0Hfr];
            CBHfr = [CB1Hfr, CBHfr(2:end)];
            CAMn  = [CAMn(1:end-1),CAn0Mn];
            CBMn  = [CB1Mn, CBMn(2:end)];
            lxA   = lxA   + dt*v;
            lxB   = lxB   - dt*v;
            dx_A  = lxA/(nx_A-1);
            xA    = (0:dx_A:lxA);
            dx_B  = lxB/(nx_B-1);
            xB    = (lxA:dx_B:(lxA+lxB));
            xcA   = 0.5*(xA(2:end)+xA(1:end-1));
            xcB   = 0.5*(xB(2:end)+xB(1:end-1));
            xAL   = (xcA(1:end-1)).^(ndim-1);
            xAC   = xA(2:end-1).^(ndim-1);
            xAR   = (xcA(2:end)).^(ndim-1);
            xBL   = (xcB(1:end-1)).^(ndim-1);
            xBC   = xB(2:end-1).^(ndim-1);
            xBR   = (xcB(2:end)).^(ndim-1);
            % This micro-step (interface moved < microStepTol, so the mesh was
            % updated in-place above instead of via the full pchip resample)
            % would otherwise `continue` straight past the recording section
            % below every time, silently dropping history during long
            % near-stagnant phases (e.g. growth velocity ~0). Record here too.
            if doRecord
                lastRecordT = t;
                if store_history == 1
                    itp             = itp +1;
                    Srec(itp)       = S;
                    Vrec(itp)       = v;
                    dtrec(itp)      = dt;
                    dxArec(itp)     = dx_A;
                    dxBrec(itp)     = dx_B;
                    CAh(itp)        = CAb;
                    CBh(itp)        = CBb;
                    trec(itp)       = t;
                    Trec(itp)       = T;
                    Prec(itp)       = P;
                    CArec(itp,:)    = CA;
                    CBrec(itp,:)    = CB;
                    CALurec(itp,:)  = CALu;
                    CBLurec(itp,:)  = CBLu;
                    CAHfrec(itp,:)  = CAHf;
                    CBHfrec(itp,:)  = CBHf;
                    CAHfrrec(itp,:) = CAHfr;
                    CBHfrrec(itp,:) = CBHfr;
                    CAMnrec(itp,:)  = CAMn;
                    CBMnrec(itp,:)  = CBMn;
                    xArec(itp,:)    = xA;
                    xBrec(itp,:)   = xB;
                    tA1(itp,:)      = tALuHf1;
                    tB1(itp,:)      = tBLuHf1;
                    tRimAh(itp)     = t_rimA;
                    tCoreAh(itp)    = t_coreA;
                    tBulkAh(itp)    = t_bulkA;
                    tMaxAh(itp)     = t_maxA;
                    misfitApparentH(itp) = max(abs(tALuHf1 - t));
                    misfitIsochronH(itp) = max(abs([t_rimA,t_coreA,t_bulkA,t_maxA] - t));
                    MB(itp)         = calc_mass_vol(xA,xB,CA,CB,ndim);
                    MBLu(itp)       = calc_mass_vol(xA,xB,CALu,CBLu,ndim);
                    MBHf(itp)       = calc_mass_vol(xA,xB,CAHf,CBHf,ndim);
                    MBHfr(itp)      = calc_mass_vol(xA,xB,CAHfr,CBHfr,ndim);
                    MBMn(itp)       = calc_mass_vol(xA,xB,CAMn,CBMn,ndim);
                    dMB(itp)        = (MB(itp)   - MB0   )/MB0;
                    dMBMn(itp)      = (MBMn(itp) - MBMn0 )/MBMn0;
                    dMBHfr(itp)     = (MBHfr(itp)- MBHfr0)/MBHfr0;
                end
            end
            continue
        end
        lxA        = lxA   + dt*v;
        lxB        = lxB   - dt*v;
        xA_temp    = [xA,S];                            % Adjust grid
        xB_temp    = [S,xB(2:end)];
        CA_temp    = [CA,CAb];
        CB_temp    = [CBb, CB(2:end)];
        CALu_temp  = [CALu,CAn0Lu];
        CBLu_temp  = [CB1Lu, CBLu(2:end)];
        CAHf_temp  = [CAHf,CAn0Hf];
        CBHf_temp  = [CB1Hf, CBHf(2:end)];
        CAHfr_temp = [CAHfr,CAn0Hfr];
        CBHfr_temp = [CB1Hfr, CBHfr(2:end)];
        CAMn_temp  = [CAMn,CAn0Mn];
        CBMn_temp  = [CB1Mn, CBMn(2:end)];
        dx_A       = lxA/(nx_A-1);
        xA         = (0:dx_A:lxA);                      % Resample
        CA         = pchip(xA_temp,CA_temp,xA);         % Interpolate
        CALu       = pchip(xA_temp,CALu_temp,xA);
        CAHf       = pchip(xA_temp,CAHf_temp,xA);
        CAHfr      = pchip(xA_temp,CAHfr_temp,xA);
        CAMn       = pchip(xA_temp,CAMn_temp,xA);
        dx_B       = lxB/(nx_B-1);
        xB         = (lxA:dx_B:(lxA+lxB));
        CB         = pchip(xB_temp,CB_temp,xB);
        CBLu       = pchip(xB_temp,CBLu_temp,xB);
        CBHf       = pchip(xB_temp,CBHf_temp,xB);
        CBHfr      = pchip(xB_temp,CBHfr_temp,xB);
        CBMn       = pchip(xB_temp,CBMn_temp,xB);
        xcA        = 0.5*(xA(2:end)+xA(1:end-1));
        xcB        = 0.5*(xB(2:end)+xB(1:end-1));
        xAL        = (xcA(1:end-1)).^(ndim-1);
        xAC        = xA(2:end-1).^(ndim-1);
        xAR        = (xcA(2:end)).^(ndim-1);
        xBL        = (xcB(1:end-1)).^(ndim-1);
        xBC        = xB(2:end-1).^(ndim-1);
        xBR        = (xcB(2:end)).^(ndim-1);
    elseif v < 0
        if abs(dt*v) > dx_A
            error('Reduce CFL, resorption >> dxA')
        end
        S          = S   + dt*v;                        % Move interface
        if max(abs(S-xA(end))) < microStepTol
            CA    = [CA(1:end-1),CAb];
            CB    = [CBb, CB(2:end)];
            CALu  = [CALu(1:end-1),CAn0Lu];
            CBLu  = [CB1Lu, CBLu(2:end)];
            CAHf  = [CAHf(1:end-1),CAn0Hf];
            CBHf  = [CB1Hf, CBHf(2:end)];
            CAHfr = [CAHfr(1:end-1),CAn0Hfr];
            CBHfr = [CB1Hfr, CBHfr(2:end)];
            CAMn  = [CAMn(1:end-1),CAn0Mn];
            CBMn  = [CB1Mn, CBMn(2:end)];
            lxA   = lxA   + dt*v;
            lxB   = lxB   - dt*v;
            dx_A  = lxA/(nx_A-1);
            xA    = (0:dx_A:lxA);
            dx_B  = lxB/(nx_B-1);
            xB    = (lxA:dx_B:(lxA+lxB));
            xcA   = 0.5*(xA(2:end)+xA(1:end-1));
            xcB   = 0.5*(xB(2:end)+xB(1:end-1));
            xAL   = (xcA(1:end-1)).^(ndim-1);
            xAC   = xA(2:end-1).^(ndim-1);
            xAR   = (xcA(2:end)).^(ndim-1);
            xBL   = (xcB(1:end-1)).^(ndim-1);
            xBC   = xB(2:end-1).^(ndim-1);
            xBR   = (xcB(2:end)).^(ndim-1);
            % This micro-step (interface moved < microStepTol, so the mesh was
            % updated in-place above instead of via the full pchip resample)
            % would otherwise `continue` straight past the recording section
            % below every time, silently dropping history during long
            % near-stagnant phases (e.g. growth velocity ~0). Record here too.
            if doRecord
                lastRecordT = t;
                if store_history == 1
                    itp             = itp +1;
                    Srec(itp)       = S;
                    Vrec(itp)       = v;
                    dtrec(itp)      = dt;
                    dxArec(itp)     = dx_A;
                    dxBrec(itp)     = dx_B;
                    CAh(itp)        = CAb;
                    CBh(itp)        = CBb;
                    trec(itp)       = t;
                    Trec(itp)       = T;
                    Prec(itp)       = P;
                    CArec(itp,:)    = CA;
                    CBrec(itp,:)    = CB;
                    CALurec(itp,:)  = CALu;
                    CBLurec(itp,:)  = CBLu;
                    CAHfrec(itp,:)  = CAHf;
                    CBHfrec(itp,:)  = CBHf;
                    CAHfrrec(itp,:) = CAHfr;
                    CBHfrrec(itp,:) = CBHfr;
                    CAMnrec(itp,:)  = CAMn;
                    CBMnrec(itp,:)  = CBMn;
                    xArec(itp,:)    = xA;
                    xBrec(itp,:)   = xB;
                    tA1(itp,:)      = tALuHf1;
                    tB1(itp,:)      = tBLuHf1;
                    tRimAh(itp)     = t_rimA;
                    tCoreAh(itp)    = t_coreA;
                    tBulkAh(itp)    = t_bulkA;
                    tMaxAh(itp)     = t_maxA;
                    misfitApparentH(itp) = max(abs(tALuHf1 - t));
                    misfitIsochronH(itp) = max(abs([t_rimA,t_coreA,t_bulkA,t_maxA] - t));
                    MB(itp)         = calc_mass_vol(xA,xB,CA,CB,ndim);
                    MBLu(itp)       = calc_mass_vol(xA,xB,CALu,CBLu,ndim);
                    MBHf(itp)       = calc_mass_vol(xA,xB,CAHf,CBHf,ndim);
                    MBHfr(itp)      = calc_mass_vol(xA,xB,CAHfr,CBHfr,ndim);
                    MBMn(itp)       = calc_mass_vol(xA,xB,CAMn,CBMn,ndim);
                    dMB(itp)        = (MB(itp)   - MB0   )/MB0;
                    dMBMn(itp)      = (MBMn(itp) - MBMn0 )/MBMn0;
                    dMBHfr(itp)     = (MBHfr(itp)- MBHfr0)/MBHfr0;
                end
            end
            continue
        end
        lxA        = lxA + dt*v;
        lxB        = lxB - dt*v;                            % Adjust grid
        xA_temp    = [xA(1:end-1),S];
        xB_temp    = [S,xB];
        CA_temp    = [CA(1:end-1),CAb];
        CB_temp    = [CBb, CB];
        CALu_temp  = [CALu(1:end-1),CAn0Lu];
        CBLu_temp  = [CB1Lu, CBLu];
        CAHf_temp  = [CAHf(1:end-1),CAn0Hf];
        CBHf_temp  = [CB1Hf, CBHf];
        CAHfr_temp = [CAHfr(1:end-1),CAn0Hfr];
        CBHfr_temp = [CB1Hfr, CBHfr];
        CAMn_temp  = [CAMn(1:end-1),CAn0Mn];
        CBMn_temp  = [CB1Mn, CBMn];
        dx_A       = lxA/(nx_A-1);
        xA         = (0:dx_A:lxA);                          % Resample
        CA         = pchip(xA_temp,CA_temp,xA);             % Interpolate
        CALu       = pchip(xA_temp,CALu_temp,xA);
        CAHf       = pchip(xA_temp,CAHf_temp,xA);
        CAHfr      = pchip(xA_temp,CAHfr_temp,xA);
        CAMn       = pchip(xA_temp,CAMn_temp,xA);
        dx_B       = lxB/(nx_B-1);
        xB         = (lxA:dx_B:(lxA+lxB));
        CB         = pchip(xB_temp,CB_temp,xB);
        CBLu       = pchip(xB_temp,CBLu_temp,xB);
        CBHf       = pchip(xB_temp,CBHf_temp,xB);
        CBHfr      = pchip(xB_temp,CBHfr_temp,xB);
        CBMn       = pchip(xB_temp,CBMn_temp,xB);
        xcA        = 0.5*(xA(2:end)+xA(1:end-1));
        xcB        = 0.5*(xB(2:end)+xB(1:end-1));
        xAL        = (xcA(1:end-1)).^(ndim-1);
        xAC        = xA(2:end-1).^(ndim-1);
        xAR        = (xcA(2:end)).^(ndim-1);
        xBL        = (xcB(1:end-1)).^(ndim-1);
        xBC        = xB(2:end-1).^(ndim-1);
        xBR        = (xcB(2:end)).^(ndim-1);
    end
    if S > (lxA+lxB)*0.95
        error('better stop here (crystal 95% of model)')
    elseif S < 0.05*(lxA+lxB)
        error('better stop here (crystal becomes negligible)')
    end
    % Plotting & Post-processing--------------------------------
    % (doRecord was already decided above, before the Interface Condition
    % block, so the micro-step "continue" fast paths there can use it too)
    if doRecord
        lastRecordT = t;
        % Plotting----------------------------------------------
        if doPlot
            yMaxCA   = max([yMaxCA,   max(CA(:))  *1.2, max(CB(:))  *1.2]);
            yMaxCAMn = max([yMaxCAMn, max(CAMn(:))*1.2, max(CBMn(:))*1.2]);
            yMaxCALu = max([yMaxCALu, max(CALu(:))*1.2, max(CBLu(:))*1.2]);
            yMaxCAHf = max([yMaxCAHf, max(CAHf(:))*1.2, max(CBHf(:))*1.2]);
            figure(1), set(gcf,'Color',[1 1 1],'Position',[50 50 1400 1800])
            if plot_kind ==1
                plot_them_1;
            elseif plot_kind ==2
                plot_them_2;
            elseif plot_kind ==3
                plot_them_3;
            end
            % Figure-saving checkpoints --------------------------
            if saveCheckpoints
                if ~firstPlotSaved
                    export_pub_fig(gcf,fullfile(outDir,[data_name,'_initial']))   % t=0 initial conditions, for documentation
                    firstPlotSaved = true;
                else
                    export_pub_fig(gcf,fullfile(outDir,sprintf('%s_t%05.2f',data_name,t)))   % one per recorded step (same cadence as doRecord)
                end
            end
        end
        if make_movie == 1 && doPlot
            % Make movie----------------------------------------
            it_loc     = it_loc+1;
            addSoftwareStamp(gcf);   % so a GIF/frame pulled out of context can still be traced back to MIDAS
            frame      = getframe(1);
            im         = frame2im(frame);
            [imind,cm] = rgb2ind(im,256);
            if it_loc == 1
                imwrite(imind,cm,filename,'gif', 'Loopcount',inf,'DelayTime',1.0);
            else
                imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',1.0);
            end
            % The gif frame above is screen-capture quality (getframe) -
            % also save this same frame as its own 300 dpi JPG, one per
            % movie frame, independent of saveCheckpoints.
            exportgraphics(gcf, fullfile(outDir, sprintf('%s_movie_t%05.2f.jpg', data_name, t)), 'Resolution', 300);
        end
        % Record -----------------------------------------------
        if store_history == 1
            itp             = itp +1;
            Srec(itp)       = S;                        % Interface position
            Vrec(itp)       = v;                        % Monitor Velocity
            dtrec(itp)      = dt;                       % Monitor dt
            dxArec(itp)     = dx_A;                     % Monitor dx_A
            dxBrec(itp)     = dx_B;                     % Monitor dx_B
            CAh(itp)        = CAb;                      % Monitor interface boundary A
            CBh(itp)        = CBb;                      % Monitor interface boundary B
            trec(itp)       = t;                        % Monitor time
            Trec(itp)       = T;                        % Monitor Temperature
            Prec(itp)       = P;                        % Monitor Pressure
            % Monitor compositions
            CArec(itp,:)    = CA;
            CBrec(itp,:)    = CB;
            CALurec(itp,:)  = CALu;
            CBLurec(itp,:)  = CBLu;
            CAHfrec(itp,:)  = CAHf;
            CBHfrec(itp,:)  = CBHf;
            CAHfrrec(itp,:) = CAHfr;
            CBHfrrec(itp,:) = CBHfr;
            CAMnrec(itp,:)  = CAMn;
            CBMnrec(itp,:)  = CBMn;
            % Monitor space
            xArec(itp,:)    = xA;
            xBrec(itp,:)   = xB;
            % Monitor age
            tA1(itp,:)      = tALuHf1;
            tB1(itp,:)      = tBLuHf1;
            tRimAh(itp)     = t_rimA;                       % Monitor isochron age (rim)
            tCoreAh(itp)    = t_coreA;                      % Monitor isochron age (core)
            tBulkAh(itp)    = t_bulkA;                      % Monitor isochron age (bulk)
            tMaxAh(itp)     = t_maxA;                       % Monitor isochron age (max)
            misfitApparentH(itp) = max(abs(tALuHf1 - t));   % Apparent-age misfit vs model time
            misfitIsochronH(itp) = max(abs([t_rimA,t_coreA,t_bulkA,t_maxA] - t)); % Isochron-age misfit vs model time
            MB(itp)         = calc_mass_vol(xA,xB,CA,CB,ndim);
            MBLu(itp)       = calc_mass_vol(xA,xB,CALu,CBLu,ndim);
            MBHf(itp)       = calc_mass_vol(xA,xB,CAHf,CBHf,ndim);
            MBHfr(itp)      = calc_mass_vol(xA,xB,CAHfr,CBHfr,ndim);
            MBMn(itp)       = calc_mass_vol(xA,xB,CAMn,CBMn,ndim);
            % Mass-balance drift, closed-system species only (no decay source/sink):
            % MgO/Mn are conserved by diffusion+partitioning alone, and Hfr
            % (non-radiogenic reference field) never receives ingrowth. Lu/Hf
            % are excluded here since their totals are expected to change
            % (decay), so a drift from t=0 is not a numerical error for them.
            dMB(itp)        = (MB(itp)   - MB0   )/MB0;
            dMBMn(itp)      = (MBMn(itp) - MBMn0 )/MBMn0;
            dMBHfr(itp)     = (MBHfr(itp)- MBHfr0)/MBHfr0;
        end
    end
end
% Final Record ------------------------------------------------------------
% Reuse the last slot instead of appending a new one if it's already at this
% exact time (e.g. stoppedEarly reverted t to an already-recorded step) -
% trec must stay strictly increasing for the pchip interpolation below.
if itp == 0 || trec(itp) ~= t
    itp = itp +1;
end
Srec(itp)       = S;
Vrec(itp)       = v;
dtrec(itp)      = dt;
dxArec(itp)     = dx_A;
dxBrec(itp)     = dx_B;
CAh(itp)        = CAb;
CBh(itp)        = CBb;
trec(itp)       = t;
Trec(itp)       = T;
Prec(itp)       = P;
CArec(itp,:)    = CA;
CBrec(itp,:)    = CB;
CALurec(itp,:)  = CALu;
CBLurec(itp,:)  = CBLu;
CAHfrec(itp,:)  = CAHf;
CBHfrec(itp,:)  = CBHf;
CAHfrrec(itp,:) = CAHfr;
CBHfrrec(itp,:) = CBHfr;
CAMnrec(itp,:)  = CAMn;
CBMnrec(itp,:)  = CBMn;
xArec(itp,:)    = xA;
xBrec(itp,:)   = xB;
tA1(itp,:)      = tALuHf1;
tB1(itp,:)      = tBLuHf1;
tRimAh(itp)     = t_rimA;
tCoreAh(itp)    = t_coreA;
tBulkAh(itp)    = t_bulkA;
tMaxAh(itp)     = t_maxA;
misfitApparentH(itp) = max(abs(tALuHf1 - t));
misfitIsochronH(itp) = max(abs([t_rimA,t_coreA,t_bulkA,t_maxA] - t));
MB(itp)         = calc_mass_vol(xA,xB,CA,CB,ndim);
MBLu(itp)       = calc_mass_vol(xA,xB,CALu,CBLu,ndim);
MBHf(itp)       = calc_mass_vol(xA,xB,CAHf,CBHf,ndim);
MBHfr(itp)      = calc_mass_vol(xA,xB,CAHfr,CBHfr,ndim);
MBMn(itp)       = calc_mass_vol(xA,xB,CAMn,CBMn,ndim);
dMB(itp)        = (MB(itp)   - MB0   )/MB0;
dMBMn(itp)      = (MBMn(itp) - MBMn0 )/MBMn0;
dMBHfr(itp)     = (MBHfr(itp)- MBHfr0)/MBHfr0;
%--------------------------------------------------------------------------
if doPlot
    yMaxCA   = max([yMaxCA,   max(CA(:))  *1.2, max(CB(:))  *1.2]);
    yMaxCAMn = max([yMaxCAMn, max(CAMn(:))*1.2, max(CBMn(:))*1.2]);
    yMaxCALu = max([yMaxCALu, max(CALu(:))*1.2, max(CBLu(:))*1.2]);
    yMaxCAHf = max([yMaxCAHf, max(CAHf(:))*1.2, max(CBHf(:))*1.2]);
    figure(1), set(gcf,'Color',[1 1 1],'Position',[50 50 1400 1800])
    if plot_kind ==1
        plot_them_1;
    elseif plot_kind ==2
        plot_them_2;
    elseif plot_kind ==3
        plot_them_3;
    end
    if saveCheckpoints
        export_pub_fig(gcf,fullfile(outDir,[data_name,'_last']))
    end
end
if save_data == 1
    save(fullfile(outDir,data_name));
end
%--------------------------------------------------------------------------
% Package results for the caller (single run and/or statistics) -----------
R = struct();
R.params        = params;
R.software      = 'MIDAS - Stroh, A. & Moulas, E. (2026)';  % small provenance tag, carried into every .mat/.xlsx export
R.solver        = mfilename;
R.run_timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
R.stoppedEarly = stoppedEarly;                              % true if the trace-element BC solve failed before t_tot (see "Trace Elements" in the run loop above)
R.stopReason   = stopReason;                                % the causing error message if stoppedEarly, else ''
R.S_initial   = S0;  R.t_initial = 0;
R.T_initial   = Tstart; R.P_initial = Pstart;
R.CA_initial  = CA0;  R.CB_initial  = CB0;
R.xA_initial  = xA0;  R.xB_initial  = xB0;
R.CALu_initial  = CALu0;  R.CBLu_initial  = CBLu0;
R.CAHf_initial  = CAHf0;  R.CBHf_initial  = CBHf0;
R.CAHfr_initial = CAHfr0; R.CBHfr_initial = CBHfr0;
R.CAMn_initial  = CAMn0;  R.CBMn_initial  = CBMn0;
R.S_final     = S;   R.v_final = v;   R.t_final = t;
R.T_final     = T;   R.P_final = P;
R.CA_final    = CA;  R.CB_final = CB;
R.xA_final    = xA;  R.xB_final = xB;
R.CALu_final  = CALu;  R.CBLu_final  = CBLu;
R.CAHf_final  = CAHf;  R.CBHf_final  = CBHf;
R.CAHfr_final = CAHfr; R.CBHfr_final = CBHfr;
R.CAMn_final  = CAMn;  R.CBMn_final  = CBMn;
R.tALuHf1_final = tALuHf1; R.tBLuHf1_final = tBLuHf1;
R.tALuHf1_max   = max(tALuHf1); R.tBLuHf1_max   = max(tBLuHf1); % Max age in final profile (across space)
R.t_rimA_final  = t_rimA;  R.t_coreA_final = t_coreA; R.t_bulkA_final = t_bulkA; R.t_maxA_final = t_maxA;
R.misfitApparent_final = max(abs(tALuHf1 - t));
R.misfitIsochron_final = max(abs([t_rimA,t_coreA,t_bulkA,t_maxA] - t));
R.MB0 = MB0; R.MBLu0 = MBLu0; R.MBHf0 = MBHf0; R.MBHfr0 = MBHfr0; R.MBMn0 = MBMn0;
R.dMB_final = (MB(itp)-MB0)/MB0; R.dMBMn_final = (MBMn(itp)-MBMn0)/MBMn0; R.dMBHfr_final = (MBHfr(itp)-MBHfr0)/MBHfr0;
if store_history == 1
    R.Srec      = Srec;      R.Vrec      = Vrec;      R.dtrec     = dtrec;
    R.dxArec    = dxArec;    R.dxBrec    = dxBrec;
    R.CAh       = CAh;       R.CBh       = CBh;       R.trec      = trec;
    R.Trec      = Trec;      R.Prec      = Prec;
    R.CArec     = CArec;     R.CBrec     = CBrec;
    R.CALurec   = CALurec;   R.CBLurec   = CBLurec;
    R.CAHfrec   = CAHfrec;   R.CBHfrec   = CBHfrec;
    R.CAHfrrec  = CAHfrrec;  R.CBHfrrec  = CBHfrrec;
    R.CAMnrec   = CAMnrec;   R.CBMnrec   = CBMnrec;
    R.xArec     = xArec;     R.xBrec     = xBrec;
    R.tA1       = tA1;       R.tB1       = tB1;
    R.tALuHf1_maxAll = max(tA1(:)); R.tBLuHf1_maxAll = max(tB1(:));                             % Peak age over full history (space & time)
    R.tRimAh    = tRimAh;    R.tCoreAh   = tCoreAh;   R.tBulkAh   = tBulkAh;   R.tMaxAh = tMaxAh;
    R.misfitApparentH = misfitApparentH; R.misfitIsochronH = misfitIsochronH;
    R.misfitApparent_max = max(misfitApparentH); R.misfitIsochron_max = max(misfitIsochronH);   % Peak misfit over the run
    R.MB        = MB;        R.MBLu      = MBLu;
    R.MBHf      = MBHf;      R.MBHfr     = MBHfr;     R.MBMn      = MBMn;
    R.dMB       = dMB;       R.dMBMn     = dMBMn;     R.dMBHfr    = dMBHfr;
    R.dMB_max   = max(abs(dMB)); R.dMBMn_max = max(abs(dMBMn)); R.dMBHfr_max = max(abs(dMBHfr)); % Peak mass-balance drift over the run
end
end
% ============================== FUNCTIONS ================================
function v = pathThreePoint(t0,tpeak,t1,v0,vpeak,v1,tt)
    % Shape-preserving path through (t0,v0)-(tpeak,vpeak)-(t1,v1). If the
    % peak time coincides with (or falls outside) an endpoint, that
    % endpoint's value is replaced by the peak value and the duplicate
    % node is dropped, instead of handing pchip a repeated x (which errors).
    if tpeak <= t0
        xs = [t0,t1]; ys = [vpeak,v1];
    elseif tpeak >= t1
        xs = [t0,t1]; ys = [v0,vpeak];
    else
        xs = [t0,tpeak,t1]; ys = [v0,vpeak,v1];
    end
    v = pchip(xs,ys,tt);
end
function [T2,P2,CA2,CB2] = load_TData(Trange,Prange,eqFun)
    % Creates the P-T values and corresponding equilibrium compositions as
    % grid
    nT             = 100;                       % Resolution of the T grid
    nP             = 100;                       % Resolution of the P grid
    [T2,P2]        = ndgrid(linspace(Trange(1),Trange(2),nT),linspace(Prange(1),Prange(2),nP));
    [CA_eq, CB_eq] = eqFun(T2(:),P2(:));
    CA2            = reshape(CA_eq,nT,nP);
    CB2            = reshape(CB_eq,nT,nP);
end
function [x] = find_poly(Car,Tar,Par)
    % P-T diagram with compositions as contours
    % Find the coefficient of the polynomial that produces
    % CA1 at the 1st point
    % CA2 at the 2nd point
    % CA3 at the 3rd point
    % using Linear Least Squares; A: parameter matrix, y: compositions, x: polynomial coefficients
    A   = [1, Tar(1), Par(1);
           1, Tar(2), Par(2);
           1, Tar(3), Par(3)];
    y   = Car(:);
    x = A\y;
end
function [CA_eq, CB_eq]=TL(T,P,CAc,CBc)
    % Calculates the equilibrium composition at given P & T
    CA_eq = CAc(1) + CAc(2).*T + CAc(3).*P;             % in A
    CB_eq = CBc(1) + CBc(2).*T + CBc(3).*P;             % in B
    if any(CA_eq<0) || any(CB_eq<0)
       [row,col] = find(CA_eq<0);
       CA_eq(row,col) = NaN;
       [row,col] = find(CB_eq<0);
       CB_eq(row,col) = NaN;
    end
end
function [DMgFe] = calc_diff_binary(CA,T,P,Rgac,Myr)
    % Effective Mg-Fe coefficients for binary - Chakraborty and Ganguly, 1991, p.137
    % Pressure is converted to bar (as in their paper)
    % Final values converted to mm^2/Myr (from cm^2/s)
    CAc     = 0.5*(CA(2:end)+CA(1:end-1))./100;         % From percent to ratio [0,1]
    D0mg    = 1.11*1e-3;                                % Pre-exponent of D for Mg (cm^2/s)
    Q0mg    = 67997 + 0.1276.*P.*1e4;                   % Activation energy of Mg  (cal/mol)
    D0fe    = 6.36*1e-4;                                % Pre-exponent of D for Fe (cm^2/s)
    Q0fe    = 65824 + 0.1363.*P.*1e4;                   % Activation energy of Fe  (cal/mol)
    DMg     = D0mg.*(10^2).*Myr.*exp(-Q0mg./Rgac./T);   % Convert coefficient to mm^2/Myr
    DFe     = D0fe.*(10^2).*Myr.*exp(-Q0fe./Rgac./T);   % Convert coefficient to mm^2/Myr
    DMgFe   = (DMg.*DFe)./(CAc.*DMg + (1-CAc).*DFe);    % Calculated after Manning (1968) in Ganguly et al (2001), p. 310
end
function [DLu,DHf] = calc_diffLuHf(T,P,RgaJ,Myr)
    % Diffusion for Lu and Hf after Bloch et al. (2015), p.7
    D0Lu    = 1.15*1e-5;                                % In cm^2/s
    D0Hf    = 2.37*1e-5;                                % In cm^2/s
    DLu     = D0Lu.*(10^2).*Myr.*exp(-(272.8*1e3 +(P*1e9-1e5)*10.8*1e-6)./RgaJ./T); % Converted to mm^2/Myr
    DHf     = D0Hf.*(10^2).*Myr.*exp(-(291.6*1e3 +(P*1e9-1e5)*12.5*1e-6)./RgaJ./T); % Converted to mm^2/Myr
end
function [DMn] = calc_diffMn(T,P,Rgac,Myr)
    % Chakraborty and Ganguly, 1991, p.137
    D0Mn    = 5.15*1e-4;                                % Pre-exponent of D for Mn in cm^2/s
    Q0Mn    = 60569 + 0.1463.*P.*1e4;                   % Activation energy of Mn  (cal/mol)
    DMn     = D0Mn.*(10^2).*Myr.*exp(-Q0Mn./Rgac./T);   % Convert coefficient to mm^2/Myr
end
function [CAn0, CB1] =  solveBC(CAn0_old,CB1_old,CAn1,CB2,dxA,dxB,DA,DB,KD,v,dt,lamA,lamB)
    % Solve for the BC given known velocity
    % CAn0 (right edge of left mineral)
    % CB1  (left edge of right mineral (matrix))
    % Eq1: KD = CA_end/CB_1  Eq2: (CB_1 - CA_end)*v = JB-JA
    CB1_eq  = (CAn1*DA*dxB + CB2*DB*dxA)/(KD*v*dxA*dxB + DA*KD*dxB -v*dxA*dxB + DB*dxA);
    CAn0_eq = KD*CB1_eq;
    % Exponential decay N(t) = N0*exp(-lam*t) = d(N0-N_eq)*exp(-lam*t)
    CB1     = CB1_eq  + exp(-lamB*dt)*(CB1_old  - CB1_eq);
    CAn0    = CAn0_eq + exp(-lamA*dt)*(CAn0_old - CAn0_eq);
    if CB1<0
        error('CB_BC (trace element) < 0');
    end
    if CAn0<0
        error('CA_BC (trace element) < 0');
    end
end
function plotChist(xArec,CArec,trec,time_it,cols,FSS)
    % Plots composition history of mineral A
    if time_it>trec
        error("Time chosen for plot is out of bounds")
    end
    [tdiff, it] = min(abs(time_it-trec));
    plot(xArec(it,:),CArec(it,:),cols,'DisplayName',[num2str(time_it),' Myr'])
    grid on,axis square
    xlabel(['$x$',' (mm)'],'interpreter','latex','FontSize',FSS)
    ylabel(['MgO',' (wt.\%)'],'interpreter','latex','FontSize',FSS)
    lgd = legend;
    lgd.Location = 'best';
    drawnow
end
function [a,b,c] = CreateTriDiag(D,dt,dx,nx,xL,xC,xR)
    % Build the tridiagonal system (sub-/main-/super-diagonal, each length nx)
    % for Backward Euler on  x^m*dC/dt = d/dx( x^m*D*dC/dx ),  m = ndim-1.
    % Equation pre-multiplied by x^m; the RHS is scaled by x^m (=xC) by the
    % caller, so no division by xC here. Metric: xL=xc_{i-1/2}^m, xC=x_i^m, xR=xc_{i+1/2}^m.
    % Row i (interior) reads: a(i)*C(i-1) + b(i)*C(i) + c(i)*C(i+1) = rhs(i).
    % Equivalent to the tridiagonal system previously assembled with spdiags,
    % but solved directly (Thomas algorithm) below instead of via sparse \,
    % which is much faster for the small (~100-unknown) systems solved here.
    if length(D)==1
        SL = D*dt/dx^2;
        SR = SL;
    else
        S  = D*dt/dx^2;
        SL = S(1:end-1);
        SR = S(2:end);
    end
    a = zeros(nx,1);
    b = zeros(nx,1);
    c = zeros(nx,1);
    a(2:nx-1) = -(SL(:).*xL(:));
    b(2:nx-1) =  xC(:) + SL(:).*xL(:) + SR(:).*xR(:);
    c(2:nx-1) = -(SR(:).*xR(:));
end
function [x] = thomasSolve(a,b,c,d)
    % Direct tridiagonal solve (Thomas algorithm). a,b,c are the sub-, main-
    % and super-diagonals (length n; a(1) and c(n) are unused). d is the
    % right-hand side, n-by-k (k>1 solves several systems sharing a,b,c at once).
    n  = length(b);
    cp = zeros(n,1);
    dp = d;
    cp(1)   = c(1)/b(1);
    dp(1,:) = d(1,:)/b(1);
    for i = 2:n
        m = b(i) - a(i)*cp(i-1);
        if i < n
            cp(i) = c(i)/m;
        end
        dp(i,:) = (d(i,:) - a(i)*dp(i-1,:))/m;
    end
    x = zeros(n,size(d,2));
    x(n,:) = dp(n,:);
    for i = n-1:-1:1
        x(i,:) = dp(i,:) - cp(i)*x(i+1,:);
    end
end
function [CA, CB] = implicitDiffusionSolver(CA,DA,dt,dx_A,nx_A,CB,DB,dx_B,nx_B,NBC,xAC,xAL,xAR,xBC,xBL,xBR,ndim)
    CA_o = CA(:);
    CB_o = CB(:);
    CA_o = [CA_o(1);xAC(:).*CA_o(2:end-1);CA_o(end)];
    CB_o = [CB_o(1);xBC(:).*CB_o(2:end-1);CB_o(end)];
    [aA,bA,cA] = CreateTriDiag(DA,dt,dx_A,nx_A,xAL,xAC,xAR);
    [aB,bB,cB] = CreateTriDiag(DB,dt,dx_B,nx_B,xBL,xBC,xBR);
    % Dirichlet BC everywhere (inner BC always)
    aA(1)   = 0; bA(1)   = 1; cA(1)   = 0;
    aA(end) = 0; bA(end) = 1; cA(end) = 0;
    aB(1)   = 0; bB(1)   = 1; cB(1)   = 0;
    aB(end) = 0; bB(end) = 1; cB(end) = 0;
    % Left boundary (x=0): the center of the domain when ndim~=1
    % (cylindrical/spherical), where a Neumann (no-flux) condition is
    % physically required by symmetry regardless of NBC - not a free
    % choice there. Only genuinely optional when ndim==1 (planar), where
    % it follows NBC like the right boundary does.
    if ndim ~= 1 || NBC == 1
        cA(1)   = -1;
        CA_o(1) = 0;
    end
    % Right boundary (outer edge of phase B): always the user's free
    % choice via NBC, independent of geometry.
    if NBC == 1
        aB(end)   = -1;
        CB_o(end) = 0;
    end
    % Solve SoE
    CA = thomasSolve(aA,bA,cA,CA_o)';
    CB = thomasSolve(aB,bB,cB,CB_o)';
end
function [Mtot, M_A,M_B]=calc_mass_vol(x_A,x_B,C_A,C_B,ndim)
    % Calculate the volume-weighted average composition-----------------
    % Assume a density of 1
    V_A_ini = x_A.^ndim;
    V_B_ini = x_B.^ndim;
    dV_A = max(V_A_ini)-min(V_A_ini);                   % Volume of phase A
    dV_B = max(V_B_ini)-min(V_B_ini);                   % Volume of phase B
    M_A  = trapz(V_A_ini,C_A)/dV_A;                     %Calculate mass left phase
    M_B  = trapz(V_B_ini,C_B)/dV_B;                     %Calculate mass right phase
    Mtot = (M_A*dV_A + M_B*dV_B)/(dV_A+dV_B);           %Volume-weighted average over the whole system
end
function [X,Y,yfit,Rsq,t_int]=isochrons(CA,CB,CBr,lam)
    % Simple OLS isochron regression over whatever points are passed in
    % (self-contained: no external reference point). Used for phase B.
    X      =  CA./CBr;
    Y      =  CB./CBr;
    [Pfit] = polyfit(X,Y,1);                            % Perform regression
    yfit   = polyval(Pfit, X);                          % Estimated  Regression Line
    SStot  = sum((Y-mean(Y)).^2);                       % Total Sum-Of-Squares
    SSres  = sum((Y-yfit).^2);                          % Residual Sum-Of-Squares
    Rsq    = 1-SSres/SStot;                             % R coefficient
    t_int  = log((Pfit(1)+1))/lam;                      % Time from regression
end
function [t_rim,t_core,t_bulk,Xdat,Ydat,Xfit,YfitRim,YfitCore,YfitBulk,t_prof,Xprof,Yprof,YfitProf,t_max,Xmax,Ymax,YfitMax] = ...
    isochronsRef(CPA,CDA,CDrA,xA,ndim,Pref,Dref,Drref,lam,nskip)
    % Two-point isochrons for phase A (crystal): rim, core, and bulk, each
    % regressed against a single external reference point (Pref,Dref,Drref)
    % supplied by the caller - the matrix's bulk or core composition.
    % Profile convention: CPA(1)/CDA(1)/CDrA(1) = core (x=0, center, oldest);
    % CPA(end)/CDA(end)/CDrA(end) = rim (x=lxA, interface, youngest).
    Xref  = Pref/Drref;              Yref  = Dref/Drref;
    Xcore = CPA(1)/CDrA(1);          Ycore = CDA(1)/CDrA(1);
    Xrim  = CPA(end)/CDrA(end);      Yrim  = CDA(end)/CDrA(end);
    % Bulk (volume-weighted average across the crystal profile)
    VA     = xA.^ndim;
    dVA    = max(VA)-min(VA);
    Pbulk  = trapz(VA,CPA)/dVA;
    Dbulk  = trapz(VA,CDA)/dVA;
    Drbulk = trapz(VA,CDrA)/dVA;
    Xbulk  = Pbulk/Drbulk;           Ybulk = Dbulk/Drbulk;
    % Two-point regressions (reference point vs. each mineral point)
    PfitRim  = polyfit([Xref,Xrim], [Yref,Yrim], 1);
    PfitCore = polyfit([Xref,Xcore],[Yref,Ycore],1);
    PfitBulk = polyfit([Xref,Xbulk],[Yref,Ybulk],1);
    % Ages from the slope: slope = exp(lam*t)-1
    t_rim  = log(PfitRim(1) +1)/lam;
    t_core = log(PfitCore(1)+1)/lam;
    t_bulk = log(PfitBulk(1)+1)/lam;
    % Data points and fit lines, for plotting
    Xdat = [Xref, Xcore, Xrim, Xbulk];
    Ydat = [Yref, Ycore, Yrim, Ybulk];
    Xfit = linspace(0, max(Xdat)*1.1, 10);
    YfitRim  = polyval(PfitRim,  Xfit);
    YfitCore = polyval(PfitCore, Xfit);
    YfitBulk = polyval(PfitBulk, Xfit);
    % Every nskip-th node across the profile: one two-point isochron age each
    % (in addition to the single rim/core/bulk points above), same reference.
    idx    = 1:nskip:numel(CPA);
    Xprof  = CPA(idx)./CDrA(idx);
    Yprof  = CDA(idx)./CDrA(idx);
    nProf  = numel(idx);
    t_prof   = zeros(1,nProf);
    YfitProf = zeros(numel(Xfit),nProf);
    for i = 1:nProf
        PfitI       = polyfit([Xref,Xprof(i)],[Yref,Yprof(i)],1);
        t_prof(i)   = log(PfitI(1)+1)/lam;
        YfitProf(:,i) = polyval(PfitI, Xfit);
    end
    % Maximum age among rim/core/bulk/profile points
    [t_max,iMax] = max([t_rim,t_core,t_bulk,t_prof]);
    YfitAll = [YfitRim(:),YfitCore(:),YfitBulk(:),YfitProf];
    XdatAll = [Xdat(3),Xdat(2),Xdat(4),Xprof];    % rim, core, bulk, profile (Xdat = [ref,core,rim,bulk])
    YdatAll = [Ydat(3),Ydat(2),Ydat(4),Yprof];
    Xmax    = XdatAll(iMax);
    Ymax    = YdatAll(iMax);
    YfitMax = YfitAll(:,iMax)';
end
function [C_eq]=interpolateC(PGPa,TK,C,P_int,T_int)
    C_eq = interp2(PGPa,TK,C,P_int,T_int);
    if isnan(C_eq) || isinf(C_eq)
        fprintf('P = %g GPa, T = %g K\n',P_int,T_int)
        error('P-T point is outside the calculated phase diagram range or the mineral is unstable. Please select a different P-T path.')
    end
end
function [PGPa,TK,MgOA,MgOB,MnOA,MnOB]=create_grid(PhaseDiagram)
    nx2    = length(PhaseDiagram(:,1));
    nx     = sqrt(nx2);

    TK     = reshape(PhaseDiagram(:,1),nx,nx);
    PGPa   = reshape(PhaseDiagram(:,2),nx,nx)/1e4; %convert from bar to GPa
    MgOA   = reshape(PhaseDiagram(:,7),nx,nx);
    MgOB   = reshape(PhaseDiagram(:,8),nx,nx);
    MnOA   = reshape(PhaseDiagram(:,9),nx,nx);
    MnOB   = reshape(PhaseDiagram(:,10),nx,nx);
end

function validateCoreParams(p)
% VALIDATECOREPARAMS  Fails fast, with one specific message per problem
% field (naming the field, its actual value, and why it matters), on
% parameter values that would otherwise either hang MIDAS_Main forever or
% crash deep inside a numerical routine with a MATLAB error meaningless to
% someone who isn't a programmer. Checks are written as "~(x > 0)" rather
% than "x <= 0": a NaN (e.g. from a GUI numeric field that got non-numeric
% text) silently passes any <=/</>= comparison, so a plain "x <= 0" check
% would miss it.
issues = {};

if ~(p.CFL > 0)
    issues{end+1} = sprintf(['params.CFL must be > 0 (got %s). Every timescale that the adaptive time step is built from is ', ...
        'scaled directly by CFL, so CFL <= 0 makes dt = 0: the model time never advances and the run hangs forever with no ', ...
        'error and no output, rather than failing - see docs/mesh-refinement.md.'], num2str(p.CFL));
end
if ~(p.t_tot > 0)
    issues{end+1} = sprintf('params.t_tot must be > 0 Myr (got %s) - it is the total simulated duration.', num2str(p.t_tot));
end
if ~(p.lxA > 0)
    issues{end+1} = sprintf('params.lxA must be > 0 mm (got %s) - it is the initial length of phase A (the crystal).', num2str(p.lxA));
end
if ~(p.lxB_factor > 0)
    issues{end+1} = sprintf('params.lxB_factor must be > 0 (got %s) - phase B''s length is lxB_factor*lxA.', num2str(p.lxB_factor));
end
if ~(p.nx_A >= 2) || p.nx_A ~= fix(p.nx_A)
    issues{end+1} = sprintf('params.nx_A must be a whole number >= 2 (got %s) - it is the number of grid nodes in phase A.', num2str(p.nx_A));
end
if ~(p.nx_B >= 2) || p.nx_B ~= fix(p.nx_B)
    issues{end+1} = sprintf('params.nx_B must be a whole number >= 2 (got %s) - it is the number of grid nodes in phase B.', num2str(p.nx_B));
end
posFields = {'DRG','DRG_LuHf','DRG_Mn','DamA','DamB'};
posWhat   = {'the diffusivity ratio (major elements, B relative to A)', ...
             'the diffusivity ratio (Lu/Hf, matrix relative to A)', ...
             'the diffusivity ratio (Mn, matrix relative to A)', ...
             'the Damköhler_II number for phase A (interface kinetics)', ...
             'the Damköhler_II number for phase B (interface kinetics)'};
for i = 1:numel(posFields)
    v = p.(posFields{i});
    if ~(v > 0)
        issues{end+1} = sprintf('params.%s must be > 0 (got %s) - it is %s.', posFields{i}, num2str(v), posWhat{i});
    end
end

if ~isempty(issues)
    msg = sprintf('%s\n', issues{:});
    error('MIDAS:InvalidParams', 'MIDAS_Main stopped before running because of %d invalid parameter(s):\n%s', numel(issues), msg);
end
end