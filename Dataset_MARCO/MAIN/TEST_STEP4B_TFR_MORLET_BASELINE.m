%% =========================================================================
% TEST_STEP4B_TFR_MORLET_BASELINE
% OLD file: STEP4B_TFR_MORLET_BASELINE
%% =========================================================================
%
% Full-spectrum Morlet Time-Frequency analysis
%
% Frequency range: 2-90 Hz
% Baseline:        -200 ms to 0 ms
% Baseline order:  AFTER averaging across ROI channels and trials
%
% Outputs:
%   TFR_Subj
%   TFR_Group
%   TFRBandResults
%   Band-specific summaries
%
% ROI strategy: channel_first
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

addpath('C:\Users\mirco\Desktop\eeglab2026.1.0');
eeglab nogui

set(groot, ...
    'defaultTextInterpreter','tex', ...
    'defaultAxesTickLabelInterpreter','tex', ...
    'defaultLegendInterpreter','tex');

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
step4_outroot = fullfile( ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO', ...
    'STEP4B_TFR_MORLET_BASELINE');

if ~exist(step4_outroot,'dir')
    mkdir(step4_outroot);
end

%% ============================================================
% LOAD DATA
%% ============================================================
step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

% Time check
time0 = subj_list(1).data_trials(1).time;

for i = 1:numel(subj_list)
    t = subj_list(i).data_trials(1).time;
    assert(isequal(size(t),size(time0)), ...
        'Time vector size mismatch');
end

% Sampling-rate check
Fs_all = zeros(numel(subj_list),1);

for i = 1:numel(subj_list)
    Fs_all(i) = subj_list(i).data_trials(1).srate;
end

assert(numel(unique(Fs_all))==1, ...
    'Sampling rates differ across subjects');

assert(Fs_all(1) >= 180, ...
    'Fs troppo bassa per analizzare fino a 90 Hz');

fprintf('\n');
fprintf('=====================================\n');
fprintf('LOAD COMPLETED\n');
fprintf('Subjects : %d\n',numel(subj_list));
fprintf('Fs       : %.1f Hz\n',Fs_all(1));
fprintf('=====================================\n');

%% ============================================================
% ANALYSIS CONFIGURATION
%% ============================================================
cfgTFR = struct();

% ------------------------------------------------------------
% PROCESSING MODE
% ------------------------------------------------------------
cfgTFR.method = 'channel_first';
% 'channel_first' or 'roi_first'

cfgTFR.nameConditions = 'Consonance';
cfgTFR.conditions = { ...
    'Consonant', ...
    'Dissonant'};
cfgTFR.cond_field = 'eventLabel';

% ------------------------------------------------------------
% TFR PARAMETERS
% ------------------------------------------------------------
cfgTFR.freqs = 2:1:90;

% Frequency-dependent number of cycles:
% 3 cycles at low frequencies, 7 cycles from 28 Hz upward
cfgTFR.nCycles = max(3,round(cfgTFR.freqs / 4));

cfgTFR.baseline_win = [-0.2 0];
cfgTFR.save_trial_level = false;

cfgTFR.srate = Fs_all(1);
cfgTFR.time  = time0;

% ------------------------------------------------------------
% ACTIVE ROIS
% ------------------------------------------------------------
cfgTFR.analysis_rois = { ...
    'ERAN_CORE', ...
    'MMN', ...
    'FrontoCentral', ...
    'N5_CENTRAL'};

% ------------------------------------------------------------
% ACTIVE BANDS
% ------------------------------------------------------------
cfgTFR.activeBands = { ...
    'Delta', ...
    'Theta', ...
    'Alpha', ...
    'BetaLow', ...
    'BetaHigh', ...
    'GammaLow', ...
    'GammaHigh'};

% ------------------------------------------------------------
% SUMMARY WINDOWS
% ------------------------------------------------------------
% These windows are used to extract numerical band summaries.
cfgTFR.summary_windows.Global   = [0.00 0.80];
cfgTFR.summary_windows.EarlyNeg = [0.17 0.22];
cfgTFR.summary_windows.Rebound  = [0.22 0.32];
cfgTFR.summary_windows.Late     = [0.45 0.55];

