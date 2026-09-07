function Features = run_bandpower_features( ...
    TrainTrials,...
    TestTrials,...
    cfgBP)

%% ============================================================
% SETTINGS
%% ============================================================

SignalField = 'BP';

%% ============================================================
% TRAIN
%% ============================================================

[TrainEEG,FeatureNames] = ...
    compute_bp_features( ...
    TrainTrials,...
    cfgBP,...
    SignalField);

%% ============================================================
% TEST
%% ============================================================

[TestEEG,~] = ...
    compute_bp_features( ...
    TestTrials,...
    cfgBP,...
    SignalField);

%% ============================================================
% OUTPUT
%% ============================================================

Features = struct();

Features.TrainEEG = TrainEEG;
Features.TestEEG  = TestEEG;

Features.SignalField = SignalField;

Features.FeatureNames = FeatureNames;

if isempty(TrainEEG)

    Features.nFeatures = 0;

else

    Features.nFeatures = ...
        numel(TrainEEG(1).(SignalField));

end

end


%% ========================================================================
% COMPUTE FEATURES
%% ========================================================================

function [EEGout,FeatureNames] = ...
    compute_bp_features( ...
    EEGin,...
    cfgBP,...
    SignalField)

EEGout = EEGin;

FeatureNames = {};

for iTr = 1:numel(EEGin)

    tr = EEGin(iTr);

    featureVector = [];

    if isempty(tr.chanlocs)

        error('chanlocs missing');

    end

    chanLabels = ...
        upper(string({tr.chanlocs.labels}));

    for r = 1:numel(cfgBP.analysis_rois)

        roiName = ...
            cfgBP.analysis_rois{r};

        roiLabels = ...
            upper(string( ...
            cfgBP.rois.(roiName)));

        roiIdx = ...
            find(ismember( ...
            chanLabels,...
            roiLabels));

        if isempty(roiIdx)

            continue

        end

        %% ====================================================
        % ROI EEG
        %% ====================================================

        eegROI = ...
            tr.eeg(roiIdx,:);

        %% ====================================================
        % BANDS
        %% ====================================================

        for b = 1:numel(cfgBP.analysis_bands)

            bandName = ...
                cfgBP.analysis_bands{b};

            bandRange = ...
                cfgBP.bands.(bandName);

            roiPower = ...
                nan(numel(roiIdx), ...
                size(eegROI,2));

            %% -----------------------------------------------
            % CHANNEL LOOP
            %% -----------------------------------------------

            for ch = 1:numel(roiIdx)

                sig = ...
                    double( ...
                    eegROI(ch,:));

                sigF = ...
                    bandpass( ...
                    sig,...
                    bandRange,...
                    tr.srate);

                H = ...
                    hilbert(sigF);

                P = ...
                    abs(H).^2;

                %% -------------------------------------------
                % BASELINE
                %% -------------------------------------------

                idxBase = ...
                    tr.time >= ...
                    cfgBP.baseline_win(1) & ...
                    tr.time <= ...
                    cfgBP.baseline_win(2);

                baselinePower = ...
                    mean(P(idxBase),...
                    'omitnan');

                if baselinePower <= 0

                    baselinePower = eps;

                end

                switch lower(cfgBP.normalization)

                    case 'none'

                        Pcorr = P;

                    case 'subtract'

                        Pcorr = ...
                            P - baselinePower;

                    case 'relative'

                        Pcorr = ...
                            (P - baselinePower) ...
                            ./ baselinePower;

                    case 'db'

                        Pcorr = ...
                            10 .* log10( ...
                            P ./ baselinePower);

                    otherwise

                        error( ...
                            'Unknown normalization: %s',...
                            cfgBP.normalization);

                end

                roiPower(ch,:) = ...
                    Pcorr;

            end

            %% -----------------------------------------------
            % ROI AVERAGE
            %% -----------------------------------------------

            roiWave = ...
                mean( ...
                roiPower,...
                1,...
                'omitnan');

            %% -----------------------------------------------
            % FEATURE MODE
            %% -----------------------------------------------

            switch lower(cfgBP.feature_mode)

                %% ===========================================
                % SUMMARY
                %% ===========================================

                case 'summary'

                    val = ...
                        mean(roiWave,'omitnan');

                    featureVector = ...
                        [featureVector val];

                    if iTr == 1

                        FeatureNames{end+1} = ...
                            sprintf( ...
                            '%s_%s',...
                            roiName,...
                            bandName);

                    end

                    %% ===========================================
                    % WINDOW
                    %% ===========================================

                case 'window'

                    winNames = ...
                        fieldnames( ...
                        cfgBP.feature_windows);

                    for iWin = 1:numel(winNames)

                        winName = ...
                            winNames{iWin};

                        winRange = ...
                            cfgBP.feature_windows.(winName);

                        idxWin = ...
                            tr.time >= winRange(1) & ...
                            tr.time <= winRange(2);

                        if any(idxWin)

                            val = ...
                                mean( ...
                                roiWave(idxWin),...
                                'omitnan');

                        else

                            val = NaN;

                        end

                        featureVector = ...
                            [featureVector val];

                        if iTr == 1

                            FeatureNames{end+1} = ...
                                sprintf( ...
                                '%s_%s_%s',...
                                roiName,...
                                bandName,...
                                winName);

                        end

                    end

                    %% ===========================================
                    % TIMECOURSE
                    %% ===========================================

                case 'timecourse'

                    featureVector = ...
                        [featureVector roiWave];

                    if iTr == 1

                        for it = 1:numel(roiWave)

                            FeatureNames{end+1} = ...
                                sprintf( ...
                                '%s_%s_T%04d',...
                                roiName,...
                                bandName,...
                                it);

                        end

                    end

                otherwise

                    error( ...
                        'Unknown feature_mode: %s',...
                        cfgBP.feature_mode);

            end

        end % band loop

    end % roi loop

    %% ========================================================
    % STORE FEATURE VECTOR
    %% ========================================================

    EEGout(iTr).(SignalField) = ...
        featureVector;

    EEGout(iTr).trialType = ...
        tr.trialType;

end % trial loop

end