%% =========================================================================
% STEP4C_TFR_SUBJECT_LINEAR
%% =========================================================================

%% =========================================================================

clear
close all
clc

origState = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');

addpath('C:\Users\mirco\Desktop\eeglab2026.1.0')
eeglab nogui

set(groot, 'defaultTextInterpreter', 'tex');
set(groot, 'defaultAxesTickLabelInterpreter', 'tex');
set(groot, 'defaultLegendInterpreter', 'tex');

%% =========================================================================
% Paths
%% =========================================================================

projectRoot = 'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

inputDir = projectRoot;

outputRoot = fullfile( ...
    projectRoot, ...
    'STEP4B_TFR_MORLET', ...
    'STEP4C_TFR_SUBJECT_LINEAR');

if ~exist(outputRoot, 'dir')
    mkdir(outputRoot);
end

figDir = fullfile(outputRoot, 'Figures');

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

topoDir = fullfile(outputRoot, 'Topoplots');

if ~exist(topoDir, 'dir')
    mkdir(topoDir);
end


%% =========================================================================
% Load data
%% =========================================================================

load(fullfile(inputDir, 'subj_list.mat'), 'subj_list');

assert(~isempty(subj_list), ...
    'subj_list is empty.');

time0 = subj_list(1).data_trials(1).time(:)';

nSubjects = numel(subj_list);

Fs_all = nan(nSubjects, 1);

