function roi_tfr = extract_roi_tfr(subj_curr,cfg)
% ============================================================
% EXTRACT_ROI_TFR
%
% Compute induced TFR power for a given ROI.
%
% Supported methods:
%
%   channel_first
%   roi_first
%
% cfg.nCycles can be:
%
%   - a scalar, applied to all frequencies
%   - a vector with one value per frequency
%
% ============================================================

roi_tfr = [];

assert(isfield(subj_curr,'data_trials'), ...
    'Missing data_trials');
assert(~isempty(subj_curr.data_trials), ...
    'Empty subject');

time  = cfg.time;
freqs = cfg.freqs;
Fs    = cfg.srate;

nFreq = numel(freqs);
nTime = numel(time);

% ------------------------------------------------------------
% CHECK CYCLES
% ------------------------------------------------------------
if isscalar(cfg.nCycles)
    nCycles = repmat(cfg.nCycles,1,nFreq);
elseif numel(cfg.nCycles) == nFreq
    nCycles = cfg.nCycles(:)';
else
    error( ...
        ['nCycles must be scalar or have one value ', ...
        'per frequency']);
end

roi_tfr.time = time;
roi_tfr.freq = freqs;
roi_tfr.nCycles = nCycles;

%% ------------------------------------------------------------
% FIND ROI CHANNELS
%% ------------------------------------------------------------
chanLabels = ...
    {subj_curr.data_trials(1).chanlocs.labels};

roiIdx = find( ...
    ismember(chanLabels, ...
    cfg.roi_labels));

if isempty(roiIdx)
    warning('No ROI channels found');
    return
end

%% ------------------------------------------------------------
% LOOP CONDITIONS
%% ------------------------------------------------------------
for c = 1:numel(cfg.conditions)

    condName = cfg.conditions{c};

    fprintf('   Condition: %s\n',condName);

    %% --------------------------------------------------------
    % SELECT TRIALS
    %% --------------------------------------------------------
    trialLabels = ...
        {subj_curr.data_trials.(cfg.cond_field)};

    keepTrials = find( ...
        strcmpi(trialLabels,condName));

    if isempty(keepTrials)
        warning('No %s trials found',condName);
        continue
    end

    %% --------------------------------------------------------
    % TRIAL LOOP
    %% --------------------------------------------------------
    nTrials = numel(keepTrials);

    trialPower = zeros( ...
        nFreq, ...
        nTime, ...
        nTrials, ...
        'single');

    for tr = 1:nTrials

        trialIdx = keepTrials(tr);
        EEG = subj_curr.data_trials(trialIdx).eeg;

        switch lower(cfg.method)

            % =================================================
            % CHANNEL-FIRST
            % =================================================
            case 'channel_first'

                nROI = numel(roiIdx);

                roiPower = zeros( ...
                    nFreq, ...
                    nTime, ...
                    nROI, ...
                    'single');

                for ch = 1:numel(roiIdx)

                    signal = double(EEG(roiIdx(ch),:));

                    powerCh = compute_frequency_dependent_power( ...
                        signal, ...
                        freqs, ...
                        Fs, ...
                        nCycles);

                    powerCh = baseline_correct_tfr( ...
                        powerCh, ...
                        time, ...
                        cfg.baseline_win);

                    roiPower(:,:,ch) = single(powerCh);

                end

                trialPower(:,:,tr) = mean(roiPower,3);

            % =================================================
            % ROI-FIRST
            % =================================================
            case 'roi_first'

                signal = mean( ...
                    double(EEG(roiIdx,:)), ...
                    1);

                powerROI = compute_frequency_dependent_power( ...
                    signal, ...
                    freqs, ...
                    Fs, ...
                    nCycles);

                powerROI = baseline_correct_tfr( ...
                    powerROI, ...
                    time, ...
                    cfg.baseline_win);

                trialPower(:,:,tr) = powerROI;

            otherwise
                error('Unknown method: %s',cfg.method)

        end
    end

    %% --------------------------------------------------------
    % INDUCED POWER
    %% --------------------------------------------------------
    roi_tfr.(condName).power = ...
        mean(trialPower,3);

    roi_tfr.(condName).nTrials = ...
        numel(keepTrials);

    if cfg.save_trial_level
        roi_tfr.(condName).trialPower = ...
            trialPower;
    end

end

end

%% ============================================================
% LOCAL FUNCTION
%% ============================================================
function power = compute_frequency_dependent_power( ...
    signal, ...
    freqs, ...
    Fs, ...
    nCycles)
% Compute TFR power supporting frequency-dependent cycles.
%
% If nCycles is scalar, calls compute_induced_power once.
% If nCycles is a vector, computes one frequency at a time.

nFreq = numel(freqs);
nTime = numel(signal);

if isscalar(nCycles)
    power = compute_induced_power( ...
        signal, ...
        freqs, ...
        Fs, ...
        nCycles);
    return
end

power = zeros(nFreq,nTime,'like', ...
    compute_induced_power( ...
    signal, ...
    freqs(1), ...
    Fs, ...
    nCycles(1)));

for f = 1:nFreq
    power(f,:) = compute_induced_power( ...
        signal, ...
        freqs(f), ...
        Fs, ...
        nCycles(f));
end

end