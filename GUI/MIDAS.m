classdef MIDAS < matlab.apps.AppBase
% MIDAS  Interactive front-end for the single-run crystal-growth
% model (MIDAS_Main.m). Every field of MIDAS_Params.m is exposed as
% a labeled, tooltip-annotated control (grouped into sidebar sections
% matching that file's own comment sections, pre-filled with its defaults).
% Run shows the same post-run figures Run_MIDAS.m does (each its own
% window); the results and figures can then be exported: data as
% .mat/.xlsx, figures as vector PDF + 300 dpi JPG.
%
% Usage:
%   MIDAS
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================

    properties (Access = public)
        UIFigure            matlab.ui.Figure
        GridMain            matlab.ui.container.GridLayout
        RunButton           matlab.ui.control.Button
        ResetButton         matlab.ui.control.Button
        SavePresetButton    matlab.ui.control.Button
        LoadPresetButton    matlab.ui.control.Button
        ExampleDropDown     matlab.ui.control.DropDown
        LoadExampleButton   matlab.ui.control.Button
        StatusArea          matlab.ui.control.TextArea
        ResultsListDropDown    matlab.ui.control.DropDown
        RefreshResultsButton   matlab.ui.control.Button
        DeleteResultButton     matlab.ui.control.Button
        DeleteAllResultsButton matlab.ui.control.Button
        DataFolderField     matlab.ui.control.EditField
        DataBaseField       matlab.ui.control.EditField
        MatCheckBox         matlab.ui.control.CheckBox
        XlsxCheckBox        matlab.ui.control.CheckBox
        ExportDataButton    matlab.ui.control.Button
        BrowseDataButton    matlab.ui.control.Button
        FigFolderField      matlab.ui.control.EditField
        FigBaseField        matlab.ui.control.EditField
        ExportFiguresButton matlab.ui.control.Button
        BrowseFigButton     matlab.ui.control.Button
        CitationLabel       matlab.ui.control.Label
        ThemeToggle         matlab.ui.control.Button
        LogoImage           matlab.ui.control.Image
    end

    properties (Access = private)
        Ctrl                    % struct: Ctrl.(paramName) = control handle (array of handles for 'vector' fields)
        FieldMeta                % struct array from buildFieldMeta()
        DefaultParams            % struct from MIDAS_Params(), used as-is
        LastR = []                % last run's result struct (Export Data source)
        LastFigs = {}             % last run's figure handles (Export Figures source)
        LastFigTags = {}          % short name per entry in LastFigs, used to build export filenames

        SectionPanels             % struct: SectionPanels.(tabKey) = panel handle (sidebar content, one shown at a time)
        NavButtons                % array of sidebar nav button handles
        NavButtonKeys             % cell array, same order as NavButtons, tab key each one activates

        % Brand palette (set once in createComponents, reused throughout)
        ColIndigo   = [0.180 0.102 0.278]   % #2E1A47 - sidebar / primary text
        ColGold     = [0.851 0.643 0.255]   % #D9A441 - primary action / active nav
        ColTeal     = [0.243 0.561 0.486]   % #3E8F7C - secondary accent
        ColBg       = [0.965 0.957 0.945]   % #F6F4F1 - content background
        ColWhite    = [1 1 1]
        ColLavender = [0.898 0.875 0.949]   % #E5DFF2 - inactive sidebar text

        % Dark-mode counterparts of ColBg/ColWhite/ColIndigo (the sidebar
        % itself is already dark in both modes, so it isn't included here).
        % Matches the dark-mode logo's own palette (GUI/assets/midas_*_dark.svg).
        DarkBg      = [0.114 0.106 0.129]   % #1D1B21 - content background, dark mode
        DarkPanel   = [0.169 0.157 0.192]   % #2B2831 - panel background, dark mode
        DarkText    = [0.918 0.890 0.984]   % #EAE3F2 - primary text on a dark background

        IsDarkMode = false        % current theme; toggled by ThemeToggle
        ThemeBgAreas = gobjects(1,0)     % grids/panels whose BackgroundColor swaps ColBg<->DarkBg
        ThemePanels  = gobjects(1,0)     % uipanels whose BackgroundColor/ForegroundColor swap ColWhite/ColIndigo<->DarkPanel/DarkText
        ThemeLabels  = gobjects(1,0)     % uilabels whose FontColor swaps ColIndigo<->DarkText
    end

    methods (Access = public)
        function app = MIDAS
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @(app)startupFcn(app))
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end

    methods (Access = private)

        function M = buildFieldMeta(~)
            % One row per MIDAS_Params.m field: {name, tab, type, tooltip, options, n}.
            % tab keys match that file's own comment sections.
            % type: 'text' | 'numeric' | 'checkbox' | 'dropdown' | 'vector'
            rows = {
                'outDir',          'Output',      'text',     'Folder all saved figures/movie/data go into (created if missing)', {}, 1
                'data_name',       'Output',      'text',     'Base name used when saving results/movie', {}, 1
                'save_data',       'Output',      'checkbox', '1: save workspace with data_name at the end (MIDAS_Main''s own auto-save - separate from the Export Data panel on the right)', {}, 1
                'make_movie',      'Output',      'checkbox', '1: write a .gif while running (needs doPlot = true)', {}, 1
                'doPlot',          'Output',      'checkbox', 'Master switch for MATLAB''s own live figures during the run (separate from this app''s post-run figures, which always show)', {}, 1
                'saveCheckpoints', 'Output',      'checkbox', '1: also save _initial/_snapN/_last figures to outDir while doPlot=true; 0: show them live only, don''t write to disk', {}, 1
                'plot_kind',       'Output',      'dropdown', '1: profiles+phase diagram+ages, 2: profiles+apparent age, 3: all (only affects live plotting while doPlot=true)', {'1','2','3'}, 1
                'FSS',             'Output',      'numeric',  'FontSize used in all figures', {}, 1
                'LWW',             'Output',      'numeric',  'LineWidth used in all figures', {}, 1

                'checkmaxT_Eq',    'Programming', 'checkbox', '1: stop advancing T once max T is reached (checks equilibrium there)', {}, 1
                'checkFinT_Eq',    'Programming', 'numeric',  '>1: extend run to checkFinT_Eq*t_tot at constant final P-T (relaxation)', {}, 1
                'store_history',   'Programming', 'checkbox', '1: store the full time history (REQUIRED by most of this app''s post-run figures)', {}, 1
                'nout',            'Programming', 'numeric',  'Plot/record every nout iterations; used only if recordMode = ''iteration''', {}, 1
                'recordMode',      'Programming', 'dropdown', '''iteration'': record every nout iterations (not evenly spaced in time, dt is adaptive); ''time'': record every recordDT Myr instead', {'iteration','time'}, 1
                'recordDT',        'Programming', 'numeric',  'Plot/record every recordDT Myr; used only if recordMode = ''time''', {}, 1
                'CFL',             'Programming', 'numeric',  'CFL condition', {}, 1
                'nStepsMin',       'Programming', 'numeric',  'Minimum number of adaptive time steps across the run (caps dt at t_tot/nStepsMin); without this, near-stagnant regimes (growth velocity ~0) can take a single enormous step straight to t_final, leaving no recorded time history', {}, 1
                'microStepTol',    'Programming', 'numeric',  'mm; if the interface moves less than this in one step, update the boundary node in-place instead of doing a full mesh resample - still recorded like any other step', {}, 1

                'lxA',             'Physics', 'numeric',  'Length of A (crystal, e.g. Grt) in mm', {}, 1
                'lxB_factor',      'Physics', 'numeric',  'lxB = lxB_factor*lxA; length of B (matrix) in mm', {}, 1
                'DRG',             'Physics', 'numeric',  'Diffusivity of B wrt A (major elements)', {}, 1
                'DRG_LuHf',        'Physics', 'numeric',  'Diffusivity Lu/Hf in matrix (wrt A)', {}, 1
                'DRG_Mn',          'Physics', 'numeric',  'Diffusivity Mn in matrix (wrt A)', {}, 1
                'DamA',            'Physics', 'numeric',  'Damkohler_II for material A (interface kinetics)', {}, 1
                'DamB',            'Physics', 'numeric',  'Damkohler_II for material B (interface kinetics)', {}, 1
                'KDLu',            'Physics', 'numeric',  'KD Lu (Xtl/Mtrx: pelites) (Kohn, 2009, p.171)', {}, 1
                'KDHf',            'Physics', 'numeric',  'KD Hf (Xtl/Mtrx: pelites) (Kohn, 2009, p.171)', {}, 1
                'MnMode',          'Physics', 'dropdown', '''fixed'': use constant KDMn below; ''PD'': derive KD_Mn(T,P) from the phase diagram (PD)', {'fixed','PD'}, 1
                'KDMn',            'Physics', 'numeric',  'KD Mn (Xtl/Mtrx: pelites) (KD = 30, Kretz, 1959); used only if MnMode = ''fixed'', or if MniBMode = ''manual'' (overrides a ''PD'' MnMode)', {}, 1
                'LuiB',            'Physics', 'numeric',  'Initial amount in ppm of Lu (in B)', {}, 1
                'HfiB',            'Physics', 'numeric',  'Initial amount in ppm of Hf (in B)', {}, 1
                'HfiBref',         'Physics', 'numeric',  'Initial amount in ppm of Hf(ref) (in B); normalization reference (176Lu/177Hf ~0.279, Faure & Mensing, 2025)', {}, 1
                'MniBMode',        'Physics', 'dropdown', '''manual'': use MniB below; ''PD'': override it with MnO_Bt interpolated from the phase diagram at Tstart,Pstart', {'manual','PD'}, 1
                'MniB',            'Physics', 'numeric',  'Initial amount in wt% of Mn (in B); used only if MniBMode = ''manual''', {}, 1
                'isoRefMode',      'Physics', 'dropdown', 'Isochron reference point for phase A (crystal): ''bulk'' (volume-weighted average of B), ''core'' (B node farthest from the interface), or ''wholerock'' (volume-weighted average of A+B together)', {'bulk','core','wholerock'}, 1
                'isoNskip',        'Physics', 'numeric',  'Isochron profile sampling: compute an age for every isoNskip-th node across phase A (in addition to rim/core/bulk)', {}, 1
                'isoShowProfile',  'Physics', 'checkbox', '1: also plot the isoNskip-th profile points/lines in the isochron panel; 0: show only core/rim/bulk/max', {}, 1

                't_tot',           'Time_PT', 'numeric',  'Total time in Myr (growth & diffusion, before relaxation)', {}, 1
                'PTmode',          'Time_PT', 'dropdown', '''Tbump'': old T-only bump (delT), P linear; ''peak'': explicit Tpeak/Ppeak with independent peak timing for T and P', {'Tbump','peak'}, 1
                'Tstart',          'Time_PT', 'numeric',  'Starting T in K', {}, 1
                'Tstop',           'Time_PT', 'numeric',  'Tstop in K', {}, 1
                'delT',            'Time_PT', 'numeric',  'Thermal max during decompression (changes peak T); used only if PTmode = ''Tbump''', {}, 1
                'Tpeak',           'Time_PT', 'numeric',  'Peak T in K; used only if PTmode = ''peak''', {}, 1
                'T_peak_frac',     'Time_PT', 'numeric',  'Time of peak T, as a fraction of t_tot; used only if PTmode = ''peak''', {}, 1
                'Pstart',          'Time_PT', 'numeric',  'Pstart in GPa', {}, 1
                'Pstop',           'Time_PT', 'numeric',  'Pstop in GPa', {}, 1
                'Ppeak',           'Time_PT', 'numeric',  'Peak P in GPa; used only if PTmode = ''peak''', {}, 1
                'P_peak_frac',     'Time_PT', 'numeric',  'Time of peak P, as a fraction of t_tot (independent of T_peak_frac); used only if PTmode = ''peak''', {}, 1
                'Trange',          'Time_PT', 'vector',   'T range [min max] for visualization/phase diagram in K', {}, 2
                'Prange',          'Time_PT', 'vector',   'P range [min max] for visualization/phase diagram in GPa', {}, 2

                'eqMode',          'Thermo', 'dropdown', 'Equilibrium composition source: ''poly'' (3-point bilinear fit) or ''PD'' (phase diagram)', {'poly','PD'}, 1
                'Tar',             'Thermo', 'vector',   'Temperatures in K at the 3 calibration points (used if eqMode = ''poly'')', {}, 3
                'Par',             'Thermo', 'vector',   'Pressures in GPa at the 3 calibration points (used if eqMode = ''poly'')', {}, 3
                'Car_G',           'Thermo', 'vector',   'Compositions of MgO in garnet (A) at the 3 points (used if eqMode = ''poly'')', {}, 3
                'Car_B',           'Thermo', 'vector',   'Compositions of MgO in biotite (B) at the 3 points (used if eqMode = ''poly'')', {}, 3
                'PD',              'Thermo', 'text',     'Perplex table filename: cols [T(K), P(bar), ..., MgO_A(wt%), MgO_B(wt%), ...] (used if eqMode = ''PD'')', {}, 1

                'ndim',            'Numerics', 'dropdown', 'Geometry factor (1: planar, 2: cylindrical, 3: spherical)', {'1','2','3'}, 1
                'NBC',             'Numerics', 'numeric',  'Neumann (no-flux) outer boundary condition', {}, 1
                'nx_A',            'Numerics', 'numeric',  'Grid resolution in A', {}, 1
                'nx_B',            'Numerics', 'numeric',  'Grid resolution in B', {}, 1
            };
            M = cell2struct(rows, {'name','tab','type','tooltip','options','n'}, 2);
        end

        function ctrl = addFieldRow(app, parentGrid, row, f)
            % Adds one label+control row into parentGrid at the given row for
            % field metadata f (one row from buildFieldMeta), returns the
            % created control handle (1xN array of handles for 'vector' fields).
            lbl = uilabel(parentGrid);
            lbl.Text = [f.name '  ' char(9432)];   % trailing (i) hints that a tooltip is available on hover
            lbl.Tooltip = f.tooltip;
            lbl.Layout.Row = row;
            lbl.Layout.Column = 1;
            lbl.FontColor = app.ColIndigo;
            app.ThemeLabels(end+1) = lbl;

            switch f.type
                case 'checkbox'
                    c = uicheckbox(parentGrid);
                    c.Text = '';
                    c.Tooltip = f.tooltip;
                    c.Layout.Row = row;
                    c.Layout.Column = 2;
                case 'dropdown'
                    c = uidropdown(parentGrid);
                    c.Items = f.options;
                    c.Tooltip = f.tooltip;
                    c.Layout.Row = row;
                    c.Layout.Column = 2;
                case 'text'
                    c = uieditfield(parentGrid, 'text');
                    c.Tooltip = f.tooltip;
                    c.Layout.Row = row;
                    c.Layout.Column = 2;
                case 'numeric'
                    c = uieditfield(parentGrid, 'numeric');
                    c.Tooltip = f.tooltip;
                    c.Layout.Row = row;
                    c.Layout.Column = 2;
                case 'vector'
                    sub = uigridlayout(parentGrid, [1, f.n]);
                    sub.Layout.Row = row;
                    sub.Layout.Column = 2;
                    sub.ColumnWidth = repmat({'1x'}, 1, f.n);
                    sub.Padding = [0 0 0 0];
                    sub.ColumnSpacing = 4;
                    c = gobjects(1, f.n);
                    for j = 1:f.n
                        c(j) = uieditfield(sub, 'numeric');
                        c(j).Tooltip = f.tooltip;
                        c(j).Layout.Row = 1;
                        c(j).Layout.Column = j;
                    end
                otherwise
                    error('MIDAS:UnknownFieldType', 'Unknown field type "%s" for %s', f.type, f.name);
            end
            ctrl = c;
        end

        function createComponents(app)
            app.FieldMeta = app.buildFieldMeta();
            assetsDir = fullfile(fileparts(mfilename('fullpath')), 'assets');

            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [60 40 1250 780];
            app.UIFigure.Name = 'MIDAS - Crystal Growth Model';
            app.UIFigure.Color = app.ColBg;
            iconPath = fullfile(assetsDir, 'midas_icon.png');
            if isfile(iconPath)
                app.UIFigure.Icon = iconPath;
            end

            app.GridMain = uigridlayout(app.UIFigure, [3, 1]);
            app.GridMain.RowHeight = {90, '1x', 26};
            app.GridMain.ColumnWidth = {'1x'};
            app.GridMain.Padding = [0 0 0 0];
            app.GridMain.RowSpacing = 0;
            app.GridMain.BackgroundColor = app.ColBg;
            app.ThemeBgAreas(end+1) = app.GridMain;

            % --- Header: logo + subtitle + theme toggle -----------------------------
            header = uipanel(app.GridMain);
            header.Layout.Row = 1;
            header.Layout.Column = 1;
            header.BackgroundColor = app.ColWhite;
            header.BorderType = 'line';
            app.ThemePanels(end+1) = header;   % ColWhite/DarkPanel, like the section panels (not ColBg)

            headerGrid = uigridlayout(header, [1, 3]);
            headerGrid.ColumnWidth = {320, '1x', 90};
            headerGrid.Padding = [16 8 16 8];

            app.LogoImage = uiimage(headerGrid);
            logoPath = fullfile(assetsDir, 'midas_logo_horizontal.png');
            if isfile(logoPath)
                app.LogoImage.ImageSource = logoPath;
            end
            app.LogoImage.Layout.Row = 1;
            app.LogoImage.Layout.Column = 1;

            subLbl = uilabel(headerGrid);
            subLbl.Text = 'Single-run crystal-growth model';
            subLbl.FontColor = app.ColIndigo;
            subLbl.FontSize = 14;
            subLbl.HorizontalAlignment = 'right';
            subLbl.VerticalAlignment = 'bottom';
            subLbl.Layout.Row = 1;
            subLbl.Layout.Column = 2;
            app.ThemeLabels(end+1) = subLbl;

            app.ThemeToggle = uibutton(headerGrid, 'push');
            app.ThemeToggle.Text = [char(9789) '  Dark'];   % moon glyph
            app.ThemeToggle.BackgroundColor = app.ColIndigo;
            app.ThemeToggle.FontColor = app.ColWhite;
            app.ThemeToggle.Layout.Row = 1;
            app.ThemeToggle.Layout.Column = 3;
            app.ThemeToggle.Tooltip = 'Switch between light and dark mode.';
            app.ThemeToggle.ButtonPushedFcn = createCallbackFcn(app, @app.ThemeToggleButtonPushed, true);

            % --- Body: sidebar + content + run/export panel ------------------------
            body = uigridlayout(app.GridMain, [1, 3]);
            body.Layout.Row = 2;
            body.Layout.Column = 1;
            body.ColumnWidth = {200, '1x', 300};
            body.Padding = [0 0 0 0];
            body.ColumnSpacing = 0;
            body.BackgroundColor = app.ColBg;

            % --- Sidebar navigation -------------------------------------------------
            sidebar = uipanel(body);
            sidebar.Layout.Row = 1;
            sidebar.Layout.Column = 1;
            sidebar.BackgroundColor = app.ColIndigo;
            sidebar.BorderType = 'none';

            % Science inputs first (what are you simulating), bookkeeping
            % last (how it runs/is saved) - matches MIDAS_Params.m's own
            % section order.
            tabKeys   = {'Physics','Time_PT','Thermo','Numerics','Programming','Output'};
            tabTitles = {'Physics','Time & P-T Path','Thermodynamics','Grid & Numerics','Numerics Flags','Output & Plotting'};
            tabIconCodes = [9883, 9201, 9832, 8862, 9881, 9638];   % atom, stopwatch, hot-springs, squared-plus, gear, square-hatch

            navGrid = uigridlayout(sidebar, [numel(tabKeys)+1, 1]);
            navGrid.RowHeight = [repmat({40}, 1, numel(tabKeys)), {'1x'}];
            navGrid.Padding = [8 12 8 8];
            navGrid.RowSpacing = 4;
            navGrid.BackgroundColor = app.ColIndigo;

            app.NavButtons = gobjects(1, numel(tabKeys));
            app.NavButtonKeys = tabKeys;
            for it = 1:numel(tabKeys)
                btn = uibutton(navGrid, 'push');
                btn.Text = [char(tabIconCodes(it)) '  ' tabTitles{it}];
                btn.Layout.Row = it;
                btn.Layout.Column = 1;
                btn.HorizontalAlignment = 'left';
                btn.BackgroundColor = app.ColIndigo;
                btn.FontColor = app.ColLavender;
                btn.ButtonPushedFcn = @(src,evt) app.NavButtonPushed(tabKeys{it});
                app.NavButtons(it) = btn;
            end

            % --- Content area: one stacked panel per section, one shown at a time ---
            content = uigridlayout(body, [1, 1]);
            content.Layout.Row = 1;
            content.Layout.Column = 2;
            content.Padding = [12 12 12 12];
            content.BackgroundColor = app.ColBg;
            app.ThemeBgAreas(end+1) = content;

            app.Ctrl = struct();
            app.SectionPanels = struct();
            for it = 1:numel(tabKeys)
                panel = uipanel(content);
                panel.Layout.Row = 1;
                panel.Layout.Column = 1;
                panel.Title = tabTitles{it};
                panel.FontWeight = 'bold';
                panel.ForegroundColor = app.ColIndigo;
                panel.BackgroundColor = app.ColWhite;
                panel.Visible = 'off';
                app.ThemePanels(end+1) = panel;
                app.SectionPanels.(tabKeys{it}) = panel;

                fieldsHere = app.FieldMeta(strcmp({app.FieldMeta.tab}, tabKeys{it}));
                tg = uigridlayout(panel, [numel(fieldsHere), 2]);
                tg.Scrollable = 'on';
                tg.RowHeight = repmat({30}, 1, numel(fieldsHere));
                tg.ColumnWidth = {220, '1x'};
                tg.RowSpacing = 4;

                for k = 1:numel(fieldsHere)
                    f = fieldsHere(k);
                    c = app.addFieldRow(tg, k, f);
                    app.Ctrl.(f.name) = c;
                end
            end
            app.NavButtonPushed(tabKeys{1});   % show the first section, style its nav button active

            % --- Right: run/status/export panel --------------------------------------
            rightGrid = uigridlayout(body, [9, 1]);
            rightGrid.Layout.Row = 1;
            rightGrid.Layout.Column = 3;
            rightGrid.RowHeight = {40, 32, 32, 22, 140, 160, 160, 150, 10};
            rightGrid.RowSpacing = 8;
            rightGrid.Padding = [10 10 10 10];
            rightGrid.BackgroundColor = app.ColBg;
            app.ThemeBgAreas(end+1) = rightGrid;
            rightGrid.Scrollable = 'on';   % so nothing gets clipped on shorter screens now that more blocks were added

            runResetGrid = uigridlayout(rightGrid, [1, 2]);
            runResetGrid.Layout.Row = 1;
            runResetGrid.Layout.Column = 1;
            runResetGrid.Padding = [0 0 0 0];
            runResetGrid.ColumnSpacing = 6;

            app.RunButton = uibutton(runResetGrid, 'push');
            app.RunButton.Text = [char(9654) '  Run'];
            app.RunButton.FontWeight = 'bold';
            app.RunButton.BackgroundColor = app.ColGold;
            app.RunButton.FontColor = app.ColIndigo;
            app.RunButton.Layout.Row = 1;
            app.RunButton.Layout.Column = 1;
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @app.RunButtonPushed, true);

            app.ResetButton = uibutton(runResetGrid, 'push');
            app.ResetButton.Text = [char(8634) '  Reset'];
            app.ResetButton.BackgroundColor = app.ColIndigo;
            app.ResetButton.FontColor = app.ColWhite;
            app.ResetButton.Layout.Row = 1;
            app.ResetButton.Layout.Column = 2;
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @app.ResetButtonPushed, true);

            % --- Load Example row -------------------------------------------------
            exampleGrid = uigridlayout(rightGrid, [1, 2]);
            exampleGrid.Layout.Row = 2;
            exampleGrid.Layout.Column = 1;
            exampleGrid.Padding = [0 0 0 0];
            exampleGrid.ColumnSpacing = 6;
            exampleGrid.ColumnWidth = {'1x', 70};

            app.ExampleDropDown = uidropdown(exampleGrid);
            app.ExampleDropDown.Items = {'MIDAS_Params (default)', 'Example1_Baseline', ...
                'Example2_PolyEquilibrium', 'Example3_ThermalBump', 'Example4_ManualPartitioning', ...
                'Example5_PlanarGeometry', 'Example6_CylindricalGeometry'};
            app.ExampleDropDown.Layout.Row = 1;
            app.ExampleDropDown.Layout.Column = 1;
            app.ExampleDropDown.Tooltip = 'Pick a starting configuration, then Load - every field stays freely editable afterwards.';

            app.LoadExampleButton = uibutton(exampleGrid, 'push');
            app.LoadExampleButton.Text = 'Load';
            app.LoadExampleButton.BackgroundColor = app.ColTeal;
            app.LoadExampleButton.FontColor = app.ColWhite;
            app.LoadExampleButton.Layout.Row = 1;
            app.LoadExampleButton.Layout.Column = 2;
            app.LoadExampleButton.Tooltip = 'Populate every field from the selected configuration.';
            app.LoadExampleButton.ButtonPushedFcn = createCallbackFcn(app, @app.LoadExampleButtonPushed, true);

            % --- Save/Load preset row -------------------------------------------
            presetGrid = uigridlayout(rightGrid, [1, 2]);
            presetGrid.Layout.Row = 3;
            presetGrid.Layout.Column = 1;
            presetGrid.Padding = [0 0 0 0];
            presetGrid.ColumnSpacing = 6;

            app.SavePresetButton = uibutton(presetGrid, 'push');
            app.SavePresetButton.Text = 'Save Preset';
            app.SavePresetButton.BackgroundColor = app.ColTeal;
            app.SavePresetButton.FontColor = app.ColWhite;
            app.SavePresetButton.Layout.Row = 1;
            app.SavePresetButton.Layout.Column = 1;
            app.SavePresetButton.Tooltip = 'Save the current field values (this whole form) as a .mat preset you can reload later.';
            app.SavePresetButton.ButtonPushedFcn = createCallbackFcn(app, @app.SavePresetButtonPushed, true);

            app.LoadPresetButton = uibutton(presetGrid, 'push');
            app.LoadPresetButton.Text = 'Load Preset';
            app.LoadPresetButton.BackgroundColor = app.ColTeal;
            app.LoadPresetButton.FontColor = app.ColWhite;
            app.LoadPresetButton.Layout.Row = 1;
            app.LoadPresetButton.Layout.Column = 2;
            app.LoadPresetButton.Tooltip = 'Load field values from a previously saved .mat preset.';
            app.LoadPresetButton.ButtonPushedFcn = createCallbackFcn(app, @app.LoadPresetButtonPushed, true);

            statusLbl = uilabel(rightGrid);
            statusLbl.Text = 'Status:';
            statusLbl.FontColor = app.ColIndigo;
            app.ThemeLabels(end+1) = statusLbl;
            statusLbl.FontWeight = 'bold';
            statusLbl.Layout.Row = 4;
            statusLbl.Layout.Column = 1;

            app.StatusArea = uitextarea(rightGrid);
            app.StatusArea.Editable = 'off';
            app.StatusArea.Value = {'Ready.'};
            app.StatusArea.Layout.Row = 5;
            app.StatusArea.Layout.Column = 1;

            % --- Export Data panel -----------------------------------------------
            dataPanel = uipanel(rightGrid);
            dataPanel.Title = 'Export Data';
            dataPanel.FontWeight = 'bold';
            dataPanel.ForegroundColor = app.ColIndigo;
            dataPanel.BackgroundColor = app.ColWhite;
            app.ThemePanels(end+1) = dataPanel;
            dataPanel.Layout.Row = 6;
            dataPanel.Layout.Column = 1;

            dg = uigridlayout(dataPanel, [4, 3]);
            dg.RowHeight = {24, 24, 24, 28};
            dg.ColumnWidth = {55, '1x', 60};
            dg.RowSpacing = 4;

            l1 = uilabel(dg); l1.Text = 'Folder:'; l1.Layout.Row = 1; l1.Layout.Column = 1; l1.FontColor = app.ColIndigo; app.ThemeLabels(end+1) = l1;
            app.DataFolderField = uieditfield(dg, 'text');
            app.DataFolderField.Layout.Row = 1;
            app.DataFolderField.Layout.Column = 2;
            app.BrowseDataButton = uibutton(dg, 'push');
            app.BrowseDataButton.Text = 'Browse...';
            app.BrowseDataButton.BackgroundColor = app.ColIndigo;
            app.BrowseDataButton.FontColor = app.ColWhite;
            app.BrowseDataButton.Layout.Row = 1;
            app.BrowseDataButton.Layout.Column = 3;
            app.BrowseDataButton.ButtonPushedFcn = createCallbackFcn(app, @app.BrowseDataButtonPushed, true);

            l2 = uilabel(dg); l2.Text = 'Name:'; l2.Layout.Row = 2; l2.Layout.Column = 1; l2.FontColor = app.ColIndigo; app.ThemeLabels(end+1) = l2;
            app.DataBaseField = uieditfield(dg, 'text');
            app.DataBaseField.Layout.Row = 2;
            app.DataBaseField.Layout.Column = [2 3];

            app.MatCheckBox = uicheckbox(dg);
            app.MatCheckBox.Text = '.mat';
            app.MatCheckBox.Value = true;
            app.MatCheckBox.Layout.Row = 3;
            app.MatCheckBox.Layout.Column = 2;

            app.XlsxCheckBox = uicheckbox(dg);
            app.XlsxCheckBox.Text = '.xlsx';
            app.XlsxCheckBox.Value = true;
            app.XlsxCheckBox.Layout.Row = 3;
            app.XlsxCheckBox.Layout.Column = 3;

            app.ExportDataButton = uibutton(dg, 'push');
            app.ExportDataButton.Text = [char(11015) '  Export Data'];
            app.ExportDataButton.BackgroundColor = app.ColIndigo;
            app.ExportDataButton.FontColor = app.ColWhite;
            app.ExportDataButton.Layout.Row = 4;
            app.ExportDataButton.Layout.Column = [1 3];
            app.ExportDataButton.ButtonPushedFcn = createCallbackFcn(app, @app.ExportDataButtonPushed, true);

            % --- Export Figures panel ---------------------------------------------
            figPanel = uipanel(rightGrid);
            figPanel.Title = 'Export Figures (PDF + 300 dpi JPG)';
            figPanel.FontWeight = 'bold';
            figPanel.ForegroundColor = app.ColIndigo;
            figPanel.BackgroundColor = app.ColWhite;
            app.ThemePanels(end+1) = figPanel;
            figPanel.Layout.Row = 7;
            figPanel.Layout.Column = 1;

            fg = uigridlayout(figPanel, [3, 3]);
            fg.RowHeight = {24, 24, 28};
            fg.ColumnWidth = {55, '1x', 60};
            fg.RowSpacing = 4;

            l3 = uilabel(fg); l3.Text = 'Folder:'; l3.Layout.Row = 1; l3.Layout.Column = 1; l3.FontColor = app.ColIndigo; app.ThemeLabels(end+1) = l3;
            app.FigFolderField = uieditfield(fg, 'text');
            app.FigFolderField.Layout.Row = 1;
            app.FigFolderField.Layout.Column = 2;
            app.BrowseFigButton = uibutton(fg, 'push');
            app.BrowseFigButton.Text = 'Browse...';
            app.BrowseFigButton.BackgroundColor = app.ColIndigo;
            app.BrowseFigButton.FontColor = app.ColWhite;
            app.BrowseFigButton.Layout.Row = 1;
            app.BrowseFigButton.Layout.Column = 3;
            app.BrowseFigButton.ButtonPushedFcn = createCallbackFcn(app, @app.BrowseFigButtonPushed, true);

            l4 = uilabel(fg); l4.Text = 'Name:'; l4.Layout.Row = 2; l4.Layout.Column = 1; l4.FontColor = app.ColIndigo; app.ThemeLabels(end+1) = l4;
            app.FigBaseField = uieditfield(fg, 'text');
            app.FigBaseField.Layout.Row = 2;
            app.FigBaseField.Layout.Column = [2 3];

            app.ExportFiguresButton = uibutton(fg, 'push');
            app.ExportFiguresButton.Text = [char(11015) '  Export Figures'];
            app.ExportFiguresButton.BackgroundColor = app.ColIndigo;
            app.ExportFiguresButton.FontColor = app.ColWhite;
            app.ExportFiguresButton.Layout.Row = 3;
            app.ExportFiguresButton.Layout.Column = [1 3];
            app.ExportFiguresButton.ButtonPushedFcn = createCallbackFcn(app, @app.ExportFiguresButtonPushed, true);

            % --- Manage Results panel ---------------------------------------------
            resultsPanel = uipanel(rightGrid);
            resultsPanel.Title = 'Manage Results';
            resultsPanel.FontWeight = 'bold';
            resultsPanel.ForegroundColor = app.ColIndigo;
            resultsPanel.BackgroundColor = app.ColWhite;
            app.ThemePanels(end+1) = resultsPanel;
            resultsPanel.Layout.Row = 8;
            resultsPanel.Layout.Column = 1;

            rg = uigridlayout(resultsPanel, [3, 1]);
            rg.RowHeight = {28, 28, 30};
            rg.RowSpacing = 6;

            app.ResultsListDropDown = uidropdown(rg);
            app.ResultsListDropDown.Layout.Row = 1;
            app.ResultsListDropDown.Layout.Column = 1;
            app.ResultsListDropDown.Tooltip = 'Run folders currently saved under results/';

            delRefreshGrid = uigridlayout(rg, [1, 2]);
            delRefreshGrid.Layout.Row = 2;
            delRefreshGrid.Layout.Column = 1;
            delRefreshGrid.Padding = [0 0 0 0];
            delRefreshGrid.ColumnSpacing = 6;

            app.RefreshResultsButton = uibutton(delRefreshGrid, 'push');
            app.RefreshResultsButton.Text = 'Refresh';
            app.RefreshResultsButton.BackgroundColor = app.ColIndigo;
            app.RefreshResultsButton.FontColor = app.ColWhite;
            app.RefreshResultsButton.Layout.Row = 1;
            app.RefreshResultsButton.Layout.Column = 1;
            app.RefreshResultsButton.ButtonPushedFcn = createCallbackFcn(app, @app.RefreshResultsButtonPushed, true);

            app.DeleteResultButton = uibutton(delRefreshGrid, 'push');
            app.DeleteResultButton.Text = 'Delete Selected';
            app.DeleteResultButton.BackgroundColor = [0.71 0.11 0.11];   % warning red, distinct from every other action button
            app.DeleteResultButton.FontColor = app.ColWhite;
            app.DeleteResultButton.Layout.Row = 1;
            app.DeleteResultButton.Layout.Column = 2;
            app.DeleteResultButton.ButtonPushedFcn = createCallbackFcn(app, @app.DeleteResultButtonPushed, true);

            app.DeleteAllResultsButton = uibutton(rg, 'push');
            app.DeleteAllResultsButton.Text = [char(9888) '  Delete ALL Results'];
            app.DeleteAllResultsButton.BackgroundColor = [0.45 0.07 0.07];   % darker red - the more destructive of the two actions
            app.DeleteAllResultsButton.FontColor = app.ColWhite;
            app.DeleteAllResultsButton.Layout.Row = 3;
            app.DeleteAllResultsButton.Layout.Column = 1;
            app.DeleteAllResultsButton.ButtonPushedFcn = createCallbackFcn(app, @app.DeleteAllResultsButtonPushed, true);

            % --- Footer: citation ------------------------------------------------------
            % TODO: once the Zenodo DOI exists, append it here, e.g.
            %   'MIDAS - Stroh, A. & Moulas, E. (2026). https://doi.org/10.5281/zenodo.XXXXXXX'
            app.CitationLabel = uilabel(app.GridMain);
            app.CitationLabel.Layout.Row = 3;
            app.CitationLabel.Layout.Column = 1;
            app.CitationLabel.HorizontalAlignment = 'center';
            app.CitationLabel.FontSize = 11;
            app.CitationLabel.FontColor = app.ColIndigo;
            app.CitationLabel.Text = 'MIDAS - Stroh, A. & Moulas, E. (2026)';
            app.ThemeLabels(end+1) = app.CitationLabel;

            app.UIFigure.Visible = 'on';
        end

        function NavButtonPushed(app, key)
            fn = fieldnames(app.SectionPanels);
            for i = 1:numel(fn)
                app.SectionPanels.(fn{i}).Visible = strcmp(fn{i}, key);
            end
            for i = 1:numel(app.NavButtons)
                btn = app.NavButtons(i);
                if strcmp(app.NavButtonKeys{i}, key)
                    btn.BackgroundColor = app.ColGold;
                    btn.FontColor = app.ColIndigo;
                    btn.FontWeight = 'bold';
                else
                    btn.BackgroundColor = app.ColIndigo;
                    btn.FontColor = app.ColLavender;
                    btn.FontWeight = 'normal';
                end
            end
        end

        function startupFcn(app)
            p = MIDAS_Params();
            % Give outDir a per-run-safe default (same convention Run_MIDAS.m
            % uses) instead of the file's bare '.' - avoids different runs silently
            % overwriting each other's auto-saved output (checkpoints/movie/save_data).
            p.outDir = fullfile('results', [p.data_name, '_', datestr(now,'yyyymmdd_HHMMSS')]);

            app.DefaultParams = p;
            app.populateControlsFromParams(p);

            app.DataFolderField.Value = fullfile(pwd, 'exported_data');
            app.DataBaseField.Value   = 'midas_results';
            app.FigFolderField.Value  = fullfile(pwd, 'exported_figures');
            app.FigBaseField.Value    = 'midas_fig';

            app.refreshResultsList();
        end

        function populateControlsFromParams(app, p)
            for k = 1:numel(app.FieldMeta)
                f = app.FieldMeta(k);
                if ~isfield(p, f.name)
                    continue   % tolerate presets saved before a field existed
                end
                c = app.Ctrl.(f.name);
                val = p.(f.name);
                switch f.type
                    case 'checkbox'
                        c.Value = logical(val);
                    case 'dropdown'
                        if app.isNumericOptions(f.options)
                            c.Value = num2str(val);
                        else
                            c.Value = val;
                        end
                    case 'text'
                        c.Value = val;
                    case 'numeric'
                        % NaN marks a field unused under the current mode
                        % combination (see MIDAS_Params.m) - numeric edit
                        % fields can't hold NaN as their Value, so show 0
                        % as an inert placeholder instead of erroring.
                        if isnan(val)
                            c.Value = 0;
                        else
                            c.Value = val;
                        end
                    case 'vector'
                        for j = 1:f.n
                            if isnan(val(j))
                                c(j).Value = 0;
                            else
                                c(j).Value = val(j);
                            end
                        end
                end
            end
        end

        function params = collectParamsFromControls(app)
            params = app.DefaultParams;   % seed with defaults, then overwrite every field below
            for k = 1:numel(app.FieldMeta)
                f = app.FieldMeta(k);
                c = app.Ctrl.(f.name);
                switch f.type
                    case 'checkbox'
                        params.(f.name) = double(c.Value);
                    case 'dropdown'
                        if app.isNumericOptions(f.options)
                            params.(f.name) = str2double(c.Value);
                        else
                            params.(f.name) = c.Value;
                        end
                    case 'text'
                        params.(f.name) = c.Value;
                    case 'numeric'
                        % Numeric edit fields can't display NaN (see
                        % populateControlsFromParams), so a field that was
                        % NaN in the defaults and still shows its 0
                        % placeholder is read back as NaN, not a literal 0 -
                        % otherwise an inert/unused field (e.g. a poly-mode
                        % fit coefficient while eqMode='PD') would silently
                        % turn into an active zero the moment some other
                        % switch (e.g. a missing phase-diagram file) makes
                        % it start mattering. A field the user has actually
                        % typed a new value into is read back as-is,
                        % including an explicit 0.
                        if c.Value == 0 && isnan(app.DefaultParams.(f.name))
                            params.(f.name) = NaN;
                        else
                            params.(f.name) = c.Value;
                        end
                    case 'vector'
                        vals = arrayfun(@(h) h.Value, c);
                        defVal = app.DefaultParams.(f.name);
                        isPlaceholder = (vals == 0) & isnan(defVal(:))';
                        vals(isPlaceholder) = NaN;
                        params.(f.name) = vals;
                end
            end
        end

        function tf = isNumericOptions(~, options)
            tf = ~isempty(options) && all(~isnan(cellfun(@str2double, options)));
        end

        function issues = validateParams(~, p)
            % Catches parameter combinations that are physically meaningless or
            % would silently degrade the run (e.g. extrapolating the phase
            % diagram lookup), so they're caught before spending time on a run
            % rather than discovered afterwards. Returns a cell array of
            % human-readable problem descriptions (empty = nothing found).
            issues = {};

            if isempty(strtrim(p.data_name))
                issues{end+1} = 'data_name must not be empty (it is used to build the output folder name).';
            end
            % Written as "~(x > 0)"/"~(x >= 2)" rather than "x <= 0"/"x < 2":
            % a NaN silently passes any <=/</>= comparison, so a plain
            % "x <= 0" check would miss it and let garbage straight through
            % to MIDAS_Main. MATLAB's uieditfield(...,'numeric') makes this
            % harder to trigger than in the Octave GUI (whose plain-text
            % fields can't prevent non-numeric input the same way), but the
            % check is free insurance either way.
            if ~(p.lxA > 0)
                issues{end+1} = 'lxA must be > 0 (initial crystal length, mm).';
            end
            if ~(p.lxB_factor > 0)
                issues{end+1} = 'lxB_factor must be > 0.';
            end
            if ~(p.nx_A >= 2) || p.nx_A ~= fix(p.nx_A) || ~(p.nx_B >= 2) || p.nx_B ~= fix(p.nx_B)
                issues{end+1} = 'nx_A and nx_B must each be a whole number >= 2.';
            end
            if ~(p.t_tot > 0)
                issues{end+1} = 't_tot must be > 0 Myr.';
            end
            if ~(p.CFL > 0)
                issues{end+1} = 'CFL must be > 0. CFL=0 hangs the run forever instead of erroring.';
            end
            if any(~([p.DRG, p.DRG_LuHf, p.DRG_Mn, p.DamA, p.DamB] > 0))
                issues{end+1} = 'DRG, DRG_LuHf, DRG_Mn, DamA and DamB must all be > 0.';
            end
            if any([p.Pstart, p.Pstop, p.Ppeak] < 0)
                issues{end+1} = 'Pstart, Pstop and Ppeak cannot be negative (GPa).';
            end
            if p.Trange(1) >= p.Trange(2)
                issues{end+1} = 'Trange(1) must be less than Trange(2).';
            end
            if p.Prange(1) >= p.Prange(2)
                issues{end+1} = 'Prange(1) must be less than Prange(2).';
            end

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
                if p.T_peak_frac < 0 || p.T_peak_frac > 1
                    issues{end+1} = 'T_peak_frac must be between 0 and 1.';
                end
                if p.P_peak_frac < 0 || p.P_peak_frac > 1
                    issues{end+1} = 'P_peak_frac must be between 0 and 1.';
                end
            end
            if any(Tvals < p.Trange(1)) || any(Tvals > p.Trange(2))
                issues{end+1} = 'Tstart/Tstop/Tpeak fall outside Trange - the phase-diagram lookup table will extrapolate.';
            end
            if any(Pvals < p.Prange(1)) || any(Pvals > p.Prange(2))
                issues{end+1} = 'Pstart/Pstop/Ppeak fall outside Prange - the phase-diagram lookup table will extrapolate.';
            end
        end

        function RunButtonPushed(app, ~)
            cleanupObj = onCleanup(@() set(app.RunButton, 'Enable', 'on')); %#ok<NASGU>
            app.RunButton.Enable = 'off';
            drawnow;

            params = app.collectParamsFromControls();

            issues = app.validateParams(params);
            if ~isempty(issues)
                app.logStatus('Cannot run - fix the following first:');
                for i = 1:numel(issues)
                    app.logStatus(['  - ' issues{i}]);
                end
                uialert(app.UIFigure, issues, 'Invalid parameters', 'Icon', 'warning');
                return
            end

            d = uiprogressdlg(app.UIFigure, 'Title', 'MIDAS', 'Message', 'Running simulation...', ...
                'Indeterminate', 'on', 'Cancelable', 'off');
            progressCleanup = onCleanup(@() close(d)); %#ok<NASGU>

            try
                % Fresh, collision-safe outDir every run, regardless of what's
                % currently in the outDir field (same convention as Run_MIDAS.m).
                params.outDir = fullfile('results', [params.data_name, '_', datestr(now,'yyyymmdd_HHMMSS')]);
                app.Ctrl.outDir.Value = params.outDir;

                app.logStatus('Running...');
                t0 = tic;
                R = MIDAS_Main(params);
                app.LastR = R;
                if isfield(R,'stoppedEarly') && R.stoppedEarly
                    app.logStatus(sprintf('Note: run stopped early at t=%.3g Myr (before reaching t_final): %s', R.t_final, R.stopReason));
                end

                % The solver call above has no internal progress hooks, so it
                % ran with an indeterminate spinner; the 8 post-run plots each
                % complete in a bounded, known number of steps, so switch to a
                % real percentage for this part.
                d.Indeterminate = 'off';
                nSteps = 11;
                figs = {};
                tags = {};

                d.Value = 1/nSteps; d.Message = 'Plotting velocity/age...';
                try
                    [figAB, figErr, figRelErr, figErrLog, figRelErrLog, figABOnly] = plot_velocity_age(R);
                    figs(end+1:end+6) = {figAB, figErr, figRelErr, figErrLog, figRelErrLog, figABOnly};
                    tags(end+1:end+6) = {'velocity_age','velocity_age_misfit','velocity_age_relmisfit','velocity_age_misfit_log','velocity_age_relmisfit_log','velocity_age_AB_only'};
                catch ME
                    app.logStatus(['  plot_velocity_age failed: ' ME.message]);
                end

                d.Value = 2/nSteps; d.Message = 'Plotting misfit...';
                try
                    plot_misfit(R);
                    figs{end+1} = gcf; tags{end+1} = 'misfit';
                catch ME
                    app.logStatus(['  plot_misfit failed: ' ME.message]);
                end

                d.Value = 3/nSteps; d.Message = 'Plotting mass balance...';
                try
                    plot_massbalance(R);
                    figs{end+1} = gcf; tags{end+1} = 'massbalance';
                catch ME
                    app.logStatus(['  plot_massbalance failed: ' ME.message]);
                end

                d.Value = 4/nSteps; d.Message = 'Plotting MgO mass drift...';
                try
                    figMgODrift = plot_massbalance_MgO(R);
                    figs{end+1} = figMgODrift; tags{end+1} = 'massbalance_MgO';
                catch ME
                    app.logStatus(['  plot_massbalance_MgO failed: ' ME.message]);
                end

                d.Value = 5/nSteps; d.Message = 'Plotting Lu profile...';
                try
                    plot_Lu_profile(R);
                    figs{end+1} = gcf; tags{end+1} = 'Lu_profile';
                catch ME
                    app.logStatus(['  plot_Lu_profile failed: ' ME.message]);
                end

                d.Value = 6/nSteps; d.Message = 'Plotting Mn profile...';
                try
                    plot_Mn_profile(R);
                    figs{end+1} = gcf; tags{end+1} = 'Mn_profile';
                catch ME
                    app.logStatus(['  plot_Mn_profile failed: ' ME.message]);
                end

                d.Value = 7/nSteps; d.Message = 'Plotting age at fixed positions...';
                try
                    figAge = plot_age_at_fixed_positions(R);
                    figs{end+1} = figAge; tags{end+1} = 'age_fixed_positions';
                catch ME
                    app.logStatus(['  plot_age_at_fixed_positions failed: ' ME.message]);
                end

                d.Value = 8/nSteps; d.Message = 'Plotting concentration at fixed positions...';
                try
                    figConc = plot_conc_at_fixed_positions(R);
                    figs{end+1} = figConc; tags{end+1} = 'conc_fixed_positions';
                catch ME
                    app.logStatus(['  plot_conc_at_fixed_positions failed: ' ME.message]);
                end

                d.Value = 9/nSteps; d.Message = 'Plotting all composition profiles...';
                try
                    figAllComp = plot_all_composition_profiles(R);
                    figs{end+1} = figAllComp; tags{end+1} = 'all_composition_profiles';
                catch ME
                    app.logStatus(['  plot_all_composition_profiles failed: ' ME.message]);
                end

                d.Value = 10/nSteps; d.Message = 'Plotting age vs temperature...';
                try
                    figAgeT = plot_age_vs_temperature(R);
                    figs{end+1} = figAgeT; tags{end+1} = 'age_vs_temperature';
                catch ME
                    app.logStatus(['  plot_age_vs_temperature failed: ' ME.message]);
                end

                d.Value = 11/nSteps; d.Message = 'Plotting initial conditions...';
                try
                    figInit = plot_initial_conditions(R);
                    figs{end+1} = figInit; tags{end+1} = 'initial_conditions';
                catch ME
                    app.logStatus(['  plot_initial_conditions failed: ' ME.message]);
                end

                app.LastFigs = figs;
                app.LastFigTags = tags;

                % Point the export panels at this run's own output folder by
                % default (still user-editable before clicking Export).
                app.DataFolderField.Value = R.params.outDir;
                app.FigFolderField.Value  = R.params.outDir;
                app.refreshResultsList();

                app.logStatus(sprintf('Done in %.1f s (%d/16 figures).', toc(t0), numel(figs)));
            catch ME
                app.logStatus(['ERROR: ' ME.message]);
            end
        end

        function ResetButtonPushed(app, ~)
            app.populateControlsFromParams(app.DefaultParams);
            app.logStatus('Reset to defaults.');
        end

        function SavePresetButtonPushed(app, ~)
            params = app.collectParamsFromControls(); %#ok<NASGU>
            presetsDir = fullfile(pwd, 'presets');
            if ~exist(presetsDir, 'dir')
                mkdir(presetsDir);
            end
            defaultName = [app.Ctrl.data_name.Value '_preset.mat'];
            [file, folder] = uiputfile('*.mat', 'Save parameter preset', fullfile(presetsDir, defaultName));
            if isequal(file, 0)
                return   % user cancelled
            end
            save(fullfile(folder, file), 'params');
            app.logStatus(['Saved preset ' fullfile(folder, file)]);
        end

        function LoadPresetButtonPushed(app, ~)
            presetsDir = fullfile(pwd, 'presets');
            if ~exist(presetsDir, 'dir')
                presetsDir = pwd;
            end
            [file, folder] = uigetfile('*.mat', 'Load parameter preset', presetsDir);
            if isequal(file, 0)
                return   % user cancelled
            end
            S = load(fullfile(folder, file));
            if ~isfield(S, 'params') || ~isstruct(S.params)
                app.logStatus(['ERROR: ' file ' does not contain a ''params'' struct - not a MIDAS preset file.']);
                return
            end
            app.populateControlsFromParams(S.params);
            app.logStatus(['Loaded preset ' fullfile(folder, file)]);
        end

        function LoadExampleButtonPushed(app, ~)
            choice = app.ExampleDropDown.Value;
            if strcmp(choice, 'MIDAS_Params (default)')
                fname = 'MIDAS_Params';
            else
                fname = ['MIDAS_Params_' choice];
            end
            if ~(exist(fname, 'file') == 2)
                app.logStatus(['ERROR: ' fname '.m not found on the path.']);
                return
            end
            exParams = feval(fname);
            app.populateControlsFromParams(exParams);
            app.logStatus(['Loaded ' fname '() - every field above is still freely editable before you Run.']);
        end

        function ThemeToggleButtonPushed(app, ~)
            app.IsDarkMode = ~app.IsDarkMode;
            app.applyTheme();
        end

        function applyTheme(app)
            % Re-colors every tracked component (populated during
            % createComponents) between the light and dark palettes, and
            % swaps the logo image. Individual input controls (edit
            % fields/dropdowns/checkboxes) are deliberately left at their
            % OS-default light rendering in both modes - MATLAB's uifigure
            % Theme API (which would restyle those too) only exists from
            % R2022b, while this app targets R2019b+.
            if app.IsDarkMode
                bg = app.DarkBg; panelBg = app.DarkPanel; text = app.DarkText;
                logoFile = 'midas_logo_horizontal_dark.png';
                app.ThemeToggle.Text = [char(9728) '  Light'];
            else
                bg = app.ColBg; panelBg = app.ColWhite; text = app.ColIndigo;
                logoFile = 'midas_logo_horizontal.png';
                app.ThemeToggle.Text = [char(9789) '  Dark'];
            end

            app.UIFigure.Color = bg;
            for h = app.ThemeBgAreas
                if isvalid(h), h.BackgroundColor = bg; end
            end
            for h = app.ThemePanels
                if isvalid(h)
                    h.BackgroundColor = panelBg;
                    h.ForegroundColor = text;
                end
            end
            for h = app.ThemeLabels
                if isvalid(h), h.FontColor = text; end
            end

            assetsDir = fullfile(fileparts(mfilename('fullpath')), 'assets');
            logoPath = fullfile(assetsDir, logoFile);
            if isfile(logoPath) && isvalid(app.LogoImage)
                app.LogoImage.ImageSource = logoPath;
            end
        end

        function ExportDataButtonPushed(app, ~)
            if isempty(app.LastR)
                app.logStatus('Nothing to export yet - run a calculation first.');
                return
            end
            folder = app.DataFolderField.Value;
            base   = app.DataBaseField.Value;
            if isempty(base)
                app.logStatus('Please enter a base filename for the exported data.');
                return
            end
            if ~exist(folder, 'dir')
                mkdir(folder);
            end

            didSomething = false;
            if app.MatCheckBox.Value
                R = app.LastR; %#ok<NASGU>
                save(fullfile(folder, [base '.mat']), 'R');
                app.logStatus(['Saved ' fullfile(folder, [base '.mat'])]);
                didSomething = true;
            end
            if app.XlsxCheckBox.Value
                export_results_excel(app.LastR, fullfile(folder, [base '.xlsx']));
                app.logStatus(['Saved ' fullfile(folder, [base '.xlsx'])]);
                didSomething = true;
            end
            if ~didSomething
                app.logStatus('Check .mat and/or .xlsx to export data.');
            end
        end

        function ExportFiguresButtonPushed(app, ~)
            if isempty(app.LastFigs)
                app.logStatus('No figures to export yet - run a calculation first.');
                return
            end
            folder = app.FigFolderField.Value;
            base   = app.FigBaseField.Value;
            if isempty(base)
                app.logStatus('Please enter a base filename for the exported figures.');
                return
            end
            if ~exist(folder, 'dir')
                mkdir(folder);
            end

            n = 0;
            for i = 1:numel(app.LastFigs)
                fig = app.LastFigs{i};
                if isempty(fig) || ~isvalid(fig)
                    continue
                end
                export_pub_fig(fig, fullfile(folder, sprintf('%s_%s', base, app.LastFigTags{i})));
                n = n + 1;
            end
            app.logStatus(sprintf('Exported %d figure(s) (PDF + 300dpi JPG) to %s', n, folder));
        end

        function BrowseDataButtonPushed(app, ~)
            folder = uigetdir(app.DataFolderField.Value, 'Choose export folder for data');
            if ischar(folder)
                app.DataFolderField.Value = folder;
            end
        end

        function BrowseFigButtonPushed(app, ~)
            folder = uigetdir(app.FigFolderField.Value, 'Choose export folder for figures');
            if ischar(folder)
                app.FigFolderField.Value = folder;
            end
        end

        function d = resultsRootDir(~)
            % Same 'results' folder every run writes into (see startupFcn/
            % RunButtonPushed: outDir = fullfile('results', data_name_timestamp)).
            d = fullfile(pwd, 'results');
        end

        function refreshResultsList(app)
            root = app.resultsRootDir();
            names = {};
            if exist(root, 'dir')
                listing = dir(root);
                listing = listing([listing.isdir]);
                names = setdiff({listing.name}, {'.','..'});
            end
            if isempty(names)
                app.ResultsListDropDown.Items = {'(no saved results)'};
                app.ResultsListDropDown.Enable = 'off';
                app.DeleteResultButton.Enable = 'off';
                app.DeleteAllResultsButton.Enable = 'off';
            else
                app.ResultsListDropDown.Items = sort(names);
                app.ResultsListDropDown.Value = app.ResultsListDropDown.Items{1};
                app.ResultsListDropDown.Enable = 'on';
                app.DeleteResultButton.Enable = 'on';
                app.DeleteAllResultsButton.Enable = 'on';
            end
        end

        function RefreshResultsButtonPushed(app, ~)
            app.refreshResultsList();
            items = app.ResultsListDropDown.Items;
            if numel(items) == 1 && strcmp(items{1}, '(no saved results)')
                n = 0;
            else
                n = numel(items);
            end
            app.logStatus(sprintf('Results list refreshed (%d folder(s)).', n));
        end

        function DeleteResultButtonPushed(app, ~)
            sel = app.ResultsListDropDown.Value;
            if isempty(sel) || strcmp(sel, '(no saved results)')
                return
            end
            target = fullfile(app.resultsRootDir(), sel);
            choice = uiconfirm(app.UIFigure, ...
                sprintf('Delete result folder "%s" and everything in it?\nThis cannot be undone.', sel), ...
                'Delete result', 'Options', {'Delete','Cancel'}, ...
                'DefaultOption', 'Cancel', 'CancelOption', 'Cancel', 'Icon', 'warning');
            if ~strcmp(choice, 'Delete')
                return
            end
            try
                rmdir(target, 's');
                app.logStatus(['Deleted ' target]);
            catch ME
                app.logStatus(['ERROR deleting ' target ': ' ME.message]);
            end
            app.refreshResultsList();
        end

        function DeleteAllResultsButtonPushed(app, ~)
            root = app.resultsRootDir();
            items = app.ResultsListDropDown.Items;
            if isempty(items) || strcmp(items{1}, '(no saved results)')
                return
            end
            choice = uiconfirm(app.UIFigure, ...
                sprintf('Delete ALL %d saved result folder(s) under:\n%s\nThis cannot be undone.', numel(items), root), ...
                'Delete ALL results', 'Options', {'Delete all','Cancel'}, ...
                'DefaultOption', 'Cancel', 'CancelOption', 'Cancel', 'Icon', 'warning');
            if ~strcmp(choice, 'Delete all')
                return
            end
            try
                rmdir(root, 's');
                mkdir(root);
                app.logStatus(['Deleted all result folders under ' root]);
            catch ME
                app.logStatus(['ERROR deleting results: ' ME.message]);
            end
            app.refreshResultsList();
        end

        function logStatus(app, msg)
            app.StatusArea.Value = [app.StatusArea.Value; {char(msg)}];
            drawnow;
            try
                scroll(app.StatusArea, 'bottom');
            catch
            end
        end
    end
end
