function events = parse_Barbieri_trc_markers(trcFile)
% parse_Barbieri_trc_markers
% Tenta di leggere marker/eventi da un TRC Micromed.
% Se il reader non è disponibile, fallisce in modo esplicito.

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end

events = struct('name', {}, 'code', {}, 'condition', {}, 'eventClass', {}, 'sample', {});

% Tentativo 1: FieldTrip
try
    hdr = ft_read_header(trcFile);
    evt = ft_read_event(trcFile);

    if isempty(evt)
        error('No events returned by ft_read_event.');
    end

    k = 0;
    for i = 1:numel(evt)
        if ~isfield(evt(i), 'type') || ~isfield(evt(i), 'sample')
            continue;
        end

        k = k + 1;
        events(k).name = string(evt(i).type);
        events(k).code = i;
        events(k).sample = double(evt(i).sample);

        nameLower = lower(string(evt(i).type));
        if contains(nameLower, 'conson')
            events(k).condition = 'consonant';
        elseif contains(nameLower, 'disson')
            events(k).condition = 'dissonant';
        else
            events(k).condition = 'unknown';
        end

        if contains(nameLower, 'deviant') || contains(nameLower, 'dev')
            events(k).eventClass = 'deviant';
        elseif contains(nameLower, 'standard') || contains(nameLower, 'std')
            events(k).eventClass = 'standard';
        else
            events(k).eventClass = 'unknown';
        end
    end

    if isempty(events)
        error('Events parsed but empty after filtering.');
    end
    return;
catch
end

% Tentativo 2: fallback esplicito
error(['TRC marker parser not implemented for this file yet. ', ...
       'Use ft_read_event / ft_read_header or a Micromed-specific reader.']);
end