function TF = ...
    extract_roi_timefrequency( ...
    subj_curr,...
    cfgTF)

%% ============================================================
% INPUT
%% ============================================================

data_trials = ...
    subj_curr.data_trials;

roi_labels = ...
    cfgTF.roi_labels;

cond_names = ...
    cfgTF.conditions;

eventField = ...
    cfgTF.eventField;

%% ============================================================
% CHANNEL SELECTION
%% ============================================================

chanloc = ...
    data_trials(1).chanloc;

chanLabels = ...
    {chanloc.labels};

roi_idx = ...
    find(ismember( ...
    chanLabels,...
    roi_labels));

if isempty(roi_idx)
    error('No ROI channels found.');
end

%% ============================================================
% OUTPUT
%% ============================================================

TF = struct();

%% ============================================================
% CONDITIONS
%% ============================================================

for iCond = 1:numel(cond_names)

    conditionName = ...
        cond_names{iCond};

    idxCond = ...
        strcmp( ...
        {data_trials.(eventField)},...
        conditionName);

    trials_cond = ...
        data_trials(idxCond);

    if isempty(trials_cond)

        warning('No trials found for %s', ...
            conditionName);

        continue

    end

    %% --------------------------------------------------------
    % ROI SIGNAL PER TRIAL
    %% --------------------------------------------------------

    trialSignals = [];

    for iTr = 1:numel(trials_cond)

        eeg = ...
            trials_cond(iTr).eeg;

        eeg_roi = ...
            eeg(roi_idx,:);

        eeg_roi_mean = ...
            mean(eeg_roi,1);

        trialSignals(iTr,:) = ...
            eeg_roi_mean;

    end

    %% --------------------------------------------------------
    % ERP OF CONDITION
    %% --------------------------------------------------------

    signalERP = ...
        mean(trialSignals,1);

    fs = ...
        trials_cond(1).srate;

    %% --------------------------------------------------------
    % TIME-FREQUENCY
    %% --------------------------------------------------------

    [S,F,T] = ...
        spectrogram( ...
        signalERP,...
        hamming(cfgTF.window_length),...
        cfgTF.overlap,...
        cfgTF.nfft,...
        fs);

    TFpower = ...
        10*log10(abs(S).^2);

    %% --------------------------------------------------------
    % FREQUENCY RANGE
    %% --------------------------------------------------------

    freqIdx = ...
        F >= cfgTF.fmin & ...
        F <= cfgTF.fmax;

    F = ...
        F(freqIdx);

    TFpower = ...
        TFpower(freqIdx,:);

    %% --------------------------------------------------------
    % BASELINE CORRECTION
    %% --------------------------------------------------------

    baselineMask = ...
        T >= cfgTF.baseline_win(1) & ...
        T <= cfgTF.baseline_win(2);

    if any(baselineMask)

        baselineMean = ...
            mean( ...
            TFpower(:,baselineMask),...
            2);

        TFpower = ...
            TFpower - baselineMean;

    end

    %% --------------------------------------------------------
    % STORE CONDITION
    %% --------------------------------------------------------

    TF.(conditionName).Power = ...
        TFpower;

    TF.(conditionName).F = ...
        F;

    TF.(conditionName).T = ...
        T;

    TF.(conditionName).ERP = ...
        signalERP;

    TF.(conditionName).nTrials = ...
        numel(trials_cond);

end

%% ============================================================
% DIFFERENCE MAP
%% ============================================================

if isfield(TF,'Consonant') && ...
   isfield(TF,'Dissonant')

    TF.Difference.Power = ...
        TF.Consonant.Power - ...
        TF.Dissonant.Power;

    TF.Difference.F = ...
        TF.Consonant.F;

    TF.Difference.T = ...
        TF.Consonant.T;

end

%% ============================================================
% SUBJECT INFO
%% ============================================================

TF.subjectID = ...
    subj_curr.subj_id;

TF.roi_labels = ...
    roi_labels;
``