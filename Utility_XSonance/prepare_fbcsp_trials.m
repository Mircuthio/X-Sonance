function EEG = prepare_fbcsp_trials(Trials)

EEG = Trials;

for iTr = 1:length(Trials)

    EEG(iTr).timeeeg = ...
        double(Trials(iTr).time);

    EEG(iTr).eeg = ...
        double(Trials(iTr).eeg);

    EEG(iTr).trialType = ...
        Trials(iTr).label;

end

end