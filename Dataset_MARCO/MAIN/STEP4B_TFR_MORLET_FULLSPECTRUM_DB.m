%% =========================================================================
% STEP4B_TFR_MORLET_FULLSPECTRUM_DB
% OLD file: STEP4B_TFR_MORLET_FULLSPECTRUM
%% =========================================================================
%
% PROJECT
% -------
% X-SONANCE EEG
%
% PURPOSE
% -------
% Full-spectrum induced time-frequency analysis in decibel scale.
%
% The analysis uses a channel-first ROI approach and dB baseline
% correction, then evaluates Consonant versus Dissonant induced power
% across Delta, Theta, Alpha, Beta and Gamma bands.
%
% In dB, the Difference is:
%
%     Difference_dB = Consonant_dB - Dissonant_dB
%
% This corresponds to the logarithm of the Consonant/Dissonant power
% ratio.
%
% OUTPUTS
% -------
%   TFR_Subj
%   TFR_Group
%   BandStats
%   BandSummaryTable
%   Topo_Group
%
% =========================================================================
clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

addpath('C:\Users\mirco\Desktop\eeglab2026.1.0')
eeglab nogui

set(groot, ...
    'defaultTextInterpreter','tex', ...
    'defaultAxesTickLabelInterpreter','tex', ...
    'defaultLegendInterpreter','tex');

%% =========================================================================
% Paths
%% =========================================================================
projectRoot = 'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

inputDir = projectRoot;

outputRoot = fullfile( ...
    projectRoot, ...
    'STEP4B_TFR_MORLET', ...
    'FULLSPECTRUM_DB','ALL_ROI');

if ~exist(outputRoot,'dir')
    mkdir(outputRoot);
end

figDir = fullfile(outputRoot,'Figures');

if ~exist(figDir,'dir')
    mkdir(figDir);
end

topoDir = fullfile(outputRoot,'Topoplots');

if ~exist(topoDir,'dir')
    mkdir(topoDir);
end

%% =========================================================================
% Load data
%% =========================================================================
load(fullfile(inputDir,'subj_list.mat'),'subj_list');

assert(~isempty(subj_list), ...
    'subj_list is empty.');

time0 = subj_list(1).data_trials(1).time(:)';

nSubjects = numel(subj_list);

Fs_all = nan(nSubjects,1);