%% ============================================================
% BAND DEFINITIONS
%% ============================================================
BandRanges = struct();
BandRanges.Delta     = [2 4];
BandRanges.Theta     = [4 8];
BandRanges.Alpha     = [8 13];
BandRanges.BetaLow   = [13 20];
BandRanges.BetaHigh  = [20 30];
BandRanges.GammaLow  = [30 40];
BandRanges.GammaHigh = [40 90];

%% ============================================================
% PLOT CONFIGURATION
%% ============================================================
cfgPlot = struct();

cfgPlot.groupTFR            = true;
cfgPlot.bandTimeCourses     = true;
cfgPlot.broadbandTimeCourse = true;

cfgPlot.zoomedTFR        = true;
cfgPlot.differenceOnly   = false;
cfgPlot.differenceZoomed = false;

cfgPlot.saveFigures  = true;
cfgPlot.closeFigures = true;

% ------------------------------------------------------------
% ZOOM WINDOWS
% ------------------------------------------------------------
% These windows are used ONLY for zoomed TFR figures.
cfgPlot.windows = struct();
cfgPlot.windows.ERAN = [0.15 0.25];
cfgPlot.windows.MMN  = [0.10 0.25];
cfgPlot.windows.N5   = [0.45 0.55];

cfgPlot.windows.EarlyNeg_170_220 = [0.17 0.22];
cfgPlot.windows.Rebound_220_320  = [0.22 0.32];
cfgPlot.windows.Late_450_550     = [0.45 0.55];

cfgPlot.windows.Post_100_250 = [0.10 0.25];
cfgPlot.windows.Post_250_500 = [0.25 0.50];
cfgPlot.windows.Post_500_800 = [0.50 0.80];

% ------------------------------------------------------------
% DISPLAY WINDOW
% ------------------------------------------------------------
cfgTFR.plot_time_win = [-0.2 1.0];

%% ============================================================
% ROI DEFINITIONS
%% ============================================================
MAIN_ROI

roiFields = fieldnames(ROI);
missingRois = setdiff(cfgTFR.analysis_rois,roiFields);

assert(isempty(missingRois), ...
    'ROI mancanti in MAIN_ROI: %s', ...
    strjoin(missingRois,', '));

cfgTFR.rois = ROI;
roiNames = cfgTFR.analysis_rois;

