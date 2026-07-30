function [EEG_out, blinkModel] = applyTimeShiftPCAblink(EEG_in, eogChannel, varargin)
% applyTimeShiftPCAblink
% Backup blink-removal function based on time-shift PCA of an EOG/blink channel.
%
% PURPOSE
%   Build a delayed-embedding matrix from a blink/EOG channel, extract the
%   dominant temporal subspace with PCA, and regress this blink subspace out
%   from EEG channels.
%
% USAGE
%   [EEG_clean, blinkModel] = applyTimeShiftPCAblink(EEG, 'VEOG');
%   [EEG_clean, blinkModel] = applyTimeShiftPCAblink(EEG, 65, 'MaxLagMs', 120);
%
% INPUTS
%   EEG_in      - EEGLAB EEG struct.
%   eogChannel  - EOG channel label (char/string) or numeric channel index.
%
% NAME-VALUE OPTIONS
%   'MaxLagMs'        : symmetric lag around 0 in ms for time-shift matrix.
%                       Default: 120.
%   'NumPCs'          : number of PCA components to regress out. If empty,
%                       selected from cumulative explained variance.
%                       Default: [].
%   'ExplainedThresh' : cumulative explained variance threshold in [0 100]
%                       used only if NumPCs is empty. Default: 95.
%   'ChannelMask'     : channel indices to clean. Default: all channels
%                       except the EOG channel.
%   'CenterData'      : logical, mean-center predictor matrix and targets.
%                       Default: true.
%   'Verbose'         : logical. Default: true.
%
% OUTPUTS
%   EEG_out     - EEGLAB EEG struct after blink regression.
%   blinkModel  - struct with metadata, PCA model, regression weights, lags,
%                 explained variance, and cleaned channels.
%
% NOTES
%   - This function is intended as a backup / alternative to ICA.
%   - Best suited when a reliable blink/EOG channel is available.
%   - It performs linear regression of blink subspace predictors onto EEG.
%   - The EOG channel itself is left unchanged.
%
% AUTHORING STYLE
%   Programmer-facing English, designed for integration into batch EEGLAB
%   pipelines.