for iSub = 1:nSubjects

    trial0 = subj_list(iSub).data_trials(1);

    assert(isequal(trial0.time(:)',time0), ...
        'Time vector differs across subjects.');

    Fs_all(iSub) = trial0.srate;
end

assert(numel(unique(Fs_all)) == 1, ...
    'Sampling rate differs across subjects.');

Fs = Fs_all(1);

fprintf('\n=====================================\n');
fprintf('FULL-SPECTRUM CHANNEL-FIRST DB: LOAD COMPLETED\n');
fprintf('Subjects : %d\n',nSubjects);
fprintf('Fs       : %.2f Hz\n',Fs);
fprintf('Time     : %.3f to %.3f s (%d samples)\n', ...
    time0(1), ...
    time0(end), ...
    numel(time0));
fprintf('=====================================\n');

assert(time0(1) <= -0.2 && time0(end) >= 1.0, ...
    'Epoch does not include [-200, 1000] ms.');

%% =========================================================================
% ANALYSIS CONFIGURATION
%% =========================================================================
cfgTFR = struct();

% -------------------------------------------------------------------------
% PROCESSING
% -------------------------------------------------------------------------
cfgTFR.method = 'channel_first';

cfgTFR.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgTFR.cond_field = 'eventLabel';

% -------------------------------------------------------------------------
% FREQUENCY ANALYSIS
% -------------------------------------------------------------------------
cfgTFR.freqs = 2:1:90;

cfgTFR.nCycles = min(7,max(3,round(cfgTFR.freqs / 4)));

cfgTFR.baseline_win = [-0.200 -0.050];

cfgTFR.plot_time_win = [-0.200 1.000];

cfgTFR.save_trial_level = false;

cfgTFR.srate = Fs;
cfgTFR.time  = time0;

% -------------------------------------------------------------------------
% ACTIVE ROIS
% -------------------------------------------------------------------------
% cfgTFR.analysis_rois = { ...
%     'ERAN_CORE',...
%     'MMN',...
%     'FrontoCentral',...
%     'N5_CENTRAL'};

cfgTFR.analysis_rois = { ...
        'Occipital',...
        'Parietal',...
        'SPN_POSTERIOR'};

% -------------------------------------------------------------------------
% ACTIVE BANDS
% -------------------------------------------------------------------------
cfgTFR.activeBands = { ...
    'Delta',...
    'Theta',...
    'Alpha',...
    'BetaLow',...
    'BetaHigh',...
    'GammaLow',...
    'GammaHigh'};

% -------------------------------------------------------------------------
% REFERENCE WINDOW
% -------------------------------------------------------------------------
cfgTFR.reference_freq_win = [30 60];
cfgTFR.reference_time_win = [0.100 0.250];

cfgTFR.summary_windows = struct();

cfgTFR.summary_windows.Global   = [0.00 0.80];
cfgTFR.summary_windows.EarlyNeg = [0.17 0.22];
cfgTFR.summary_windows.Rebound  = [0.22 0.32];
cfgTFR.summary_windows.Late     = [0.45 0.55];

%% ------------------------------------------------------------------------
% BAND DEFINITIONS
%% ------------------------------------------------------------------------
BandRanges = struct();

BandRanges.Delta     = [2 4];
BandRanges.Theta     = [4 8];
BandRanges.Alpha     = [8 13];
BandRanges.BetaLow   = [13 20];
BandRanges.BetaHigh  = [20 30];
BandRanges.GammaLow  = [30 40];
BandRanges.GammaHigh = [40 90];

%% =========================================================================
% PLOT CONFIGURATION
%% =========================================================================
cfgPlot = struct();

% -------------------------------------------------------------------------
% MAIN FIGURES
% -------------------------------------------------------------------------
cfgPlot.groupTFR = true;

% -------------------------------------------------------------------------
% Full-spectrum channel-level topoplots
% -------------------------------------------------------------------------
cfgPlot.topoBands = cfgTFR.activeBands;

cfgPlot.topoDifferenceOnly = true;
cfgPlot.topoConDisDiff = false;

% Band time-course figures
cfgPlot.bandTimeCourses = true;
cfgPlot.bandConDis = true;
cfgPlot.bandConDisDiff = true;
cfgPlot.bandDifferenceOnly = false;

% Channel-level topoplots
cfgPlot.topoplots = true;

% -------------------------------------------------------------------------
% TOPO WINDOWS
% -------------------------------------------------------------------------
cfgPlot.windows = struct();

cfgPlot.windows.Park_100_250      = [0.100 0.250];
cfgPlot.windows.ParkPeak_150_200  = [0.150 0.200];
cfgPlot.windows.Early_170_220     = [0.170 0.220];
cfgPlot.windows.Post_220_320      = [0.220 0.320];
cfgPlot.windows.Late_450_550      = [0.450 0.550];

%% =========================================================================
% ROI definitions
%% =========================================================================
MAIN_ROI

cfgTFR.rois = ROI;

roiNames = cfgTFR.analysis_rois;

assert(~isempty(roiNames), ...
    'No ROI defined in MAIN_ROI.');

fprintf('\n=====================================\n');
fprintf('ROI CONFIGURATION\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    fprintf('%02d) %s: ',r,roiName);
    disp(cfgTFR.rois.(roiName));
end

%% =========================================================================
% Subject-level channel-first ROI TFR
%% =========================================================================
TFR_Subj = struct();

fprintf('\n=====================================\n');
fprintf('SUBJECT-LEVEL CHANNEL-FIRST TFR (dB)\n');
fprintf('=====================================\n');

for iSub = 1:nSubjects

    subj_curr = subj_list(iSub);
    subjID = matlab.lang.makeValidName(char(subj_curr.subj_id));

    fprintf('\nSubject: %s\n',subjID);

    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        cfgROI = cfgTFR;
        cfgROI.roi_labels = cfgTFR.rois.(roiName);

        fprintf('  ROI: %s\n',roiName);

        roi_tfr = extract_roi_tfr_db(subj_curr,cfgROI);

        if isempty(roi_tfr) || ...
                ~isfield(roi_tfr,'Consonant') || ...
                ~isfield(roi_tfr,'Dissonant')

            warning('%s | %s: incomplete TFR output.', ...
                subjID, ...
                roiName);

            continue
        end

        assert(isequal(size(roi_tfr.Consonant.power), ...
            [numel(cfgTFR.freqs),numel(time0)]), ...
            'Unexpected Consonant TFR dimensions.');

        assert(isequal(size(roi_tfr.Dissonant.power), ...
            [numel(cfgTFR.freqs),numel(time0)]), ...
            'Unexpected Dissonant TFR dimensions.');

        TFR_Subj.(subjID).(roiName) = roi_tfr;
    end
end

subjectNames = fieldnames(TFR_Subj);

assert(~isempty(subjectNames), ...
    'No participant-level results were generated.');

fprintf('\nSubjects retained: %d\n',numel(subjectNames));

%% =========================================================================
% Group-level TFR
%% =========================================================================
TFR_Group = struct();

fprintf('\n=====================================\n');
fprintf('GROUP-LEVEL CHANNEL-FIRST TFR (dB)\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    TFR_Group.(roiName) = average_group_tfr(TFR_Subj,roiName);

    groupData = TFR_Group.(roiName);

    assert(isfield(groupData,'Consonant') && ...
        isfield(groupData,'Dissonant') && ...
        isfield(groupData,'Difference'), ...
        '%s: missing condition/difference field.',roiName);

    fprintf('Built ROI: %s | [%d freq x %d time]\n', ...
        roiName, ...
        size(groupData.Consonant.power,1), ...
        size(groupData.Consonant.power,2));
end

%% =========================================================================
% Shared colour limits
%% =========================================================================
nROI = numel(roiNames);

firstROI = roiNames{1};
firstGroupData = TFR_Group.(firstROI);

nFreq = numel(firstGroupData.freq(:));
nTime = numel(firstGroupData.time(:));

allConditionPower = nan( ...
    2, ...
    nROI, ...
    nFreq, ...
    nTime, ...
    'single');

allDifferencePower = nan( ...
    nROI, ...
    nFreq, ...
    nTime, ...
    'single');

for r = 1:nROI

    roiName = roiNames{r};
    groupData = TFR_Group.(roiName);

    assert(isequal(size(groupData.Consonant.power), ...
        [nFreq nTime]), ...
        '%s: unexpected Consonant TFR dimensions.',roiName);

    assert(isequal(size(groupData.Dissonant.power), ...
        [nFreq nTime]), ...
        '%s: unexpected Dissonant TFR dimensions.',roiName);

    assert(isequal(size(groupData.Difference.power), ...
        [nFreq nTime]), ...
        '%s: unexpected Difference TFR dimensions.',roiName);

    allConditionPower(1,r,:,:) = single( ...
        groupData.Consonant.power);

    allConditionPower(2,r,:,:) = single( ...
        groupData.Dissonant.power);

    allDifferencePower(r,:,:) = single( ...
        groupData.Difference.power);
end

conditionCLim = prctile( ...
    allConditionPower(:), ...
    [2 98]);

differenceAbsMax = prctile( ...
    abs(allDifferencePower(:)), ...
    98);

if isempty(differenceAbsMax) || ...
        isnan(differenceAbsMax) || ...
        differenceAbsMax == 0

    differenceAbsMax = max(abs(allDifferencePower(:)), ...
        [], ...
        'omitnan');
end

fprintf('\n=====================================\n');
fprintf('GLOBAL COLOR LIMITS (dB)\n');
fprintf('=====================================\n');
fprintf('Conditions: [%.4f, %.4f] dB\n', ...
    conditionCLim(1), ...
    conditionCLim(2));
fprintf('Difference: ±%.4f dB\n', ...
    differenceAbsMax);

%% =========================================================================
% ROI figures and band time courses
%% =========================================================================
BandStats = struct();

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    roiFigDir = fullfile(figDir,roiName);

    if ~exist(roiFigDir,'dir')
        mkdir(roiFigDir);
    end

    groupData = TFR_Group.(roiName);

    time = groupData.time(:)';
    freq = groupData.freq(:);

    conMap = groupData.Consonant.power;
    disMap = groupData.Dissonant.power;
    difMap = groupData.Difference.power;

    assert(size(conMap,2) == numel(time), ...
        '%s: time dimensions mismatch.',roiName);

    % ---------------------------------------------------------------------
    % Band time courses
    % ---------------------------------------------------------------------
    for b = 1:numel(cfgTFR.activeBands)

        bandName = cfgTFR.activeBands{b};
        bandRange = BandRanges.(bandName);

        idxBand = ...
            freq >= bandRange(1) & ...
            freq <= bandRange(2);

        bandConTime = ...
            mean(conMap(idxBand,:),1,'omitnan');

        bandDisTime = ...
            mean(disMap(idxBand,:),1,'omitnan');

        bandDifTime = ...
            mean(difMap(idxBand,:),1,'omitnan');

        BandStats.(roiName).TimeCourse.(bandName).time = time;

        BandStats.(roiName).TimeCourse.(bandName).Consonant = ...
            bandConTime;

        BandStats.(roiName).TimeCourse.(bandName).Dissonant = ...
            bandDisTime;

        BandStats.(roiName).TimeCourse.(bandName).Difference = ...
            bandDifTime;

        windowNames = fieldnames(cfgTFR.summary_windows);

        for w = 1:numel(windowNames)

            windowName = windowNames{w};
            timeRange = cfgTFR.summary_windows.(windowName);

            idxWindow = ...
                time >= timeRange(1) & ...
                time <= timeRange(2);

            BandStats.(roiName).(windowName).(bandName).Consonant = ...
                mean(bandConTime(idxWindow),'omitnan');

            BandStats.(roiName).(windowName).(bandName).Dissonant = ...
                mean(bandDisTime(idxWindow),'omitnan');

            BandStats.(roiName).(windowName).(bandName).Difference = ...
                mean(bandDifTime(idxWindow),'omitnan');
        end
    end

    % ---------------------------------------------------------------------
    % TFR panels shown only from -200 to 1000 ms
    % ---------------------------------------------------------------------
    idxPlotTime = ...
        time >= cfgTFR.plot_time_win(1) & ...
        time <= cfgTFR.plot_time_win(2);

    assert(any(idxPlotTime), ...
        '%s: no samples in display range.',roiName);

    timePlot = time(idxPlotTime) * 1000;

    conMapPlot = conMap(:,idxPlotTime);
    disMapPlot = disMap(:,idxPlotTime);
    difMapPlot = difMap(:,idxPlotTime);

    if cfgPlot.groupTFR

        fig = figure('Color','w', ...
            'Position',[100 100 1050 900]);

        subplot(3,1,1)
        imagesc(timePlot,freq,conMapPlot)
        axis xy
        clim(conditionCLim)
        colorbar
        xline(0,'k--','LineWidth',1)
        xline(cfgTFR.reference_time_win(1)*1000,'k:','LineWidth',1)
        xline(cfgTFR.reference_time_win(2)*1000,'k:','LineWidth',1)
        xlim(cfgTFR.plot_time_win*1000)
        xlabel('Time (ms)')
        ylabel('Frequency (Hz)')
        title(sprintf('%s — Consonant', ...
            format_tex_name(roiName)))

        subplot(3,1,2)
        imagesc(timePlot,freq,disMapPlot)
        axis xy
        clim(conditionCLim)
        colorbar
        xline(0,'k--','LineWidth',1)
        xline(cfgTFR.reference_time_win(1)*1000,'k:','LineWidth',1)
        xline(cfgTFR.reference_time_win(2)*1000,'k:','LineWidth',1)
        xlim(cfgTFR.plot_time_win*1000)
        xlabel('Time (ms)')
        ylabel('Frequency (Hz)')
        title(sprintf('%s — Dissonant', ...
            format_tex_name(roiName)))

        subplot(3,1,3)
        imagesc(timePlot,freq,difMapPlot)
        axis xy
        clim([-differenceAbsMax differenceAbsMax])
        colorbar
        xline(0,'k--','LineWidth',1)
        xline(cfgTFR.reference_time_win(1)*1000,'k:','LineWidth',1)
        xline(cfgTFR.reference_time_win(2)*1000,'k:','LineWidth',1)
        xlim(cfgTFR.plot_time_win*1000)
        xlabel('Time (ms)')
        ylabel('Frequency (Hz)')
        title(sprintf('%s — Consonant minus Dissonant', ...
            format_tex_name(roiName)))

        sgtitle('Induced time-frequency power, baseline-corrected (dB)')

        saveas(fig,fullfile(roiFigDir, ...
            sprintf('TFR_ChannelFirst_DB_%s.png',roiName)));

        close(fig)
    end

    % ---------------------------------------------------------------------
    % Band time-course figures
    % ---------------------------------------------------------------------
    if cfgPlot.bandTimeCourses

        for b = 1:numel(cfgTFR.activeBands)

            bandName = cfgTFR.activeBands{b};
            bandRange = BandRanges.(bandName);

            bandConTime = ...
                BandStats.(roiName).TimeCourse.(bandName).Consonant;

            bandDisTime = ...
                BandStats.(roiName).TimeCourse.(bandName).Dissonant;

            bandDifTime = ...
                BandStats.(roiName).TimeCourse.(bandName).Difference;

            if cfgPlot.bandConDis

                fig = figure('Color','w', ...
                    'Position',[100 100 1000 500]);

                plot(timePlot,bandConTime(idxPlotTime), ...
                    'LineWidth',2, ...
                    'Color',[0.75 0.20 0.20]);

                hold on

                plot(timePlot,bandDisTime(idxPlotTime), ...
                    'LineWidth',2, ...
                    'Color',[0.20 0.25 0.70]);

                xline(0,'k--','LineWidth',1);
                yline(0,'k--','LineWidth',1);
                xlim(cfgTFR.plot_time_win*1000)

                xlabel('Time (ms)')
                ylabel('Induced power change (dB)')
                legend('Consonant chord','Dissonant chord', ...
                    'Location','northeast')

                title(sprintf( ...
                    '%s time course (%d-%d Hz) - %s', ...
                    bandName, ...
                    bandRange(1), ...
                    bandRange(2), ...
                    format_tex_name(roiName)))

                grid on
                box off

                saveas(fig,fullfile(roiFigDir, ...
                    sprintf('%s_ConDis_ChannelFirst_DB_%s.png', ...
                    bandName, ...
                    roiName)));

                close(fig)
            end

            if cfgPlot.bandConDisDiff

                fig = figure('Color','w', ...
                    'Position',[100 100 1000 500]);

                plot(timePlot,bandConTime(idxPlotTime), ...
                    'LineWidth',2, ...
                    'Color',[0.75 0.20 0.20]);

                hold on

                plot(timePlot,bandDisTime(idxPlotTime), ...
                    'LineWidth',2, ...
                    'Color',[0.20 0.25 0.70]);

                plot(timePlot,bandDifTime(idxPlotTime), ...
                    'k--', ...
                    'LineWidth',1.8);

                xline(0,'k--','LineWidth',1);
                yline(0,'k--','LineWidth',1);
                xlim(cfgTFR.plot_time_win*1000)

                xlabel('Time (ms)')
                ylabel('Induced power change (dB)')
                legend('Consonant chord','Dissonant chord', ...
                    'Consonant - Dissonant', ...
                    'Location','northeast')

                title(sprintf( ...
                    '%s time course (%d-%d Hz) - %s', ...
                    bandName, ...
                    bandRange(1), ...
                    bandRange(2), ...
                    format_tex_name(roiName)))

                grid on
                box off

                saveas(fig,fullfile(roiFigDir, ...
                    sprintf('%s_ConDisDiff_ChannelFirst_DB_%s.png', ...
                    bandName, ...
                    roiName)));

                close(fig)
            end

            if cfgPlot.bandDifferenceOnly

                fig = figure('Color','w', ...
                    'Position',[100 100 1000 500]);

                plot(timePlot,bandDifTime(idxPlotTime), ...
                    'k-', ...
                    'LineWidth',2);

                hold on

                xline(0,'k--','LineWidth',1);
                yline(0,'k--','LineWidth',1);
                xlim(cfgTFR.plot_time_win*1000)

                xlabel('Time (ms)')
                ylabel('Consonant - Dissonant (dB)')

                title(sprintf( ...
                    '%s difference time course (%d-%d Hz) - %s', ...
                    bandName, ...
                    bandRange(1), ...
                    bandRange(2), ...
                    format_tex_name(roiName)))

                grid on
                box off

                saveas(fig,fullfile(roiFigDir, ...
                    sprintf('%s_Difference_ChannelFirst_DB_%s.png', ...
                    bandName, ...
                    roiName)));

                close(fig)
            end
        end
    end
end

%% =========================================================================
% BAND SUMMARY TABLE
%% =========================================================================
summaryWindowNames = fieldnames(cfgTFR.summary_windows);

nROI = numel(roiNames);
nSummaryWindows = numel(summaryWindowNames);
nBands = numel(cfgTFR.activeBands);

nSummaryRows = nROI * nSummaryWindows * nBands;

summaryRows = cell(nSummaryRows,10);

row = 0;

for r = 1:nROI

    roiName = roiNames{r};

    for w = 1:nSummaryWindows

        windowName = summaryWindowNames{w};
        timeRange = cfgTFR.summary_windows.(windowName);

        for b = 1:nBands

            bandName = cfgTFR.activeBands{b};
            bandRange = BandRanges.(bandName);

            stats = BandStats.(roiName).(windowName).(bandName);

            row = row + 1;

            summaryRows(row,:) = { ...
                roiName, ...
                windowName, ...
                bandName, ...
                bandRange(1), ...
                bandRange(2), ...
                timeRange(1), ...
                timeRange(2), ...
                stats.Consonant, ...
                stats.Dissonant, ...
                stats.Difference};
        end
    end
end

assert(row == nSummaryRows, ...
    ['Band summary rows do not match the expected number. ' ...
    'Expected %d, found %d.'], ...
    nSummaryRows, ...
    row);

BandSummaryTable = cell2table(summaryRows, ...
    'VariableNames',{ ...
    'ROI', ...
    'TimeWindow', ...
    'Band', ...
    'FreqMin_Hz', ...
    'FreqMax_Hz', ...
    'TimeMin_s', ...
    'TimeMax_s', ...
    'Consonant_dB', ...
    'Dissonant_dB', ...
    'Difference_ConMinusDis_dB'});

writetable(BandSummaryTable, ...
    fullfile(outputRoot, ...
    'BandSummary_FullSpectrum_DB.csv'));

fprintf('\n=====================================\n');
fprintf('BAND SUMMARY TABLE SAVED\n');
fprintf('Rows: %d\n',height(BandSummaryTable));
fprintf('=====================================\n');

%% =========================================================================
% CHANNEL-LEVEL FULL-SPECTRUM TOPOPLOTS
%
% A TFR is computed once per subject and electrode.
% For memory efficiency, power is immediately averaged within each
% frequency band and only band-specific time courses are retained.
%
% Stored dimensions:
%   subjects x channels x bands x time
%
% Topoplots are generated for:
%   all active bands x all cfgPlot.windows
%% =========================================================================
Topo_Group = struct();

topoConBandTime = [];
topoDisBandTime = [];

allChanLocs = [];
allChanLabels = {};

if cfgPlot.topoplots

    fprintf('\n=====================================\n');
    fprintf('FULL-SPECTRUM CHANNEL-LEVEL TOPOPLOTS (dB)\n');
    fprintf('=====================================\n');

    allChanLocs = subj_list(1).data_trials(1).chanlocs;
    allChanLabels = {allChanLocs.labels};

    nChan = numel(allChanLabels);
    nTime = numel(cfgTFR.time);

    topoBandNames = cfgPlot.topoBands;
    nTopoBands = numel(topoBandNames);

    assert(nChan > 0, ...
        'No channel locations found.');

    assert(isfield(allChanLocs,'X') || ...
        isfield(allChanLocs,'theta'), ...
        ['Channel coordinates are missing. ' ...
        'chanlocs must contain spatial information for topoplot.']);

    topoConBandTime = nan( ...
        nSubjects, ...
        nChan, ...
        nTopoBands, ...
        nTime, ...
        'single');

    topoDisBandTime = nan( ...
        nSubjects, ...
        nChan, ...
        nTopoBands, ...
        nTime, ...
        'single');

    for iSub = 1:nSubjects

        subj_curr = subj_list(iSub);
        subjID = matlab.lang.makeValidName( ...
            char(subj_curr.subj_id));

        fprintf('Topography subject %d/%d: %s\n', ...
            iSub, ...
            nSubjects, ...
            subjID);

        for ch = 1:nChan

            cfgChan = cfgTFR;
            cfgChan.roi_labels = allChanLabels(ch);

            chanTFR = extract_roi_tfr_db(subj_curr,cfgChan);

            if isempty(chanTFR) || ...
                    ~isfield(chanTFR,'Consonant') || ...
                    ~isfield(chanTFR,'Dissonant')

                warning('%s | %s: no channel-level TFR.', ...
                    subjID, ...
                    allChanLabels{ch});

                continue
            end

            for b = 1:nTopoBands

                bandName = topoBandNames{b};
                bandRange = BandRanges.(bandName);

                idxBandFreq = ...
                    chanTFR.freq >= bandRange(1) & ...
                    chanTFR.freq <= bandRange(2);

                assert(any(idxBandFreq), ...
                    '%s: no frequencies found for band %s.', ...
                    allChanLabels{ch}, ...
                    bandName);

                topoConBandTime(iSub,ch,b,:) = single( ...
                    mean( ...
                    chanTFR.Consonant.power(idxBandFreq,:), ...
                    1, ...
                    'omitnan'));

                topoDisBandTime(iSub,ch,b,:) = single( ...
                    mean( ...
                    chanTFR.Dissonant.power(idxBandFreq,:), ...
                    1, ...
                    'omitnan'));
            end
        end
    end

    PlotWindows = cfgPlot.windows;
    topoWindowNames = fieldnames(PlotWindows);

    for b = 1:nTopoBands

        bandName = topoBandNames{b};
        bandRange = BandRanges.(bandName);

        bandTopoDir = fullfile(topoDir,bandName);

        if ~exist(bandTopoDir,'dir')
            mkdir(bandTopoDir);
        end

        diffTopoDir = fullfile(bandTopoDir,'Difference');

        if ~exist(diffTopoDir,'dir')
            mkdir(diffTopoDir);
        end

        conDisDiffTopoDir = ...
            fullfile(bandTopoDir,'ConDisDiff');

        if cfgPlot.topoConDisDiff && ...
                ~exist(conDisDiffTopoDir,'dir')
            mkdir(conDisDiffTopoDir);
        end

        for w = 1:numel(topoWindowNames)

            windowName = topoWindowNames{w};
            currentWin = PlotWindows.(windowName);

            idxTopoTime = ...
                cfgTFR.time >= currentWin(1) & ...
                cfgTFR.time <= currentWin(2);

            assert(any(idxTopoTime), ...
                'No samples in topoplot window %s.', ...
                windowName);

            conSubChan = reshape( ...
                mean(topoConBandTime(:,:,b,idxTopoTime), ...
                4, ...
                'omitnan'), ...
                nSubjects,nChan);

            disSubChan = reshape( ...
                mean(topoDisBandTime(:,:,b,idxTopoTime), ...
                4, ...
                'omitnan'), ...
                nSubjects,nChan);

            assert(isequal(size(conSubChan), ...
                [nSubjects nChan]), ...
                '%s | %s: unexpected Consonant dimensions.', ...
                bandName, ...
                windowName);

            assert(isequal(size(disSubChan), ...
                [nSubjects nChan]), ...
                '%s | %s: unexpected Dissonant dimensions.', ...
                bandName, ...
                windowName);

            difSubChan = conSubChan - disSubChan;

            Topo_Group.(bandName).(windowName).labels = ...
                allChanLabels;

            Topo_Group.(bandName).(windowName).chanlocs = ...
                allChanLocs;

            Topo_Group.(bandName).(windowName).freq_win = ...
                bandRange;

            Topo_Group.(bandName).(windowName).time_win = ...
                currentWin;

            Topo_Group.(bandName).(windowName).Consonant_Subject = ...
                conSubChan;

            Topo_Group.(bandName).(windowName).Dissonant_Subject = ...
                disSubChan;

            Topo_Group.(bandName).(windowName).Difference_Subject = ...
                difSubChan;

            Topo_Group.(bandName).(windowName).Consonant = ...
                mean(conSubChan,1,'omitnan');

            Topo_Group.(bandName).(windowName).Dissonant = ...
                mean(disSubChan,1,'omitnan');

            Topo_Group.(bandName).(windowName).Difference = ...
                mean(difSubChan,1,'omitnan');

            diffTopoLimit = max(abs( ...
                Topo_Group.(bandName).(windowName).Difference), ...
                [], ...
                'omitnan');

            if isempty(diffTopoLimit) || ...
                    isnan(diffTopoLimit) || ...
                    diffTopoLimit == 0

                diffTopoLimit = 1;
            end

            if cfgPlot.topoDifferenceOnly

                fig = figure('Color','w', ...
                    'Position',[100 100 700 550]);

                topoplot( ...
                    Topo_Group.(bandName).(windowName).Difference, ...
                    allChanLocs, ...
                    'maplimits',[-diffTopoLimit diffTopoLimit], ...
                    'electrodes','on', ...
                    'style','map', ...
                    'numcontour',6);

                colorbar

                title(sprintf( ...
                    '%s | Consonant - Dissonant', ...
                    format_tex_name(bandName)));

                sgtitle(sprintf( ...
                    ['Channel-level induced power difference | ' ...
                    '%d-%d Hz | %d-%d ms (dB)'], ...
                    bandRange(1), ...
                    bandRange(2), ...
                    round(currentWin(1)*1000), ...
                    round(currentWin(2)*1000)));

                saveas(fig,fullfile(diffTopoDir, ...
                    sprintf( ...
                    'Difference_%s_%s_%d_%dms.png', ...
                    bandName, ...
                    windowName, ...
                    round(currentWin(1)*1000), ...
                    round(currentWin(2)*1000))));

                close(fig)
            end

            if cfgPlot.topoConDisDiff

                condTopoLimit = max(abs([ ...
                    Topo_Group.(bandName).(windowName).Consonant, ...
                    Topo_Group.(bandName).(windowName).Dissonant]), ...
                    [], ...
                    'omitnan');

                if isempty(condTopoLimit) || ...
                        isnan(condTopoLimit) || ...
                        condTopoLimit == 0

                    condTopoLimit = 1;
                end

                fig = figure('Color','w', ...
                    'Position',[100 100 1450 500]);

                subplot(1,3,1)
                topoplot( ...
                    Topo_Group.(bandName).(windowName).Consonant, ...
                    allChanLocs, ...
                    'maplimits',[-condTopoLimit condTopoLimit], ...
                    'electrodes','on', ...
                    'style','map', ...
                    'numcontour',6);
                colorbar
                title('Consonant')

                subplot(1,3,2)
                topoplot( ...
                    Topo_Group.(bandName).(windowName).Dissonant, ...
                    allChanLocs, ...
                    'maplimits',[-condTopoLimit condTopoLimit], ...
                    'electrodes','on', ...
                    'style','map', ...
                    'numcontour',6);
                colorbar
                title('Dissonant')

                subplot(1,3,3)
                topoplot( ...
                    Topo_Group.(bandName).(windowName).Difference, ...
                    allChanLocs, ...
                    'maplimits',[-diffTopoLimit diffTopoLimit], ...
                    'electrodes','on', ...
                    'style','map', ...
                    'numcontour',6);
                colorbar
                title('Consonant - Dissonant')

                sgtitle(sprintf( ...
                    ['Channel-level induced power | %s (%d-%d Hz) | ' ...
                    '%d-%d ms (dB)'], ...
                    format_tex_name(bandName), ...
                    bandRange(1), ...
                    bandRange(2), ...
                    round(currentWin(1)*1000), ...
                    round(currentWin(2)*1000)));

                saveas(fig,fullfile(conDisDiffTopoDir, ...
                    sprintf( ...
                    'ConDisDiff_%s_%s_%d_%dms.png', ...
                    bandName, ...
                    windowName, ...
                    round(currentWin(1)*1000), ...
                    round(currentWin(2)*1000))));

                close(fig)
            end

            fprintf( ...
                'Saved %s topoplot: %s [%d-%d ms]\n', ...
                bandName, ...
                windowName, ...
                round(currentWin(1)*1000), ...
                round(currentWin(2)*1000));
        end
    end
end

%% =========================================================================
% Save results
%% =========================================================================
save( ...
    fullfile(outputRoot, ...
    'STEP4B_TFR_MORLET_FULLSPECTRUM_DB_RESULTS.mat'), ...
    'TFR_Subj', ...
    'TFR_Group', ...
    'BandSummaryTable', ...
    'BandRanges', ...
    'BandStats', ...
    'Topo_Group', ...
    'allChanLocs', ...
    'allChanLabels', ...
    'cfgPlot', ...
    'cfgTFR', ...
    '-v7.3');

fprintf('\n=====================================\n');
fprintf('FULL-SPECTRUM CHANNEL-FIRST DB ANALYSIS COMPLETED\n');
fprintf('=====================================\n');

set(0,'DefaultFigureVisible',origState);