function roi_tfr = extract_roi_tfr_park(subj_curr,cfg)
% ============================================================
% EXTRACT_ROI_TFR_PARK
%
% Park et al. (2011)-style induced gamma TFR:
% - Morlet wavelet power: |Z|^2
% - absolute baseline subtraction in linear power
% - Output unit: µV^2, assuming EEG input is in µV
%
% Output:
% roi_tfr.(condition).power : nFreq x nTime
% ============================================================

roi_tfr = [];

assert(isfield(subj_curr,'data_trials'), ...
    'Missing data_trials');

assert(~isempty(subj_curr.data_trials), ...
    'Empty subject data_trials');

time  = cfg.time(:)';
freqs = cfg.freqs(:)';
Fs    = cfg.srate;

nFreq = numel(freqs);
nTime = numel(time);

roi_tfr.time = time;
roi_tfr.freq = freqs;

% ------------------------------------------------------------
% Find ROI channels
% ------------------------------------------------------------
chanLabels = {subj_curr.data_trials(1).chanlocs.labels};

roiIdx = find(ismember(chanLabels, cfg.roi_labels));

if isempty(roiIdx)
    warning('No channels found for requested ROI.');
    roi_tfr = [];
    return
end

% ------------------------------------------------------------
% Conditions
% ------------------------------------------------------------
for c = 1:numel(cfg.conditions)

    condName = cfg.conditions{c};

    trialLabels = {subj_curr.data_trials.(cfg.cond_field)};

    keepTrials = find(strcmpi(trialLabels, condName));

    if isempty(keepTrials)
        warning('No %s trials found.', condName);
        continue
    end

    nTrials = numel(keepTrials);

    trialPower = nan(nFreq, nTime, nTrials, 'single');

    % --------------------------------------------------------
    % Trials
    % --------------------------------------------------------
    for tr = 1:nTrials

        trialIdx = keepTrials(tr);

        EEG = double(subj_curr.data_trials(trialIdx).eeg);

        assert(size(EEG,2) == nTime, ...
            '%s | trial %d: EEG time dimension (%d) differs from time (%d).', ...
            condName, trialIdx, size(EEG,2), nTime);

        switch lower(cfg.method)

            % =================================================
            % Channel-first: TFR per channel, then ROI average
            % =================================================
            case 'channel_first'

                nROI = numel(roiIdx);

                roiPower = nan(nFreq, nTime, nROI, 'single');

                for ch = 1:nROI

                    signal = EEG(roiIdx(ch), :);

                    powerCh = compute_induced_power( ...
                        signal, ...
                        freqs, ...
                        Fs, ...
                        cfg.nCycles);

                    powerCh = Parker_baseline_correct_tfr( ...
                        powerCh, ...
                        time, ...
                        cfg.baseline_win);

                    roiPower(:,:,ch) = single(powerCh);
                end

                trialPower(:,:,tr) = mean(roiPower, 3, 'omitnan');

            % =================================================
            % ROI-first: channels averaged before TFR
            % =================================================
            case 'roi_first'

                signal = mean(EEG(roiIdx,:), 1, 'omitnan');

                powerROI = compute_induced_power( ...
                    signal, ...
                    freqs, ...
                    Fs, ...
                    cfg.nCycles);

                powerROI = Parker_baseline_correct_tfr( ...
                    powerROI, ...
                    time, ...
                    cfg.baseline_win);

                trialPower(:,:,tr) = single(powerROI);

            otherwise
                error('Unknown cfg.method: %s', cfg.method)
        end
    end

    % Subject-level induced TFR:
    % average trial-wise power, not complex coefficients.
    roi_tfr.(condName).power = mean(trialPower, 3, 'omitnan');
    roi_tfr.(condName).nTrials = nTrials;

    if cfg.save_trial_level
        roi_tfr.(condName).trialPower = trialPower;
    end
end
end