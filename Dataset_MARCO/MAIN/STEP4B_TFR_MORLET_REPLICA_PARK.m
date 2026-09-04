%% =========================================================================
% STEP4B_TFR_MORLET_REPLICA_PARK
%% =========================================================================
%
% PROJECT
% -------
% X-SONANCE EEG
%
%
% PURPOSE
% -------
% Targeted Time-Frequency replication of:
%
% Park et al. (2011)
%
% "Consonant chords stimulate higher EEG gamma activity
% than dissonant chords"
%
% The analysis focuses on induced gamma-band activity
% and reproduces the main methodological choices used
% to investigate consonance-related oscillatory effects.
%
%
% =========================================================================
% ANALYSIS GOAL
% =========================================================================
%
% Evaluate whether consonant musical chords elicit
% stronger gamma-band activity than dissonant chords.
%
%
% Experimental Conditions
%
%     Consonant
%     Dissonant
%
%
% =========================================================================
% PROCESSING PIPELINE
% =========================================================================
%
% Trial
%   ↓
% ROI channels
%   ↓
% Morlet Wavelet Transform
%   ↓
% Power = |Z|²
%   ↓
% Baseline correction
%   ↓
% Trial averaging
%   ↓
% Subject TFR
%   ↓
% Group TFR
%
%
% =========================================================================
% ROI STRATEGIES
% =========================================================================
%
% CHANNEL-FIRST
%
%     Wavelet decomposition is performed separately
%     for each channel and power is averaged within ROI.
%
%     Advantages:
%         - preserves channel-specific oscillatory activity
%         - minimizes phase-cancellation effects
%         - recommended approach
%
%
% ROI-FIRST
%
%     EEG channels are averaged before wavelet analysis.
%
%     Advantages:
%         - simpler implementation
%         - useful for methodological comparison
%         - potentially closer to historical approaches
%
%
% =========================================================================
% CURRENT IMPLEMENTATION
% =========================================================================
%
% Method:
%
%     channel_first
%
%
% =========================================================================
% PARK REPLICATION PARAMETERS
% =========================================================================
%
% Frequency Range:
%
%     30-60 Hz
%
%
% Statistical Window:
%
%     100-250 ms
%
%
% Baseline:
%
%     -200 ms to -50 ms
%
%
% =========================================================================
% OUTPUTS
% =========================================================================
%
% Subject-Level
%
%     TFR_Subj
%
%
% Group-Level
%
%     TFR_Group
%
%
% Replication Metrics
%
%     Consonant Gamma Power
%     Dissonant Gamma Power
%     Difference Gamma Power
%
%
% Figures
%
%     Consonant TFR
%     Dissonant TFR
%     Difference TFR
%
%     Gamma Time Courses
%
%
% =========================================================================
% RELATION TO OTHER STEPS
% =========================================================================
%
% STEP3_ERP
%
%     Event-related potentials
%
%
% STEP4_BANDPOWER
%
%     Band-limited power envelopes
%
%
% STEP4_TFR_MORLET
%
%     Full-spectrum TFR analysis (1-90 Hz)
%
%
% STEP4_TFR_MORLET_REPLICA_PARK
%
%     Targeted Park et al. replication
%
% =========================================================================
% =========================================================================
% ANALYSIS STRATEGIES
% =========================================================================
%
% Two alternative ROI implementations are supported.
%
% -------------------------------------------------------------------------
% METHOD 1 : CHANNEL-FIRST (OFFICIAL ANALYSIS)
% -------------------------------------------------------------------------
%
% This is the primary pipeline used for all scientific analyses.
%
% Processing:
%
% Trial
%   ↓
% Each ROI channel separately
%   ↓
% Morlet Wavelet Transform
%   ↓
% Power = |Z|²
%   ↓
% Baseline correction
%   ↓
% Average power across ROI channels
%   ↓
% Average power across trials
%   ↓
% Subject TFR
%   ↓
% Group TFR
%
% Advantages:
%
% - Preserves channel-specific oscillatory activity
% - Avoids signal cancellation before TFR estimation
% - Standard approach in modern EEG TFR analyses
% - Recommended for publication-quality analyses
%
%
% -------------------------------------------------------------------------
% METHOD 2 : ROI-FIRST (PARK-STYLE REPLICA)
% -------------------------------------------------------------------------
%
% Implemented separately for methodological comparison.
%
% Processing:
%
% Trial
%   ↓
% Average EEG channels within ROI
%   ↓
% Single ROI signal
%   ↓
% Morlet Wavelet Transform
%   ↓
% Power = |Z|²
%   ↓
% Baseline correction
%   ↓
% Average power across trials
%
% Notes:
%
% - Computationally simpler
% - May reduce oscillatory activity if channels are
%   not perfectly phase aligned
% - Potentially closer to the original Park et al.
%   implementation, although the paper does not
%   explicitly report the exact ROI processing order.
%
%
% =========================================================================
% CURRENT IMPLEMENTATION
% =========================================================================
%
% cfgTFR.method = 'channel_first'
%
% The project currently uses METHOD 1.
%
%
% =========================================================================
% STEP4 OBJECTIVES
% =========================================================================
%
% Generate:
%
% 1) Subject-level induced gamma TFR
% 2) Group-level induced gamma TFR
% 3) Consonant Time-Frequency Maps
% 4) Dissonant Time-Frequency Maps
% 5) Mean Gamma Time Courses
%
%
% =========================================================================
% STEP5 CONNECTION
% =========================================================================
%
% Outputs generated here will be used by STEP5
% for replication of Figure 3.
%
% Planned statistical window:
%
% Frequency:
%   30-60 Hz
%
% Time:
%   100-250 ms
%
%
% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

