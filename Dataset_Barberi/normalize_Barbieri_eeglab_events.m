function EEG = normalize_Barbieri_eeglab_events(EEG)
% normalize_Barbieri_eeglab_events
% Porta gli eventi a una forma uniforme.

if ~isfield(EEG, 'event') || isempty(EEG.event)
    error('EEG.event is empty.');
end

for i = 1:numel(EEG.event)
    if ~isfield(EEG.event(i), 'type')
        EEG.event(i).type = 'unknown';
    end
    if ~isfield(EEG.event(i), 'latency')
        error('Missing latency in EEG.event.');
    end
    if iscell(EEG.event(i).type)
        EEG.event(i).type = EEG.event(i).type{1};
    end
    EEG.event(i).type = string(EEG.event(i).type);
end
end