fprintf('\n');
fprintf('=====================================\n');
fprintf('ROI CONFIGURATION\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)
    fprintf('%02d) %s\n',r,roiNames{r});
    disp(cfgTFR.rois.(roiNames{r})');
end

%% ============================================================
% OUTPUT FOLDER
%% ============================================================
tfrdir = fullfile( ...
    step4_outroot, ...
    'PARK_CHANNELFIRST_TFR', ...
    cfgTFR.method);

if ~exist(tfrdir,'dir')
    mkdir(tfrdir);
end

subDirs = { ...
    'ConVsDis', ...
    'Difference', ...
    'ConDisDiff', ...
    'Zoomed_TFR', ...
    'Difference_Only', ...
    'Difference_Zoomed'};

for d = 1:numel(subDirs)
    outSubDir = fullfile(tfrdir,subDirs{d});
    if ~exist(outSubDir,'dir')
        mkdir(outSubDir);
    end
end

fprintf('\n');
fprintf('Output folder:\n');
fprintf('%s\n',tfrdir);

%% ============================================================
% WINDOW NAMES
%% ============================================================
% Summary windows: used for TFRBandResults
summaryWindowNames = fieldnames(cfgTFR.summary_windows);

% Plot windows: used only for zoomed TFR figures
plotWindowNames = fieldnames(cfgPlot.windows);

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
    subjID = matlab.lang.makeValidName(char(subj_curr.subj_id));

    fprintf('\n');
    fprintf('-------------------------------------\n');
    fprintf('SUBJECT: %s\n',subjID);
    fprintf('-------------------------------------\n');

    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        fprintf('\n');
        fprintf('ROI : %s\n',roiName);

        cfgROI = cfgTFR;
        cfgROI.roi_labels = cfgTFR.rois.(roiName);

        roi_tfr = extract_roi_tfrBASELINE( ...
            subj_curr, ...
            cfgROI);

        if isempty(roi_tfr)
            warning('%s | %s empty result',subjID,roiName);
            continue
        end

        TFR_Subj.(subjID).(roiName) = roi_tfr;

        if isfield(roi_tfr,'Consonant')
            sz = size(roi_tfr.Consonant.power);
            fprintf('Consonant TFR: [%d x %d]\n',sz(1),sz(2));
        end

        if isfield(roi_tfr,'Dissonant')
            sz = size(roi_tfr.Dissonant.power);
            fprintf('Dissonant TFR: [%d x %d]\n',sz(1),sz(2));
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

fprintf('Subjects processed: %d\n',numel(subjectNames));

assert(~isempty(subjectNames), ...
    'No subject results generated');

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

    hasRoi = false;

    for s = 1:numel(subjectNames)
        if isfield(TFR_Subj.(subjectNames{s}),roiName)
            hasRoi = true;
            break
        end
    end

    assert(hasRoi, ...
        'Nessun soggetto ha risultati per la ROI %s',roiName);

    TFR_Group.(roiName) = average_group_tfr(TFR_Subj,roiName);
end

%% ============================================================
% GLOBAL COLOR LIMITS
%% ============================================================
allPower = [];
allDiff  = [];

for r = 1:numel(roiNames)

    roiName = roiNames{r};
    groupData = TFR_Group.(roiName);

    allPower = [ ...
        allPower; ...
        groupData.Consonant.power(:); ...
        groupData.Dissonant.power(:)];

    allDiff = [ ...
        allDiff; ...
        groupData.Difference.power(:)];
end

assert(~isempty(allPower), ...
    'Nessun dato TFR disponibile per i limiti colore');

assert(~isempty(allDiff), ...
    'Nessun dato Difference disponibile per i limiti colore');

GLOBAL_TFR_MIN = prctile(allPower,2);
GLOBAL_TFR_MAX = prctile(allPower,98);
GLOBAL_DIFF_MAX = prctile(abs(allDiff),98);

fprintf('\n');
fprintf('=====================================\n');
fprintf('GLOBAL COLOR LIMITS\n');
fprintf('=====================================\n');
fprintf('TFR  : [%.3f %.3f]\n',GLOBAL_TFR_MIN,GLOBAL_TFR_MAX);
fprintf('DIFF : +/- %.3f\n',GLOBAL_DIFF_MAX);
fprintf('=====================================\n');

%% ============================================================
% BAND SUMMARY FROM TFR
%% ============================================================
bandNames = cfgTFR.activeBands;

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    for w = 1:numel(summaryWindowNames)

        windowName = summaryWindowNames{w};
        currentWindow = cfgTFR.summary_windows.(windowName);

        for b = 1:numel(bandNames)

            bandName = bandNames{b};

            TFRBandResults.(roiName).(windowName).(bandName) = ...
                extract_tfr_window( ...
                TFR_Group.(roiName), ...
                BandRanges.(bandName), ...
                currentWindow);

        end
    end
end

%% ============================================================
% PLOTS
%% ============================================================
for r = 1:numel(roiNames)

    roiName = roiNames{r};
    groupData = TFR_Group.(roiName);
    diffMap = groupData.Difference.power;

    fprintf('\n');
    fprintf('ROI: %s\n',roiName);

    % --------------------------------------------------------
    % PRINT BAND SUMMARIES
    % --------------------------------------------------------
    for w = 1:numel(summaryWindowNames)

        windowName = summaryWindowNames{w};

        fprintf('\n');
        fprintf('--- %s ---\n',windowName);

        currBands = fieldnames( ...
            TFRBandResults.(roiName).(windowName));

        for b = 1:numel(currBands)

            bandName = currBands{b};
            stats = TFRBandResults.(roiName).(windowName).(bandName);

            fprintf( ...
                '%s | CON %.4f | DIS %.4f | DIFF %.4f\n', ...
                bandName, ...
                stats.Consonant, ...
                stats.Dissonant, ...
                stats.Difference);

        end
    end

    fprintf('Mean Broadband Difference: %.4f dB\n', ...
        mean(diffMap(:)));

    idxPlotTime = ...
        groupData.time >= cfgTFR.plot_time_win(1) & ...
        groupData.time <= cfgTFR.plot_time_win(2);

    timePlot = groupData.time(idxPlotTime);

    assert(any(idxPlotTime), ...
        'No samples inside cfgTFR.plot_time_win');

    % --------------------------------------------------------
    % MAIN GROUP TFR
    % --------------------------------------------------------
    if cfgPlot.groupTFR

        figure

        subplot(3,1,1)
        imagesc( ...
            timePlot, ...
            groupData.freq, ...
            groupData.Consonant.power(:,idxPlotTime))
        axis xy
        colorbar
        clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])
        title(sprintf('%s - Consonant',format_tex_name(roiName)))

        subplot(3,1,2)
        imagesc( ...
            timePlot, ...
            groupData.freq, ...
            groupData.Dissonant.power(:,idxPlotTime))
        axis xy
        colorbar
        clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])
        title(sprintf('%s - Dissonant',format_tex_name(roiName)))

        subplot(3,1,3)
        imagesc( ...
            timePlot, ...
            groupData.freq, ...
            diffMap(:,idxPlotTime))
        axis xy
        colorbar
        clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])
        title(sprintf('%s - Difference',format_tex_name(roiName)))

        if cfgPlot.saveFigures
            saveas(gcf, ...
                fullfile(tfrdir, ...
                sprintf('TFR_Group_%s.png',roiName)));
        end

        if cfgPlot.closeFigures
            close
        end

    end

    % --------------------------------------------------------
    % BROADBAND TIME COURSE
    % --------------------------------------------------------
    meanConTime = mean(groupData.Consonant.power,1);
    meanDisTime = mean(groupData.Dissonant.power,1);

    TFRBandResults.(roiName).Broadband.time = groupData.time;
    TFRBandResults.(roiName).Broadband.Consonant = meanConTime;
    TFRBandResults.(roiName).Broadband.Dissonant = meanDisTime;
    TFRBandResults.(roiName).Broadband.Difference = ...
        mean(groupData.Difference.power,1);

    if cfgPlot.broadbandTimeCourse

        figure
        plot(timePlot, ...
            meanConTime(idxPlotTime), ...
            'LineWidth',2)
        hold on
        plot(timePlot, ...
            meanDisTime(idxPlotTime), ...
            'LineWidth',2)
        xline(0,'k')
        legend('Consonant','Dissonant')
        xlabel('Time (s)')
        ylabel('Power (dB)')
        title(sprintf( ...
            'Broadband TFR Time Course - %s', ...
            format_tex_name(roiName)))

        if cfgPlot.saveFigures
            saveas(gcf, ...
                fullfile(tfrdir, ...
                sprintf('BroadbandTFRTimeCourse_%s.png',roiName)));
        end

        if cfgPlot.closeFigures
            close
        end

    end

    % --------------------------------------------------------
    % BAND-SPECIFIC TIME COURSES
    % --------------------------------------------------------
    if cfgPlot.bandTimeCourses

        for b = 1:numel(bandNames)

            bandName = bandNames{b};
            bandRange = BandRanges.(bandName);

            idxFreq = ...
                groupData.freq >= bandRange(1) & ...
                groupData.freq <= bandRange(2);

            assert(any(idxFreq), ...
                'Nessuna frequenza nella banda %s',bandName);

            conTime = mean( ...
                groupData.Consonant.power(idxFreq,:),1);
            disTime = mean( ...
                groupData.Dissonant.power(idxFreq,:),1);
            diffTime = mean( ...
                groupData.Difference.power(idxFreq,:),1);

            TFRBandResults.(roiName).TimeCourse.(bandName).time = ...
                groupData.time;
            TFRBandResults.(roiName).TimeCourse.(bandName).Consonant = ...
                conTime;
            TFRBandResults.(roiName).TimeCourse.(bandName).Dissonant = ...
                disTime;
            TFRBandResults.(roiName).TimeCourse.(bandName).Difference = ...
                diffTime;

            % Consonant vs Dissonant
            figure
            plot(timePlot, ...
                conTime(idxPlotTime), ...
                'LineWidth',2)
            hold on
            plot(timePlot, ...
                disTime(idxPlotTime), ...
                'LineWidth',2)
            xline(0,'k')
            legend('Consonant','Dissonant')
            xlabel('Time (s)')
            ylabel('Power (dB)')
            title(sprintf( ...
                '%s Time Course - %s - %s', ...
                bandName, ...
                format_tex_name(roiName), ...
                format_tex_name(cfgTFR.method)))

            if cfgPlot.saveFigures
                saveas(gcf, ...
                    fullfile(tfrdir,'ConVsDis', ...
                    sprintf('%s_TimeCourse_%s.png', ...
                    bandName,roiName)));
            end

            if cfgPlot.closeFigures
                close
            end

            % Difference
            figure
            plot(timePlot, ...
                diffTime(idxPlotTime), ...
                'k--', ...
                'LineWidth',2)
            xline(0,'k')
            legend('Difference (Dis-Cond)')
            xlabel('Time (s)')
            ylabel('Power (dB)')
            title(sprintf( ...
                '%s Time Course - %s - %s', ...
                bandName, ...
                format_tex_name(roiName), ...
                format_tex_name(cfgTFR.method)))

            if cfgPlot.saveFigures
                saveas(gcf, ...
                    fullfile(tfrdir,'Difference', ...
                    sprintf('%s_TimeCourse_%s.png', ...
                    bandName,roiName)));
            end

            if cfgPlot.closeFigures
                close
            end

            % Consonant, Dissonant and Difference
            figure
            plot(timePlot, ...
                conTime(idxPlotTime), ...
                'LineWidth',2)
            hold on
            plot(timePlot, ...
                disTime(idxPlotTime), ...
                'LineWidth',2)
            plot(timePlot, ...
                diffTime(idxPlotTime), ...
                'k--', ...
                'LineWidth',2)
            xline(0,'k')
            legend('Consonant','Dissonant','Difference')
            xlabel('Time (s)')
            ylabel('Power (dB)')
            title(sprintf( ...
                '%s Time Course - %s - %s', ...
                bandName, ...
                format_tex_name(roiName), ...
                format_tex_name(cfgTFR.method)))

            if cfgPlot.saveFigures
                saveas(gcf, ...
                    fullfile(tfrdir,'ConDisDiff', ...
                    sprintf('%s_TimeCourse_%s.png', ...
                    bandName,roiName)));
            end

            if cfgPlot.closeFigures
                close
            end

        end
    end

