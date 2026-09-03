function bp_channel = extract_channel_bandpower(subj_curr,cfg)

% ============================================================
% EXTRACT_CHANNEL_BANDPOWER
%
% Trial
%   ↓
% Channel
%   ↓
% Band-pass filtering
%   ↓
% Hilbert transform
%   ↓
% Instantaneous power
%       abs(H).^2
%   ↓
% Baseline normalization
%   ↓
% Trial averaging
%
% Output:
%
%   Channels x Time
%
% Used for:
%
%   Topographic band-power analyses
%
% ============================================================

%% -----------------------------------------------------------
% Checks
%% -----------------------------------------------------------

if ~isfield(cfg,'normalization')
    cfg.normalization = 'db';
end

dt = subj_curr.data_trials;

time0 = double(dt(1).(cfg.time_field));

Fs = dt(1).srate;

nChan = size(dt(1).eeg,1);

bp_channel = struct();

bp_channel.time = time0;

bp_channel.band = cfg.band;

if isfield(dt(1),'chanlocs')
    bp_channel.chanlocs = dt(1).chanlocs;
end

%% -----------------------------------------------------------
% Baseline samples
%% -----------------------------------------------------------

idxBase = ...
    time0 >= cfg.baseline_win(1) & ...
    time0 <= cfg.baseline_win(2);

if ~any(idxBase)

    error('No baseline samples found');

end

%% -----------------------------------------------------------
% Conditions
%% -----------------------------------------------------------

for ic = 1:numel(cfg.conditions)

    condName = cfg.conditions{ic};

    condMask = strcmpi( ...
        {dt.(cfg.cond_field)}, ...
        condName);

    condTrials = dt(condMask);

    if isempty(condTrials)

        warning('Condition %s not found',condName);
        continue

    end

    nTrials = numel(condTrials);

    chanTrials = ...
        nan(nChan,numel(time0),nTrials);

    %% =======================================================
    % Trial loop
    %% =======================================================

    for it = 1:nTrials

        eeg = condTrials(it).eeg;

        for ch = 1:nChan

            signal = eeg(ch,:);

            signalF = bandpass( ...
                signal,...
                cfg.band,...
                Fs);

            H = hilbert(signalF);

            P = abs(H).^2;

            baselinePower = ...
                mean(P(idxBase),...
                'omitnan');

            if baselinePower <= 0
                baselinePower = eps;
            end

            switch lower(cfg.normalization)

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
                        cfg.normalization);

            end

            chanTrials(ch,:,it) = Pcorr;

        end

    end

    %% =======================================================
    % Average across trials
    %% =======================================================

    bp_channel.(condName).power = ...
        mean(chanTrials,3,'omitnan');

    bp_channel.(condName).sem = ...
        std(chanTrials,0,3,'omitnan') ...
        ./ sqrt(nTrials);

    bp_channel.(condName).trials = ...
        chanTrials;

    bp_channel.(condName).nTrials = ...
        nTrials;

end

%% -----------------------------------------------------------
% Difference map
%% -----------------------------------------------------------

condA = cfg.conditions{1};
condB = cfg.conditions{2};

if isfield(bp_channel,condA) && ...
        isfield(bp_channel,condB)

    bp_channel.Difference.power = ...
        bp_channel.(condB).power - ...
        bp_channel.(condA).power;
    
    bp_channel.Difference.sem = ...
        sqrt( ...
        bp_channel.(condA).sem.^2 + ...
        bp_channel.(condB).sem.^2 );
end

end