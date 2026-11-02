%% =========================================================================
% STEP4A_BANDPOWER_ROI
% MAIN_DATASET_MARCO_BANDPOWER_STEP4
%% =========================================================================
%
% PROJECT
% -------
% X-SONANCE EEG
%
%
% PURPOSE
% -------
% Band-limited oscillatory power analysis using:
%
%   Band-pass filtering
%   +
%   Hilbert Transform
%
% Power is estimated at single-trial level and subsequently
% averaged across ROI channels and trials.
%
%
% =========================================================================
% PROCESSING PIPELINE
% =========================================================================
%
% Trial
%   ↓
% Channel
%   ↓
% Band-pass filtering
%   ↓
% Hilbert Transform
%   ↓
% Instantaneous Power
%       abs(H).^2
%   ↓
% Baseline correction
%   ↓
% ROI averaging
%   ↓
% Trial averaging
%   ↓
% Subject band-power waveform
%   ↓
% Group band-power waveform
%
%
% =========================================================================
% OUTPUT
% =========================================================================
%
% Per ogni ROI viene salvato un file separato:
%
%   BANDPOWER_STEP4A_RESULTS_<nomeroi>.mat
%
% contenente:
%   - BandPower_Subj_ROI   (solo ROI corrente)
%   - BandPower_Group_ROI  (solo ROI corrente)
%   - roiName
%   - QC
%   - cfgBP
%
%% =========================================================================
clear
close all
clc
origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');
set(groot,...
    'defaultTextInterpreter','tex');
set(groot,...
    'defaultAxesTickLabelInterpreter','tex');
set(groot,...
    'defaultLegendInterpreter','tex');
% addpath('C:\Users\mirco\Desktop\eeglab2026.1.0')
% eeglab nogui
%% ============================================================
% LOAD STEP2 DATA
%% ============================================================
step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';
if ~exist(step2_indir,'dir')
    error('STEP2 folder not found');
end
%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
step4_outroot = ...
    fullfile( ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO',...
    'STEP4A_BANDPOWER');
if ~exist(step4_outroot,'dir')
    mkdir(step4_outroot);
end
%% =========================================================================
% LOAD
%% =========================================================================
load(fullfile(step2_indir,'subj_list.mat'));
assert(~isempty(subj_list), ...
    'subj_list is empty.')
%% ============================================================
% DATASET SUMMARY
%% ============================================================
num_trials = cellfun( ...
    @(x) numel(x), ...
    {subj_list.data_trials});
total_trials = sum(num_trials);
%% ============================================================
% CONFIGURATION
%% ============================================================
cfgBP = struct();
comparisonName = 'Consonance';
cfgBP.conditions = { ...
    'Consonant',...
    'Dissonant'};
cfgBP.cond_field = 'eventLabel';
cfgBP.time_field = 'time';
cfgBP.baseline_win = [-0.2 0];
cfgBP.target_time_units = 's';
%% ============================================================
% FREQUENCY BANDS
%% ============================================================
cfgBP.bands = struct();
cfgBP.bands.Delta     = [1 4];
cfgBP.bands.Theta     = [4 8];
cfgBP.bands.Alpha     = [8 13];
cfgBP.bands.BetaLow   = [13 20];
cfgBP.bands.BetaHigh  = [20 30];
cfgBP.bands.GammaLow  = [30 40];
cfgBP.bands.GammaHigh = [40 90];
% cfgBP.normalization = 'none';
% cfgBP.normalization = 'subtract';
% cfgBP.normalization = 'relative';
cfgBP.normalization = 'db';
%% ============================================================
% ROI DEFINITIONS
%% ============================================================
MAIN_ROI
cfgBP.rois = ROI;
cfgBP.analysis_rois = {
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};

% ERAN_CORE,...
%     'MMN',...
%     'FrontoCentral',...
%     'N5_CENTRAL',...
%     'Occipital',...
%     'Parietal'};
% roiNames = fieldnames(cfgBP.rois);
roiNames = cfgBP.analysis_rois;
bandNames = fieldnames(cfgBP.bands);
%% ============================================================
% QUALITY CHECK
%% ============================================================
QC = struct();
QC.nSubjects = numel(subj_list);
QC.totalTrials = total_trials;
QC.trialsPerSubject = num_trials;
QC.comparisonName = comparisonName;
QC.conditions = cfgBP.conditions;
QC.baselineWindow = cfgBP.baseline_win;
QC.normalization = cfgBP.normalization;
QC.timeUnits = cfgBP.target_time_units;
QC.roiNames = roiNames;
QC.nROI = numel(roiNames);
QC.bandDefinitions = cfgBP.bands;
QC.bandNames = bandNames;
QC.nBands = numel(bandNames);
QC.conditionCounts = struct();
for c = 1:numel(cfgBP.conditions)
    condName = cfgBP.conditions{c};
    nCond = 0;
    for iSub = 1:numel(subj_list)
        cond_values = ...
            string({subj_list(iSub).data_trials.(cfgBP.cond_field)});
        nCond = ...
            nCond + ...
            sum(strcmpi(cond_values,condName));
    end
    QC.conditionCounts.( ...
        matlab.lang.makeValidName(condName)) = ...
        nCond;
