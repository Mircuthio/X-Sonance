function data_trials = assemble_Barbieri_data_trials_from_scaffold(D, events)
% assemble_Barbieri_data_trials_from_scaffold
% Costruisce 4 trial placeholder: consonant/dissonant x standard/deviant.

if nargin < 1 || isempty(D)
    error('D is required.');
end
if nargin < 2
    events = struct([]);
end

data_trials = struct();
data_trials.fs = D.fs;
data_trials.epochMs = D.epochMs;
data_trials.baselineMs = D.baselineMs;
data_trials.chanLabels = D.goodEEG;
data_trials.badChannels = D.badChannels;
data_trials.time = D.time;
data_trials.events = events;

conds = {'consonant','dissonant'};
classes = {'standard','deviant'};
k = 0;

for c = 1:numel(conds)
    for e = 1:numel(classes)
        k = k + 1;
        data_trials.trials(k).trialName = [conds{c} '_' classes{e}];
        data_trials.trials(k).condition = conds{c};
        data_trials.trials(k).eventClass = classes{e};
        data_trials.trials(k).epochData = [];
        data_trials.trials(k).time = D.time;
        data_trials.trials(k).isGood = true;
        data_trials.trials(k).event = [];
    end
end

data_trials.meta = struct('note', 'Placeholder: replace with real epochs.');
end