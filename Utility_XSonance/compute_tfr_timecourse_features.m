function [out,FeatureNames] = ...
    compute_tfr_timecourse_features( ...
    tr,...
    cfg,...
    outField)

%% ============================================================
% INIT
%% ============================================================

Features = [];
FeatureNames = {};

timeVec = tr.time;
Fs      = tr.srate;

%% ============================================================
% LOOP ROI
%% ============================================================

for iROI = 1:numel(cfg.analysis_rois)

    roiName = cfg.analysis_rois{iROI};

    roiLabels = cfg.rois.(roiName);

    chanLabels = ...
        {tr.chanlocs.labels};

    roiIdx = ...
        ismember( ...
        chanLabels,...
        roiLabels);

    if ~any(roiIdx)
        continue
    end

    roiSignal = ...
        mean( ...
        tr.eeg(roiIdx,:),...
        1);

    %% --------------------------------------------------------
    % MORLET
    %% --------------------------------------------------------

    powerTF = ...
        compute_induced_power( ...
        roiSignal,...
        cfg.freqs,...
        Fs,...
        cfg.nCycles);

    %% --------------------------------------------------------
    % BASELINE
    %% --------------------------------------------------------

    idxBase = ...
        timeVec >= cfg.baseline_win(1) & ...
        timeVec <= cfg.baseline_win(2);

    baseMean = ...
        mean(powerTF(:,idxBase),2);

    powerTF = ...
        10*log10( ...
        powerTF ./ baseMean);

    %% --------------------------------------------------------
    % GAMMA
    %% --------------------------------------------------------

    freqIdx = ...
        cfg.freqs >= cfg.gamma_freq_win(1) & ...
        cfg.freqs <= cfg.gamma_freq_win(2);

    timeIdx = ...
        timeVec >= cfg.gamma_time_win(1) & ...
        timeVec <= cfg.gamma_time_win(2);

    gammaTime = ...
        mean(powerTF(freqIdx,timeIdx),1);

    Features = ...
        [Features gammaTime];

    %% --------------------------------------------------------
    % NAMES
    %% --------------------------------------------------------

    nT = numel(gammaTime);

    for k = 1:nT

        FeatureNames{end+1,1} = ...
            sprintf( ...
            '%s_Gamma_t%03d',...
            roiName,...
            k);

    end

end

%% ============================================================
% OUTPUT
%% ============================================================

out = struct();

out.(outField) = Features;

out.(['time' outField]) = ...
    1:numel(Features);

out.FeatureNames = ...
    FeatureNames;

out.nFeatures = ...
    numel(Features);