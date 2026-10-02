%% =========================================================================
% STEP4B_TFR_MORLET_LINEAR
%% =========================================================================
%
% Channel-first induced gamma analysis using Park et al. (2011)
% parameters.
%
% Pipeline:
%
% Single trial
%   -> Morlet TFR at each ROI electrode
%   -> Power = |Z|^2
%   -> Absolute baseline correction [-200 -50] ms
%   -> Average across ROI electrodes
%   -> Average across trials
%   -> Subject-level TFR
%   -> Group-level TFR
%
% The original Park et al. paper does not state the exact order
% of ROI averaging and time-frequency decomposition. This script
% provides a channel-first sensitivity/modern implementation.
%
% Frequencies      : 30-60 Hz, 1-Hz steps
% Morlet cycles    : 7
% Baseline         : -0.200 to -0.050 s
% Output unit      : µV^2
% Display range    : -0.200 to 1.000 s
% Gamma window     : 30-60 Hz, 100-250 ms
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
    'PARK_CHANNELFIRST_LINEAR_UV2','ALL_ROI');

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

cfgTFR.freqs = 30:1:60;
cfgTFR.nCycles = 7;

% Park prestimulus baseline
cfgTFR.baseline_win = [-0.200 -0.050];

% Main Park gamma window
cfgTFR.gamma_freq_win = [30 60];
cfgTFR.gamma_time_win = [0.100 0.250];

% Visualization only; full epoch remains used for TFR
cfgTFR.plot_time_win = [-0.200 1.000];

% Multiple descriptive/confirmatory topography windows
cfgTFR.topo_windows = struct();

cfgTFR.topo_windows.Park_100_250 = [0.100 0.250];
cfgTFR.topo_windows.ParkPeak_150_200 = [0.150 0.200];
cfgTFR.topo_windows.Early_170_220 = [0.170 0.220];
cfgTFR.topo_windows.Post_220_320 = [0.220 0.320];
cfgTFR.topo_windows.Late_450_550 = [0.450 0.550];

cfgTFR.srate = Fs;
cfgTFR.time = time0;
cfgTFR.save_trial_level = false;

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
% ROI figures and gamma time courses
%% =========================================================================