addpath(genpath('D:\eeglab2026.0.0\'))

set(groot,...
    'defaultTextInterpreter','tex');
set(groot,...
    'defaultAxesTickLabelInterpreter','tex');
set(groot,...
    'defaultLegendInterpreter','tex');

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
step4_outroot = ...
    fullfile( ...
    'D:\X-SONANCE\Dataset_MARCO',...
    'STEP4B_TFR_MORLET');

if ~exist(step4_outroot,'dir')
    mkdir(step4_outroot);
end
%% ============================================================
% LOAD DATA
%% ============================================================
step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

% Time check
time0 = subj_list(1).data_trials(1).time;

for i = 1:numel(subj_list)
    t = subj_list(i).data_trials(1).time;
    assert(isequal(size(t),size(time0)), ...
        'Time vector size mismatch');
end
% Frequency check
Fs_all = zeros(numel(subj_list),1);
for i = 1:numel(subj_list)
    Fs_all(i) = ...
        subj_list(i).data_trials(1).srate;
end
assert(numel(unique(Fs_all))==1,...
    'Sampling rates differ across subjects');
fprintf('\n');
fprintf('=====================================\n');
fprintf('LOAD COMPLETED\n');
fprintf('Subjects : %d\n',numel(subj_list));
fprintf('Fs       : %.1f Hz\n',Fs_all(1));
fprintf('=====================================\n');


%% ============================================================
% REPLICA PARK
%% ============================================================

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgTFR = struct();

cfgTFR.method = 'roi_first';

% available:
% 'channel_first' - channels time-frequency and mean
% 'roi_first' - mean on channels before

cfgTFR.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgTFR.cond_field = 'eventLabel';

cfgTFR.freqs = 30:1:60;

cfgTFR.nCycles = 7;

cfgTFR.baseline_win = [-0.2 -0.05];

cfgTFR.save_trial_level = false;

cfgTFR.srate = Fs_all(1);

cfgTFR.time = time0;
%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI_TFR

cfgTFR.rois = ParkROI;

roiNames = fieldnames(cfgTFR.rois);

fprintf('\n');
fprintf('=====================================\n');
fprintf('ROI CONFIGURATION\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    fprintf('%02d) %s\n', ...
        r,...
        roiNames{r});

    disp(cfgTFR.rois.(roiNames{r})')

end
%% ============================================================
% OUTPUT FOLDER
%% ============================================================

parkdir = fullfile( ...
    step4_outroot,...
    'PARK_TFR_STEP4',...
    cfgTFR.method);

if ~exist(parkdir,'dir')
    mkdir(parkdir);
end

fprintf('\n');
fprintf('Output folder:\n');
fprintf('%s\n',parkdir);

%% ============================================================
% INITIALIZE OUTPUT
%% ============================================================

TFR_Subj = struct();
%% ============================================================
% SUBJECT LEVEL TFR
%% ============================================================

fprintf('\n');
fprintf('=====================================\n');
fprintf('SUBJECT LEVEL TFR\n');
fprintf('=====================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);

    subjID = matlab.lang.makeValidName( ...
    char(subj_curr.subj_id));

    fprintf('\n');
    fprintf('-------------------------------------\n');
    fprintf('SUBJECT: %s\n',subjID);
    fprintf('-------------------------------------\n');
    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        fprintf('\n');
        fprintf('ROI : %s\n',roiName);

        cfgROI = cfgTFR;

        cfgROI.roi_labels = ...
            cfgTFR.rois.(roiName);
        roi_tfr = extract_roi_tfr( ...
            subj_curr,...
            cfgROI);
        if isempty(roi_tfr)

            warning('%s | %s empty result',...
                subjID,...
                roiName);

            continue

        end
        TFR_Subj.(subjID).(roiName) = ...
            roi_tfr;
        if isfield(roi_tfr,'Consonant')

            sz = size( ...
                roi_tfr.Consonant.power);

            fprintf( ...
                'Consonant TFR: [%d x %d]\n',...
                sz(1),...
                sz(2));

        end

        if isfield(roi_tfr,'Dissonant')

            sz = size( ...
                roi_tfr.Dissonant.power);

            fprintf( ...
                'Dissonant TFR: [%d x %d]\n',...
                sz(1),...
                sz(2));

        end
    end

end
%% ============================================================
% SANITY CHECK
%% ============================================================

fprintf('\n');
fprintf('=====================================\n');
fprintf('SANITY CHECK\n');
fprintf('=====================================\n');

subjectNames = fieldnames(TFR_Subj);

fprintf('Subjects processed: %d\n', ...
    numel(subjectNames));
%% ============================================================
% GROUP LEVEL TFR
%% ============================================================

TFR_Group = struct();

fprintf('\n');
fprintf('=====================================\n');
fprintf('GROUP LEVEL TFR\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    fprintf('Building ROI: %s\n',roiName);

    TFR_Group.(roiName) = ...
        average_group_tfr( ...
        TFR_Subj,...
        roiName);

end
%% ============================================================
% GLOBAL COLOR LIMITS
%% ============================================================

allPower = [];
allDiff  = [];

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    allPower = [ ...
        allPower ;
        TFR_Group.(roiName).Consonant.power(:) ;
        TFR_Group.(roiName).Dissonant.power(:)];

    allDiff = [ ...
        allDiff ;
        TFR_Group.(roiName).Difference.power(:)];

end

GLOBAL_TFR_MIN = prctile(allPower,2);
GLOBAL_TFR_MAX = prctile(allPower,98);

GLOBAL_DIFF_MAX = ...
    prctile(abs(allDiff),98);

fprintf('\n');
fprintf('=====================================\n');
fprintf('GLOBAL COLOR LIMITS\n');
fprintf('=====================================\n');
fprintf('TFR  : [%.3f %.3f]\n', ...
    GLOBAL_TFR_MIN,...
    GLOBAL_TFR_MAX);

fprintf('DIFF : +/- %.3f\n', ...
    GLOBAL_DIFF_MAX);
fprintf('=====================================\n');
%% ============================================================
% PLOTS
%% ============================================================
for r=1:numel(roiNames)
    roiName = roiNames{r};
    groupData = ...
        TFR_Group.(roiName);

    gammaStats.(roiName) = ...
        extract_gamma_window( ...
        TFR_Group.(roiName),...
        [30 60],...
        [0.10 0.25]);
    stats = gammaStats.(roiName);

    fprintf('\n');
    fprintf('=====================================\n');
    fprintf('PARK WINDOW RESULTS\n');
    fprintf('ROI : %s\n',roiName);
    fprintf('Consonant : %.4f dB\n',stats.Consonant);
    fprintf('Dissonant : %.4f dB\n',stats.Dissonant);
    fprintf('Difference: %.4f dB\n',stats.Difference);
    fprintf('=====================================\n');

    diffMap = groupData.Difference.power;

    fprintf('\n');
    fprintf('ROI: %s\n',roiName);
    fprintf('Mean Difference: %.4f dB\n', ...
        mean(diffMap(:)));
    figure

    subplot(3,1,1)

    imagesc( ...
        groupData.time,...
        groupData.freq,...
        groupData.Consonant.power)

    axis xy
    colorbar
        clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])

    title(sprintf('%s - Consonant',format_tex_name(roiName)))

    subplot(3,1,2)

    imagesc( ...
        groupData.time,...
        groupData.freq,...
        groupData.Dissonant.power)

    axis xy
    colorbar
    clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])

    title(sprintf('%s - Dissonant',format_tex_name(roiName)))

    subplot(3,1,3)

    imagesc( ...
        groupData.time,...
        groupData.freq,...
        diffMap)

    axis xy
    colorbar
        clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])

    title(sprintf('%s - Difference',format_tex_name(roiName)))
    saveas( ...
        gcf,...
        fullfile( ...
        parkdir,...
        sprintf('TFR_Group_%s.png',roiName)));
    close
    gammaConTime = ...
        mean(groupData.Consonant.power,1);
    gammaDisTime = ...
        mean(groupData.Dissonant.power,1);
    gammaDiffTime = ...
        mean(groupData.Difference.power,1);
    gammaStats.(roiName).TimeCourse.time = ...
    groupData.time;
    gammaStats.(roiName).TimeCourse.Consonant = ...
        gammaConTime;
    gammaStats.(roiName).TimeCourse.Dissonant = ...
        gammaDisTime;
    gammaStats.(roiName).TimeCourse.Difference = ...
        gammaDiffTime;

    figure
    plot(groupData.time,...
        gammaConTime,...
        'LineWidth',2)
    hold on
    plot(groupData.time,...
        gammaDisTime,...
        'LineWidth',2)
    plot(groupData.time,...
        gammaDiffTime,...
        'k--',...
        'LineWidth',2)

    xline(0,'k')
    legend( ...
        'Consonant',...
        'Dissonant',...
        'Difference');
    xlabel('Time (s)')
    ylabel('Power (dB)')
    title(sprintf('Gamma Time Course - %s',format_tex_name(roiName)))
    saveas( ...
        gcf,...
        fullfile( ...
        parkdir,...
        sprintf('GammaTimeCourse_%s.png',roiName)));
    close
end
%% ============================================================
% SAVE
%% ============================================================
assert(~isempty(fieldnames(TFR_Subj)), ...
    'No subject results generated');
save( ...
    fullfile( ...
    parkdir,...
    'STEP4B_TFR_MORLET_REPLICA_PARK_RESULTS.mat'),...
    'TFR_Subj',...
    'TFR_Group',...
    'gammaStats',...
    'cfgTFR',...
    'ParkROI',...
    '-v7.3');

fprintf('\n');
fprintf('=====================================\n');
fprintf('STEP4B REPLICA PARK SUBJECT LEVEL SAVED\n');
fprintf('=====================================\n');

set(0,'DefaultFigureVisible',origState);