end
fprintf('\n');
fprintf('================================\n');
fprintf('BAND POWER CONFIGURATION\n');
fprintf('================================\n');
fprintf('Conditions :\n');
for iCond = 1:numel(cfgBP.conditions)
    fprintf('   %s\n', ...
        cfgBP.conditions{iCond});
end
fprintf('Subjects   : %d\n', ...
    QC.nSubjects);
fprintf('Trials     : %d\n', ...
    QC.totalTrials);
fprintf('ROIs       : %d\n', ...
    QC.nROI);
fprintf('Bands      : %d\n', ...
    QC.nBands);
fprintf('Normalization : %s\n', ...
    cfgBP.normalization);
%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
outdir = ...
    fullfile( ...
    step4_outroot,...
    comparisonName);
if ~exist(outdir,'dir')
    mkdir(outdir);
end
%% ============================================================
% SUBJECT + GROUP LEVEL ANALYSIS PER ROI
% Salvataggio separato, una sola ROI per file
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT + GROUP LEVEL BAND POWER\n');
fprintf('================================\n');

for r = 1:numel(roiNames)
    roiName = roiNames{r};

    fprintf('\n');
    fprintf('================================\n');
    fprintf('ROI: %s\n',roiName);
    fprintf('================================\n');

    % --- Inizializza struct temporanee per la ROI corrente ---
    BandPower_Subj_ROI = struct();
    BandPower_Group_ROI = struct();

    % --- SUBJECT LEVEL ---
    for iSub = 1:numel(subj_list)
        subj_curr = subj_list(iSub);
        subjID = matlab.lang.makeValidName(char(subj_curr.subj_id));

        fprintf('\n[%02d/%02d] Subject: %s\n', ...
            iSub,numel(subj_list),subjID);

        for b = 1:numel(bandNames)
            bandName = bandNames{b};

            cfgCurr = cfgBP;
            cfgCurr.roi_labels = cfgBP.rois.(roiName);
            cfgCurr.band = cfgBP.bands.(bandName);
            cfgCurr.band_name = bandName;

            roi_bp = extract_roi_bandpower(subj_curr,cfgCurr);

            BandPower_Subj_ROI.(subjID).(roiName).(bandName) = roi_bp;

            fprintf('   %s | %s OK\n',roiName,bandName);
        end
    end

    % --- GROUP LEVEL ---
    for b = 1:numel(bandNames)
        bandName = bandNames{b};

        fprintf('%s | %s\n',roiName,bandName);

        BandPower_Group_ROI.(roiName).(bandName) = ...
            average_group_bandpower( ...
            BandPower_Subj_ROI, ...
            roiName, ...
            bandName);
    end

    % --- SALVATAGGIO DOPO OGNI ROI ---
    outdir_roi = fullfile(step4_outroot,comparisonName,roiName);
    if ~exist(outdir_roi,'dir')
        mkdir(outdir_roi);
    end

    save(fullfile(outdir_roi, ...
        sprintf('BANDPOWER_STEP4A_RESULTS_%s.mat',roiName)), ...
        'BandPower_Subj_ROI', ...
        'BandPower_Group_ROI', ...
        'roiName', ...
        'QC', ...
        'cfgBP', ...
        '-v7.3');

    fprintf('\nSalvato risultato ROI: %s\n',roiName);
    fprintf('File: BANDPOWER_STEP4A_RESULTS_%s.mat\n',roiName);

    % --- Pulizia per la prossima ROI ---
    clear BandPower_Subj_ROI BandPower_Group_ROI

end % fine loop ROI
%% ============================================================
% RESTORE FIGURE SETTINGS
%% ============================================================
close all
set(0,'DefaultFigureVisible',origState);
fprintf('\n');
fprintf('================================\n');
fprintf('STEP4 BAND POWER COMPLETED\n');
fprintf('================================\n');