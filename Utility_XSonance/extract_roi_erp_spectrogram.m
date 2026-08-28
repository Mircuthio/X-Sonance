function roi_tf = ...
    extract_roi_erp_spectrogram( ...
    subj_curr,...
    cfgTFERP)

%% ============================================================
% INPUT
%% ============================================================

trials = ...
    subj_curr.data_trials;

roi_labels = ...
    cfgTFERP.roi_labels;

cond_names = ...
    cfgTFERP.conditions;

%% ============================================================
% TIME WINDOW
%% ============================================================

timeVec = ...
    double(trials(1).time);

timeMask = ...
    timeVec >= cfgTFERP.analysis_window(1) & ...
    timeVec <= cfgTFERP.analysis_window(2);

if ~any(timeMask)

    error( ...
        'Analysis window outside epoch range.');

end

timeERP = ...
    timeVec(timeMask);

%% ============================================================
% ROI CHANNELS
%% ============================================================

chanLabels = ...
    {trials(1).chanlocs.labels};

roi_idx = ...
    find(ismember( ...
    chanLabels,...
    roi_labels));

if isempty(roi_idx)

    warning('ROI contains no channels');

    roi_tf = [];

    return

end

%% ============================================================
% OUTPUT
%% ============================================================

roi_tf = struct();

%% ============================================================
% CONDITIONS
%% ============================================================

for iCond = 1:numel(cond_names)

    condName = ...
        cond_names{iCond};

    %% --------------------------------------------------------
    % SELECT CONDITION
    %% --------------------------------------------------------

    idxCond = ...
        strcmp( ...
        {trials.eventLabel},...
        condName);

    condTrials = ...
        trials(idxCond);

    if isempty(condTrials)

        warning('%s: no trials found', ...
            condName);

        continue

    end

    %% --------------------------------------------------------
    % ROI ERP
    %% --------------------------------------------------------

    nTrials = ...
        numel(condTrials);

    nSamples = ...
        sum(timeMask);

    roiTrialMatrix = ...
        zeros( ...
        nTrials,...
        nSamples);

    for iTr = 1:nTrials

        eeg = ...
            double(condTrials(iTr).eeg);

        eegROI = ...
            eeg( ...
            roi_idx,...
            timeMask);

        roiTrialMatrix(iTr,:) = ...
            mean(eegROI,1);

    end

    erpSignal = ...
        mean(roiTrialMatrix,1);

    %% --------------------------------------------------------
    % SPECTROGRAM
    %% --------------------------------------------------------

    fs = ...
        condTrials(1).srate;

    [S,F,T] = ...
        spectrogram( ...
        erpSignal,...
        hamming(cfgTFERP.window_length),...
        cfgTFERP.overlap,...
        cfgTFERP.nfft,...
        fs);
    %% --------------------------------------------------------
    % ALIGN SPECTROGRAM TIME TO ERP TIME
    %% --------------------------------------------------------

    T = T + timeERP(1);
    
    %% --------------------------------------------------------
    % POWER
    %% --------------------------------------------------------

    TFpower = ...
        10*log10(abs(S).^2);

    %% --------------------------------------------------------
    % FREQUENCY RANGE
    %% --------------------------------------------------------

    keepFreq = ...
        F >= cfgTFERP.fmin & ...
        F <= cfgTFERP.fmax;

    F = ...
        F(keepFreq);

    TFpower = ...
        TFpower(keepFreq,:);

    %% --------------------------------------------------------
    % STORE
    %% --------------------------------------------------------

    roi_tf.(condName).power = ...
        TFpower;

    roi_tf.(condName).freq = ...
        F;

    roi_tf.(condName).time = ...
        T;

    roi_tf.(condName).erp = ...
        erpSignal;

    roi_tf.(condName).time_erp = ...
        timeERP;

    roi_tf.(condName).nTrials = ...
        nTrials;

    roi_tf.(condName).condition = ...
        condName;

end

%% ============================================================
% DIFFERENCE
%% ============================================================

if numel(cond_names)==2 && ...
        isfield(roi_tf,cond_names{1}) && ...
        isfield(roi_tf,cond_names{2})

    cond1 = cond_names{1};
    cond2 = cond_names{2};

    roi_tf.Difference.power = ...
        roi_tf.(cond1).power - ...
        roi_tf.(cond2).power;

    roi_tf.Difference.freq = ...
        roi_tf.(cond1).freq;

    roi_tf.Difference.time = ...
        roi_tf.(cond1).time;

    roi_tf.Difference.label = ...
        sprintf('%s - %s', ...
        cond1,...
        cond2);

end

%% ============================================================
% METADATA
%% ============================================================

roi_tf.subjectID = ...
    subj_curr.subj_id;

roi_tf.roi_labels = ...
    roi_labels;

roi_tf.analysis_window = ...
    cfgTFERP.analysis_window;

end