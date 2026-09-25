%% MAIN_BUILD_CLASSIFICATION_TABLE_WITH_SUBEPOCHS
% Scans recursively all MAT files under rootDir and creates a table with:
% - Results_LOSO.QDA.MeanBalancedAccuracy
% - Results_LOSO.QDA.StdBalancedAccuracy
% - cfgFBCSP.csp_components
% - cfgFBCSP.mi_k
% - cfgFBCSP.time_window
% - cfgFBCSP.filterBankName
% - cfgFBCSP.useSubEpochs
% - cfgFBCSP.subEpochLength
% - cfgFBCSP.subEpochOverlap
% - file and folder information

clear; clc;

%% Select root folder
%% Select root folder
% rootDir = uigetdir(pwd, 'Select the root folder containing classification results');

rootDir = 'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\STEP9_FBCSP_TRIALWISE\PART1';
if isequal(rootDir, 0)
    error('No folder selected.');
end

%% Find MAT files recursively
matFiles = dir(fullfile(rootDir, '**', '*.mat'));

if isempty(matFiles)
    error('No MAT files found under: %s', rootDir);
end

fprintf('Found %d MAT files.\n', numel(matFiles));

%% Preallocate variables
nFiles = numel(matFiles);

FileName       = strings(nFiles, 1);
RelativeFolder = strings(nFiles, 1);
FullPath       = strings(nFiles, 1);
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

%% Load and extract information
for iFile = 1:nFiles
    matPath = fullfile(matFiles(iFile).folder, matFiles(iFile).name);

    FileName(iFile) = string(matFiles(iFile).name);
    FullPath(iFile) = string(matPath);

    relativeFolder = erase(string(matFiles(iFile).folder), string(rootDir));
    relativeFolder = erase(relativeFolder, filesep);
    RelativeFolder(iFile) = relativeFolder;

    try
        % Load the variables of interest into a structure.
        S = load(matPath, 'Results_LOSO', 'cfgFBCSP');

        %% Classification results
        if isfield(S, 'Results_LOSO') && ...
                isfield(S.Results_LOSO, 'QDA')

            qda = S.Results_LOSO.QDA;

            if isfield(qda, 'MeanBalancedAccuracy')
                MeanBalancedAccuracy(iFile) = ...
                    scalarValue(qda.MeanBalancedAccuracy);
            end

            if isfield(qda, 'StdBalancedAccuracy')
                StdBalancedAccuracy(iFile) = ...
                    scalarValue(qda.StdBalancedAccuracy);
            end
        end

        %% FBCSP and subepoch configuration
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
                FilterBankName(iFile) = ...
                    stringValue(cfg.filterBankName);
            end

            % Subepoch variables
            if isfield(cfg, 'useSubEpochs')
                UseSubEpochs(iFile) = ...
                    scalarValue(cfg.useSubEpochs);
            end

            if isfield(cfg, 'subEpochLength')
                SubEpochLength(iFile) = ...
                    scalarValue(cfg.subEpochLength);
            end

            if isfield(cfg, 'subEpochOverlap')
                SubEpochOverlap(iFile) = ...
                    scalarValue(cfg.subEpochOverlap);
            end
        end

        Status(iFile) = "OK";

    catch ME
        Status(iFile) = "ERROR: " + string(ME.message);
        warning('Could not process %s: %s', matPath, ME.message);
    end
end

%% Create output table
ResultsTable = table(...
    FileName, RelativeFolder, FullPath, ...
    MeanBalancedAccuracy, StdBalancedAccuracy, ...
    CSPComponents, MI_k, ...
    TimeWindowStart, TimeWindowEnd, ...
    FilterBankName, ...
    UseSubEpochs, SubEpochLength, SubEpochOverlap, ...
    Status);

%% Add a combined time-window column
ResultsTable.TimeWindow = compose('[%.4f %.4f]', ...
    ResultsTable.TimeWindowStart, ...
    ResultsTable.TimeWindowEnd);

ResultsTable = movevars(ResultsTable, 'TimeWindow', ...
    'Before', 'TimeWindowStart');

%% Display and save results
fprintf('\nResults table:\n');
disp(ResultsTable);

outputMat = fullfile(rootDir, ...
    'ClassificationResults_Summary.mat');
outputCsv = fullfile(rootDir, ...
    'ClassificationResults_Summary.csv');

save(outputMat, 'ResultsTable', 'rootDir');
writetable(ResultsTable, outputCsv);

fprintf('\nSaved MAT file: %s\n', outputMat);
fprintf('Saved CSV file: %s\n', outputCsv);

%% Local helper functions
function value = scalarValue(x)
    % Converts scalar numeric/logical/cell/string values to double.
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
    % Converts a numeric vector or text representation to a row vector.
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
    % Converts text-like values to a MATLAB string.
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