end

%% ============================================================
% ZOOMED TFR PLOTS
%% ============================================================
if cfgPlot.zoomedTFR

    zoomdir = fullfile(tfrdir,'Zoomed_TFR');

    if ~exist(zoomdir,'dir')
        mkdir(zoomdir);
    end

    for r = 1:numel(roiNames)

        roiName = roiNames{r};
        groupData = TFR_Group.(roiName);

        for w = 1:numel(plotWindowNames)

            winName = plotWindowNames{w};
            win = cfgPlot.windows.(winName);

            idxTime = ...
                groupData.time >= win(1) & ...
                groupData.time <= win(2);

            assert(any(idxTime), ...
                'Finestra %s fuori dal vettore temporale',winName);

            tPlot = groupData.time(idxTime);

            conMap = groupData.Consonant.power(:,idxTime);
            disMap = groupData.Dissonant.power(:,idxTime);
            diffMap = groupData.Difference.power(:,idxTime);

            figure('Position',[100 100 1000 900])

            subplot(3,1,1)
            imagesc(tPlot,groupData.freq,conMap)
            axis xy
            colorbar
            clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])
            title(sprintf('%s | %s | Consonant', ...
                format_tex_name(roiName), ...
                format_tex_name(winName)))
            xlabel('Time (s)')
            ylabel('Frequency (Hz)')

            subplot(3,1,2)
            imagesc(tPlot,groupData.freq,disMap)
            axis xy
            colorbar
            clim([GLOBAL_TFR_MIN GLOBAL_TFR_MAX])
            title(sprintf('%s | %s | Dissonant', ...
                format_tex_name(roiName), ...
                format_tex_name(winName)))
            xlabel('Time (s)')
            ylabel('Frequency (Hz)')

            subplot(3,1,3)
            imagesc(tPlot,groupData.freq,diffMap)
            axis xy
            colorbar
            clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])
            title(sprintf('%s | %s | Difference', ...
                format_tex_name(roiName), ...
                format_tex_name(winName)))
            xlabel('Time (s)')
            ylabel('Frequency (Hz)')

            if cfgPlot.saveFigures
                saveas(gcf, ...
                    fullfile(zoomdir, ...
                    sprintf('TFR_%s_%s.png', ...
                    format_tex_name(roiName), ...
                    format_tex_name(winName))));
            end

            if cfgPlot.closeFigures
                close
            end

        end
    end
