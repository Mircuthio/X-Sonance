function [EEGout,FeatureNames] = ...
    compute_tfrerp_features( ...
    EEGin,...
    cfg,...
    SignalField)

%% ============================================================
% INIT
%% ============================================================

EEGout = EEGin;

roiNames = ...
    fieldnames(cfg.rois);

bandNames = ...
    fieldnames(cfg.bandDefs);

windowNames = ...
    fieldnames(cfg.windowDefs);

%% ============================================================
% BUILD FEATURE NAMES
%% ============================================================

FeatureNames = {};

for iROI = 1:numel(roiNames)

    roiName = ...
        roiNames{iROI};

    for iBand = 1:numel(bandNames)

        bandName = ...
            bandNames{iBand};

        for iWin = 1:numel(windowNames)

            winName = ...
                windowNames{iWin};

            FeatureNames{end+1,1} = ...
                sprintf( ...
                '%s_%s_%s',...
                roiName,...
                bandName,...
                winName);

        end

    end

end

nFeatures = ...
    numel(FeatureNames);

%% ============================================================
% CHANNEL LABELS
%% ============================================================

chanLabels = ...
    string( ...
    {EEGin.chanlocs.labels});

%% ============================================================
% FEATURE VECTOR
%% ============================================================

featureVector = ...
    nan(1,nFeatures);

iFeat = 1;

%% ============================================================
% ROI LOOP
%% ============================================================

for iROI = 1:numel(roiNames)

    roiName = ...
        roiNames{iROI};

    roiLabels = ...
        string(cfg.rois.(roiName));

    roiIdx = ...
        find( ...
        ismember( ...
        upper(chanLabels),...
        upper(roiLabels)));

    if isempty(roiIdx)

        warning( ...
            'ROI %s not found', ...
            roiName);

        iFeat = ...
            iFeat + ...
            numel(bandNames)*numel(windowNames);

        continue

    end

    %% --------------------------------------------------------
    % ROI SIGNAL
    %% --------------------------------------------------------

    eegROI = ...
        mean( ...
        double(EEGin.eeg(roiIdx,:)),...
        1,...
        'omitnan');

    %% --------------------------------------------------------
    % TFR
    %% --------------------------------------------------------

    powerMap = ...
        compute_induced_power( ...
        eegROI,...
        cfg.freqs,...
        EEGin.srate,...
        cfg.nCycles);

    %% --------------------------------------------------------
    % BASELINE
    %% --------------------------------------------------------

    powerMap = ...
        Parker_baseline_correct_tfr( ...
        powerMap,...
        EEGin.time,...
        cfg.baseline_win);

    %% --------------------------------------------------------
    % BANDS
    %% --------------------------------------------------------

    for iBand = 1:numel(bandNames)

        bandName = ...
            bandNames{iBand};

        freqWin = ...
            cfg.bandDefs.(bandName);

        idxFreq = ...
            cfg.freqs >= freqWin(1) & ...
            cfg.freqs <= freqWin(2);

        %% ----------------------------------------------------
        % WINDOWS
        %% ----------------------------------------------------

        for iWin = 1:numel(windowNames)

            winName = ...
                windowNames{iWin};

            timeWin = ...
                cfg.windowDefs.(winName);

            idxTime = ...
                EEGin.time >= timeWin(1) & ...
                EEGin.time <= timeWin(2);

            if ~any(idxFreq) || ~any(idxTime)

                featureVector(iFeat) = ...
                    NaN;

            else

                featureVector(iFeat) = ...
                    mean( ...
                    powerMap(idxFreq,idxTime),...
                    'all',...
                    'omitnan');

            end

            iFeat = ...
                iFeat + 1;

        end

    end

end

%% ============================================================
% OUTPUT
%% ============================================================

EEGout.(SignalField) = ...
    featureVector;

EEGout.(['time' SignalField]) = ...
    1:nFeatures;

end