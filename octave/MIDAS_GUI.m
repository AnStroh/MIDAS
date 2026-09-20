function MIDAS_GUI
% MIDAS_GUI  Interactive front-end for the single-run crystal-growth model
% (MIDAS_Main.m), for GNU Octave - a from-scratch rebuild of ../GUI/MIDAS.m
% (MATLAB App Designer; App Designer files can't be opened by Octave at
% all) using Octave's plain figure/uicontrol primitives instead. Every
% field of MIDAS_Params.m is exposed as a labeled, tooltip-annotated
% control (grouped into sidebar sections matching that file's own comment
% sections, pre-filled with its defaults). Run shows the same post-run
% figures Run_MIDAS.m does (each its own window); the results and figures
% can then be exported: data as .mat/.xlsx, figures as vector PDF + 300 dpi
% JPG.
%
% Octave has no uigridlayout/uitabgroup/App Designer component model, so
% layout here is manual normalized-position placement, and "tabs" are
% sidebar nav buttons toggling uipanel Visible - which is what the MATLAB
% version's own tabs already reduce to under the hood (see NavButtonPushed
% in GUI/MIDAS.m), so this matches its actual behavior, not just its look.
% Verified against Octave 11.3.0 (fltk toolkit) - see octave/README.md for
% toolkit limitations that affect exported/live plots (not this GUI itself).
%
% Usage:
%   MIDAS_GUI
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================

% ------------------------------------------------------------------------
% Brand palette (same values as GUI/MIDAS.m)
% ------------------------------------------------------------------------
ColIndigo   = [0.180 0.102 0.278];   % #2E1A47 - sidebar / primary text
ColGold     = [0.851 0.643 0.255];   % #D9A441 - primary action / active nav
ColTeal     = [0.243 0.561 0.486];   % #3E8F7C - secondary accent
ColBg       = [0.965 0.957 0.945];   % #F6F4F1 - content background
ColWhite    = [1 1 1];
ColLavender = [0.898 0.875 0.949];   % #E5DFF2 - inactive sidebar text

thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir,'examples'), fullfile(thisDir,'plotting'), fullfile(thisDir,'export'));
FieldMeta = buildFieldMeta();
DefaultParams = MIDAS_Params();
DefaultParams.outDir = fullfile('results', [DefaultParams.data_name, '_', datestr(now,'yyyymmdd_HHMMSS')]);

% ------------------------------------------------------------------------
% Main window
% ------------------------------------------------------------------------
fig = figure('Name','MIDAS - Mineral Interface Dynamics and apparent-Age Simulation (Octave)', 'NumberTitle','off', ...
    'Color', ColBg, 'Units','pixels', 'Position',[60 40 1250 900], 'MenuBar','none', 'Toolbar','none');

% --- Header: logo + subtitle -------------------------------------------
header = uipanel(fig, 'Units','normalized', 'Position',[0 0.90 1 0.10], ...
    'BackgroundColor', ColWhite, 'BorderType','line');
assetsDir = fullfile(fileparts(mfilename('fullpath')), '..', 'GUI', 'assets');
logoPath = fullfile(assetsDir, 'midas_logo_horizontal.png');
if isfile(logoPath)
    try
        [img,~,alpha] = imread(logoPath);
        ax = axes(header, 'Units','normalized', 'Position',[0.02 0.1 0.4 0.8]);
        if ~isempty(alpha)
            imshow(img); % alpha not composited under fltk axes(); shown as-is
        else
            imshow(img);
        end
        axis(ax,'off');
    catch
        uicontrol(header, 'Style','text', 'String','MIDAS', 'Units','normalized', ...
            'Position',[0.02 0.2 0.3 0.6], 'FontSize',18, 'FontWeight','bold', ...
            'ForegroundColor', ColIndigo, 'BackgroundColor', ColWhite, 'HorizontalAlignment','left');
    end
else
    uicontrol(header, 'Style','text', 'String','MIDAS', 'Units','normalized', ...
        'Position',[0.02 0.2 0.3 0.6], 'FontSize',18, 'FontWeight','bold', ...
        'ForegroundColor', ColIndigo, 'BackgroundColor', ColWhite, 'HorizontalAlignment','left');
end
uicontrol(header, 'Style','text', 'String','Single-run crystal-growth model (Octave)', ...
    'Units','normalized', 'Position',[0.45 0.3 0.53 0.4], 'FontSize',11, ...
    'ForegroundColor', ColIndigo, 'BackgroundColor', ColWhite, 'HorizontalAlignment','right');

% --- Sidebar nav ----------------------------------------------------------
tabKeys   = {'Physics','Time_PT','Thermo','Numerics','Programming','Output'};
tabTitles = {'Physics','Time & P-T Path','Thermodynamics','Grid & Numerics','Numerics Flags','Output & Plotting'};

sidebarW = 0.16; contentW = 0.60; rightW = 1 - sidebarW - contentW;
bodyTop = 0.90; bodyBot = 0.02;

sidebar = uipanel(fig, 'Units','normalized', 'Position',[0 bodyBot sidebarW (bodyTop-bodyBot)], ...
    'BackgroundColor', ColIndigo, 'BorderType','none');

nTabs = numel(tabKeys);
navButtons = zeros(1,nTabs);   % Octave has no gobjects(); graphics handles are plain doubles
navH = 0.9/(nTabs+0.2);
for it = 1:nTabs
    yTop = 1 - 0.02 - it*navH;
    navButtons(it) = uicontrol(sidebar, 'Style','pushbutton', 'String', tabTitles{it}, ...
        'Units','normalized', 'Position',[0.05 yTop 0.9 navH*0.85], ...
        'BackgroundColor', ColIndigo, 'ForegroundColor', ColLavender, ...
        'HorizontalAlignment','left', 'Callback', @(src,evt) navButtonPushed(tabKeys{it}));
