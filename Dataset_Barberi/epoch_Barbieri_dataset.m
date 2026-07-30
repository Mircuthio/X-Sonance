function EEG = epoch_Barbieri_dataset(EEG)
% epoch_Barbieri_dataset
% Epoca i dati solo se gli eventi sono presenti.

if ~isfield(EEG, 'event') || isempty(EEG.event)
    error('Cannot epoch: EEG.event is empty.');
end

EEG = pop_epoch(EEG, {'standard','deviant','consonant','dissonant'}, [-0.2 0.8], 'epochinfo', 'yes');
EEG = pop_rmbase(EEG, [-200 0]);
end