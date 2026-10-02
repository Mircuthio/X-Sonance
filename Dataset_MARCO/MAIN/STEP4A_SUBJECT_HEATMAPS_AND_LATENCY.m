%% ============================================================
% STEP4A_SUBJECT_HEATMAPS_AND_LATENCY
%% ============================================================

clear
close all
clc

%% ============================================================
% LOAD
%% ============================================================

load( ...
    'BANDPOWER_STEP4A_RESULTS.mat',...
    'BandPower_Subj');

subjNames = fieldnames(BandPower_Subj);

%% ============================================================
% SETTINGS
%% ============================================================

roiNames = { ...
    'ERAN_CORE',...
    'MMN',...
    'FrontoCentral',...
    'N5_CENTRAL'};

bandNames = { ...
    'Delta',...
    'Theta',...
    'Alpha',...
    'BetaLow',...
    'BetaHigh',...
    'GammaLow',...
    'GammaHigh'};

outdir = ...
    'STEP4A_SUBJECT_HEATMAPS';

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% TABLE
%% ============================================================

nROI  = numel(roiNames);
nBand = numel(bandNames);
nRows = numel(subjNames) * nROI * nBand;

ResultsTable = table( ...
    'Size', [nRows 5], ...
    'VariableTypes', ...
    {'string','string','string','double','double'}, ...
    'VariableNames', ...
    {'Subject','ROI','Band','Latency','Amplitude'});

iRow = 0;
nSummaryRows = nROI * nBand;

SummaryTable = table( ...
    'Size', [nSummaryRows 6], ...
    'VariableTypes', ...
    {'string','string','double','double','double','double'}, ...
    'VariableNames', ...
    {'ROI','Band','MeanLatency','StdLatency', ...
    'MeanAmplitude','StdAmplitude'});

iSummary = 0;
%% ============================================================
% LOOP ROI/BANDS
%% ============================================================

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    roiDir = ...
        fullfile(outdir,roiName);

    if ~exist(roiDir,'dir')
        mkdir(roiDir);
    end

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        fprintf('\n%s | %s\n', ...
            roiName,...
            bandName);

        %% ----------------------------------------------------
        % BUILD MATRIX
        %% ----------------------------------------------------

        M = [];

        peakLatency = nan(numel(subjNames),1);
        peakAmp     = nan(numel(subjNames),1);

        for iSub = 1:numel(subjNames)

            subjID = subjNames{iSub};

            bp = ...
                BandPower_Subj.(subjID).(roiName).(bandName);

            diffWave = ...
                bp.Difference.power(:)';

            M(iSub,:) = diffWave;

            %% --------------------------------------------
            % PEAK EXTRACTION
            %% --------------------------------------------

            idxWin = ...
                bp.time >= 0 & ...
                bp.time <= 0.6;

            waveWin = ...
                diffWave(idxWin);

            timeWin = ...
                bp.time(idxWin);

            [amp,idx] = ...
                min(waveWin);

            peakAmp(iSub) = amp;

            peakLatency(iSub) = ...
                timeWin(idx);

        end

        %% ----------------------------------------------------
        % HEATMAP ORIGINAL
        %% ----------------------------------------------------

        figH = figure( ...
            'Color','w',...
            'Position',[100 100 1000 500]);

        imagesc( ...
            bp.time,...
            1:numel(subjNames),...
            M);

        axis xy

        colorbar

        xlabel('Time (s)');
        ylabel('Subject');

        title(sprintf( ...
            '%s | %s | Difference',...
            roiName,...
            bandName));

        saveas( ...
            figH,...
            fullfile( ...
            roiDir,...
            sprintf( ...
            '%s_%s_HEATMAP.png',...
            roiName,...
            bandName)));

        close(figH)

        %% ----------------------------------------------------
        % HEATMAP SORTED BY LATENCY
        %% ----------------------------------------------------

        [~,ord] = sort(peakLatency);

        figH = figure( ...
            'Color','w',...
            'Position',[100 100 1000 500]);

        imagesc( ...
            bp.time,...
            1:numel(subjNames),...
            M(ord,:));

        axis xy

        colorbar

        xlabel('Time (s)');
        ylabel('Subjects (sorted latency)');

        title(sprintf( ...
            '%s | %s | Difference Sorted',...
            roiName,...
            bandName));

        saveas( ...
            figH,...
            fullfile( ...
            roiDir,...
            sprintf( ...
            '%s_%s_HEATMAP_SORTED.png',...
            roiName,...
            bandName)));

        close(figH)

        %% ----------------------------------------------------
        % LATENCY TABLE
        %% ----------------------------------------------------

        for iSub = 1:numel(subjNames)

            iRow = iRow + 1;

            ResultsTable.Subject(iRow)   = string(subjNames{iSub});
            ResultsTable.ROI(iRow)       = string(roiName);
            ResultsTable.Band(iRow)      = string(bandName);
            ResultsTable.Latency(iRow)   = peakLatency(iSub);
            ResultsTable.Amplitude(iRow) = peakAmp(iSub);
        end

        %% ----------------------------------------------------
        % SUMMARY
        %% ----------------------------------------------------

        iSummary = iSummary + 1;

        SummaryTable.ROI(iSummary) = string(roiName);
        SummaryTable.Band(iSummary) = string(bandName);

        SummaryTable.MeanLatency(iSummary) = ...
            mean(peakLatency,'omitnan');

        SummaryTable.StdLatency(iSummary) = ...
            std(peakLatency,'omitnan');

        SummaryTable.MeanAmplitude(iSummary) = ...
            mean(peakAmp,'omitnan');

        SummaryTable.StdAmplitude(iSummary) = ...
            std(peakAmp,'omitnan');

    end
end
ResultsTable = ResultsTable(1:iRow,:);
SummaryTable = SummaryTable(1:iSummary,:);
%% ============================================================
% EXPORT TABLES
%% ============================================================

writetable( ...
    ResultsTable,...
    fullfile( ...
    outdir,...
    'Subject_LatencyAmplitude.csv'));

writetable( ...
    SummaryTable,...
    fullfile( ...
    outdir,...
    'Summary_LatencyAmplitude.csv'));

save( ...
    fullfile( ...
    outdir,...
    'STEP4A_LATENCY_RESULTS.mat'),...
    'ResultsTable',...
    'SummaryTable');

fprintf('\n');
fprintf('================================\n');
fprintf('STEP4A HEATMAP COMPLETED\n');
fprintf('================================\n');