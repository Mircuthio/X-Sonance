function roi_bp = extract_roi_bandpower(subj_curr,cfg)

% ============================================================
% EXTRACT_ROI_BANDPOWER
%
% Processing Pipeline
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
% ROI averaging
%   ↓
% Trial averaging
%
% ============================================================

% ------------------------------------------------------------
% Checks
% ------------------------------------------------------------

assert(isfield(cfg,'conditions'),...
    'cfg.conditions missing');

assert(isfield(cfg,'cond_field'),...
    'cfg.cond_field missing');

assert(isfield(cfg,'time_field'),...
    'cfg.time_field missing');

assert(isfield(cfg,'roi_labels'),...
    'cfg.roi_labels missing');

assert(isfield(cfg,'band'),...
    'cfg.band missing');

assert(isfield(cfg,'baseline_win'),...
    'cfg.baseline_win missing');


if ~isfield(cfg,'normalization')

    cfg.normalization = 'db';

end

% ------------------------------------------------------------
% Basic data
% ------------------------------------------------------------

dt = subj_curr.data_trials;

time0 = double(dt(1).(cfg.time_field));

Fs = dt(1).srate;

roiLabels = upper(string(cfg.roi_labels));

roi_bp = struct();

roi_bp.time = time0;

roi_bp.band = cfg.band;

roi_bp.roi_labels = cfg.roi_labels;

roi_bp.normalization = cfg.normalization;

% ------------------------------------------------------------
% Baseline samples
% ------------------------------------------------------------

idxBase = ...
    time0 >= cfg.baseline_win(1) & ...
    time0 <= cfg.baseline_win(2);

if ~any(idxBase)

    error('No baseline samples found');

end

% ------------------------------------------------------------
% Conditions
% ------------------------------------------------------------

for ic = 1:numel(cfg.conditions)

    condName = cfg.conditions{ic};

    condMask = strcmpi( ...
        {dt.(cfg.cond_field)}, ...
        condName);

    condTrials = dt(condMask);

    if isempty(condTrials)

        warning( ...
            'Condition %s not found',...
            condName);

        continue

    end

    nTrials = numel(condTrials);

    powerTrials = ...
        nan(nTrials,numel(time0));

    % ========================================================
    % Trial loop
    % ========================================================

    for it = 1:nTrials

        tr = condTrials(it);

        chanLabels = ...
            upper(string({tr.chanlocs.labels}));

        roiIdx = ...
            find(ismember( ...
            chanLabels,...
            roiLabels));

        if isempty(roiIdx)

            continue

        end

        eeg = tr.eeg(roiIdx,:);

        nChan = size(eeg,1);

        roiPower = ...
            nan(nChan,size(eeg,2));

        % ----------------------------------------------------
        % Channel loop
        % ----------------------------------------------------

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
                        10 * log10( ...
                        P ./ baselinePower);

                otherwise

                    error( ...
                        'Unknown normalization: %s',...
                        cfg.normalization);

            end

            roiPower(ch,:) = Pcorr;

        end

        % ----------------------------------------------------
        % ROI average
        % ----------------------------------------------------

        powerTrials(it,:) = ...
            mean(roiPower,1,'omitnan');

    end

    % ========================================================
    % Trial average
    % ========================================================

    roi_bp.(condName).power = ...
        mean(powerTrials,1,'omitnan');

    roi_bp.(condName).sem = ...
        std(powerTrials,0,1,'omitnan') ./ ...
        sqrt(nTrials);

    roi_bp.(condName).trials = ...
        powerTrials;

    roi_bp.(condName).nTrials = ...
        nTrials;
    roi_bp.band_name = cfg.band_name;
end

% ------------------------------------------------------------
% Difference waveform
% ------------------------------------------------------------
condA = cfg.conditions{1};
condB = cfg.conditions{2};

if isfield(roi_bp,condA) && ...
        isfield(roi_bp,condB)

    roi_bp.Difference.power = ...
        roi_bp.(condB).power - ...
        roi_bp.(condA).power;

    roi_bp.Difference.sem = ...
        sqrt( ...
        roi_bp.(condA).sem.^2 + ...
        roi_bp.(condB).sem.^2 );
end

end