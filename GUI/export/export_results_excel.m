function export_results_excel(R, filepath)
% EXPORT_RESULTS_EXCEL  Write the scalar/summary data of a MIDAS_Main
% result struct R to an Excel file: one 'Summary' sheet of every scalar (and
% text) field on R, plus one sheet per group of same-length numeric vector
% fields (e.g. every profile field sharing phase A's node count lands
% together in one sheet, phase B's in another, recorded time-series fields
% in another).
%
% Deliberately excludes R.params and the full 2-D time-history arrays (e.g.
% R.CArec, R.xArec - [nTimesteps x nNodes], not vector/sheet-shaped and
% often large). For full-fidelity export including those, save R itself to
% .mat instead (see MIDAS's Export Data panel).
%
% Usage:
%   export_results_excel(R, fullfile(folder,'results.xlsx'))
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if exist(filepath, 'file')
    delete(filepath);   % writetable/writecell add sheets to an existing file otherwise
end

fn = fieldnames(R);

% --- Summary sheet: every scalar/text field --------------------------------
summaryRows = cell(0, 2);
for k = 1:numel(fn)
    name = fn{k};
    if strcmp(name, 'params'), continue; end
    val = R.(name);
    if isscalar(val) && (isnumeric(val) || islogical(val))
        summaryRows(end+1,:) = {name, double(val)}; %#ok<AGROW>
    elseif ischar(val) || isstring(val)
        summaryRows(end+1,:) = {name, char(val)}; %#ok<AGROW>
    end
end
if ~isempty(summaryRows)
    writecell([{'Field','Value'}; summaryRows], filepath, 'Sheet', 'Summary');
end

% --- Vector-field sheets: group same-length numeric vectors -----------------
lengths = [];
names   = {};
for k = 1:numel(fn)
    name = fn{k};
    if strcmp(name, 'params'), continue; end
    val = R.(name);
    if isnumeric(val) && isvector(val) && numel(val) > 1
        lengths(end+1) = numel(val); %#ok<AGROW>
        names{end+1}   = name;       %#ok<AGROW>
    end
end

uniqueLengths = unique(lengths);
for iLen = 1:numel(uniqueLengths)
    L = uniqueLengths(iLen);
    groupNames = names(lengths == L);
    if isempty(groupNames)
        continue
    end
    cols = cell(1, numel(groupNames));
    for j = 1:numel(groupNames)
        cols{j} = R.(groupNames{j})(:);
    end
    Mdata = [cols{:}];
    varNames = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(groupNames));
    T = array2table(Mdata, 'VariableNames', varNames);

    sheetName = sprintf('profile_n%d', L);
    if numel(sheetName) > 31
        sheetName = sheetName(1:31);
    end
    writetable(T, filepath, 'Sheet', sheetName);
end
end
