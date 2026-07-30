function EEG = load_Barbieri_trc_with_eeglab(trcFile)
% load_Barbieri_trc_with_eeglab
% Carica un TRC con EEGLAB e verifica gli eventi.

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end

if exist('pop_biosig', 'file') == 2
    EEG = pop_biosig(trcFile);
elseif exist('pop_readegi', 'file') == 2
    EEG = pop_readegi(trcFile);
else
    error('No suitable EEGLAB import function found.');
end

if ~isfield(EEG, 'event') || isempty(EEG.event)
    error('EEGLAB imported the file but EEG.event is empty.');
end
end