p = inputParser;
p.addRequired('EEG_in', @(x) isstruct(x) && isfield(x,'data') && isfield(x,'srate'));
p.addRequired('eogChannel');
p.addParameter('MaxLagMs', 120, @(x) isnumeric(x) && isscalar(x) && x >= 0);
p.addParameter('NumPCs', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
p.addParameter('ExplainedThresh', 95, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 100);
p.addParameter('ChannelMask', [], @(x) isempty(x) || isnumeric(x));
p.addParameter('CenterData', true, @(x) islogical(x) || isnumeric(x));
p.addParameter('Verbose', true, @(x) islogical(x) || isnumeric(x));
p.parse(EEG_in, eogChannel, varargin{:});
opt = p.Results;

EEG_out = EEG_in;
X = double(EEG_in.data);
[nCh, ~] = size(X);

if ischar(eogChannel) || isstring(eogChannel)
    labels = {EEG_in.chanlocs.labels};
    eogIdx = find(strcmpi(labels, char(eogChannel)), 1);
    if isempty(eogIdx)
        error('applyTimeShiftPCAblink:EOGNotFound', ...
            'EOG channel "%s" not found in EEG.chanlocs.labels.', char(eogChannel));
    end
elseif isnumeric(eogChannel) && isscalar(eogChannel) && eogChannel >= 1 && eogChannel <= nCh
    eogIdx = eogChannel;
else
    error('applyTimeShiftPCAblink:BadEOGChannel', ...
        'eogChannel must be a valid channel label or numeric index.');
end

if isempty(opt.ChannelMask)
    cleanIdx = setdiff(1:nCh, eogIdx);
else
    cleanIdx = unique(opt.ChannelMask(:)');
    cleanIdx = intersect(cleanIdx, 1:nCh);
    cleanIdx(cleanIdx == eogIdx) = [];
end

maxLagSamp = round((opt.MaxLagMs / 1000) * EEG_in.srate);
lags = -maxLagSamp:maxLagSamp;
nLags = numel(lags);

eog = X(eogIdx, :);
if opt.CenterData
    eog = eog - mean(eog, 'omitnan');
end

T = buildLagMatrix(eog, lags);
validRows = all(~isnan(T), 2);
Tvalid = T(validRows, :);

if isempty(Tvalid)
    error('applyTimeShiftPCAblink:NoValidSamples', ...
        'No valid samples available after lag embedding.');
end

[coeff, score, latent, ~, explained, mu] = pca(Tvalid, 'Centered', logical(opt.CenterData));

if isempty(opt.NumPCs)
    cumExpl = cumsum(explained);
    nPC = find(cumExpl >= opt.ExplainedThresh, 1, 'first');
    nPC = max(1, nPC);
else
    nPC = min(size(score,2), round(opt.NumPCs));
end

P = score(:, 1:nPC);

betas = nan(nPC, numel(cleanIdx));
intercepts = nan(1, numel(cleanIdx));
r2 = nan(1, numel(cleanIdx));

for k = 1:numel(cleanIdx)
    ch = cleanIdx(k);
    y = X(ch, validRows)';
    if opt.CenterData
        yMean = mean(y, 'omitnan');
        y0 = y - yMean;
        b = P \ y0;
        yHat = P * b + yMean;
        intercepts(k) = yMean;
    else
        Xreg = [ones(size(P,1),1), P];
        bfull = Xreg \ y;
        intercepts(k) = bfull(1);
        b = bfull(2:end);
        yHat = Xreg * bfull;
    end

    yClean = y - (yHat - intercepts(k));
    X(ch, validRows) = yClean';
    betas(:,k) = b;

    ssRes = nansum((y - yHat).^2);
    ssTot = nansum((y - mean(y,'omitnan')).^2);
    if ssTot > 0
        r2(k) = 1 - ssRes / ssTot;
    end
end

EEG_out.data = cast(X, class(EEG_in.data));
if exist('eeg_checkset', 'file') == 2
    EEG_out = eeg_checkset(EEG_out);
end

blinkModel = struct();
blinkModel.method = 'time_shift_pca_blink_regression';
blinkModel.eogIndex = eogIdx;
blinkModel.eogLabel = getChannelLabel(EEG_in, eogIdx);
blinkModel.cleanedChannelIdx = cleanIdx;
blinkModel.cleanedChannelLabels = getChannelLabels(EEG_in, cleanIdx);
blinkModel.maxLagMs = opt.MaxLagMs;
blinkModel.maxLagSamples = maxLagSamp;
blinkModel.lags = lags;
blinkModel.numLagPredictors = nLags;
blinkModel.numPCsUsed = nPC;
blinkModel.explained = explained;
blinkModel.cumulativeExplained = cumsum(explained);
blinkModel.coeff = coeff;
blinkModel.score = score(:, 1:nPC);
blinkModel.latent = latent;
blinkModel.mu = mu;
blinkModel.validRows = validRows;
blinkModel.regressionBetas = betas;
blinkModel.regressionIntercepts = intercepts;
blinkModel.channelR2 = r2;
blinkModel.options = opt;

if ~isfield(EEG_out, 'etc') || isempty(EEG_out.etc)
    EEG_out.etc = struct();
end
EEG_out.etc.timeShiftPCABlink = rmfield(blinkModel, {'score','validRows'});

if opt.Verbose
    fprintf('applyTimeShiftPCAblink: EOG channel = %s (idx %d)\n', blinkModel.eogLabel, eogIdx);
    fprintf('applyTimeShiftPCAblink: Lags = %d (%d to %d samples)\n', nLags, lags(1), lags(end));
    fprintf('applyTimeShiftPCAblink: PCs used = %d\n', nPC);
    fprintf('applyTimeShiftPCAblink: Median channel R^2 = %.4f\n', median(r2, 'omitnan'));
end

end

function T = buildLagMatrix(x, lags)
n = numel(x);
T = nan(n, numel(lags));
for i = 1:numel(lags)
    lag = lags(i);
    if lag < 0
        T(1:end+lag, i) = x(1-lag:end);
    elseif lag > 0
        T(1+lag:end, i) = x(1:end-lag);
    else
        T(:, i) = x(:);
    end
end
end

function label = getChannelLabel(EEG, idx)
if isfield(EEG, 'chanlocs') && numel(EEG.chanlocs) >= idx && isfield(EEG.chanlocs(idx), 'labels')
    label = EEG.chanlocs(idx).labels;
else
    label = sprintf('Ch%d', idx);
end
end

function labels = getChannelLabels(EEG, idx)
labels = cell(size(idx));
for i = 1:numel(idx)
    labels{i} = getChannelLabel(EEG, idx(i));
end
end