end

% --- Content area: one panel per section, one shown at a time -----------
content = uipanel(fig, 'Units','normalized', 'Position',[sidebarW bodyBot contentW (bodyTop-bodyBot)], ...
    'BackgroundColor', ColBg, 'BorderType','none');

Ctrl = struct();
SectionPanels = struct();
for it = 1:nTabs
    panel = uipanel(content, 'Title', tabTitles{it}, 'Units','normalized', 'Position',[0.01 0.01 0.98 0.98], ...
        'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo, 'FontWeight','bold', 'Visible','off');
    SectionPanels.(tabKeys{it}) = panel;

    fieldsHere = FieldMeta(strcmp({FieldMeta.tab}, tabKeys{it}));
    nRows = numel(fieldsHere);
    rowH = 1/(nRows+0.5);
    for k = 1:nRows
        f = fieldsHere(k);
        yTop = 1 - 0.02 - k*rowH;
        lbl = uicontrol(panel, 'Style','text', 'String', [f.name '  (i)'], ...
            'Units','normalized', 'Position',[0.02 yTop 0.40 rowH*0.85], ...
            'ForegroundColor', ColIndigo, 'BackgroundColor', ColWhite, ...
            'HorizontalAlignment','left', 'TooltipString', f.tooltip);
        c = addFieldRow(panel, [0.44 yTop 0.54 rowH*0.85], f);
        Ctrl.(f.name) = c;
    end
end
navButtonPushed(tabKeys{1});

% --- Right: run/status/export panel --------------------------------------
rightX = sidebarW + contentW;
rightPanel = uipanel(fig, 'Units','normalized', 'Position',[rightX bodyBot rightW (bodyTop-bodyBot)], ...
    'BackgroundColor', ColBg, 'BorderType','none');

RunButton = uicontrol(rightPanel, 'Style','pushbutton', 'String','> Run', 'FontWeight','bold', ...
    'Units','normalized', 'Position',[0.03 0.955 0.30 0.035], ...
    'BackgroundColor', ColGold, 'ForegroundColor', ColIndigo, 'Callback', @(s,e) runButtonPushed());
ResetButton = uicontrol(rightPanel, 'Style','pushbutton', 'String','Reset', ...
    'Units','normalized', 'Position',[0.345 0.955 0.30 0.035], ...
    'BackgroundColor', ColIndigo, 'ForegroundColor', ColWhite, 'Callback', @(s,e) resetButtonPushed());
CloseFiguresButton = uicontrol(rightPanel, 'Style','pushbutton', 'String','Close Figs', ...
    'Units','normalized', 'Position',[0.66 0.955 0.31 0.035], ...
    'BackgroundColor', ColIndigo, 'ForegroundColor', ColWhite, 'Callback', @(s,e) closeAllFiguresButtonPushed(), ...
    'TooltipString', 'Close every figure window this app has opened (does not affect this control window).');

ExampleDropDown = uicontrol(rightPanel, 'Style','popupmenu', 'Units','normalized', ...
    'Position',[0.03 0.905 0.65 0.035], 'String', {'MIDAS_Params (default)', 'Example1_Baseline', ...
    'Example2_PolyEquilibrium', 'Example3_ThermalBump', 'Example4_ManualPartitioning', ...
    'Example5_PlanarGeometry', 'Example6_CylindricalGeometry'}, ...
    'TooltipString','Pick a starting configuration, then Load - every field stays freely editable afterwards.');
LoadExampleButton = uicontrol(rightPanel, 'Style','pushbutton', 'String','Load', ...
    'Units','normalized', 'Position',[0.70 0.905 0.27 0.035], ...
    'BackgroundColor', ColTeal, 'ForegroundColor', ColWhite, 'Callback', @(s,e) loadExampleButtonPushed());

SavePresetButton = uicontrol(rightPanel, 'Style','pushbutton', 'String','Save Preset', ...
    'Units','normalized', 'Position',[0.03 0.860 0.45 0.035], ...
    'BackgroundColor', ColTeal, 'ForegroundColor', ColWhite, 'Callback', @(s,e) savePresetButtonPushed());
LoadPresetButton = uicontrol(rightPanel, 'Style','pushbutton', 'String','Load Preset', ...
    'Units','normalized', 'Position',[0.52 0.860 0.45 0.035], ...
    'BackgroundColor', ColTeal, 'ForegroundColor', ColWhite, 'Callback', @(s,e) loadPresetButtonPushed());

uicontrol(rightPanel, 'Style','text', 'String','Status:', 'FontWeight','bold', ...
    'Units','normalized', 'Position',[0.03 0.815 0.5 0.030], 'BackgroundColor', ColBg, ...
    'ForegroundColor', ColIndigo, 'HorizontalAlignment','left');
StatusArea = uicontrol(rightPanel, 'Style','listbox', 'Units','normalized', ...
    'Position',[0.03 0.640 0.94 0.175], 'String',{'Ready.'}, 'Max',2, 'Min',0);

% --- Export Data panel ----------------------------------------------------
dataPanel = uipanel(rightPanel, 'Title','Export Data', 'FontWeight','bold', ...
    'Units','normalized', 'Position',[0.03 0.470 0.94 0.160], ...
    'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo);
uicontrol(dataPanel, 'Style','text', 'String','Folder:', 'Units','normalized', ...
    'Position',[0.03 0.72 0.20 0.20], 'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo, 'HorizontalAlignment','left');
DataFolderField = uicontrol(dataPanel, 'Style','edit', 'Units','normalized', ...
    'Position',[0.25 0.72 0.50 0.22], 'BackgroundColor',[1 1 1], 'HorizontalAlignment','left');
BrowseDataButton = uicontrol(dataPanel, 'Style','pushbutton', 'String','Browse...', ...
    'Units','normalized', 'Position',[0.77 0.72 0.20 0.22], ...
    'BackgroundColor', ColIndigo, 'ForegroundColor', ColWhite, 'Callback', @(s,e) browseDataButtonPushed());
uicontrol(dataPanel, 'Style','text', 'String','Name:', 'Units','normalized', ...
    'Position',[0.03 0.45 0.20 0.20], 'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo, 'HorizontalAlignment','left');
DataBaseField = uicontrol(dataPanel, 'Style','edit', 'Units','normalized', ...
    'Position',[0.25 0.45 0.72 0.22], 'BackgroundColor',[1 1 1], 'HorizontalAlignment','left');
MatCheckBox = uicontrol(dataPanel, 'Style','checkbox', 'String','.mat', 'Value',1, ...
    'Units','normalized', 'Position',[0.25 0.22 0.30 0.20], 'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo);
XlsxCheckBox = uicontrol(dataPanel, 'Style','checkbox', 'String','.xlsx', 'Value',1, ...
    'Units','normalized', 'Position',[0.60 0.22 0.35 0.20], 'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo);
ExportDataButton = uicontrol(dataPanel, 'Style','pushbutton', 'String','Export Data', ...
    'Units','normalized', 'Position',[0.03 0.02 0.94 0.18], ...
    'BackgroundColor', ColIndigo, 'ForegroundColor', ColWhite, 'Callback', @(s,e) exportDataButtonPushed());

% --- Export Figures panel --------------------------------------------------
figPanel = uipanel(rightPanel, 'Title','Export Figures (PDF + 300 dpi JPG)', 'FontWeight','bold', ...
    'Units','normalized', 'Position',[0.03 0.310 0.94 0.150], ...
    'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo);
uicontrol(figPanel, 'Style','text', 'String','Folder:', 'Units','normalized', ...
    'Position',[0.03 0.65 0.20 0.22], 'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo, 'HorizontalAlignment','left');
FigFolderField = uicontrol(figPanel, 'Style','edit', 'Units','normalized', ...
    'Position',[0.25 0.65 0.50 0.24], 'BackgroundColor',[1 1 1], 'HorizontalAlignment','left');
BrowseFigButton = uicontrol(figPanel, 'Style','pushbutton', 'String','Browse...', ...
    'Units','normalized', 'Position',[0.77 0.65 0.20 0.24], ...
    'BackgroundColor', ColIndigo, 'ForegroundColor', ColWhite, 'Callback', @(s,e) browseFigButtonPushed());
uicontrol(figPanel, 'Style','text', 'String','Name:', 'Units','normalized', ...
    'Position',[0.03 0.35 0.20 0.22], 'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo, 'HorizontalAlignment','left');
FigBaseField = uicontrol(figPanel, 'Style','edit', 'Units','normalized', ...
    'Position',[0.25 0.35 0.72 0.24], 'BackgroundColor',[1 1 1], 'HorizontalAlignment','left');
ExportFiguresButton = uicontrol(figPanel, 'Style','pushbutton', 'String','Export Figures', ...
    'Units','normalized', 'Position',[0.03 0.03 0.94 0.24], ...
    'BackgroundColor', ColIndigo, 'ForegroundColor', ColWhite, 'Callback', @(s,e) exportFiguresButtonPushed());

% --- Manage Results panel --------------------------------------------------
resultsPanel = uipanel(rightPanel, 'Title','Manage Results', 'FontWeight','bold', ...
    'Units','normalized', 'Position',[0.03 0.150 0.94 0.140], ...
    'BackgroundColor', ColWhite, 'ForegroundColor', ColIndigo);
ResultsListDropDown = uicontrol(resultsPanel, 'Style','popupmenu', 'String',{'(no saved results)'}, ...
    'Units','normalized', 'Position',[0.03 0.65 0.94 0.28], ...
    'TooltipString','Run folders currently saved under results/');
RefreshResultsButton = uicontrol(resultsPanel, 'Style','pushbutton', 'String','Refresh', ...
    'Units','normalized', 'Position',[0.03 0.35 0.45 0.26], ...
    'BackgroundColor', ColIndigo, 'ForegroundColor', ColWhite, 'Callback', @(s,e) refreshResultsButtonPushed());
DeleteResultButton = uicontrol(resultsPanel, 'Style','pushbutton', 'String','Delete Selected', ...
    'Units','normalized', 'Position',[0.52 0.35 0.45 0.26], ...
    'BackgroundColor',[0.71 0.11 0.11], 'ForegroundColor', ColWhite, 'Callback', @(s,e) deleteResultButtonPushed());
DeleteAllResultsButton = uicontrol(resultsPanel, 'Style','pushbutton', 'String','! Delete ALL Results', ...
    'Units','normalized', 'Position',[0.03 0.04 0.94 0.26], ...
    'BackgroundColor',[0.45 0.07 0.07], 'ForegroundColor', ColWhite, 'Callback', @(s,e) deleteAllResultsButtonPushed());

% --- Footer: citation -------------------------------------------------------
uicontrol(fig, 'Style','text', 'String', ...
    'MIDAS - Mineral Interface Dynamics and apparent-Age Simulation (Octave GUI)', ...
    'Units','normalized', 'Position',[0 0 1 0.018], 'BackgroundColor', ColBg, ...
    'ForegroundColor', ColIndigo, 'FontSize',8);

% ------------------------------------------------------------------------
% Populate controls from defaults
% ------------------------------------------------------------------------
populateControlsFromParams(DefaultParams);

% Shared run-state (nested functions below close over these)
LastR = [];
LastFigs = {};
LastFigTags = {};
refreshResultsList();

    % ---- nested functions (share this function's workspace) ------------
    function navButtonPushed(key)
        fn = fieldnames(SectionPanels);
        for i = 1:numel(fn)
            set(SectionPanels.(fn{i}), 'Visible', ifelse(strcmp(fn{i},key),'on','off'));
        end
        for i = 1:nTabs
            if strcmp(tabKeys{i}, key)
                set(navButtons(i), 'BackgroundColor', ColGold, 'ForegroundColor', ColIndigo, 'FontWeight','bold');
            else
                set(navButtons(i), 'BackgroundColor', ColIndigo, 'ForegroundColor', ColLavender, 'FontWeight','normal');
            end
        end
    end

    function populateControlsFromParams(p)
        for k = 1:numel(FieldMeta)
            f = FieldMeta(k);
            if ~isfield(p, f.name), continue; end
            c = Ctrl.(f.name);
            val = p.(f.name);
            switch f.type
                case 'checkbox'
                    set(c, 'Value', logical(val));
                case 'dropdown'
                    if isNumericOptions(f.options)
                        idx = find(strcmp(f.options, num2str(val)));
                    else
                        idx = find(strcmp(f.options, val));
                    end
                    if isempty(idx), idx = 1; end
                    set(c, 'Value', idx);
                case 'text'
                    set(c, 'String', val);
                case 'numeric'
                    if isnan(val)
                        set(c, 'String', 'NaN', 'ForegroundColor', [0.6 0.6 0.6]);
                    else
                        set(c, 'String', num2str(val), 'ForegroundColor', [0 0 0]);
                    end
                case 'vector'
                    for j = 1:f.n
                        if isnan(val(j))
                            set(c(j), 'String', 'NaN', 'ForegroundColor', [0.6 0.6 0.6]);
                        else
                            set(c(j), 'String', num2str(val(j)), 'ForegroundColor', [0 0 0]);
                        end
                    end
            end
        end
    end

    function params = collectParamsFromControls()
        params = DefaultParams;   % seed with defaults, then overwrite every field below
        for k = 1:numel(FieldMeta)
            f = FieldMeta(k);
            c = Ctrl.(f.name);
            switch f.type
                case 'checkbox'
                    params.(f.name) = double(get(c,'Value'));
                case 'dropdown'
                    items = get(c,'String');
                    sel = items{get(c,'Value')};
                    if isNumericOptions(f.options)
                        params.(f.name) = str2double(sel);
                    else
                        params.(f.name) = sel;
                    end
                case 'text'
                    params.(f.name) = get(c,'String');
                case 'numeric'
                    % The field's own text is the source of truth (it shows
                    % 'NaN' literally for an unused field - see
                    % populateControlsFromParams), so no need to guess from
                    % DefaultParams like the old 0-placeholder approach had to.
                    params.(f.name) = str2double(get(c,'String'));
                case 'vector'
                    params.(f.name) = arrayfun(@(h) str2double(get(h,'String')), c);
            end
        end
    end

    function issues = validateParams(p)
        % Catches parameter combinations that are physically meaningless or
        % would silently degrade the run, so they're caught before spending
        % time on a run rather than discovered afterwards.
        issues = {};
        if isempty(strtrim(p.data_name))
            issues{end+1} = 'data_name must not be empty (it is used to build the output folder name).';
        end
        % Written as "~(x > 0)"/"~(x >= 2)" rather than "x <= 0"/"x < 2": a
        % NaN - e.g. from non-numeric text typed into one of these fields,
        % which Octave's plain text-based edit fields can't prevent the
        % way MATLAB's numeric-only uieditfield does - silently passes any
        % <=/</>= comparison, so a plain "x <= 0" check would miss it and
        % let garbage straight through to MIDAS_Main.
        if ~(p.lxA > 0), issues{end+1} = sprintf('lxA must be > 0 (initial crystal length, mm) - got "%s".', get(Ctrl.lxA,'String')); end
        if ~(p.lxB_factor > 0), issues{end+1} = sprintf('lxB_factor must be > 0 - got "%s".', get(Ctrl.lxB_factor,'String')); end
        if ~(p.nx_A >= 2) || p.nx_A ~= fix(p.nx_A), issues{end+1} = sprintf('nx_A must be a whole number >= 2 - got "%s".', get(Ctrl.nx_A,'String')); end
        if ~(p.nx_B >= 2) || p.nx_B ~= fix(p.nx_B), issues{end+1} = sprintf('nx_B must be a whole number >= 2 - got "%s".', get(Ctrl.nx_B,'String')); end
        if ~(p.t_tot > 0), issues{end+1} = sprintf('t_tot must be > 0 Myr - got "%s".', get(Ctrl.t_tot,'String')); end
        if ~(p.CFL > 0), issues{end+1} = sprintf('CFL must be > 0 - got "%s". CFL=0 hangs the run forever instead of erroring.', get(Ctrl.CFL,'String')); end
        posFields = {'DRG','DRG_LuHf','DRG_Mn','DamA','DamB'};
        for pfi = 1:numel(posFields)
            if ~(p.(posFields{pfi}) > 0)
                issues{end+1} = sprintf('%s must be > 0 - got "%s".', posFields{pfi}, get(Ctrl.(posFields{pfi}),'String'));
            end
        end
        if any([p.Pstart, p.Pstop, p.Ppeak] < 0)
            issues{end+1} = 'Pstart, Pstop and Ppeak cannot be negative (GPa).';
        end
        if p.Trange(1) >= p.Trange(2), issues{end+1} = 'Trange(1) must be less than Trange(2).'; end
        if p.Prange(1) >= p.Prange(2), issues{end+1} = 'Prange(1) must be less than Prange(2).'; end

        Tvals = [p.Tstart, p.Tstop];
        Pvals = [p.Pstart, p.Pstop];
        if strcmp(p.PTmode, 'peak')
            Tvals(end+1) = p.Tpeak;
            Pvals(end+1) = p.Ppeak;
            if p.Tpeak < max(p.Tstart, p.Tstop)
                issues{end+1} = 'Tpeak should be >= Tstart and Tstop (PTmode=''peak'' expects it to be the maximum of the path).';
            end
            if p.Ppeak < max(p.Pstart, p.Pstop)
                issues{end+1} = 'Ppeak should be >= Pstart and Pstop (PTmode=''peak'' expects it to be the maximum of the path).';
            end
            if p.T_peak_frac < 0 || p.T_peak_frac > 1, issues{end+1} = 'T_peak_frac must be between 0 and 1.'; end
            if p.P_peak_frac < 0 || p.P_peak_frac > 1, issues{end+1} = 'P_peak_frac must be between 0 and 1.'; end
        end
        if any(Tvals < p.Trange(1)) || any(Tvals > p.Trange(2))
            issues{end+1} = 'Tstart/Tstop/Tpeak fall outside Trange - the phase-diagram lookup table will extrapolate.';
        end
        if any(Pvals < p.Prange(1)) || any(Pvals > p.Prange(2))
            issues{end+1} = 'Pstart/Pstop/Ppeak fall outside Prange - the phase-diagram lookup table will extrapolate.';
        end
    end

    function logStatus(msg)
        cur = get(StatusArea,'String');
        if ischar(cur), cur = {cur}; end
        cur{end+1} = char(msg);
        set(StatusArea, 'String', cur, 'Value', numel(cur), 'ListboxTop', max(1,numel(cur)-6));
        drawnow;
    end

    function runButtonPushed()
        set(RunButton, 'Enable','off');
        drawnow;
        params = collectParamsFromControls();
        issues = validateParams(params);
        if ~isempty(issues)
            logStatus('Cannot run - fix the following first:');
            for i = 1:numel(issues)
                logStatus(['  - ' issues{i}]);
            end
            set(RunButton, 'Enable','on');
            return
        end
        try
            params.outDir = fullfile('results', [params.data_name, '_', datestr(now,'yyyymmdd_HHMMSS')]);
            set(Ctrl.outDir, 'String', params.outDir);
            logStatus('Running...');
            t0 = tic;
            R = MIDAS_Main(params);
            LastR = R;

            figs = {}; tags = {};
            try
                [figRelErrLog,figABOnly] = plot_velocity_age(R);
                figs(end+1:end+2) = {figRelErrLog,figABOnly};
                tags(end+1:end+2) = {'velocity_age_relmisfit_log','velocity_age_AB_only'};
            catch ME
                logStatus(['  plot_velocity_age failed: ' ME.message]);
            end
            try
                plot_misfit(R); figs{end+1} = gcf; tags{end+1} = 'misfit';
            catch ME, logStatus(['  plot_misfit failed: ' ME.message]); end
            try
                figMgODrift = plot_massbalance_MgO(R); figs{end+1} = figMgODrift; tags{end+1} = 'massbalance_MgO';
            catch ME, logStatus(['  plot_massbalance_MgO failed: ' ME.message]); end
            try
                figAge = plot_age_at_fixed_positions(R); figs{end+1} = figAge; tags{end+1} = 'age_fixed_positions';
            catch ME, logStatus(['  plot_age_at_fixed_positions failed: ' ME.message]); end
            try
                figConc = plot_conc_at_fixed_positions(R); figs{end+1} = figConc; tags{end+1} = 'conc_fixed_positions';
            catch ME, logStatus(['  plot_conc_at_fixed_positions failed: ' ME.message]); end
            try
                figAgeT = plot_age_vs_temperature(R); figs{end+1} = figAgeT; tags{end+1} = 'age_vs_temperature';
            catch ME, logStatus(['  plot_age_vs_temperature failed: ' ME.message]); end
            try
                figAllComp = plot_all_composition_profiles(R); figs{end+1} = figAllComp; tags{end+1} = 'all_composition_profiles';
            catch ME, logStatus(['  plot_all_composition_profiles failed: ' ME.message]); end

            LastFigs = figs;
            LastFigTags = tags;
            % Absolute, not R.params.outDir as-is (relative to pwd at the
            % time of the run) - if pwd ever shifts before Export is
            % clicked (e.g. a browse dialog can do this), a relative path
            % here would silently resolve somewhere else.
            outDirAbs = fullfile(pwd, R.params.outDir);
            set(DataFolderField, 'String', outDirAbs);
            set(FigFolderField, 'String', outDirAbs);
            refreshResultsList();
            logStatus(sprintf('Done in %.1f s (%d/8 figures).', toc(t0), numel(figs)));
        catch ME
            logStatus(['ERROR: ' ME.message]);
        end
        set(RunButton, 'Enable','on');
    end

    function resetButtonPushed()
        populateControlsFromParams(DefaultParams);
        logStatus('Reset to defaults.');
    end

    function closeAllFiguresButtonPushed()
        % Closes every figure window (all past runs, not just the last
        % one) except this control window itself, which is a figure too.
        figHandles = findall(0, 'Type', 'figure');
        n = 0;
        for i = 1:numel(figHandles)
            h = figHandles(i);
            if ishandle(h) && h ~= fig
                close(h);
                n = n + 1;
            end
        end
        LastFigs = {};
        logStatus(sprintf('Closed %d figure(s).', n));
    end

    function loadExampleButtonPushed()
        items = get(ExampleDropDown,'String');
        choice = items{get(ExampleDropDown,'Value')};
        if strcmp(choice, 'MIDAS_Params (default)')
            fname = 'MIDAS_Params';
        else
            fname = choice;   % examples/<choice>.m, added to the path at startup
        end
        if ~(exist(fname, 'file') == 2)
            logStatus(['ERROR: ' fname '.m not found on the path.']);
            return
        end
        exParams = feval(fname);
        populateControlsFromParams(exParams);
        logStatus(['Loaded ' fname '() - every field above is still freely editable before you Run.']);
    end

    function savePresetButtonPushed()
        params = collectParamsFromControls();
        presetsDir = fullfile(pwd, 'presets');
        if ~exist(presetsDir, 'dir'), mkdir(presetsDir); end
        defaultName = [get(Ctrl.data_name,'String') '_preset.mat'];
        [file, folder] = uiputfile('*.mat', 'Save parameter preset', fullfile(presetsDir, defaultName));
        if isequal(file, 0), return; end
        save(fullfile(folder, file), 'params');
        logStatus(['Saved preset ' fullfile(folder, file)]);
    end

    function loadPresetButtonPushed()
        presetsDir = fullfile(pwd, 'presets');
        if ~exist(presetsDir, 'dir'), presetsDir = pwd; end
        [file, folder] = uigetfile('*.mat', 'Load parameter preset', presetsDir);
        if isequal(file, 0), return; end
        S = load(fullfile(folder, file));
        if ~isfield(S, 'params') || ~isstruct(S.params)
            logStatus(['ERROR: ' file ' does not contain a ''params'' struct - not a MIDAS preset file.']);
            return
        end
        populateControlsFromParams(S.params);
        logStatus(['Loaded preset ' fullfile(folder, file)]);
    end

    function exportDataButtonPushed()
        if isempty(LastR)
            logStatus('Nothing to export yet - run a calculation first.');
            return
        end
        folder = get(DataFolderField,'String');
        base = get(DataBaseField,'String');
        if isempty(base)
            logStatus('Please enter a base filename for the exported data.');
            return
        end
        if ~exist(folder, 'dir'), mkdir(folder); end
        didSomething = false;
        if get(MatCheckBox,'Value')
            R = LastR;
            save(fullfile(folder, [base '.mat']), 'R');
            logStatus(['Saved ' fullfile(folder, [base '.mat'])]);
            didSomething = true;
        end
        if get(XlsxCheckBox,'Value')
            export_results_excel(LastR, fullfile(folder, [base '.xlsx']));
            logStatus(['Saved ' fullfile(folder, [base '.xlsx'])]);
            didSomething = true;
        end
        if ~didSomething
            logStatus('Check .mat and/or .xlsx to export data.');
        end
    end

    function exportFiguresButtonPushed()
        if isempty(LastFigs)
            logStatus('No figures to export yet - run a calculation first.');
            return
        end
        folder = get(FigFolderField,'String');
        base = get(FigBaseField,'String');
        if isempty(base)
            logStatus('Please enter a base filename for the exported figures.');
            return
        end
        if ~exist(folder, 'dir'), mkdir(folder); end
        n = 0;
        for i = 1:numel(LastFigs)
            h = LastFigs{i};
            if isempty(h) || ~ishandle(h), continue; end
            try
                export_pub_fig(h, fullfile(folder, sprintf('%s_%s', base, LastFigTags{i})));
                n = n + 1;
            catch ME
                logStatus(sprintf('  %s export failed: %s', LastFigTags{i}, ME.message));
            end
        end
        logStatus(sprintf('Exported %d/%d figure(s) (PDF + 300dpi JPG) to %s', n, numel(LastFigs), folder));
    end

    function browseDataButtonPushed()
        folder = uigetdir(get(DataFolderField,'String'), 'Choose export folder for data');
        if ischar(folder), set(DataFolderField,'String',folder); end
    end

    function browseFigButtonPushed()
        folder = uigetdir(get(FigFolderField,'String'), 'Choose export folder for figures');
        if ischar(folder), set(FigFolderField,'String',folder); end
    end

    function d = resultsRootDir()
        d = fullfile(pwd, 'results');
    end

    function refreshResultsList()
        root = resultsRootDir();
        names = {};
        if exist(root, 'dir')
            listing = dir(root);
            listing = listing([listing.isdir]);
            names = setdiff({listing.name}, {'.','..'});
        end
        if isempty(names)
            set(ResultsListDropDown, 'String', {'(no saved results)'}, 'Value', 1, 'Enable','off');
            set(DeleteResultButton, 'Enable','off');
            set(DeleteAllResultsButton, 'Enable','off');
        else
            set(ResultsListDropDown, 'String', sort(names), 'Value', 1, 'Enable','on');
            set(DeleteResultButton, 'Enable','on');
            set(DeleteAllResultsButton, 'Enable','on');
        end
    end

    function refreshResultsButtonPushed()
        refreshResultsList();
        items = get(ResultsListDropDown,'String');
        if numel(items) == 1 && strcmp(items{1}, '(no saved results)')
            n = 0;
        else
            n = numel(items);
        end
        logStatus(sprintf('Results list refreshed (%d folder(s)).', n));
    end

    function deleteResultButtonPushed()
        items = get(ResultsListDropDown,'String');
        sel = items{get(ResultsListDropDown,'Value')};
        if isempty(sel) || strcmp(sel, '(no saved results)'), return; end
        target = fullfile(resultsRootDir(), sel);
        choice = questdlg(sprintf('Delete result folder "%s" and everything in it?\nThis cannot be undone.', sel), ...
            'Delete result', 'Delete', 'Cancel', 'Cancel');
        if ~strcmp(choice, 'Delete'), return; end
        try
            rmdir(target, 's');
            logStatus(['Deleted ' target]);
        catch ME
            logStatus(['ERROR deleting ' target ': ' ME.message]);
        end
        refreshResultsList();
    end

    function deleteAllResultsButtonPushed()
        root = resultsRootDir();
        items = get(ResultsListDropDown,'String');
        if isempty(items) || strcmp(items{1}, '(no saved results)'), return; end
        choice = questdlg(sprintf('Delete ALL %d saved result folder(s) under:\n%s\nThis cannot be undone.', numel(items), root), ...
            'Delete ALL results', 'Delete all', 'Cancel', 'Cancel');
        if ~strcmp(choice, 'Delete all'), return; end
        try
            rmdir(root, 's');
            mkdir(root);
            logStatus(['Deleted all result folders under ' root]);
        catch ME
            logStatus(['ERROR deleting results: ' ME.message]);
        end
        refreshResultsList();
    end
end

% ============================================================================
% Static helpers (no shared-state closure needed)
% ============================================================================
function out = ifelse(cond, a, b)
if cond, out = a; else, out = b; end
end

function tf = isNumericOptions(options)
tf = ~isempty(options) && all(~isnan(cellfun(@str2double, options)));
end

function c = addFieldRow(parent, pos, f)
% Creates the control (not the label) for one field row at normalized
% position POS = [x y w h] within PARENT. Mirrors GUI/MIDAS.m's
% addFieldRow, adapted to plain uicontrol.
switch f.type
    case 'checkbox'
        c = uicontrol(parent, 'Style','checkbox', 'Units','normalized', 'Position',pos, ...
            'BackgroundColor',[1 1 1], 'TooltipString', f.tooltip);
    case 'dropdown'
        c = uicontrol(parent, 'Style','popupmenu', 'String', f.options, 'Units','normalized', ...
            'Position',pos, 'TooltipString', f.tooltip);
    case 'text'
        c = uicontrol(parent, 'Style','edit', 'Units','normalized', 'Position',pos, ...
            'BackgroundColor',[1 1 1], 'HorizontalAlignment','left', 'TooltipString', f.tooltip);
    case 'numeric'
        c = uicontrol(parent, 'Style','edit', 'Units','normalized', 'Position',pos, ...
            'BackgroundColor',[1 1 1], 'HorizontalAlignment','left', 'TooltipString', f.tooltip);
    case 'vector'
        c = zeros(1, f.n);   % Octave has no gobjects(); graphics handles are plain doubles
        w = pos(3)/f.n - 0.01;
        for j = 1:f.n
            xj = pos(1) + (j-1)*(w+0.01);
            c(j) = uicontrol(parent, 'Style','edit', 'Units','normalized', ...
                'Position',[xj pos(2) w pos(4)], 'BackgroundColor',[1 1 1], 'TooltipString', f.tooltip);
        end
    otherwise
        error('MIDAS_GUI:UnknownFieldType', 'Unknown field type "%s" for %s', f.type, f.name);
end
end

function M = buildFieldMeta()
% One row per MIDAS_Params.m field: {name, tab, type, tooltip, options, n}.
% Identical content to GUI/MIDAS.m's buildFieldMeta (kept in sync by hand -
% pure data, no MATLAB-specific syntax, so it ports verbatim).
rows = {
    'outDir',          'Output',      'text',     'Folder all saved figures/movie/data go into (created if missing)', {}, 1
    'data_name',       'Output',      'text',     'Base name used when saving results/movie', {}, 1
    'save_data',       'Output',      'checkbox', 'Save workspace with data_name at the end (separate from the Export Data panel on the right)', {}, 1
    'make_movie',      'Output',      'checkbox', 'Write a .gif while running (needs doPlot = true)', {}, 1
    'doPlot',          'Output',      'checkbox', 'Master switch for live figures during the run (separate from this app''s post-run figures, which always show)', {}, 1
    'saveCheckpoints', 'Output',      'checkbox', 'Also save _initial/_snapN/_last figures to outDir while doPlot=true - otherwise show them live only, don''t write to disk', {}, 1
    'plot_kind',       'Output',      'dropdown', '1: profiles+phase diagram+ages, 2: profiles+apparent age, 3: all (only affects live plotting while doPlot=true)', {'1','2','3'}, 1
    'FSS',             'Output',      'numeric',  'FontSize used in all figures', {}, 1
    'LWW',             'Output',      'numeric',  'LineWidth used in all figures', {}, 1

    'checkmaxT_Eq',    'Programming', 'checkbox', 'Stop advancing T once max T is reached (checks equilibrium there)', {}, 1
    'checkFinT_Eq',    'Programming', 'numeric',  '>1: extend run to checkFinT_Eq*t_tot at constant final P-T (relaxation)', {}, 1
    'store_history',   'Programming', 'checkbox', 'Store the full time history (required by most post-run figures)', {}, 1
    'nout',            'Programming', 'numeric',  'Plot/record every nout iterations; used only if recordMode = ''iteration''', {}, 1
    'recordMode',      'Programming', 'dropdown', '''iteration'': record every nout iterations (dt is adaptive); ''time'': record every recordDT Myr instead', {'iteration','time'}, 1
    'recordDT',        'Programming', 'numeric',  'Plot/record every recordDT Myr; used only if recordMode = ''time''', {}, 1
    'CFL',             'Programming', 'numeric',  'CFL condition', {}, 1
    'nStepsMin',       'Programming', 'numeric',  'Minimum number of adaptive time steps across the run', {}, 1
    'microStepTol',    'Programming', 'numeric',  'Below-this-movement steps (mm) update the boundary node in-place instead of resampling', {}, 1

    'lxA',             'Physics', 'numeric',  'Length of A (crystal, e.g. Grt) in mm', {}, 1
    'lxB_factor',      'Physics', 'numeric',  'lxB = lxB_factor*lxA; length of B (matrix) in mm', {}, 1
    'DRG',             'Physics', 'numeric',  'Diffusivity of B wrt A (major elements)', {}, 1
    'DRG_LuHf',        'Physics', 'numeric',  'Diffusivity Lu/Hf in matrix (wrt A)', {}, 1
    'DRG_Mn',          'Physics', 'numeric',  'Diffusivity Mn in matrix (wrt A)', {}, 1
    'DamA',            'Physics', 'numeric',  'Damköhler_II for material A (interface kinetics)', {}, 1
    'DamB',            'Physics', 'numeric',  'Damköhler_II for material B (interface kinetics)', {}, 1
    'KDLu',            'Physics', 'numeric',  'KD Lu (Xtl/Mtrx: pelites)', {}, 1
    'KDHf',            'Physics', 'numeric',  'KD Hf (Xtl/Mtrx: pelites)', {}, 1
    'MnMode',          'Physics', 'dropdown', '''fixed'': use constant KDMn below; ''PD'': derive KD_Mn(T,P) from the phase diagram (PD)', {'fixed','PD'}, 1
    'KDMn',            'Physics', 'numeric',  'KD Mn (Xtl/Mtrx: pelites); used only if MnMode = ''fixed'', or if MniBMode = ''manual''', {}, 1
    'LuiB',            'Physics', 'numeric',  'Initial amount in ppm of Lu (in B)', {}, 1
    'HfiB',            'Physics', 'numeric',  'Initial amount in ppm of Hf (in B)', {}, 1
    'HfiBref',         'Physics', 'numeric',  'Initial amount in ppm of Hf(ref) (in B)', {}, 1
    'MniBMode',        'Physics', 'dropdown', '''manual'': use MniB below; ''PD'': override it from the phase diagram at Tstart,Pstart', {'manual','PD'}, 1
    'MniB',            'Physics', 'numeric',  'Initial amount in wt% of Mn (in B); used only if MniBMode = ''manual''', {}, 1
    'isoRefMode',      'Physics', 'dropdown', 'Isochron reference point for phase A: ''bulk'', ''core'', or ''wholerock''', {'bulk','core','wholerock'}, 1
    'isoNskip',        'Physics', 'numeric',  'Isochron profile sampling: compute an age for every isoNskip-th node across phase A', {}, 1
    'isoShowProfile',  'Physics', 'checkbox', 'Also plot the isoNskip-th profile points/lines in the isochron panel', {}, 1

    't_tot',           'Time_PT', 'numeric',  'Total time in Myr (growth & diffusion, before relaxation)', {}, 1
    'PTmode',          'Time_PT', 'dropdown', '''Tbump'': T-only bump (delT), P linear; ''peak'': explicit Tpeak/Ppeak with independent peak timing', {'Tbump','peak'}, 1
    'Tstart',          'Time_PT', 'numeric',  'Starting T in K', {}, 1
    'Tstop',           'Time_PT', 'numeric',  'Final T in K', {}, 1
    'delT',            'Time_PT', 'numeric',  'Thermal max during decompression; used only if PTmode = ''Tbump''', {}, 1
    'Tpeak',           'Time_PT', 'numeric',  'Peak T in K; used only if PTmode = ''peak''', {}, 1
    'T_peak_frac',     'Time_PT', 'numeric',  'Time of peak T, as a fraction of t_tot; used only if PTmode = ''peak''', {}, 1
    'Pstart',          'Time_PT', 'numeric',  'Starting P in GPa', {}, 1
    'Pstop',           'Time_PT', 'numeric',  'Final P in GPa', {}, 1
    'Ppeak',           'Time_PT', 'numeric',  'Peak P in GPa; used only if PTmode = ''peak''', {}, 1
    'P_peak_frac',     'Time_PT', 'numeric',  'Time of peak P, as a fraction of t_tot; used only if PTmode = ''peak''', {}, 1
    'Trange',          'Time_PT', 'vector',   'T range [min max] for visualization/phase diagram in K', {}, 2
    'Prange',          'Time_PT', 'vector',   'P range [min max] for visualization/phase diagram in GPa', {}, 2

    'eqMode',          'Thermo', 'dropdown', 'Equilibrium composition source: ''poly'' (3-point bilinear fit) or ''PD'' (phase diagram)', {'poly','PD'}, 1
    'Tar',             'Thermo', 'vector',   'Temperatures in K at the 3 calibration points (used if eqMode = ''poly'')', {}, 3
    'Par',             'Thermo', 'vector',   'Pressures in GPa at the 3 calibration points (used if eqMode = ''poly'')', {}, 3
    'Car_G',           'Thermo', 'vector',   'Compositions of MgO in garnet (A) at the 3 points (used if eqMode = ''poly'')', {}, 3
    'Car_B',           'Thermo', 'vector',   'Compositions of MgO in biotite (B) at the 3 points (used if eqMode = ''poly'')', {}, 3
    'PD',              'Thermo', 'text',     'Lookup table for the thermodynamic data set used to create the phase diagram (used if eqMode = ''PD'')', {}, 1

    'ndim',            'Numerics', 'dropdown', 'Geometry factor (1: planar, 2: cylindrical, 3: spherical)', {'1','2','3'}, 1
    'NBC',             'Numerics', 'numeric',  'Neumann (no-flux) outer boundary condition', {}, 1
    'nx_A',            'Numerics', 'numeric',  'Grid resolution in A', {}, 1
    'nx_B',            'Numerics', 'numeric',  'Grid resolution in B', {}, 1
};
M = cell2struct(rows, {'name','tab','type','tooltip','options','n'}, 2);
end
