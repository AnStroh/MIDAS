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
% a .mat file instead.
%
% Octave port: xlsx read/write needs the 'io' package (pkg install -forge
% io; pkg load io). If it isn't installed/working, this falls back to
% writing one .csv file per sheet next to filepath instead of failing.
%
% Usage:
%   export_results_excel(R, fullfile(folder,'results.xlsx'))
%
% Authors: Annalena Stroh, Evangelos Moulas
% JGU, Mainz, 2026
%==========================================================================
if exist('OCTAVE_VERSION','builtin')
    try
        pkg load io
    catch
        % Handled per-write below via the try/catch around writecell/writetable.
    end
end

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
    writeSheetOrCsv([{'Field','Value'}; summaryRows], filepath, 'Summary', 'cell')
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
    varNames = localMakeValidUniqueNames(groupNames);

    sheetName = sprintf('profile_n%d', L);
    if numel(sheetName) > 31
        sheetName = sheetName(1:31);
    end
    writeSheetOrCsv([varNames; num2cell(Mdata)], filepath, sheetName, 'cell')
end
end

function writeSheetOrCsv(dataCell, filepath, sheetName, ~)
% Writes one sheet to the .xlsx at filepath. If that fails (io package
% missing/broken - common on a bare Octave install), falls back to a
% single .csv named <filepath-without-ext>_<sheetName>.csv so the data is
% never silently dropped.
try
    writecell(dataCell, filepath, 'Sheet', sheetName);
catch ME
    [folder, base, ~] = fileparts(filepath);
    csvPath = fullfile(folder, [base '_' sheetName '.csv']);
    fprintf('Note: writing xlsx sheet ''%s'' failed (%s).\n  -> falling back to %s\n', ...
        sheetName, ME.message, csvPath);
    writeCellAsCsv(dataCell, csvPath);
end
end

function writeCellAsCsv(dataCell, csvPath)
% Minimal, dependency-free CSV writer for a 2-D cell array of char/numeric
% entries (header row + data rows) - used only as the xlsx fallback above.
fid = fopen(csvPath, 'w');
if fid < 0
    error('export_results_excel:CsvWriteFailed', 'Could not open %s for writing.', csvPath);
end
for i = 1:size(dataCell,1)
    rowStrs = cell(1, size(dataCell,2));
    for j = 1:size(dataCell,2)
        v = dataCell{i,j};
        if ischar(v)
            rowStrs{j} = v;
        else
            rowStrs{j} = num2str(v);
        end
    end
    fprintf(fid, '%s\n', strjoin(rowStrs, ','));
end
fclose(fid);
end

function uniqueNames = localMakeValidUniqueNames(names)
% Octave has no matlab.lang.makeValidName/makeUniqueStrings equivalent, so
% this reimplements just what's needed here: sanitize each name into a
% valid table/variable-style identifier, then de-duplicate by appending
% _2, _3, ... to any repeats (first occurrence keeps its plain name).
validNames = cell(size(names));
for i = 1:numel(names)
    s = names{i};
    s(~(isletter(s) | (s>='0' & s<='9') | s=='_')) = '_';   % sanitize
    if isempty(s) || ~isletter(s(1))
        s = ['x' s]; %#ok<AGROW>
    end
    validNames{i} = s;
end

uniqueNames = cell(size(validNames));
seenCount = containers.Map('KeyType','char','ValueType','double');
for i = 1:numel(validNames)
    s = validNames{i};
    if isKey(seenCount, s)
        seenCount(s) = seenCount(s) + 1;
        uniqueNames{i} = sprintf('%s_%d', s, seenCount(s));
    else
        seenCount(s) = 1;
        uniqueNames{i} = s;
    end
end
end