gammaStats = struct();

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    groupData = TFR_Group.(roiName);

    time = groupData.time(:)';
    freq = groupData.freq(:);

    conMap = groupData.Consonant.power;
    disMap = groupData.Dissonant.power;
    difMap = groupData.Difference.power;

    assert(size(conMap, 2) == numel(time), ...
        '%s: time dimensions mismatch.', roiName);

    % ---------------------------------------------------------------------
    % Gamma time courses
    % ---------------------------------------------------------------------
    idxGamma = freq >= cfgTFR.gamma_freq_win(1) & ...
               freq <= cfgTFR.gamma_freq_win(2);

    assert(any(idxGamma), ...
        '%s: no samples in gamma band.', roiName);

    gammaConTime = mean(conMap(idxGamma,:), 1, 'omitnan');
    gammaDisTime = mean(disMap(idxGamma,:), 1, 'omitnan');
    gammaDifTime = mean(difMap(idxGamma,:), 1, 'omitnan');

    idxBaseline = time >= cfgTFR.baseline_win(1) & ...
                  time <= cfgTFR.baseline_win(2);

    fprintf('\nBaseline check — %s\n', roiName);
    fprintf('Consonant gamma baseline mean: %.8f µV^2\n', ...
        mean(gammaConTime(idxBaseline), 'omitnan'));
    fprintf('Dissonant gamma baseline mean: %.8f µV^2\n', ...
        mean(gammaDisTime(idxBaseline), 'omitnan'));

    idxStatTime = time >= cfgTFR.gamma_time_win(1) & ...
                  time <= cfgTFR.gamma_time_win(2);

    gammaStats.(roiName).TimeCourse.time = time;
    gammaStats.(roiName).TimeCourse.Consonant = gammaConTime;
    gammaStats.(roiName).TimeCourse.Dissonant = gammaDisTime;
    gammaStats.(roiName).TimeCourse.Difference = gammaDifTime;

    gammaStats.(roiName).Window = cfgTFR.gamma_time_win;
    gammaStats.(roiName).Consonant = ...
        mean(gammaConTime(idxStatTime), 'omitnan');
    gammaStats.(roiName).Dissonant = ...
        mean(gammaDisTime(idxStatTime), 'omitnan');
    gammaStats.(roiName).Difference = ...
        mean(gammaDifTime(idxStatTime), 'omitnan');

    fprintf('\n%s | 30-60 Hz, 100-250 ms\n', roiName);
    fprintf('  Consonant : %.5f µV^2\n', ...
        gammaStats.(roiName).Consonant);
    fprintf('  Dissonant : %.5f µV^2\n', ...
        gammaStats.(roiName).Dissonant);
    fprintf('  Difference: %.5f µV^2\n', ...
        gammaStats.(roiName).Difference);

    % ---------------------------------------------------------------------
    % TFR panels shown only from -200 to 1000 ms
    % ---------------------------------------------------------------------
    idxPlotTime = time >= cfgTFR.plot_time_win(1) & ...
                  time <= cfgTFR.plot_time_win(2);

    assert(any(idxPlotTime), ...
        '%s: no samples in display range.', roiName);

    timePlot = time(idxPlotTime) * 1000;

    conMapPlot = conMap(:, idxPlotTime);
    disMapPlot = disMap(:, idxPlotTime);
    difMapPlot = difMap(:, idxPlotTime);

    fig = figure('Color', 'w', ...
        'Position', [100 100 1050 900]);

    subplot(3,1,1)
    imagesc(timePlot, freq, conMapPlot)
    axis xy
    clim(conditionCLim)
    colorbar
    xline(0, 'k--', 'LineWidth', 1)
    xline(cfgTFR.gamma_time_win(1) * 1000, 'k:', 'LineWidth', 1)
    xline(cfgTFR.gamma_time_win(2) * 1000, 'k:', 'LineWidth', 1)
    xlim(cfgTFR.plot_time_win * 1000)
    xlabel('Time (ms)')
    ylabel('Frequency (Hz)')
    title(sprintf('%s — Consonant', format_tex_name(roiName)))

    subplot(3,1,2)
    imagesc(timePlot, freq, disMapPlot)
    axis xy
    clim(conditionCLim)
    colorbar
    xline(0, 'k--', 'LineWidth', 1)
    xline(cfgTFR.gamma_time_win(1) * 1000, 'k:', 'LineWidth', 1)
    xline(cfgTFR.gamma_time_win(2) * 1000, 'k:', 'LineWidth', 1)
    xlim(cfgTFR.plot_time_win * 1000)
    xlabel('Time (ms)')
    ylabel('Frequency (Hz)')
    title(sprintf('%s — Dissonant', format_tex_name(roiName)))

    subplot(3,1,3)
    imagesc(timePlot, freq, difMapPlot)
    axis xy
    clim([-differenceAbsMax differenceAbsMax])
    colorbar
    xline(0, 'k--', 'LineWidth', 1)
    xline(cfgTFR.gamma_time_win(1) * 1000, 'k:', 'LineWidth', 1)
    xline(cfgTFR.gamma_time_win(2) * 1000, 'k:', 'LineWidth', 1)
    xlim(cfgTFR.plot_time_win * 1000)
    xlabel('Time (ms)')
    ylabel('Frequency (Hz)')
    title(sprintf('%s — Consonant minus Dissonant', ...
        format_tex_name(roiName)))

    sgtitle('Induced gamma power, baseline-corrected (\muV^2)')

    saveas(fig, fullfile(figDir, ...
        sprintf('TFR_ChannelFirst_%s.png', roiName)));

    close(fig)

    % ---------------------------------------------------------------------
    % Plot 1: consonant vs dissonant
    % ---------------------------------------------------------------------
    fig = figure('Color', 'w', ...
        'Position', [100 100 1000 500]);

    plot(time * 1000, gammaConTime, ...
        'LineWidth', 2, ...
        'Color', [0.75 0.20 0.20]);
    hold on

    plot(time * 1000, gammaDisTime, ...
        'LineWidth', 2, ...
        'Color', [0.20 0.25 0.70]);

    xline(0, 'k--', 'LineWidth', 1);
    yline(0, 'k--', 'LineWidth', 1);
    xlim(cfgTFR.plot_time_win * 1000)

    xlabel('Time (ms)')
    ylabel('Induced gamma power change (\muV^2)')
    legend('Consonant chord', 'Dissonant chord', ...
        'Location', 'northeast')
    title(sprintf('Gamma time course (30-60 Hz) — %s', ...
        format_tex_name(roiName)))
    grid on
    box off

    saveas(fig, fullfile(figDir, ...
        sprintf('Gamma_ConDis_ChannelFirst_%s.png', roiName)));

    close(fig)

    % ---------------------------------------------------------------------
    % Plot 2: consonant vs dissonant vs difference
    % ---------------------------------------------------------------------
    fig = figure('Color', 'w', ...
        'Position', [100 100 1000 500]);

    plot(time * 1000, gammaConTime, ...
        'LineWidth', 2, ...
        'Color', [0.75 0.20 0.20]);
    hold on

    plot(time * 1000, gammaDisTime, ...
        'LineWidth', 2, ...
        'Color', [0.20 0.25 0.70]);

    plot(time * 1000, gammaDifTime, ...
        'k--', ...
        'LineWidth', 1.8);

    xline(0, 'k--', 'LineWidth', 1);
    yline(0, 'k--', 'LineWidth', 1);
    xlim(cfgTFR.plot_time_win * 1000)

    xlabel('Time (ms)')
    ylabel('Induced gamma power change (\muV^2)')
    legend('Consonant chord', 'Dissonant chord', ...
        'Consonant - Dissonant', ...
        'Location', 'northeast')
    title(sprintf('Gamma time course (30-60 Hz) — %s', ...
        format_tex_name(roiName)))
    grid on
    box off

    saveas(fig, fullfile(figDir, ...
        sprintf('Gamma_ConDisDiff_ChannelFirst_%s.png', roiName)));

    close(fig)

    % ---------------------------------------------------------------------
    % Plot 3: difference only
    % ---------------------------------------------------------------------
    fig = figure('Color', 'w', ...
        'Position', [100 100 1000 500]);

    plot(time * 1000, gammaDifTime, ...
        'k-', ...
        'LineWidth', 2);
    hold on

    xline(0, 'k--', 'LineWidth', 1);
    yline(0, 'k--', 'LineWidth', 1);
    xlim(cfgTFR.plot_time_win * 1000)

    xlabel('Time (ms)')
    ylabel('Consonant - Dissonant (\muV^2)')
    title(sprintf('Gamma difference time course (30-60 Hz) — %s', ...
        format_tex_name(roiName)))
    grid on
    box off

    saveas(fig, fullfile(figDir, ...
        sprintf('Gamma_Difference_ChannelFirst_%s.png', roiName)));

    close(fig)
