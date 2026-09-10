function [ResultsTable, ResultsStruct] = ...
    collect_fbcsp_trialwise_results(rootDir, outputFile)

% COLLECT_FBCSP_TRIALWISE_RESULTS
%
% Scans all case folders recursively, loads .mat result files,
% and extracts TRIALWISE classifier summaries into a table and struct array.
%
% INPUT
%   rootDir    : root folder containing case result folders
%   outputFile : optional output .mat filename
%
% OUTPUT
%   ResultsTable  : one row per case/classifier
%   ResultsStruct : struct array equivalent of ResultsTable
%
% Expected structure:
%
% rootDir/
%   PART1/
%       FULL_CD/
%           FULL_CD.mat
%       MMN_LATE_CD/
%           MMN_LATE_CD.mat
%   PART2/
%       FULL_CCD/
%           FULL_CCD.mat
%
% Expected variables inside each MAT file:
%   Results_TrialWise
%   cfgFBCSP
%   CaseCfg

if nargin < 1 || isempty(rootDir)
    error('rootDir must be specified.');
end

if nargin < 2
    outputFile = '';
end

if ~isfolder(rootDir)
    error('Root folder does not exist: %s', rootDir);
end

%% ============================================================
% FIND MAT FILES
%% ============================================================

matFiles = dir(fullfile(rootDir, '**', '*.mat'));

if isempty(matFiles)
    warning('No MAT files found under: %s', rootDir);

    ResultsStruct = struct([]);
    ResultsTable = table();
    return
end

%% ============================================================
% INITIALIZE
%% ============================================================

ResultsStruct = struct([]);

resultCounter = 0;

%% ============================================================
% SCAN FILES
%% ============================================================