for iSub = 1:nSubjects

    trial0 = subj_list(iSub).data_trials(1);

    assert(isequal(trial0.time(:)', time0), ...
        'Time vector differs across subjects.');

    Fs_all(iSub) = trial0.srate;
end

assert(numel(unique(Fs_all)) == 1, ...
    'Sampling rate differs across subjects.');

Fs = Fs_all(1);

fprintf('\n=====================================\n');
fprintf('PARK CHANNEL-FIRST: LOAD COMPLETED\n');
fprintf('Subjects : %d\n', nSubjects);
fprintf('Fs       : %.2f Hz\n', Fs);
fprintf('Time     : %.3f to %.3f s (%d samples)\n', ...
    time0(1), time0(end), numel(time0));
fprintf('=====================================\n');

assert(time0(1) <= -0.2 && time0(end) >= 1.0, ...
    'Epoch does not include [-200, 1000] ms.');

%% =========================================================================
% Configuration
%% =========================================================================

cfgTFR = struct();

% CRITICAL: channel-specific TFR before ROI averaging
cfgTFR.method = 'channel_first';

cfgTFR.conditions = {'Consonant', 'Dissonant'};
cfgTFR.cond_field = 'eventLabel';

cfgTFR.freqs = 1:1:90;
cfgTFR.nCycles = 7;

cfgTFR.baseline_win = [-0.200 -0.050];
cfgTFR.plot_time_win = [-0.200 1.000];

cfgTFR.freqBands = struct();

cfgTFR.freqBands.Delta     = [1 4];
cfgTFR.freqBands.Theta     = [4 8];
cfgTFR.freqBands.Alpha     = [8 13];
cfgTFR.freqBands.BetaLow   = [13 20];
cfgTFR.freqBands.BetaHigh  = [20 30];
cfgTFR.freqBands.GammaLow  = [30 60];
cfgTFR.freqBands.GammaHigh = [60 90];


cfgTFR.srate = Fs;
cfgTFR.time = time0;
cfgTFR.save_trial_level = false;

cfgTFR.topo_windows = struct();

cfgTFR.topo_windows.Park_100_250  = [0.100 0.250];
cfgTFR.topo_windows.ParkPeak_150_200 = [0.150 0.200];
cfgTFR.topo_windows.Early_170_220 = [0.170 0.220];
cfgTFR.topo_windows.Post_220_320  = [0.220 0.320];
cfgTFR.topo_windows.Late_450_550  = [0.450 0.550];

bandNames = fieldnames(cfgTFR.freqBands);
for b = 1:numel(bandNames)
    tmpDir = fullfile(figDir,bandNames{b});
    if ~exist(tmpDir,'dir')
        mkdir(tmpDir);
    end
end
for b = 1:numel(bandNames)
    tmpTopoDir = fullfile(topoDir,bandNames{b});
    if ~exist(tmpTopoDir,'dir')
        mkdir(tmpTopoDir);
    end
end
%% =========================================================================
% ROI definitions
%% =========================================================================

% MAIN_ROI_TFR
%
% cfgTFR.rois = ParkROI;

MAIN_ROI

cfgTFR.rois = ROI;

roiNames = fieldnames(cfgTFR.rois);

assert(~isempty(roiNames), ...
    'No ROI defined in ParkROI or ROI.');

fprintf('\n=====================================\n');
fprintf('ROI CONFIGURATION\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    fprintf('%02d) %s: ', r, roiName);
    disp(cfgTFR.rois.(roiName));
end

%% =========================================================================
% Subject-level channel-first ROI TFR
%% =========================================================================

TFR_Subj = struct();

fprintf('\n=====================================\n');
fprintf('SUBJECT-LEVEL CHANNEL-FIRST TFR\n');
fprintf('=====================================\n');

for iSub = 1:nSubjects

    subj_curr = subj_list(iSub);

    subjID = matlab.lang.makeValidName(char(subj_curr.subj_id));

    fprintf('\nSubject: %s\n', subjID);

    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        cfgROI = cfgTFR;
        cfgROI.roi_labels = cfgTFR.rois.(roiName);

        fprintf('  ROI: %s\n', roiName);

        roi_tfr = extract_roi_tfr_park(subj_curr, cfgROI);

        if isempty(roi_tfr) || ...
                ~isfield(roi_tfr, 'Consonant') || ...
                ~isfield(roi_tfr, 'Dissonant')

            warning('%s | %s: incomplete TFR output.', ...
                subjID, roiName);
            continue
        end

        assert(isequal(size(roi_tfr.Consonant.power), ...
            [numel(cfgTFR.freqs), numel(time0)]), ...
            'Unexpected Consonant TFR dimensions.');

        assert(isequal(size(roi_tfr.Dissonant.power), ...
            [numel(cfgTFR.freqs), numel(time0)]), ...
            'Unexpected Dissonant TFR dimensions.');

        TFR_Subj.(subjID).(roiName) = roi_tfr;
    end
end

subjectNames = fieldnames(TFR_Subj);

assert(~isempty(subjectNames), ...
    'No participant-level results were generated.');

fprintf('\nSubjects retained: %d\n', numel(subjectNames));

%% =========================================================================
% Group-level TFR
%% =========================================================================

TFR_Group = struct();

fprintf('\n=====================================\n');
fprintf('GROUP-LEVEL CHANNEL-FIRST TFR\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    TFR_Group.(roiName) = average_group_tfr(TFR_Subj, roiName);

    groupData = TFR_Group.(roiName);

    assert(isfield(groupData, 'Consonant') && ...
        isfield(groupData, 'Dissonant') && ...
        isfield(groupData, 'Difference'), ...
        '%s: missing condition/difference field.', roiName);

    fprintf('Built ROI: %s | [%d freq x %d time]\n', ...
        roiName, ...
        size(groupData.Consonant.power, 1), ...
        size(groupData.Consonant.power, 2));
end

%% =========================================================================
% Shared colour limits
%% =========================================================================

allConditionPower = [];
allDifferencePower = [];

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    groupData = TFR_Group.(roiName);

    allConditionPower = [ ...
        allConditionPower; ...
        groupData.Consonant.power(:); ...
        groupData.Dissonant.power(:)];

    allDifferencePower = [ ...
        allDifferencePower; ...
        groupData.Difference.power(:)];
end

conditionCLim = prctile(allConditionPower, [2 98]);

differenceAbsMax = prctile(abs(allDifferencePower), 98);

if isempty(differenceAbsMax) || isnan(differenceAbsMax) || ...
        differenceAbsMax == 0
    differenceAbsMax = max(abs(allDifferencePower));
end

fprintf('\n=====================================\n');
fprintf('GLOBAL COLOR LIMITS (µV^2)\n');
fprintf('=====================================\n');
fprintf('Conditions: [%.4f, %.4f]\n', ...
    conditionCLim(1), conditionCLim(2));
fprintf('Difference: ±%.4f\n', differenceAbsMax);

%% =========================================================================
% ROI FIGURES - ALL BANDS
%% =========================================================================

bandStats = struct();

bandNames = fieldnames(cfgTFR.freqBands);

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    groupData = TFR_Group.(roiName);

    time = groupData.time(:)';
    freq = groupData.freq(:);

    conMap = groupData.Consonant.power;
    disMap = groupData.Dissonant.power;
    difMap = groupData.Difference.power;

    idxPlotTime = ...
        time >= cfgTFR.plot_time_win(1) & ...
        time <= cfgTFR.plot_time_win(2);

    timePlot = time(idxPlotTime)*1000;

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        bandRange = cfgTFR.freqBands.(bandName);

        idxBand = ...
            freq >= bandRange(1) & ...
            freq <= bandRange(2);

        bandConTime = ...
            mean(conMap(idxBand,:),1,'omitnan');

        bandDisTime = ...
            mean(disMap(idxBand,:),1,'omitnan');

        bandDifTime = ...
            mean(difMap(idxBand,:),1,'omitnan');

        bandStats.(roiName).(bandName).time = time;
        bandStats.(roiName).(bandName).Consonant = bandConTime;
        bandStats.(roiName).(bandName).Dissonant = bandDisTime;
        bandStats.(roiName).(bandName).Difference = bandDifTime;
        bandStats.(roiName).(bandName).freqRange = bandRange;

        bandFigDir = fullfile(figDir,bandName);

        figure('Color','w','Position',[100 100 1000 500]);

        plot(time*1000,bandConTime,...
            'LineWidth',2);

        hold on

        plot(time*1000,bandDisTime,...
            'LineWidth',2);

        xline(0,'k--');
        yline(0,'k--');

        xlabel('Time (ms)');
        ylabel('\muV^2');

        title(sprintf('%s - %s', ...
            roiName,bandName));

        legend('Consonant','Dissonant');

        grid on

        saveas(gcf,...
            fullfile(bandFigDir,...
            sprintf('%s_ConDis_%s.png', ...
            bandName,roiName)));

        close

        figure('Color','w','Position',[100 100 1000 500]);

        plot(time*1000,bandDifTime,...
            'k','LineWidth',2);

        hold on

        xline(0,'k--');
        yline(0,'k--');

        xlabel('Time (ms)');
        ylabel('\muV^2');

        title(sprintf('%s Difference - %s', ...
            bandName,roiName));

        grid on

        saveas(gcf,...
            fullfile(bandFigDir,...
            sprintf('%s_Difference_%s.png', ...
            bandName,roiName)));

        close

        figure('Color','w',...
            'Position',[100 100 1050 900]);

        subplot(3,1,1)

        imagesc(timePlot,...
            freq(idxBand),...
            conMap(idxBand,idxPlotTime))

        axis xy

        colorbar

        ylabel('Hz')

        title('Consonant')

        subplot(3,1,2)

        imagesc(timePlot,...
            freq(idxBand),...
            disMap(idxBand,idxPlotTime))

        axis xy

        colorbar

        ylabel('Hz')

        title('Dissonant')

        subplot(3,1,3)

        imagesc(timePlot,...
            freq(idxBand),...
            difMap(idxBand,idxPlotTime))

        axis xy

        colorbar

        ylabel('Hz')
        xlabel('Time (ms)')

        title('Difference')

        sgtitle(sprintf('%s - %s', ...
            roiName,bandName));

        saveas(gcf,...
            fullfile(bandFigDir,...
            sprintf('TFR_%s_%s.png', ...
            bandName,roiName)));

        close

    end
end

%% =========================================================================
% CHANNEL-LEVEL TOPOPLOTS
%
% The input is one channel at a time, so ROI-first and channel-first are
% mathematically identical for these maps. This block is retained to produce
% an independent saved output for the channel-first analysis.
%% =========================================================================

fprintf('\n=====================================\n');
fprintf('MULTI-BAND TOPOPLOTS\n');
fprintf('=====================================\n');

allChanLocs = subj_list(1).data_trials(1).chanlocs;
allChanLabels = {allChanLocs.labels};

nChan = numel(allChanLabels);
nTime = numel(cfgTFR.time);

assert(nChan > 0, ...
    'No channel locations found.');

assert(isfield(allChanLocs, 'X') || isfield(allChanLocs, 'theta'), ...
    ['Channel coordinates are missing. ' ...
    'chanlocs must contain spatial information for topoplot.']);

bandNames = fieldnames(cfgTFR.freqBands);

Topo_Group = struct();

for b = 1:numel(bandNames)

    bandName = bandNames{b};

    bandRange = cfgTFR.freqBands.(bandName);

    fprintf('\n=====================================\n');
    fprintf('TOPOPLOTS : %s [%d-%d Hz]\n', ...
        bandName, ...
        bandRange(1), ...
        bandRange(2));
    fprintf('=====================================\n');

    idxTopoFreq = ...
        cfgTFR.freqs >= bandRange(1) & ...
        cfgTFR.freqs <= bandRange(2);

    topoConBandTime = ...
        nan(nSubjects,nChan,nTime,'single');

    topoDisBandTime = ...
        nan(nSubjects,nChan,nTime,'single');

    for iSub = 1:nSubjects

        subj_curr = subj_list(iSub);

        subjID = matlab.lang.makeValidName(char(subj_curr.subj_id));

        fprintf('Topography subject %d/%d: %s\n', ...
            iSub, nSubjects, subjID);

        for ch = 1:nChan

            cfgChan = cfgTFR;
            cfgChan.roi_labels = allChanLabels(ch);

            chanTFR = extract_roi_tfr_park(subj_curr, cfgChan);

            if isempty(chanTFR) || ...
                    ~isfield(chanTFR, 'Consonant') || ...
                    ~isfield(chanTFR, 'Dissonant')

                warning('%s | %s: no channel-level TFR.', ...
                    subjID, allChanLabels{ch});
                continue
            end

            topoConBandTime(iSub,ch,:) = single( ...
                mean(chanTFR.Consonant.power(idxTopoFreq,:), ...
                1,'omitnan'));

            topoDisBandTime(iSub,ch,:) = single( ...
                mean(chanTFR.Dissonant.power(idxTopoFreq,:), ...
                1,'omitnan'));
        end
    end
    topoWindowNames = fieldnames(cfgTFR.topo_windows);

    for w = 1:numel(topoWindowNames)

        windowName = topoWindowNames{w};
        currentWin = cfgTFR.topo_windows.(windowName);

        idxTopoTime = cfgTFR.time >= currentWin(1) & ...
            cfgTFR.time <= currentWin(2);

        assert(any(idxTopoTime), ...
            'No samples in topoplot window %s.', windowName);

        conSubChan = squeeze(mean( ...
            topoConBandTime(:,:,idxTopoTime), ...
            3,'omitnan'));

        disSubChan = squeeze(mean( ...
            topoDisBandTime(:,:,idxTopoTime), ...
            3,'omitnan'));

        if nSubjects == 1
            conSubChan = reshape(conSubChan, 1, nChan);
            disSubChan = reshape(disSubChan, 1, nChan);
        end

        assert(isequal(size(conSubChan), [nSubjects nChan]), ...
            '%s: unexpected Consonant dimensions.', windowName);

        assert(isequal(size(disSubChan), [nSubjects nChan]), ...
            '%s: unexpected Dissonant dimensions.', windowName);

        difSubChan = conSubChan - disSubChan;

        Topo_Group.(bandName).(windowName).labels = allChanLabels;
        Topo_Group.(bandName).(windowName).chanlocs = allChanLocs;
        Topo_Group.(bandName).(windowName).freq_win = bandRange;
        Topo_Group.(bandName).(windowName).time_win = currentWin;

        Topo_Group.(bandName).(windowName).Consonant_Subject = conSubChan;
        Topo_Group.(bandName).(windowName).Dissonant_Subject = disSubChan;
        Topo_Group.(bandName).(windowName).Difference_Subject = difSubChan;

        Topo_Group.(bandName).(windowName).Consonant = ...
            mean(conSubChan, 1, 'omitnan');

        Topo_Group.(bandName).(windowName).Dissonant = ...
            mean(disSubChan, 1, 'omitnan');

        Topo_Group.(bandName).(windowName).Difference = ...
            mean(difSubChan, 1, 'omitnan');

        condTopoLimit = max(abs([ ...
            Topo_Group.(bandName).(windowName).Consonant, ...
            Topo_Group.(bandName).(windowName).Dissonant]), ...
            [], 'omitnan');

        diffTopoLimit = max(abs( ...
            Topo_Group.(bandName).(windowName).Difference), ...
            [], 'omitnan');

        if isempty(condTopoLimit) || isnan(condTopoLimit) || ...
                condTopoLimit == 0
            condTopoLimit = 1;
        end

        if isempty(diffTopoLimit) || isnan(diffTopoLimit) || ...
                diffTopoLimit == 0
            diffTopoLimit = 1;
        end

        fig = figure('Color', 'w', ...
            'Position', [100 100 1450 500]);

        subplot(1,3,1)
        topoplot(Topo_Group.(bandName).(windowName).Consonant, ...
            allChanLocs, ...
            'maplimits', [-condTopoLimit condTopoLimit], ...
            'electrodes', 'on', ...
            'style', 'map', ...
            'numcontour', 6);
        colorbar
        title('Consonant')

        subplot(1,3,2)
        topoplot(Topo_Group.(bandName).(windowName).Dissonant, ...
            allChanLocs, ...
            'maplimits', [-condTopoLimit condTopoLimit], ...
            'electrodes', 'on', ...
            'style', 'map', ...
            'numcontour', 6);
        colorbar
        title('Dissonant')

        subplot(1,3,3)
        topoplot(Topo_Group.(bandName).(windowName).Difference, ...
            allChanLocs, ...
            'maplimits', [-diffTopoLimit diffTopoLimit], ...
            'electrodes', 'on', ...
            'style', 'map', ...
            'numcontour', 6);
        colorbar
        title('Consonant - Dissonant')

        sgtitle(sprintf(...
            '%s band (%d-%d Hz), %d-%d ms (\\muV^2)', ...
            bandName,...
            bandRange(1),...
            bandRange(2),...
            round(currentWin(1)*1000),...
            round(currentWin(2)*1000)));

        bandTopoDir = fullfile(topoDir,bandName);

        if ~exist(bandTopoDir,'dir')
            mkdir(bandTopoDir);
        end

        saveas(fig, ...
            fullfile(bandTopoDir, ...
            sprintf('%s_%s_%d_%dms.png', ...
            bandName,...
            windowName,...
            round(currentWin(1)*1000), ...
            round(currentWin(2)*1000))));


        close(fig)

        fprintf('Saved channel-first topoplot: %s [%d, %d] ms\n', ...
            windowName, ...
            round(currentWin(1) * 1000), ...
            round(currentWin(2) * 1000));
    end
end
%% =========================================================================
% Save results
%% =========================================================================

save( ...
    fullfile(outputRoot,...
    'STEP4C_TFR_SUBJECT_LINEAR.mat'), ...
    'TFR_Subj', ...
    'TFR_Group', ...
    'bandStats', ...
    'Topo_Group', ...
    'allChanLocs', ...
    'allChanLabels', ...
    'cfgTFR', ...
    '-v7.3');

fprintf('\n=====================================\n');
fprintf('PARK CHANNEL-FIRST LINEAR ANALYSIS COMPLETED\n');
fprintf('=====================================\n');

set(0, 'DefaultFigureVisible', origState);