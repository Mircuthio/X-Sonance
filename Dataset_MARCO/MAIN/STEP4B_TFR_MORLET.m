%% =========================================================================
% % STEP4B_TFR_MORLET
%% =========================================================================
%
% Full-spectrum Morlet Time-Frequency analysis
%
% Frequency range:
% 1-90 Hz
%
% Baseline:
% -200 ms to 0 ms
%
% Summary window:
% 0-800 ms
%
% Outputs:
%     TFR_Subj
%     TFR_Group
%     TFRBandResults
%     Band-specific summaries
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
% CONFIGURATION
%% ============================================================

cfgTFR = struct();

cfgTFR.method = 'channel_first';

% available:
% 'channel_first' - channels time-frequency and mean
% 'roi_first' - mean on channels before

cfgTFR.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgTFR.cond_field = 'eventLabel';

cfgTFR.freqs = 1:3:90; %1:1:90

cfgTFR.nCycles = 7;

cfgTFR.baseline_win = [-0.2 0];

cfgTFR.save_trial_level = false;

cfgTFR.srate = Fs_all(1);

cfgTFR.time = time0;

cfgTFR.summary_windows.Global   = [0.00 0.80];
% global post-stimulus summary window

cfgTFR.summary_windows.EarlyNeg = [0.17 0.22];

cfgTFR.summary_windows.Rebound  = [0.22 0.32];

cfgTFR.summary_windows.Late     = [0.45 0.55];

BandRanges = struct();

BandRanges.Delta     = [1 4];
BandRanges.Theta     = [4 8];
BandRanges.Alpha     = [8 13];
BandRanges.BetaLow   = [13 20];
BandRanges.BetaHigh  = [20 30];
BandRanges.GammaLow  = [30 40];
BandRanges.GammaHigh = [40 90];
%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI

cfgTFR.rois = ROI;

cfgTFR.analysis_rois = { ...
    'ERAN_CORE',...
    'MMN',...
    'FrontoCentral',...
    'N5_CENTRAL'};

roiNames = cfgTFR.analysis_rois;

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

tfrdir = fullfile( ...
    step4_outroot,...
    'Consonance',...
    cfgTFR.method);

if ~exist(tfrdir,'dir')
    mkdir(tfrdir);
end

fprintf('\n');
fprintf('Output folder:\n');
fprintf('%s\n',tfrdir);

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
TFRBandResults = struct();

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
% BAND SUMMARY FROM TFR
%% ============================================================

bandNames = fieldnames(BandRanges);

windowNames = ...
    fieldnames(cfgTFR.summary_windows);

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    for w = 1:numel(windowNames)

        windowName = windowNames{w};

        currentWindow = ...
            cfgTFR.summary_windows.(windowName);

        for b = 1:numel(bandNames)

            bandName = bandNames{b};

            TFRBandResults.(roiName).(windowName).(bandName) = ...
                extract_tfr_window( ...
                TFR_Group.(roiName),...
                BandRanges.(bandName),...
                currentWindow);

        end

    end

end
%% ============================================================
% PLOTS
%% ============================================================
 
