function [x,featureLabels] = ...
    extract_bandpower_mean_features( ...
    trial,...
    cfgBP)

%% ============================================================
% INPUT CHECK
%% ============================================================
assert(isfield(trial,'eeg'), ...
    'trial.eeg missing');

assert(isfield(trial,'time'), ...
    'trial.time missing');

assert(isfield(trial,'chanlocs'), ...
    'trial.chanlocs missing');

assert(isfield(trial,'fs'), ...
    'trial.fs missing');

%% ============================================================
% DATA
%% ============================================================
eeg = trial.eeg;

time = trial.time;

fs = trial.fs;

chanLabels = ...
    {trial.chanlocs.labels};

analysisROIs = ...
    cfgBP.analysis_rois;

bandNames = ...
    fieldnames(cfgBP.bands);

%% ============================================================
% ANALYSIS WINDOW
%% ============================================================
tw = ...
    cfgBP.analysis_window;

idxTime = ...
    time >= tw(1) & ...
    time <= tw(2);

assert(any(idxTime), ...
    'No samples inside analysis window');

%% ============================================================
% PREALLOCATION
%% ============================================================
nROI = ...
    numel(analysisROIs);

nBands = ...
    numel(bandNames);

nFeatures = ...
    nROI * nBands;

x = ...
    nan(1,nFeatures);

featureLabels = ...
    cell(nFeatures,1);

iFeat = 0;

%% ============================================================
% FEATURE EXTRACTION
%% ============================================================
for iROI = 1:nROI

    roiName = ...
        analysisROIs{iROI};

    if ~isfield(cfgBP.rois,roiName)

        error( ...
            'ROI not found: %s',...
            roiName);

    end

    roiChannels = ...
        cfgBP.rois.(roiName);

    roiIdx = ...
        find( ...
        ismember( ...
        chanLabels,...
        roiChannels));

    %% --------------------------------------------------------
    % ROI MISSING
    %% --------------------------------------------------------
    if isempty(roiIdx)

        warning( ...
            'ROI %s not found in trial channels', ...
            roiName);

        for iBand = 1:nBands

            iFeat = ...
                iFeat + 1;

            x(iFeat) = NaN;

            featureLabels{iFeat} = ...
                sprintf( ...
                '%s_%s', ...
                roiName,...
                bandNames{iBand});

        end

        continue

    end

    %% --------------------------------------------------------
    % ROI DATA
    %% --------------------------------------------------------
    roiEEG = ...
        eeg(roiIdx,:);

    %% --------------------------------------------------------
    % BAND LOOP
    %% --------------------------------------------------------
    for iBand = 1:nBands

        iFeat = ...
            iFeat + 1;

        bandName = ...
            bandNames{iBand};

        featureLabels{iFeat} = ...
            sprintf( ...
            '%s_%s',...
            roiName,...
            bandName);

        bandRange = ...
            cfgBP.bands.(bandName);

        fLow = ...
            bandRange(1);

        fHigh = ...
            bandRange(2);

        try

            %% =================================================
            % BANDPASS FILTER
            %% =================================================
            roiFilt = ...
                bandpass( ...
                roiEEG',...
                [fLow fHigh],...
                fs)';

            %% =================================================
            % HILBERT
            %% =================================================
            H = ...
                hilbert( ...
                roiFilt')';

            %% =================================================
            % POWER
            %% =================================================
            powerBand = ...
                abs(H).^2;

            %% =================================================
            % ROI AVERAGE
            %% =================================================
            roiPower = ...
                mean( ...
                powerBand,...
                1);

            %% =================================================
            % TEMPORAL MEAN
            %% =================================================
            feat = ...
                mean( ...
                roiPower(idxTime),...
                'omitnan');

            %% =================================================
            % POWER MODE
            %% =================================================
            if isfield(cfgBP,'power_mode')

                switch lower(cfgBP.power_mode)

                    case 'absolute'

                        % no transform

                    case 'log'

                        feat = ...
                            log10( ...
                            feat + eps);

                    case 'zscore'

                        z = ...
                            zscore( ...
                            roiPower(idxTime));

                        feat = ...
                            mean( ...
                            z,...
                            'omitnan');

                    otherwise

                        error( ...
                            'Unknown power_mode: %s',...
                            cfgBP.power_mode);

                end

            end

            x(iFeat) = ...
                feat;

        catch ME

            warning( ...
                'Feature computation failed [%s | %s]: %s',...
                roiName,...
                bandName,...
                ME.message);

            x(iFeat) = NaN;

        end

    end

end

%% ============================================================
% CONSISTENCY CHECK
%% ============================================================
assert( ...
    iFeat == nFeatures,...
    'Feature count mismatch');

%% ============================================================
% OUTPUT SHAPE
%% ============================================================
x = ...
    reshape(x,1,[]);

featureLabels = ...
    featureLabels(:);

end