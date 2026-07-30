function results = xSonance_pelofi(raw_eeg, events, opts)
% EEG_PROCESSING_PIPELINE_ARTICLE
% MATLAB skeleton inspired by the EEG pipeline described in the attached article.
%
% INPUTS
%   raw_eeg : [nChannels x nSamples] continuous EEG
%   events  : struct array with at least field .sample (trial onset)
%   opts    : struct with fields:
%       .fs                sampling rate of raw EEG
%       .chan_labels       cell array of channel names
%       .heog_idx          index of HEOG channel(s)
%       .veog_idx          index of VEOG channel(s)
%       .neighbors         cell array; neighbors{ch} = indices of nearby channels
%       .epoch_win_sec     [tmin tmax] around event onset, e.g. [0 6]
%       .bad_chan_zthr     threshold, default 3
%       .bad_epoch_zthr    threshold, default 3
%       .lowpass_hz        default 40
%       .target_fs         default 100
%       .poly_order        default 30
%       .labels_ref_alt    optional trial labels for decoding
%
% OUTPUT
%   results : struct containing preprocessed signal, epoched data and placeholders
%             for decoding / TRF / evoked analyses.
%
% NOTE
% This is a practical skeleton. Some article-specific methods (time-shift PCA,
% DSS, TRF ridge optimization, temporal generalization decoding) are implemented
% here in simplified form or left as clearly marked placeholders.

if nargin < 3, opts = struct(); end
opts = set_defaults(opts);

X = double(raw_eeg);
[nCh, nSamp] = size(X);
assert(isfield(opts,'fs'), 'opts.fs is required');
assert(length(opts.chan_labels) == nCh, 'chan_labels length must match channels');

%% 1) Mean-centering
X = X - mean(X, 2);

%% 2) Slow trend removal via robust polynomial fit (article-inspired)
t = (0:nSamp-1) / opts.fs;
for ch = 1:nCh
    p = polyfit(t, X(ch,:), opts.poly_order);
    trend = polyval(p, t);
    X(ch,:) = X(ch,:) - trend;
end

%% 3) Detect bad channels (> 3 SD of channel amplitude metric)
chan_metric = std(X, 0, 2);
z_chan = (chan_metric - mean(chan_metric)) ./ std(chan_metric + eps);
bad_ch = find(abs(z_chan) > opts.bad_chan_zthr);

%% 4) Interpolate bad channels from neighbors
X_interp = X;
for k = 1:numel(bad_ch)
    ch = bad_ch(k);
    neigh = opts.neighbors{ch};
    neigh = neigh(neigh >= 1 & neigh <= nCh & neigh ~= ch);
    neigh = setdiff(neigh, bad_ch);
    if ~isempty(neigh)
        X_interp(ch,:) = mean(X(neigh,:), 1);
    end
end
X = X_interp;

%% 5) Low-pass filter
[b,a] = butter(4, opts.lowpass_hz / (opts.fs/2), 'low');
X = filtfilt(b, a, X')';

%% 6) Downsample
if opts.target_fs < opts.fs
    [p,q] = rat(opts.target_fs / opts.fs);
    X = resample(X', p, q)';
    scale_events = opts.target_fs / opts.fs;
    for i = 1:numel(events)
        events(i).sample_ds = round(events(i).sample * scale_events);
    end
    fs2 = opts.target_fs;
else
    for i = 1:numel(events)
        events(i).sample_ds = events(i).sample;
    end
    fs2 = opts.fs;
end

%% 7) Ocular artifact attenuation (simplified regression-based approach)
if ~isempty(opts.heog_idx) || ~isempty(opts.veog_idx)
    eog_idx = unique([opts.heog_idx(:); opts.veog_idx(:)])';
    eog_idx = eog_idx(eog_idx >= 1 & eog_idx <= nCh);
    if ~isempty(eog_idx)
        EOG = X(eog_idx,:);
        for ch = 1:nCh
            if ismember(ch, eog_idx), continue; end
            beta = (EOG' \ X(ch,:)')';
            X(ch,:) = X(ch,:) - beta * EOG;
        end
    end
end

%% 8) Re-reference with robust mean (median approximation)
ref = median(X, 1);
X = X - ref;

