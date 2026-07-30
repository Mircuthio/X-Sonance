function [events, info] = parse_Barbieri_trc_events(trcFile)
% parse_Barbieri_trc_events  Parse simple Micromed event labels around EVENT/TRIGGER.
% Save this as parse_Barbieri_trc_events.m
%
% Usage:
%   [events, info] = parse_Barbieri_trc_events('D:\X-SONANCE\Dataset_Barberi\Raw_newborns\Subj01\Subj01_F12.TRC');
%
% This parser extracts the EVENT labels visible in the header area.

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);

ascii = char(bytes(bytes >= 32 & bytes <= 126))';
patterns = {'EVENT A','EVENT B','TRIGGER','BRAINIMG'};
found = struct();
for i = 1:numel(patterns)
    found.(matlab.lang.makeValidName(patterns{i})) = strfind(ascii, patterns{i});
end

% Build a minimal event table from visible labels only.
events = struct('label', {}, 'type', {}, 'sample', {}, 'condition', {});
labels = {'EVENT A','EVENT B','TRIGGER'};
for i = 1:numel(labels)
    if ~isempty(found.(matlab.lang.makeValidName(labels{i})))
        events(end+1).label = labels{i}; %#ok<AGROW>
        events(end).type = 'header_label';
        events(end).sample = found.(matlab.lang.makeValidName(labels{i}))(1);
        events(end).condition = '';
    end
end

info = struct();
info.trcFile = trcFile;
info.ascii = ascii;
info.found = found;
info.note = 'These are header labels; next step is mapping them to actual event codes and sample positions.';
end