for r=1:numel(roiNames)
    roiName = roiNames{r};
    groupData = ...
        TFR_Group.(roiName);

    diffMap = groupData.Difference.power;

    fprintf('\n');
    fprintf('ROI: %s\n',roiName);
    windowNames = ...
        fieldnames(cfgTFR.summary_windows);

    for w = 1:numel(windowNames)

        windowName = windowNames{w};

        fprintf('\n');
        fprintf('--- %s ---\n',windowName);

        currBands = ...
            fieldnames( ...
            TFRBandResults.(roiName).(windowName));

        for b = 1:numel(currBands)

            bandName = currBands{b};

            stats = ...
                TFRBandResults.(roiName).(windowName).(bandName);

            fprintf( ...
                '%s | CON %.4f | DIS %.4f | DIFF %.4f\n',...
                bandName,...
                stats.Consonant,...
                stats.Dissonant,...
                stats.Difference);

        end

    end
    fprintf('Mean Broadband Difference: %.4f dB\n', ...
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

    clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])

    axis xy
    colorbar

    title(sprintf('%s - Difference',format_tex_name(roiName)))
    saveas( ...
        gcf,...
        fullfile( ...
        tfrdir,...
        sprintf('TFR_Group_%s.png',roiName)));
    close
    %% ============================================================
    % DIFFERENCE ONLY TFR
    %% ============================================================

    diffdir = fullfile( ...
        tfrdir,...
        'Difference_Only');

    if ~exist(diffdir,'dir')
        mkdir(diffdir);
    end

    figure('Position',[100 100 900 600])

    imagesc( ...
        groupData.time,...
        groupData.freq,...
        diffMap)

    axis xy
    colorbar

    clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    title(sprintf( ...
        '%s | Difference', ...
        format_tex_name(roiName)));

    saveas( ...
        gcf,...
        fullfile( ...
        diffdir,...
        sprintf( ...
        'DifferenceOnly_%s.png',...
        roiName)));

    close
    meanConTime = ...
        mean(groupData.Consonant.power,1);
    meanDisTime = ...
        mean(groupData.Dissonant.power,1);
    TFRBandResults.(roiName).Broadband.time = ...
        groupData.time;

    TFRBandResults.(roiName).Broadband.Consonant = ...
        meanConTime;

    TFRBandResults.(roiName).Broadband.Dissonant = ...
        meanDisTime;

    TFRBandResults.(roiName).Broadband.Difference = ...
        mean(groupData.Difference.power,1);
    % Mean power across the entire analyzed spectrum (1-90 Hz)

    figure
    plot(groupData.time,...
        meanConTime,...
        'LineWidth',2)
    hold on
    plot(groupData.time,...
        meanDisTime,...
        'LineWidth',2)
    xline(0,'k')
    legend('Consonant','Dissonant')
    xlabel('Time (s)')
    ylabel('Power (dB)')
    title(sprintf( ...
        'Broadband TFR Time Course - %s',...
        format_tex_name(roiName)))
    saveas( ...
        gcf,...
        fullfile( ...
        tfrdir,...
        sprintf('BroadbandTFRTimeCourse_%s.png',roiName)));
    close
    %% ============================================================
    % BAND-SPECIFIC TIME COURSES
    %% ============================================================

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        bandRange = ...
            BandRanges.(bandName);

        idxFreq = ...
            groupData.freq >= bandRange(1) & ...
            groupData.freq <= bandRange(2);

        conTime = ...
            mean( ...
            groupData.Consonant.power(idxFreq,:), ...
            1);

        disTime = ...
            mean( ...
            groupData.Dissonant.power(idxFreq,:), ...
            1);

        diffTime = ...
            mean( ...
            groupData.Difference.power(idxFreq,:), ...
            1);
        TFRBandResults.(roiName).TimeCourse.(bandName).time = ...
            groupData.time;

        TFRBandResults.(roiName).TimeCourse.(bandName).Consonant = ...
            conTime;

        TFRBandResults.(roiName).TimeCourse.(bandName).Dissonant = ...
            disTime;

        TFRBandResults.(roiName).TimeCourse.(bandName).Difference = ...
            diffTime;
        figure

        plot( ...
            groupData.time,...
            conTime,...
            'LineWidth',2);

        hold on

        plot( ...
            groupData.time,...
            disTime,...
            'LineWidth',2);

        plot( ...
            groupData.time,...
            diffTime,...
            'k--',...
            'LineWidth',2);

        xline(0,'k');

        legend( ...
            'Consonant',...
            'Dissonant',...
            'Difference');

        xlabel('Time (s)');
        ylabel('Power (dB)');

        title(sprintf( ...
            '%s Time Course - %s - %s',...
            bandName,...
            format_tex_name(roiName),...
            format_tex_name(cfgTFR.method)));

        saveas( ...
            gcf,...
            fullfile( ...
            tfrdir,...
            sprintf( ...
            '%s_TimeCourse_%s.png',...
            bandName,...
            roiName)));

        close

    end

end
%% ============================================================
% ZOOMED TFR PLOTS
%% ============================================================

PlotWindows = struct();

% PlotWindows.Global = [-0.5 1.5];

% Literature-driven
PlotWindows.ERAN = [0.15 0.25];
PlotWindows.MMN  = [0.10 0.25];
PlotWindows.N5   = [0.45 0.55];

