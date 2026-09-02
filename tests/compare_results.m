function compare_results(tol)
% COMPARE_RESULTS  Diffs the result structs saved by generate_results.m
% across whichever of matlab/, GUI/, octave/ have been generated, per
% example, field by field, and reports any relative difference above TOL.
%
% Usage (from tests/, or anywhere with tests/ on the path):
%   compare_results        % MATLAB or Octave; default tol = 1e-12
%   compare_results(1e-9)  % looser tolerance
%
% Caveat on the default 1e-12 tolerance: it is extremely tight - close to
% the scale where accumulated floating-point rounding across a full,
% many-timestep run can differ between platforms even when both
% implementations are mathematically correct. In particular, octave/
% deliberately uses a few not-necessarily-bit-identical-but-mathematically-
% equivalent substitutes for MATLAB-only functions (interp1(...,'extrap')
% for griddedInterpolant; round(x*10^n)/10^n for round(x,n) - see
% octave/README.md "Differences from the MATLAB version"). A handful of
% fields sitting just above 1e-12 does not necessarily mean either
% implementation is wrong; treat this as a sensitive early-warning check,
% and re-run with a looser tolerance (e.g. 1e-9) to separate "expected
% floating-point drift" from an actual divergence.
%
% Only numeric fields are compared (strings/cells - timestamps, file
% paths, mode-switch settings - are skipped; those are validated by
% construction, since all three implementations are run from the exact
% same MIDAS_Params_ExampleN.m inputs).
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if nargin < 1 || isempty(tol)
    tol = 1e-12;
end

resultsDir = fullfile(fileparts(mfilename('fullpath')), 'results');
labels = {'matlab', 'GUI', 'octave'};
exampleFns = {'MIDAS_Params_Example1_Baseline', 'MIDAS_Params_Example2_PolyEquilibrium', ...
              'MIDAS_Params_Example3_ThermalBump', 'MIDAS_Params_Example4_ManualPartitioning', ...
              'MIDAS_Params_Example5_PlanarGeometry', 'MIDAS_Params_Example6_CylindricalGeometry'};

fprintf('Looking for results in %s (tolerance = %.3g)\n\n', resultsDir, tol);

anyFail = false;
anyCompared = false;
for k = 1:numel(exampleFns)
    fname = exampleFns{k};
    present = {};
    for L = 1:numel(labels)
        f = fullfile(resultsDir, sprintf('%s_%s.mat', labels{L}, fname));
        if isfile(f)
            present{end+1} = labels{L}; %#ok<AGROW>
        end
    end
    if numel(present) < 2
        fprintf('=== %s === only %d/3 implementation(s) available (%s) - skipping\n', ...
            fname, numel(present), strjoin(present, ', '));
        continue
    end
    fprintf('=== %s === comparing: %s\n', fname, strjoin(present, ' vs '));
    for a = 1:numel(present)-1
        for b = a+1:numel(present)
            anyCompared = true;
            SA = load(fullfile(resultsDir, sprintf('%s_%s.mat', present{a}, fname)));
            SB = load(fullfile(resultsDir, sprintf('%s_%s.mat', present{b}, fname)));
            report = compareStructs(SA.R, SB.R, 'R', tol, emptyReport());
            nFail = sum(strcmp({report.status}, 'FAIL'));
            nOther = sum(~strcmp({report.status}, 'OK') & ~strcmp({report.status}, 'FAIL'));
            if nFail > 0 || nOther > 0
                anyFail = true;
                fprintf('  %s vs %s: %d field(s) exceed tolerance, %d other issue(s)\n', ...
                    present{a}, present{b}, nFail, nOther);
                for i = 1:numel(report)
                    if ~strcmp(report(i).status, 'OK')
                        if isnan(report(i).maxerr)
                            fprintf('    [%s] %s\n', report(i).status, report(i).field);
                        else
                            fprintf('    [%s] %s  (max rel. diff = %.3g)\n', report(i).status, report(i).field, report(i).maxerr);
                        end
                    end
                end
            else
                fprintf('  %s vs %s: OK (%d numeric field(s) checked)\n', present{a}, present{b}, numel(report));
            end
        end
    end
    fprintf('\n');
end

if ~anyCompared
    fprintf('Nothing to compare yet - run generate_results.m from at least two of matlab/, GUI/, octave/ first.\n');
elseif anyFail
    fprintf('Some fields exceeded tolerance - see above (and the tolerance caveat in this file''s header).\n');
    if exist('exit', 'builtin') || exist('exit', 'file')
        try, exit(1); catch, end
    end
else
    fprintf('All compared fields agree within tolerance.\n');
end
end

function r = emptyReport()
r = struct('field',{}, 'status',{}, 'maxerr',{});
end

function report = compareStructs(A, B, path, tol, report)
fA = fieldnames(A);
fB = fieldnames(B);
allFields = union(fA, fB);
for i = 1:numel(allFields)
    name = allFields{i};
    fpath = [path '.' name];
    if ~isfield(A, name) || ~isfield(B, name)
        report(end+1) = struct('field',fpath, 'status','MISSING_IN_ONE', 'maxerr',NaN); %#ok<AGROW>
        continue
    end
    va = A.(name); vb = B.(name);
    if isstruct(va) && isstruct(vb)
        report = compareStructs(va, vb, fpath, tol, report);
    elseif ischar(va) || ischar(vb) || iscell(va) || iscell(vb) || isstruct(va) ~= isstruct(vb)
        continue   % strings/cells/type-mismatches: not part of this numeric check
    elseif isnumeric(va) && isnumeric(vb) && islogical(va) == islogical(vb)
        if ~isequal(size(va), size(vb))
            report(end+1) = struct('field',fpath, 'status','SIZE_MISMATCH', 'maxerr',NaN); %#ok<AGROW>
            continue
        end
        va = double(va(:)); vb = double(vb(:));
        absdiff = abs(va - vb);
        relerr = absdiff ./ max([abs(va), abs(vb), ones(size(va))], [], 2);
        maxerr = max(relerr);
        if isempty(maxerr), maxerr = 0; end
        if maxerr > tol
            report(end+1) = struct('field',fpath, 'status','FAIL', 'maxerr',maxerr); %#ok<AGROW>
        else
            report(end+1) = struct('field',fpath, 'status','OK', 'maxerr',maxerr); %#ok<AGROW>
        end
    end
end
end
