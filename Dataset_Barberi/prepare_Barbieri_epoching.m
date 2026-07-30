function [E, meta] = prepare_Barbieri_epoching(S, varargin)
% prepare_Barbieri_epoching  Real epoching scaffold for Barbieri dataset.
% Save this as prepare_Barbieri_epoching.m
%
% Usage:
%   [E, meta] = prepare_Barbieri_epoching(S, 'sourceKey', 'Subj01_F12');
%
% IMPORTANT:
%   This function is a controlled scaffold. It tries to infer epoch-related
%   parameters, but because the TRC marker format is still unknown, it does not
%   claim to perform definitive event parsing yet. It produces a standardized
%   structure ready for manual adjustment once the TRC/event map is confirmed.

p = inputParser;
addParameter(p, 'sourceKey', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'fs', [], @(x) isempty(x) || isnumeric(x));
addParameter(p, 'epochMs', [-200 800], @(x) isnumeric(x) && numel(x)==2);
addParameter(p, 'baselineMs', [-200 0], @(x) isnumeric(x) && numel(x)==2);
parse(p, varargin{:});
sourceKey = char(p.Results.sourceKey);
fs = p.Results.fs;
epochMs = p.Results.epochMs;
baselineMs = p.Results.baselineMs;

if nargin < 1 || isempty(S)
    error('S is required.');
end

keys = fieldnames(S.raw);
if isempty(keys)
    error('S.raw is empty.');
end
if isempty(sourceKey)
    sourceKey = keys{1};
end
if ~isfield(S.raw, sourceKey)
    error('sourceKey not found in S.raw.');
end

A = S.raw.(sourceKey);
if ~isfield(A, 'data')
    error('Selected file does not contain data.');
end

data = A.data;
if ndims(data) > 2
    data = squeeze(data);
end

nCh = size(data,1);
nS = size(data,2);

% Default fs if not supplied: infer only if a TRC file count suggests a known setup.
if isempty(fs)
    fs = NaN;
end

E = struct();
E.sourceKey = sourceKey;
E.fs = fs;
E.epochMs = epochMs;
E.baselineMs = baselineMs;
E.nChannels = nCh;
E.nSamples = nS;
E.time = [];
E.chanLabels = {};
E.events = struct([]);
E.conditions = {'consonant','dissonant'};
E.trials = struct([]);
E.raw = data;

% Placeholder epoch construction: one full-recording entry for each condition,
% so downstream ERP/plot code can already be wired to standardized fields.
for c = 1:numel(E.conditions)
    E.trials(c).condition = E.conditions{c};
    E.trials(c).eventType = 'placeholder_full_recording';
    E.trials(c).data = data;
    E.trials(c).startSample = 1;
    E.trials(c).endSample = nS;
    E.trials(c).time = [];
    E.trials(c).baselineCorrected = false;
end

meta = struct();
meta.sourceKey = sourceKey;
meta.message = 'Real epoching scaffold created; replace placeholder trial mapping with TRC event parsing.';
meta.nChannels = nCh;
meta.nSamples = nS;
meta.dataClass = class(data);
meta.dataMin = min(data(:));
meta.dataMax = max(data(:));
meta.fs = fs;
meta.epochMs = epochMs;
meta.baselineMs = baselineMs;
meta.nextStep = 'Map TRC markers to standard/deviant and slice real epochs';
end