end

%% =========================================================================
% CHANNEL-LEVEL TOPOPLOTS
%
% The input is one channel at a time, so ROI-first and channel-first are
% mathematically identical for these maps. This block is retained to produce
% an independent saved output for the channel-first analysis.
%% =========================================================================

fprintf('\n=====================================\n');
fprintf('CHANNEL-LEVEL TOPOPLOTS\n');
fprintf('Frequency range: %d-%d Hz\n', ...
    cfgTFR.gamma_freq_win(1), ...
    cfgTFR.gamma_freq_win(2));
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

idxTopoFreq = cfgTFR.freqs >= cfgTFR.gamma_freq_win(1) & ...
              cfgTFR.freqs <= cfgTFR.gamma_freq_win(2);

assert(any(idxTopoFreq), ...
    'No frequency samples in requested topoplot band.');

topoConGammaTime = nan(nSubjects, nChan, nTime, 'single');
topoDisGammaTime = nan(nSubjects, nChan, nTime, 'single');

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

        topoConGammaTime(iSub,ch,:) = single( ...
            mean(chanTFR.Consonant.power(idxTopoFreq,:), ...
            1, 'omitnan'));

        topoDisGammaTime(iSub,ch,:) = single( ...
            mean(chanTFR.Dissonant.power(idxTopoFreq,:), ...
            1, 'omitnan'));
    end
end

Topo_Group = struct();

topoWindowNames = fieldnames(cfgTFR.topo_windows);

