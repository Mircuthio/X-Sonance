%% =========================================================================
% % PLOT_PARKER_GAMMA
%% =========================================================================
%

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

addpath(genpath('C:\Users\mirco\Desktop\eeglab2026.1.0\'))

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
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO',...
    'STEP4B_TFR_MORLET');

if ~exist(step4_outroot,'dir')
    mkdir(step4_outroot);
end
%% ============================================================
% LOAD DATA
%% ============================================================
step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\STEP4B_TFR_MORLET\PARK_TFR_STEP4\roi_first';

load(fullfile(step2_indir,'STEP4B_TFR_MORLET_REPLICA_PARK_RESULTS.mat'));

parkdir = fullfile( ...
    step4_outroot,...
    'PARK_TFR_STEP4',...
    cfgTFR.method,...
    'NEW_ZOOM');

if ~exist(parkdir,'dir')
    mkdir(parkdir);
end

%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI_TFR

cfgTFR.rois = ParkROI;

roiNames = fieldnames(cfgTFR.rois);

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

    time    = groupData.time;
    yCon    = gammaConTime;
    yDis    = gammaDisTime;
    yDiff   = gammaDiffTime;

    idxBaseline = time >= -0.5 & time <= 0;

    baselineConMean = mean(yCon(idxBaseline), 'omitnan');
    yBaselineConCorrected = yCon - baselineConMean;

    baselineDisMean = mean(yDis(idxBaseline), 'omitnan');
    yBaselineDisCorrected = yDis - baselineDisMean;

    baselineDiffMean = mean(yDiff(idxBaseline), 'omitnan');
    yBaselineDiffCorrected = yDiff - baselineDiffMean;

    t_start = [-0.2 -0.2 -0.2];
    t_end = [1 0.8 0.9];

    for i=1:numel(t_end)

        t1 = t_start(i);
        t2 = t_end(i);

        idx = groupData.time >= t1 & groupData.time <= t2;

        %% Plot Consonance and Dissonance
        figure
        plot(1000*time(idx), yBaselineConCorrected(idx), 'LineWidth', 2)
        hold on

        plot(1000*time(idx), yBaselineDisCorrected(idx), 'LineWidth', 2)

        xline(0,'k')
        legend( ...
            'Consonant',...
            'Dissonant');
        xlabel('Time (ms)')
        ylabel('Power (dB)')
        title(sprintf('Gamma Time Course - %s',format_tex_name(roiName)))
        saveas( ...
            gcf,...
            fullfile( ...
            parkdir,...
            sprintf('ConDisGammaTimeCourse_%s.png',roiName)));

        %% Plot Consonance Dissonance and Difference
        figure
        plot(1000*time(idx), yBaselineConCorrected(idx), 'LineWidth', 2)
        hold on

        plot(1000*time(idx), yBaselineDisCorrected(idx), 'LineWidth', 2)

        plot(1000*time(idx), yBaselineDiffCorrected(idx), 'k--',...
            'LineWidth',2)

        xline(0,'--k')
        % yline(0,'--k')
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
            sprintf('ConDisDiffGammaTimeCourse_%s.png',roiName)));

        %% Plot Difference
        figure
        plot(1000*time(idx), yBaselineDiffCorrected(idx), 'k--',...
            'LineWidth',2)

        xline(0,'k')
        % yline(0,'--k')
        legend('Difference');
        xlabel('Time (s)')
        ylabel('Power (dB)')
        title(sprintf('Gamma Time Course - %s',format_tex_name(roiName)))
        saveas( ...
            gcf,...
            fullfile( ...
            parkdir,...
            sprintf('DiffGammaTimeCourse_%s.png',roiName)));
        close
    end
end


fprintf('\n');
fprintf('=====================================\n');
fprintf('FINISH PLOT\n');
fprintf('=====================================\n');

set(0,'DefaultFigureVisible',origState);
