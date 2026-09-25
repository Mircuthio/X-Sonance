%% MAIN_BUILD_CLASSIFICATION_TABLE_UNIFIED
% Recursively scans all .mat files below rootDir and creates one summary
% table. Results can be stored in either:
%   - Results_LOSO.QDA
%   - Results_TrialWise.QDA
%
% If both structures exist in a MAT file, LOSO is given priority and the
% source is reported in the ResultType column.
%
% Extracted result fields:
%   MeanBalancedAccuracy, StdBalancedAccuracy
%
% Extracted cfgFBCSP fields:
%   csp_components, mi_k, time_window, filterBankName,
%   useSubEpochs, subEpochLength, subEpochOverlap

clear; clc;

%% Select root folder
% rootDir = uigetdir(pwd, 'Select the root folder containing classification results');

rootDir = 'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\STEP10B_ERP_INFORMED_LOSO\ERP_INFORMED';
if isequal(rootDir, 0)
    error('No folder selected.');
end


%% Locate every MAT file recursively
matFiles = dir(fullfile(rootDir, '**', '*.mat'));

% Avoid reading the summary file created by a previous execution.
summaryNames = [ ...
    "ClassificationResults_Summary.mat", ...
    "ClassificationResults_Summary_Unified.mat"];
matFiles = matFiles(~ismember(string({matFiles.name}), summaryNames));

if isempty(matFiles)
    error('No input MAT files were found under: %s', rootDir);
end

nFiles = numel(matFiles);
fprintf('Found %d input MAT file(s).\n', nFiles);

%% Preallocate output columns
FileName       = strings(nFiles, 1);
RelativeFolder = strings(nFiles, 1);
FullPath       = strings(nFiles, 1);
ResultType     = strings(nFiles, 1);
Status         = strings(nFiles, 1);

MeanBalancedAccuracy = nan(nFiles, 1);
StdBalancedAccuracy  = nan(nFiles, 1);

CSPComponents = nan(nFiles, 1);
MI_k          = nan(nFiles, 1);

TimeWindowStart = nan(nFiles, 1);
TimeWindowEnd   = nan(nFiles, 1);
FilterBankName  = strings(nFiles, 1);

UseSubEpochs    = nan(nFiles, 1);
SubEpochLength  = nan(nFiles, 1);
SubEpochOverlap = nan(nFiles, 1);

%% Process files
for iFile = 1:nFiles
    matPath = fullfile(matFiles(iFile).folder, matFiles(iFile).name);

    FileName(iFile) = string(matFiles(iFile).name);
    FullPath(iFile) = string(matPath);
    RelativeFolder(iFile) = getRelativeFolder(matFiles(iFile).folder, rootDir);

    try
        % Loading into S preserves the current workspace and permits isfield.
        % Loading the whole file is deliberately used because the available
        % result variable changes between Results_LOSO and Results_TrialWise.
        S = load(matPath);

        %% Identify the result structure
        % Priority: Results_LOSO > Results_TrialWise.
        resultStruct = [];

        if isfield(S, 'Results_LOSO') && isstruct(S.Results_LOSO)
            resultStruct = S.Results_LOSO;
            ResultType(iFile) = "LOSO";
        elseif isfield(S, 'Results_TrialWise') && isstruct(S.Results_TrialWise)
            resultStruct = S.Results_TrialWise;
            ResultType(iFile) = "TrialWise";
        else
            ResultType(iFile) = "NotFound";
        end

        %% Extract QDA metrics from the detected result structure
        if ~isempty(resultStruct) && isfield(resultStruct, 'QDA') && ...
                isstruct(resultStruct.QDA)

            qda = resultStruct.QDA;

            if isfield(qda, 'MeanBalancedAccuracy')
                MeanBalancedAccuracy(iFile) = ...
                    scalarValue(qda.MeanBalancedAccuracy);
            end

            if isfield(qda, 'StdBalancedAccuracy')
                StdBalancedAccuracy(iFile) = ...
                    scalarValue(qda.StdBalancedAccuracy);
            end
        end

        %% Extract cfgFBCSP parameters
        if isfield(S, 'cfgFBCSP') && isstruct(S.cfgFBCSP)
            cfg = S.cfgFBCSP;

            if isfield(cfg, 'csp_components')
                CSPComponents(iFile) = scalarValue(cfg.csp_components);
            end

            if isfield(cfg, 'mi_k')
                MI_k(iFile) = scalarValue(cfg.mi_k);
            end

            if isfield(cfg, 'time_window')
                timeWindow = numericVector(cfg.time_window);
                if numel(timeWindow) >= 1
                    TimeWindowStart(iFile) = timeWindow(1);
                end
                if numel(timeWindow) >= 2
                    TimeWindowEnd(iFile) = timeWindow(2);
                end
            end

            if isfield(cfg, 'filterBankName')
                FilterBankName(iFile) = stringValue(cfg.filterBankName);
            end

            if isfield(cfg, 'useSubEpochs')
                UseSubEpochs(iFile) = scalarValue(cfg.useSubEpochs);
            end

            if isfield(cfg, 'subEpochLength')
                SubEpochLength(iFile) = scalarValue(cfg.subEpochLength);
            end

            if isfield(cfg, 'subEpochOverlap')
                SubEpochOverlap(iFile) = scalarValue(cfg.subEpochOverlap);
            end
        end

        if ResultType(iFile) == "NotFound"
            Status(iFile) = "WARNING: Results_LOSO and Results_TrialWise not found";
        elseif isnan(MeanBalancedAccuracy(iFile)) && ...
                isnan(StdBalancedAccuracy(iFile))
            Status(iFile) = "WARNING: " + ResultType(iFile) + ...
                ".QDA accuracy fields not found";
        else
            Status(iFile) = "OK";
        end

    catch ME
        ResultType(iFile) = "ERROR";
        Status(iFile) = "ERROR: " + string(ME.message);
        warning('Could not process:\n%s\n%s', matPath, ME.message);
    end