for w = 1:numel(topoWindowNames)

    windowName = topoWindowNames{w};
    currentWin = cfgTFR.topo_windows.(windowName);

    idxTopoTime = cfgTFR.time >= currentWin(1) & ...
                  cfgTFR.time <= currentWin(2);

    assert(any(idxTopoTime), ...
        'No samples in topoplot window %s.', windowName);

    conSubChan = squeeze(mean( ...
        topoConGammaTime(:,:,idxTopoTime), ...
        3, 'omitnan'));

    disSubChan = squeeze(mean( ...
        topoDisGammaTime(:,:,idxTopoTime), ...
        3, 'omitnan'));

    if nSubjects == 1
        conSubChan = reshape(conSubChan, 1, nChan);
        disSubChan = reshape(disSubChan, 1, nChan);
    end

    assert(isequal(size(conSubChan), [nSubjects nChan]), ...
        '%s: unexpected Consonant dimensions.', windowName);

    assert(isequal(size(disSubChan), [nSubjects nChan]), ...
        '%s: unexpected Dissonant dimensions.', windowName);

    difSubChan = conSubChan - disSubChan;

    Topo_Group.(windowName).labels = allChanLabels;
    Topo_Group.(windowName).chanlocs = allChanLocs;
    Topo_Group.(windowName).freq_win = cfgTFR.gamma_freq_win;
    Topo_Group.(windowName).time_win = currentWin;

    Topo_Group.(windowName).Consonant_Subject = conSubChan;
    Topo_Group.(windowName).Dissonant_Subject = disSubChan;
    Topo_Group.(windowName).Difference_Subject = difSubChan;

    Topo_Group.(windowName).Consonant = ...
        mean(conSubChan, 1, 'omitnan');

    Topo_Group.(windowName).Dissonant = ...
        mean(disSubChan, 1, 'omitnan');

    Topo_Group.(windowName).Difference = ...
        mean(difSubChan, 1, 'omitnan');

    condTopoLimit = max(abs([ ...
        Topo_Group.(windowName).Consonant, ...
        Topo_Group.(windowName).Dissonant]), ...
        [], 'omitnan');

    diffTopoLimit = max(abs( ...
        Topo_Group.(windowName).Difference), ...
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
    topoplot(Topo_Group.(windowName).Consonant, ...
        allChanLocs, ...
        'maplimits', [-condTopoLimit condTopoLimit], ...
        'electrodes', 'on', ...
        'style', 'map', ...
        'numcontour', 6);
    colorbar
    title('Consonant')

    subplot(1,3,2)
    topoplot(Topo_Group.(windowName).Dissonant, ...
        allChanLocs, ...
        'maplimits', [-condTopoLimit condTopoLimit], ...
        'electrodes', 'on', ...
        'style', 'map', ...
        'numcontour', 6);
    colorbar
    title('Dissonant')

    subplot(1,3,3)
    topoplot(Topo_Group.(windowName).Difference, ...
        allChanLocs, ...
        'maplimits', [-diffTopoLimit diffTopoLimit], ...
        'electrodes', 'on', ...
        'style', 'map', ...
        'numcontour', 6);
    colorbar
    title('Consonant - Dissonant')

    sgtitle(sprintf(...
        'Channel-first induced gamma: %d-%d Hz, %d-%d ms (\\muV^2)', ...
        cfgTFR.gamma_freq_win(1), ...
        cfgTFR.gamma_freq_win(2), ...
        round(currentWin(1) * 1000), ...
        round(currentWin(2) * 1000)));

    saveas(fig, fullfile(topoDir, ...
        sprintf('Topoplot_ChannelFirst_%s_%d_%dms.png', ...
        windowName, ...
        round(currentWin(1) * 1000), ...
        round(currentWin(2) * 1000))));

    close(fig)

    fprintf('Saved channel-first topoplot: %s [%d, %d] ms\n', ...
        windowName, ...
        round(currentWin(1) * 1000), ...
        round(currentWin(2) * 1000));
end

%% =========================================================================
% Save results
%% =========================================================================

save( ...
    fullfile(outputRoot, ...
    'STEP4B_TFR_MORLET_REPLICA_PARK_CHANNELFIRST_LINEAR_RESULTS.mat'), ...
    'TFR_Subj', ...
    'TFR_Group', ...
    'gammaStats', ...
    'Topo_Group', ...
    'topoConGammaTime', ...
    'topoDisGammaTime', ...
    'allChanLocs', ...
    'allChanLabels', ...
    'cfgTFR', ...
    '-v7.3');

fprintf('\n=====================================\n');
fprintf('PARK CHANNEL-FIRST LINEAR ANALYSIS COMPLETED\n');
fprintf('=====================================\n');

set(0, 'DefaultFigureVisible', origState);