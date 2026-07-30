function data_trials = build_Barbieri_data_trials(E, events)
% build_Barbieri_data_trials  Create the data_trials container from epoched data.
% Save this as build_Barbieri_data_trials.m
%
% Usage:
%   data_trials = build_Barbieri_data_trials(E, events);
%
% Inputs:
%   E      : epoch container (placeholder or real)
%   events : struct array with fields condition, eventClass, trialIndex, sample
%
% Output:
%   data_trials : trial-wise container ready for ERP/MMR analysis

if nargin < 1 || isempty(E)
    error('E is required.');
end
if nargin < 2
    events = struct([]);
end

data_trials = struct();
data_trials.fs = E.fs;
data_trials.epochMs = E.epochMs;
data_trials.baselineMs = E.baselineMs;
data_trials.chanLabels = E.chanLabels;
data_trials.badChannels = E.badChannels;
data_trials.conditions = {'consonant','dissonant'};
data_trials.eventClasses = {'standard','deviant'};
data_trials.time = linspace(E.epochMs(1), E.epochMs(2), 1001);
data_trials.trials = struct([]);

k = 0;
for c = 1:numel(data_trials.conditions)
    for e = 1:numel(data_trials.eventClasses)
        k = k + 1;
        data_trials.trials(k).trialName = [data_trials.conditions{c} '_' data_trials.eventClasses{e}];
        data_trials.trials(k).condition = data_trials.conditions{c};
        data_trials.trials(k).eventClass = data_trials.eventClasses{e};
        data_trials.trials(k).epochData = [];
        data_trials.trials(k).isGood = true;
        data_trials.trials(k).event = [];
    end
end

data_trials.events = events;
data_trials.meta = struct();
data_trials.meta.note = 'Populate epochData with real epochs once event decoding is finalized.';
end