% ERP-driven
PlotWindows.EarlyNeg_170_220 = [0.17 0.22];
PlotWindows.Rebound_220_320  = [0.22 0.32];
PlotWindows.Late_450_550     = [0.45 0.55];

% Broad descriptive windows
PlotWindows.Post_100_250 = [0.10 0.25];
PlotWindows.Post_250_500 = [0.25 0.50];
PlotWindows.Post_500_800 = [0.50 0.80];

windowNames = fieldnames(PlotWindows);

zoomdir = fullfile(tfrdir,'Zoomed_TFR');

if ~exist(zoomdir,'dir')
    mkdir(zoomdir);
end

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    groupData = TFR_Group.(roiName);

    for w = 1:numel(windowNames)

        winName = windowNames{w};

        win = PlotWindows.(winName);

        idxTime = ...
            groupData.time >= win(1) & ...
            groupData.time <= win(2);

        tPlot = groupData.time(idxTime);

        conMap = ...
            groupData.Consonant.power(:,idxTime);

        disMap = ...
            groupData.Dissonant.power(:,idxTime);

        diffMap = ...
            groupData.Difference.power(:,idxTime);


        figure('Position',[100 100 1000 900])

        subplot(3,1,1)

        imagesc( ...
            tPlot,...
            groupData.freq,...
            conMap)

        axis xy
        colorbar
        clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])
        title(sprintf( ...
            '%s | %s | Consonant',...
            format_tex_name(roiName),...
            format_tex_name(winName)));

        xlabel('Time (s)')
        ylabel('Frequency (Hz)')

        subplot(3,1,2)

        imagesc( ...
            tPlot,...
            groupData.freq,...
            disMap)

        axis xy
        colorbar
        clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])
        title(sprintf( ...
            '%s | %s | Dissonant',...
            format_tex_name(roiName),...
            format_tex_name(winName)));

        xlabel('Time (s)')
        ylabel('Frequency (Hz)')

        subplot(3,1,3)

        imagesc( ...
            tPlot,...
            groupData.freq,...
            diffMap)

        axis xy
        colorbar

        clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])

        title(sprintf( ...
            '%s | %s | Difference',...
            format_tex_name(roiName),...
            format_tex_name(winName)));

        xlabel('Time (s)')
        ylabel('Frequency (Hz)')

        saveas( ...
            gcf,...
            fullfile( ...
            zoomdir,...
            sprintf( ...
            'TFR_%s_%s.png',...
            format_tex_name(roiName),...
            format_tex_name(winName))));

        close

    end
end
%% ============================================================
% DIFFERENCE-ONLY ZOOMED TFR
%% ============================================================

diffdir = fullfile(tfrdir,'Difference_Zoomed');

if ~exist(diffdir,'dir')
    mkdir(diffdir);
end

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    groupData = TFR_Group.(roiName);

    for w = 1:numel(windowNames)

        winName = windowNames{w};

        win = PlotWindows.(winName);

        idxTime = ...
            groupData.time >= win(1) & ...
            groupData.time <= win(2);

        tPlot = groupData.time(idxTime);

        diffMap = ...
            groupData.Difference.power(:,idxTime);

        figure('Position',[100 100 900 500])

        imagesc( ...
            tPlot,...
            groupData.freq,...
            diffMap)

        axis xy
        colorbar

        clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])

        xlabel('Time (s)')
        ylabel('Frequency (Hz)')

        title(sprintf( ...
            '%s | %s | Difference',...
            format_tex_name(roiName),...
            format_tex_name(winName)));

        saveas( ...
            gcf,...
            fullfile( ...
            diffdir,...
            sprintf( ...
            'Difference_%s_%s.png',...
            roiName,...
            winName)));

        close
    end
end
%% ============================================================
% SAVE
%% ============================================================
assert(~isempty(fieldnames(TFR_Subj)), ...
    'No subject results generated');
save( ...
    fullfile(tfrdir,...
    'STEP4B_TFR_MORLET_RESULTS.mat'),...
    'TFR_Subj',...
    'TFR_Group',...
    'TFRBandResults',...
    'BandRanges',...
    'cfgTFR',...
    'ROI',...
    '-v7.3');

fprintf('\n');
fprintf('=====================================\n');
fprintf('STEP4 TFR MORLET COMPLETED\n');
fprintf('=====================================\n');

set(0,'DefaultFigureVisible',origState);