end

%% Build output table
ResultsTable = table( ...
    FileName, RelativeFolder, FullPath, ResultType, ...
    MeanBalancedAccuracy, StdBalancedAccuracy, ...
    CSPComponents, MI_k, ...
    TimeWindowStart, TimeWindowEnd, FilterBankName, ...
    UseSubEpochs, SubEpochLength, SubEpochOverlap, Status);

% Convenient display/export representation of the analysis time window.
ResultsTable.TimeWindow = compose('[%.4f %.4f]', ...
    ResultsTable.TimeWindowStart, ResultsTable.TimeWindowEnd);
ResultsTable = movevars(ResultsTable, 'TimeWindow', 'Before', 'TimeWindowStart');

%% Save table
outputMat = fullfile(rootDir, 'ClassificationResults_Summary_Unified.mat');
outputCsv = fullfile(rootDir, 'ClassificationResults_Summary_Unified.csv');

save(outputMat, 'ResultsTable', 'rootDir');
writetable(ResultsTable, outputCsv);

fprintf('\nSummary preview:\n');
disp(ResultsTable);

fprintf('\nSaved MAT summary:\n%s\n', outputMat);
fprintf('Saved CSV summary:\n%s\n', outputCsv);

%% Local functions
function value = scalarValue(x)
    % Return the first value as double; unavailable/non-numeric values -> NaN.
    if iscell(x)
        if isempty(x)
            value = NaN;
            return;
        end
        x = x{1};
    end

    if isstring(x) || ischar(x)
        x = str2double(string(x));
    end

    if isnumeric(x) || islogical(x)
        x = x(:);
        if isempty(x)
            value = NaN;
        else
            value = double(x(1));
        end
    else
        value = NaN;
    end
end

function value = numericVector(x)
    if iscell(x)
        if isempty(x)
            value = [];
            return;
        end
        x = x{1};
    end

    if isnumeric(x) || islogical(x)
        value = double(x(:)).';
    elseif isstring(x) || ischar(x)
        value = str2num(char(x)); %#ok<ST2NM>
    else
        value = [];
    end
end

function value = stringValue(x)
    if iscell(x)
        if isempty(x)
            value = string(missing);
            return;
        end
        x = x{1};
    end

    if isstring(x) || ischar(x) || iscategorical(x)
        value = string(x);
    else
        value = string(missing);
    end
end

function relativeFolder = getRelativeFolder(currentFolder, rootFolder)
    % Return a portable relative folder representation.
    currentFolder = string(currentFolder);
    rootFolder = string(rootFolder);

    if currentFolder == rootFolder
        relativeFolder = ".";
        return;
    end

    prefix = rootFolder + filesep;
    if startsWith(currentFolder, prefix)
        relativeFolder = extractAfter(currentFolder, strlength(prefix));
    else
        relativeFolder = currentFolder;
    end
end