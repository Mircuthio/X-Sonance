function data_trials = extract_Barbieri_epochs(D, events, rawEEG)
% rawEEG: canali x campioni

if nargin < 3 || isempty(rawEEG)
    error('rawEEG is required.');
end
if isempty(events)
    error('events is empty.');
end

preMs = D.epochMs(1);
postMs = D.epochMs(2);
fs = D.fs;

conds = {'consonant','dissonant'};
classes = {'standard','deviant'};

for c = 1:numel(conds)
    for e = 1:numel(classes)
        idxTrial = find(strcmp({D.events.condition}, conds{c}) & strcmp({D.events.eventClass}, classes{e}), 1);
        if isempty(idxTrial)
            continue;
        end

        ev = events(find(strcmp({events.condition}, conds{c}) & strcmp({events.eventClass}, classes{e}), 1));
        if isempty(ev)
            continue;
        end

        s0 = round(ev.sample + preMs/1000 * fs);
        s1 = round(ev.sample + postMs/1000 * fs);

        if s0 < 1 || s1 > size(rawEEG, 2)
            continue;
        end

        epoch = rawEEG(:, s0:s1);
        t = linspace(preMs, postMs, size(epoch, 2));

        data_trials.trials(idxTrial).epochData = epoch;
        data_trials.trials(idxTrial).time = t;
        data_trials.trials(idxTrial).event = ev;
        data_trials.trials(idxTrial).isGood = true;
    end
end
end