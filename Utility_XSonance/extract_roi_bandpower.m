function roi_bp = extract_roi_bandpower(subj_curr,cfg)
% ============================================================
% EXTRACT_ROI_BANDPOWER
%
% Trial
%   ↓
% Channel
%   ↓
% Band-pass filtering  [vectorized across ROI channels]
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
% ROI indices: computed once
% ------------------------------------------------------------
chanLabels0 = upper(string({dt(1).chanlocs.labels}));

roiIdx = find(ismember(chanLabels0,roiLabels));

if isempty(roiIdx)
    error('Nessun canale della ROI trovato.');
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
        warning('Condition %s not found',condName);
        continue
    end
    
    nTrials = numel(condTrials);
    nTime = numel(time0);
    
    powerTrials = nan(nTrials,nTime);
    
    % ========================================================
    % Trial loop
    % ========================================================
    for it = 1:nTrials
        tr = condTrials(it);
        
        eeg = double(tr.eeg(roiIdx,:));   % nChan x nTime
        
        % ----------------------------------------------------
        % Filter all ROI channels at once
        % bandpass works along columns, so transpose:
        % input: nTime x nChan
        % ----------------------------------------------------
        signalF = bandpass(eeg.',cfg.band,Fs).';
        
        % ----------------------------------------------------
        % Hilbert transform along time dimension
        % hilbert opera lungo le colonne:
        % nChan x nTime -> nTime x nChan -> nChan x nTime
        % ----------------------------------------------------
        H = hilbert(signalF.').';
        P = abs(H).^2;                    % nChan x nTime
        
        % ----------------------------------------------------
        % Baseline power per channel
        % ----------------------------------------------------
        baselinePower = ...
            mean(P(:,idxBase),2,'omitnan');
        
        baselinePower(baselinePower <= 0) = eps;
        
        % ----------------------------------------------------
        % Normalization: vectorized
        % ----------------------------------------------------
        switch lower(cfg.normalization)
            case 'none'
                Pcorr = P;
                
            case 'subtract'
                Pcorr = P - baselinePower;
                
            case 'relative'
                Pcorr = ...
                    (P - baselinePower) ./ baselinePower;
                
            case 'db'
                Pcorr = ...
                    10 * log10(P ./ baselinePower);
                
            otherwise
                error('Unknown normalization: %s',...
                    cfg.normalization);
        end
        
        % ----------------------------------------------------
        % ROI average
        % ----------------------------------------------------
        powerTrials(it,:) = ...
            mean(Pcorr,1,'omitnan');
    end
    
    % ========================================================
    % Trial average
    % ========================================================
    roi_bp.(condName).power = ...
        mean(powerTrials,1,'omitnan');
    
    roi_bp.(condName).sem = ...
        std(powerTrials,0,1,'omitnan') ./ ...
        sqrt(nTrials);
    
    roi_bp.(condName).trials = powerTrials;
    roi_bp.(condName).nTrials = nTrials;
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
        roi_bp.(condB).sem.^2);
end
end