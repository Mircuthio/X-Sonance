function events = build_Barbieri_events_from_header(headerNames)
% build_Barbieri_events_from_header
% Crea eventi placeholder da etichette d'header.

if nargin < 1
    headerNames = {'EVENT A','EVENT B','TRIGGER','BRAINIMG'};
end

events = struct('name', {}, 'code', {}, 'condition', {}, 'eventClass', {}, 'sample', {});
for i = 1:numel(headerNames)
    events(i).name = headerNames{i};
    events(i).code = i;
    events(i).condition = 'unknown';
    events(i).eventClass = 'unknown';
    events(i).sample = NaN;
end
end