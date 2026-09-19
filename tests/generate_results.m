function generate_results(label)
% GENERATE_RESULTS  Runs all six MIDAS examples (reduced grid, for speed -
% this checks cross-implementation numerical agreement, not physical
% accuracy, so full resolution isn't needed) and saves each run's full
% result struct to tests/results/, one .mat per (folder, example) pair.
% compare_results.m then diffs these across matlab/, GUI/, and octave/.
%
% Run with the target folder (matlab/, GUI/, or octave/) as the working
% directory, and LABEL matching that folder's name - deliberately NOT
% inferred from pwd here: both MATLAB's and Octave's run() change the
% working directory to the called script's own folder for the duration of
% the call, which would silently pick up "tests" instead. Use addpath, not
% run(), so the working directory stays put:
%   cd matlab                                                  % or GUI, or octave
%   matlab -batch "addpath('../tests'); generate_results('matlab')"
%   octave --eval "addpath('../tests'); generate_results('octave')"
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
outDir = fullfile('..', 'tests', 'results');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
addpath('examples', 'plotting', 'export');

exampleFns = {'Example1_Baseline', 'Example2_PolyEquilibrium', ...
              'Example3_ThermalBump', 'Example4_ManualPartitioning', ...
              'Example5_PlanarGeometry', 'Example6_CylindricalGeometry'};

fprintf('Generating reference results for "%s" -> %s\n', label, outDir);
for k = 1:numel(exampleFns)
    fname = exampleFns{k};
    fprintf('  %s ... ', fname);
    params = feval(fname);
    % Same reduced settings as .github/scripts/smoke_test.m - fast, but
    % still exercises the full solver + every mode switch.
    params.doPlot = false; params.make_movie = false; params.save_data = false;
    params.store_history = true; params.t_tot = 1; params.nx_A = 15; params.nx_B = 15;
    tmpOut = tempname(); mkdir(tmpOut); params.outDir = tmpOut;

    R = MIDAS_Main(params); %#ok<NASGU>
    outFile = fullfile(outDir, sprintf('%s_%s.mat', label, fname));
    % '-mat' forces MATLAB-compatible binary format explicitly: Octave's
    % save() otherwise defaults to its own text format for .mat files,
    % which MATLAB's load() cannot read - this file needs to be loadable
    % from whichever of MATLAB/Octave later runs compare_results.m.
    save(outFile, 'R', '-mat');
    fprintf('saved %s\n', outFile);
end
fprintf('Done. Run compare_results.m once you have results from 2+ implementations.\n');
end
