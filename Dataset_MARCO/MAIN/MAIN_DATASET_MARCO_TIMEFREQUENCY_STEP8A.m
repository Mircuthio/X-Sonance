%% =========================================================================
% MAIN_DATASET_MARCO_TIMEFREQUENCY_STEP8A
%
% PROJECT
% -------
% X-SONANCE EEG
%
%
% PURPOSE
% -------
% Time-Frequency analysis of EEG responses using spectrogram-based
% decomposition.
%
%
% =========================================================================
% PIPELINE
% =========================================================================
%
% subj_list
%     ↓
% ROI Selection
%
%     ↓
% Condition Selection
%
%         Consonant
%         Dissonant
%
%     ↓
% Time-Frequency Transform
%
%     ↓
% Baseline Correction
%
%     ↓
% Subject Average
%
%     ↓
% Group Average
%
%     ↓
% Time-Frequency Maps
%
%         Consonant
%         Dissonant
%         Difference
%
%     ↓
% Plot
%
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgTF = struct();

%% ------------------------------------------------------------
% CONDITIONS
%% ------------------------------------------------------------

cfgTF.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgTF.eventField = ...
    'eventLabel';

%% ------------------------------------------------------------
% TIME
%% ------------------------------------------------------------

cfgTF.timeField = ...
    'time';

cfgTF.baseline_win = ...
    [-0.2 0];

%% ------------------------------------------------------------
% TIME-FREQUENCY METHOD
%% ------------------------------------------------------------

cfgTF.method = ...
    'spectrogram';

cfgTF.window_length = 32;

cfgTF.overlap = 16;

cfgTF.nfft = 64;

%% ------------------------------------------------------------
% FREQUENCIES
%% ------------------------------------------------------------

cfgTF.fmin = 1;

cfgTF.fmax = 90;

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

cfgTF.rois = ROI;

cfgTF.analysis_rois = { ...
    'Generic',...
    'ERAN',...
    'ERAN_RIGHT',...
    'ERAN_CORE',...
    'MMN',...
    'N5'};

roiNames = ...
    cfgTF.analysis_rois;

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'STEP8A_TIMEFREQUENCY');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% INITIALIZE OUTPUT
%% ============================================================

TF_Subj = struct();

TF_Group = struct();

%% ============================================================
% SUBJECT LEVEL ANALYSIS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL TIME-FREQUENCY\n');
fprintf('================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = ...
        subj_list(iSub);

    subjID = ...
        matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    fprintf('\n');
    fprintf('[%02d/%02d] Subject: %s\n',...
        iSub,...
        numel(subj_list),...
        subjID);

    for r = 1:numel(roiNames)

        roiName = ...
            roiNames{r};

        fprintf('   ROI: %s\n', ...
            roiName);

        cfgCurr = cfgTF;

        cfgCurr.roi_labels = ...
            cfgTF.rois.(roiName);

        TF_Subj.(subjID).(roiName) = ...
            extract_roi_timefrequency( ...
            subj_curr,...
            cfgCurr);

    end

end

%% ============================================================
% GROUP LEVEL ANALYSIS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL TIME-FREQUENCY\n');
fprintf('================================\n');

for r = 1:numel(roiNames)

    roiName = ...
        roiNames{r};

    fprintf('%s\n', ...
        roiName);

    TF_Group.(roiName) = ...
        average_group_timefrequency( ...
        TF_Subj,...
        roiName);

end

%% ============================================================
% PLOT
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('PLOT TIME-FREQUENCY\n');
fprintf('================================\n');

for r = 1:numel(roiNames)

    roiName = ...
        roiNames{r};

    plot_timefrequency( ...
        TF_Group.(roiName),...
        roiName,...
        outdir);

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'STEP8A_TIMEFREQUENCY.mat'),...
    'TF_Subj',...
    'TF_Group',...
    'cfgTF',...
    '-v7.3');

%% ============================================================
% END
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP8A TIME-FREQUENCY COMPLETED\n');
fprintf('================================\n');