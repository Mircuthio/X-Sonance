%% =========================================================================
% STEP4A_BANDPOWER
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
% RATIONALE
% =========================================================================
%
% This pipeline complements:
%
% STEP3
%   Event-Related Potentials (ERP)
%
%
% STEP4A_BANDPOWER
% Band-specific power envelopes
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
% EEG FREQUENCY BANDS
% =========================================================================
%
% Delta
%   1 - 4 Hz
%
% Theta
%   4 - 8 Hz
%
% Alpha
%   8 - 13 Hz
%
% Beta Low
%   13 - 20 Hz
%
% Beta High
%   20 - 30 Hz
%
% Gamma Low
%   30 - 40 Hz
%
% Gamma High
%   40 - 90 Hz
%
%
% =========================================================================
% OUTPUTS
% =========================================================================
%
% Subject-Level
%
%   BandPower_Subj
%
%
% Group-Level
%
%   BandPower_Group
%
%
% Figures
%
%   Consonant Power
%   Dissonant Power
%   Difference Wave
%
%
% =========================================================================
% FUTURE STEPS
% =========================================================================
%
% STEP5_BANDPOWER
%
% ROI-window statistics
%
% ERP-like statistical framework applied to band power
%
%
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD STEP2 DATA
%% ============================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA';

if ~exist(step2_indir,'dir')
    error('STEP2 folder not found');
end
%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
step4_outroot = ...
    fullfile( ...
    'D:\X-SONANCE\Dataset_MARCO',...
    'STEP4A_BANDPOWER');

if ~exist(step4_outroot,'dir')
    mkdir(step4_outroot);
end
%% 2) LOAD FILES STEP2
files = dir(fullfile(step2_indir,'*_epochData.mat'));

if isempty(files)
    error('No STEP2 files found');
end

nFiles = numel(files);

subj_list = struct( ...
    'subj_id',cell(nFiles,1), ...
    'data_trials',cell(nFiles,1));

for i = 1:nFiles

    S = load(fullfile( ...
        files(i).folder,...
        files(i).name));

    subjData = S.subjectEpochData;

    subj_list(i).subj_id = ...
        subjData.subjectID;

    subj_list(i).data_trials = ...
        subjData.data_trials;

    fprintf( ...
        '[%02d/%02d] %s loaded\n',...
        i,nFiles,...
        string(subjData.subjectID));

end

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

cfgBP.analysis_rois = { ...
    'ERAN_CORE',...
    'MMN',...
    'FrontoCentral',...
    'N5_CENTRAL'};

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
% TOPOPLOT CONFIGURATION
%% ============================================================
cfgTopo = struct();
cfgTopo.enable = false;
cfgTopo.windows = {

    [0.10 0.25]
    [0.25 0.50]
    [0.50 0.80]

    [0.17 0.22]
    [0.22 0.32]
    [0.45 0.55]

};
cfgTopo.window_names = { ...
    '100_250ms' ...
    '250_500ms' ...
    '500_800ms',...
    'EarlyNeg_170_220ms',...
    'Rebound_220_320ms',...
    'Late_450_550ms'};
cfgTopo.conditions = { ...
    'Consonant',...
    'Dissonant',...
    'Difference'};
cfgTopo.maplimits = 'absmax';
cfgTopo.colormap = turbo;
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

outdir_waveforms = fullfile(outdir,'Waveforms');
if ~exist(outdir_waveforms,'dir')
    mkdir(outdir_waveforms);
end

outdir_topoplots = fullfile(outdir,'Topoplots');
if ~exist(outdir_topoplots,'dir')
    mkdir(outdir_topoplots);
end
%% ============================================================
% CONFIGURATION
%% ============================================================


%% ============================================================
% INITIALIZE OUTPUT
%% ============================================================
BandPower_Subj = struct();
BandPower_Group = struct();
BandPower_Channel = struct();
BandPower_Channel_Group = struct();
%% ============================================================
% SUBJECT LEVEL ANALYSIS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL BAND POWER\n');
fprintf('================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);

    subjID = matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    fprintf('\n');
    fprintf('[%02d/%02d] Subject: %s\n',...
        iSub,...
        numel(subj_list),...
        subjID);

    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        for b = 1:numel(bandNames)

            bandName = bandNames{b};

            cfgCurr = cfgBP;

            cfgCurr.roi_labels = ...
                cfgBP.rois.(roiName);

            cfgCurr.band = ...
                cfgBP.bands.(bandName);

            cfgCurr.band_name = bandName;

            roi_bp = ...
                extract_roi_bandpower( ...
                subj_curr,...
                cfgCurr);

            BandPower_Subj.(subjID) ...
                .(roiName) ...
                .(bandName) = roi_bp;

            fprintf('   %s | %s OK\n', ...
                roiName,...
                bandName);
        end

    end
    % For Topoplot
    % for b = 1:numel(bandNames)
    %     bandName = bandNames{b};
    %     fprintf('   CHANNEL | %s OK\n', ...
    %         bandName);
    %     cfgCurr = cfgBP;
    %     cfgCurr.band = ...
    %         cfgBP.bands.(bandName);
    %     bp_channel = ...
    %         extract_channel_bandpower( ...
    %         subj_curr,...
    %         cfgCurr);
    %     BandPower_Channel.(subjID) ...
    %         .(bandName) = bp_channel;
    % end

end

%% ============================================================
% GROUP LEVEL ANALYSIS
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL BAND POWER\n');
fprintf('================================\n');

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        fprintf('%s | %s\n',roiName,bandName);

        BandPower_Group.(roiName).(bandName) = ...
            average_group_bandpower( ...
            BandPower_Subj,...
            roiName,...
            bandName);

    end
end
%% ============================================================
% GROUP LEVEL CHANNEL ANALYSIS
%% ============================================================

% fprintf('\n');
% fprintf('================================\n');
% fprintf('GROUP LEVEL CHANNEL BAND POWER\n');
% fprintf('================================\n');
% 
% for b = 1:numel(bandNames)
%     bandName = bandNames{b};
%     fprintf('%s\n',bandName);
%     BandPower_Channel_Group.(bandName) = ...
%         average_group_channel_bandpower( ...
%         BandPower_Channel,...
%         bandName);
% end
%% ============================================================
% PLOT
%% ============================================================
cfgPlot = struct();

cfgPlot.plot_window = [-0.2 0.8];
cfgPlot.doLIMO = false;
cfgPlot.alpha = 0.05;

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        plot_bandpower_waveforms( ...
            BandPower_Group.(roiName).(bandName), ...
            roiName,...
            bandName,...
            outdir_waveforms,...
            cfgPlot);
    end
end
%% ============================================================
% TOPOPLOTS
%% ============================================================
if cfgTopo.enable
    for b = 1:numel(bandNames)
        bandName = bandNames{b};
        plot_bandpower_topoplot( ...
            BandPower_Channel_Group.(bandName),...
            bandName,...
            cfgTopo,...
            outdir_topoplots);
    end
end
%% ============================================================
% SAVE
%% ============================================================
close all

set(0,'DefaultFigureVisible',origState);

save( ...
    fullfile(outdir,...
    'BANDPOWER_STEP4A_RESULTS.mat'),...
    'BandPower_Subj',...
    'BandPower_Group',...
    'BandPower_Channel',...
    'BandPower_Channel_Group',...
    'QC', ...
    'cfgBP',...
    'cfgTopo',...
    '-v7.3');

fprintf('\n');
fprintf('================================\n');
fprintf('STEP4 BAND POWER COMPLETED\n');
fprintf('================================\n');