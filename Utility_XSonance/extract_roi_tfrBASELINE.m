function roi_tfr = extract_roi_tfrBASELINE(subj_curr,cfg)
% ============================================================
% EXTRACT_ROI_TFRBASELINE
%
% Compute induced TFR power for a given ROI.
%
% Supported methods:
%
%   channel_first
%   roi_first
%
% Baseline strategy:
%
%   Power is computed for each trial.
%   Power is then averaged across ROI channels and trials.
%   Baseline correction is applied only AFTER averaging.
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
roi_tfr.baseline_win = cfg.baseline_win;
roi_tfr.baseline_order = 'after_trial_average';

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

                    % NO baseline correction here
                    roiPower(:,:,ch) = single(powerCh);

                end

                % Average across ROI channels
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

                % NO baseline correction here
                trialPower(:,:,tr) = powerROI;

            otherwise
                error('Unknown method: %s',cfg.method)

        end
    end

    %% --------------------------------------------------------
    % INDUCED POWER
    %% --------------------------------------------------------
    % Average across trials
    roi_tfr.(condName).power = ...
        mean(trialPower,3);

    % --------------------------------------------------------
    % BASELINE CORRECTION AFTER TRIAL AVERAGE
    % --------------------------------------------------------
    roi_tfr.(condName).power = ...
        baseline_correct_tfr( ...
        roi_tfr.(condName).power, ...
        time, ...
        cfg.baseline_win);

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

referencePower = compute_induced_power( ...
    signal, ...
    freqs(1), ...
    Fs, ...
    nCycles(1));

power = zeros(nFreq,nTime,'like',referencePower);

for f = 1:nFreq
    power(f,:) = compute_induced_power( ...
        signal, ...
        freqs(f), ...
        Fs, ...
        nCycles(f));
end

end