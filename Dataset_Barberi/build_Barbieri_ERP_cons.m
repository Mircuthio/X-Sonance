function ERP_cons = build_Barbieri_ERP_cons(E)
% build_Barbieri_ERP_cons  Condition-level ERP scaffold for consonant/deviant logic.
% Save this as build_Barbieri_ERP_cons.m
%
% What it should represent:
%   ERP_cons is the ERP for the consonant condition.
%   If/when real epochs are available, it will be the average across trials
%   belonging to the consonant condition.
%
% Important:
%   This scaffold only copies the placeholder waveform stored in E.trials(1).
%   It is not yet the real condition-average ERP from epoched data.

if nargin < 1 || isempty(E)
    error('E is required.');
end
if ~isfield(E, 'trials') || isempty(E.trials)
    error('E.trials is empty.');
end

ERP_cons = struct();
ERP_cons.condition = 'consonant';
ERP_cons.sourceKey = E.sourceKey;
ERP_cons.epochMs = E.epochMs;
ERP_cons.baselineMs = E.baselineMs;
ERP_cons.nChannels = E.nChannels;
ERP_cons.nSamples = E.nSamples;
ERP_cons.time = linspace(E.epochMs(1), E.epochMs(2), E.nSamples);
ERP_cons.waveform = E.trials(1).data;
ERP_cons.nTrials = 1;
ERP_cons.isPlaceholder = true;
ERP_cons.note = 'Replace with mean across consonant epochs once real epoch parsing is implemented.';
end