for iFile = 1:numel(matFiles)

    filePath = fullfile(matFiles(iFile).folder, matFiles(iFile).name);

    try
        loadedData = load(filePath);

        if ~isfield(loadedData, 'Results_TrialWise')
            warning('Skipped file without Results_TrialWise: %s', filePath);
            continue
        end

        Results_TrialWise = loadedData.Results_TrialWise;

        if isfield(loadedData, 'CaseCfg')
            CaseCfg = loadedData.CaseCfg;
        else
            CaseCfg = struct();
        end

        if isfield(loadedData, 'cfgFBCSP')
            cfgFBCSP = loadedData.cfgFBCSP;
        else
            cfgFBCSP = struct();
        end

        %% ----------------------------------------------------
        % CASE INFORMATION
        %% ----------------------------------------------------

        [~, caseNameFromFile, ~] = fileparts(matFiles(iFile).name);

        [~, caseFolderName] = fileparts(matFiles(iFile).folder);

        parentFolder = fileparts(matFiles(iFile).folder);
        [~, groupName] = fileparts(parentFolder);

        if isfield(CaseCfg, 'name') && ~isempty(CaseCfg.name)
            caseName = CaseCfg.name;
        else
            caseName = caseNameFromFile;
        end

        if isfield(CaseCfg, 'group') && ~isempty(CaseCfg.group)
            group = CaseCfg.group;
        else
            group = groupName;
        end

        %% ----------------------------------------------------
        % TIME WINDOW
        %% ----------------------------------------------------

        timeWindow = [];

        if isfield(cfgFBCSP, 'time_window')
            timeWindow = cfgFBCSP.time_window;
        elseif isfield(CaseCfg, 'time_window')
            timeWindow = CaseCfg.time_window;
        end

        if numel(timeWindow) >= 2
            timeStart = timeWindow(1);
            timeEnd = timeWindow(2);
        else
            timeStart = NaN;
            timeEnd = NaN;
        end

        %% ----------------------------------------------------
        % CLASS INFORMATION
        %% ----------------------------------------------------

        classLabels = {};
        classCodes = [];

        if isfield(cfgFBCSP, 'class_labels')
            classLabels = cfgFBCSP.class_labels;
        elseif isfield(CaseCfg, 'class_labels')
            classLabels = CaseCfg.class_labels;
        end

        if isfield(cfgFBCSP, 'class_codes')
            classCodes = cfgFBCSP.class_codes;
        elseif isfield(CaseCfg, 'class_codes')
            classCodes = CaseCfg.class_codes;
        end

        nClasses = numel(classLabels);

        %% ----------------------------------------------------
        % CLASSIFIERS
        %% ----------------------------------------------------

        classifierNames = fieldnames(Results_TrialWise);

        for iClassifier = 1:numel(classifierNames)

            classifierName = classifierNames{iClassifier};

            % Skip non-classifier metadata fields if present
            classifierResult = Results_TrialWise.(classifierName);

            if ~isstruct(classifierResult)
                continue
            end

            requiredFields = { ...
                'MeanAccuracy', ...
                'StdAccuracy'};

            hasRequiredFields = all( ...
                isfield(classifierResult, requiredFields));

            if ~hasRequiredFields
                continue
            end

            %% ------------------------------------------------
            % EXTRACT METRICS
            %% ------------------------------------------------

            resultCounter = resultCounter + 1;

            ResultsStruct(resultCounter).filePath = filePath;
            ResultsStruct(resultCounter).fileName = matFiles(iFile).name;
            ResultsStruct(resultCounter).caseFolder = caseFolderName;
            ResultsStruct(resultCounter).group = group;
            ResultsStruct(resultCounter).caseName = caseName;
            ResultsStruct(resultCounter).classifier = classifierName;

            ResultsStruct(resultCounter).timeWindow = timeWindow;
            ResultsStruct(resultCounter).timeStart = timeStart;
            ResultsStruct(resultCounter).timeEnd = timeEnd;

            ResultsStruct(resultCounter).classLabels = classLabels;
            ResultsStruct(resultCounter).classCodes = classCodes;
            ResultsStruct(resultCounter).nClasses = nClasses;

            ResultsStruct(resultCounter).MeanAccuracy = ...
                classifierResult.MeanAccuracy;

            ResultsStruct(resultCounter).StdAccuracy = ...
                classifierResult.StdAccuracy;

            if isfield(classifierResult, 'MeanBalancedAccuracy')
                ResultsStruct(resultCounter).MeanBalancedAccuracy = ...
                    classifierResult.MeanBalancedAccuracy;
            else
                ResultsStruct(resultCounter).MeanBalancedAccuracy = NaN;
            end

            if isfield(classifierResult, 'StdBalancedAccuracy')
                ResultsStruct(resultCounter).StdBalancedAccuracy = ...
                    classifierResult.StdBalancedAccuracy;
            else
                ResultsStruct(resultCounter).StdBalancedAccuracy = NaN;
            end

            if isfield(classifierResult, 'MeanF1')
                ResultsStruct(resultCounter).MeanF1 = ...
                    classifierResult.MeanF1;
            else
                ResultsStruct(resultCounter).MeanF1 = NaN;
            end

            if isfield(classifierResult, 'StdF1')
                ResultsStruct(resultCounter).StdF1 = ...
                    classifierResult.StdF1;
            else
                ResultsStruct(resultCounter).StdF1 = NaN;
            end

            if isfield(classifierResult, 'MeanMCC')
                ResultsStruct(resultCounter).MeanMCC = ...
                    classifierResult.MeanMCC;
            else
                ResultsStruct(resultCounter).MeanMCC = NaN;
            end

            if isfield(classifierResult, 'StdMCC')
                ResultsStruct(resultCounter).StdMCC = ...
                    classifierResult.StdMCC;
            else
                ResultsStruct(resultCounter).StdMCC = NaN;
            end

        end

    catch ME
        warning( ...
            'Could not process file:\n%s\nReason: %s', ...
            filePath, ME.message);
    end
end

%% ============================================================
% CONVERT TO TABLE
%% ============================================================

if isempty(ResultsStruct)
    ResultsTable = table();
    warning('No valid TRIALWISE results were extracted.');
    return
end

ResultsTable = struct2table(ResultsStruct);

%% ============================================================
% SORT TABLE
%% ============================================================

sortVariables = {'group','caseName','classifier'};

existingSortVariables = ...
    sortVariables(ismember(sortVariables, ResultsTable.Properties.VariableNames));

if ~isempty(existingSortVariables)
    ResultsTable = sortrows(ResultsTable, existingSortVariables);
end

%% ============================================================
% SAVE
%% ============================================================

if ~isempty(outputFile)

    save(outputFile, ...
        'ResultsTable', ...
        'ResultsStruct', ...
        '-v7.3');

    fprintf('\n');
    fprintf('Results saved to:\n%s\n', outputFile);
end

%% ============================================================
% DISPLAY
%% ============================================================

fprintf('\n');
fprintf('============================================\n');
fprintf('TRIALWISE RESULTS SUMMARY\n');
fprintf('============================================\n');
fprintf('Files scanned : %d\n', numel(matFiles));
fprintf('Rows extracted: %d\n', height(ResultsTable));

disp(ResultsTable(:, { ...
    'group', ...
    'caseName', ...
    'classifier', ...
    'timeStart', ...
    'timeEnd', ...
    'MeanAccuracy', ...
    'StdAccuracy', ...
    'MeanBalancedAccuracy', ...
    'StdBalancedAccuracy'}));

end