end

%% ============================================================
% DIFFERENCE-ONLY ZOOMED TFR
%% ============================================================
if cfgPlot.differenceZoomed

    diffdir = fullfile(tfrdir,'Difference_Zoomed');

    if ~exist(diffdir,'dir')
        mkdir(diffdir);
    end

    for r = 1:numel(roiNames)

        roiName = roiNames{r};
        groupData = TFR_Group.(roiName);

        for w = 1:numel(plotWindowNames)

            winName = plotWindowNames{w};
            win = cfgPlot.windows.(winName);

            idxTime = ...
                groupData.time >= win(1) & ...
                groupData.time <= win(2);

            assert(any(idxTime), ...
                'Finestra %s fuori dal vettore temporale',winName);

            tPlot = groupData.time(idxTime);
            diffMap = groupData.Difference.power(:,idxTime);

            figure('Position',[100 100 900 500])
            imagesc(tPlot,groupData.freq,diffMap)
            axis xy
            colorbar
            clim([-GLOBAL_DIFF_MAX GLOBAL_DIFF_MAX])
            xlabel('Time (s)')
            ylabel('Frequency (Hz)')
            title(sprintf('%s | %s | Difference', ...
                format_tex_name(roiName), ...
                format_tex_name(winName)))

            if cfgPlot.saveFigures
                saveas(gcf, ...
                    fullfile(diffdir, ...
                    sprintf('Difference_%s_%s.png', ...
                    roiName,winName)));
            end

            if cfgPlot.closeFigures
                close
            end

        end
    end
end

%% ============================================================
% SAVE
%% ============================================================
assert(~isempty(fieldnames(TFR_Subj)), ...
    'No subject results generated');

save(fullfile(tfrdir,'STEP4B_TFR_MORLET_BASELINE_RESULTS.mat'), ...
    'TFR_Subj', ...
    'TFR_Group', ...
    'TFRBandResults', ...
    'BandRanges', ...
    'cfgTFR', ...
    'cfgPlot', ...
    'ROI', ...
    '-v7.3');

fprintf('\n');
fprintf('=====================================\n');
fprintf('STEP4 TFR MORLET BASELINE COMPLETED\n');
fprintf('=====================================\n');

set(0,'DefaultFigureVisible',origState);