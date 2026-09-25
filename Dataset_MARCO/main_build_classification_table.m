%% MAIN_BUILD_CLASSIFICATION_TABLE
% Scans recursively all MAT files under rootDir and creates a table with:
% - classification results: Results_LOSO.QDA.MeanBalancedAccuracy
%   and Results_LOSO.QDA.StdBalancedAccuracy
% - configuration fields: cfgFBCSP.csp_components, mi_k, time_window,
%   filterBankName
% - file and folder information
%
% The script is robust to missing fields and stores missing values as NaN
% or <missing>.

clear; clc;

%% Select root folder
% rootDir = uigetdir(pwd, 'Select the root folder containing classification results');

rootDir = 'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\STEP9_FBCSP_LOSO\EPOCHED';
if isequal(rootDir, 0)
    error('No folder selected.');
end
%% Find MAT files recursively
matFiles = dir(fullfile(rootDir, '**', '*.mat'));
if isempty(matFiles)
    error('No MAT files found under: %s', rootDir);
end

fprintf('Found %d MAT files.\n', numel(matFiles));

%% Preallocate output variables
nFiles = numel(matFiles);

FileName       = strings(nFiles, 1);
RelativeFolder = strings(nFiles, 1);
FullPath       = strings(nFiles, 1);

MeanBalancedAccuracy = nan(nFiles, 1);
StdBalancedAccuracy  = nan(nFiles, 1);
CSPComponents        = nan(nFiles, 1);
MI_k                 = nan(nFiles, 1);

TimeWindowStart = nan(nFiles, 1);
TimeWindowEnd   = nan(nFiles, 1);
FilterBankName  = strings(nFiles, 1);

Status = strings(nFiles, 1);

%% Load and extract information
for iFile = 1:nFiles
    matPath = fullfile(matFiles(iFile).folder, matFiles(iFile).name);
    FullPath(iFile) = string(matPath);
    FileName(iFile) = string(matFiles(iFile).name);

    relativeFolder = erase(string(matFiles(iFile).folder), string(rootDir));
    relativeFolder = erase(relativeFolder, filesep);
    RelativeFolder(iFile) = relativeFolder;

    try
        % Load only the variables of interest when available.
        S = load(matPath, 'Results_LOSO', 'cfgFBCSP');

        % Classification results
        if isfield(S, 'Results_LOSO') && ...
                isfield(S.Results_LOSO, 'QDA')
            qda = S.Results_LOSO.QDA;

            if isfield(qda, 'MeanBalancedAccuracy')
                MeanBalancedAccuracy(iFile) = scalarValue(qda.MeanBalancedAccuracy);
            end

            if isfield(qda, 'StdBalancedAccuracy')
                StdBalancedAccuracy(iFile) = scalarValue(qda.StdBalancedAccuracy);
            end
        end

        % FBCSP configuration
        if isfield(S, 'cfgFBCSP')
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
        end

        Status(iFile) = "OK";

    catch ME
        Status(iFile) = "ERROR: " + string(ME.message);
        warning('Could not process %s: %s', matPath, ME.message);
    end
end

%% Create table
ResultsTable = table(...
    FileName, RelativeFolder, FullPath, ...
    MeanBalancedAccuracy, StdBalancedAccuracy, ...
    CSPComponents, MI_k, TimeWindowStart, TimeWindowEnd, ...
    FilterBankName, Status);

%% Optional combined time-window column
ResultsTable.TimeWindow = compose('[%.4f %.4f]', ...
    ResultsTable.TimeWindowStart, ResultsTable.TimeWindowEnd);

% Put the combined time window before the separate limits.
ResultsTable = movevars(ResultsTable, 'TimeWindow', ...
    'Before', 'TimeWindowStart');

%% Display and save
fprintf('\nResults table:\n');
disp(ResultsTable);

outputMat = fullfile(rootDir, 'ClassificationResults_Summary.mat');
outputCsv = fullfile(rootDir, 'ClassificationResults_Summary.csv');

save(outputMat, 'ResultsTable', 'rootDir');
writetable(ResultsTable, outputCsv);

fprintf('\nSaved MAT file: %s\n', outputMat);
fprintf('Saved CSV file: %s\n', outputCsv);

%% Local helper functions
function value = scalarValue(x)
    if iscell(x)
        x = x{1};
    end
    if isstring(x) || ischar(x)
        x = str2double(string(x));
    end
    if isnumeric(x) || islogical(x)
        x = x(:);
        if ~isempty(x)
            value = double(x(1));
        else
            value = NaN;
        end
    else
        value = NaN;
    end
end

function value = numericVector(x)
    if iscell(x)
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
        x = x{1};
    end
    if isstring(x) || ischar(x)
        value = string(x);
    elseif iscategorical(x)
        value = string(x);
    else
        value = string(missing);
    end
end