%% 9) Epoching
s1 = round(opts.epoch_win_sec(1) * fs2);
s2 = round(opts.epoch_win_sec(2) * fs2);
L = s2 - s1 + 1;
valid = false(1, numel(events));
epochs = nan(nCh, L, numel(events));
for i = 1:numel(events)
    idx = events(i).sample_ds + s1 : events(i).sample_ds + s2;
    if idx(1) >= 1 && idx(end) <= size(X,2)
        epochs(:,:,i) = X(:, idx);
        valid(i) = true;
    end
end
epochs = epochs(:,:,valid);
events_valid = events(valid);

%% 10) Reject bad epochs (> 3 SD amplitude metric)
if ~isempty(epochs)
    ep_metric = squeeze(max(std(epochs,0,2),[],1));
    z_ep = (ep_metric - mean(ep_metric)) ./ std(ep_metric + eps);
    good_ep = abs(z_ep) <= opts.bad_epoch_zthr;
    epochs = epochs(:,:,good_ep);
    events_valid = events_valid(good_ep);
else
    good_ep = [];
end

%% 11) Evoked response (simple average placeholder)
evoked = mean(epochs, 3, 'omitnan');
time = (s1:s2) / fs2;

%% 12) Placeholders for article-style analyses
results = struct();
results.fs = fs2;
results.time = time;
results.bad_channels = bad_ch;
results.X_preprocessed = X;
results.epochs = epochs;
results.events = events_valid;
results.evoked = evoked;
results.notes = {
    'Article-inspired preprocessing implemented: centering, detrending, bad-channel interpolation, low-pass, downsampling, ocular artifact attenuation, rereference, epoching, bad-epoch rejection.'
    'Article-specific analyses to add next: logistic-regression decoding with temporal generalization.'
    'Article-specific analyses to add next: TRF with ridge regression over surprisal/log-probability predictors.'
    'Article-specific analyses to add next: DSS-denoised evoked responses and statistics.'
    };

if isfield(opts,'labels_ref_alt') && numel(opts.labels_ref_alt) == size(epochs,3)
    results.decoding_placeholder = simple_timewise_decoding(epochs, opts.labels_ref_alt);
else
    results.decoding_placeholder = [];
end

end

function opts = set_defaults(opts)
if ~isfield(opts,'chan_labels'),    opts.chan_labels = {}; end
if ~isfield(opts,'heog_idx'),       opts.heog_idx = []; end
if ~isfield(opts,'veog_idx'),       opts.veog_idx = []; end
if ~isfield(opts,'neighbors'),      opts.neighbors = {}; end
if ~isfield(opts,'epoch_win_sec'),  opts.epoch_win_sec = [0 6]; end
if ~isfield(opts,'bad_chan_zthr'),  opts.bad_chan_zthr = 3; end
if ~isfield(opts,'bad_epoch_zthr'), opts.bad_epoch_zthr = 3; end
if ~isfield(opts,'lowpass_hz'),     opts.lowpass_hz = 40; end
if ~isfield(opts,'target_fs'),      opts.target_fs = 100; end
if ~isfield(opts,'poly_order'),     opts.poly_order = 30; end
if isempty(opts.neighbors) && ~isempty(opts.chan_labels)
    nCh = numel(opts.chan_labels);
    opts.neighbors = cell(1,nCh);
    for i = 1:nCh
        opts.neighbors{i} = setdiff(max(1,i-2):min(nCh,i+2), i);
    end
end
end

function out = simple_timewise_decoding(epochs, labels)
% Very small placeholder decoding: mean over channels at each time,
% class separation via AUC-like proxy using rank-sum normalization.
labels = labels(:)';
[nCh, nT, nEp] = size(epochs);
assert(numel(labels) == nEp, 'labels length mismatch');
X = squeeze(mean(epochs,1))'; % [epochs x time]
score = nan(1,nT);
for t = 1:nT
    a = X(labels==0, t);
    b = X(labels==1, t);
    if isempty(a) || isempty(b), continue; end
    score(t) = abs(mean(a) - mean(b)) / (std([a;b]) + eps);
end
out.score = score;
out.description = 'Placeholder separability score across time; replace with logistic regression + cross-validation + temporal generalization.';
end