function roi_tfr = extract_roi_tfr_db(subj_curr,cfg)
% ============================================================
% EXTRACT_ROI_TFR_DB
%
% Compute induced TFR power for a given ROI in decibel scale.
%
% Pipeline:
%   1. Compute linear Morlet power per trial and channel.
%   2. Average linear power across ROI channels.
%   3. Average linear power across trials.
%   4. Convert to dB relative to the condition-specific baseline.
%
% dB definition:
%   power_dB(t,f) =
%       10 * log10(power(t,f) / mean(power_baseline(f)))
%
% Supported methods:
%   channel_first
%   roi_first
%
% cfg.nCycles can be:
%   - a scalar, applied to all frequencies
%   - a vector with one value per frequency
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

    error(['nCycles must be scalar or have one value ', ...
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

                    % Keep linear power here.
                    roiPower(:,:,ch) = single(powerCh);
                end

                % Average linear power across ROI channels.
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

                % Keep linear power here.
                trialPower(:,:,tr) = powerROI;

            otherwise

                error('Unknown method: %s',cfg.method)
        end
    end

    %% --------------------------------------------------------
    % INDUCED LINEAR POWER
    % --------------------------------------------------------
    % Average linear power across trials.
    linearPower = mean(trialPower,3);

    %% --------------------------------------------------------
    % CONVERT TO DB RELATIVE TO BASELINE
    % --------------------------------------------------------
    idxBaseline = ...
        time >= cfg.baseline_win(1) & ...
        time <= cfg.baseline_win(2);

    assert(any(idxBaseline), ...
        '%s: no samples in baseline window.',condName);

    baselinePower = mean( ...
        linearPower(:,idxBaseline), ...
        2, ...
        'omitnan');

    assert(all(isfinite(baselinePower)), ...
        '%s: non-finite baseline power.',condName);

    assert(all(baselinePower > 0), ...
        '%s: baseline power must be positive for dB conversion.', ...
        condName);

    roi_tfr.(condName).power = ...
        10 * log10(linearPower ./ baselinePower);

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
% Compute linear Morlet TFR power supporting frequency-dependent cycles.

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