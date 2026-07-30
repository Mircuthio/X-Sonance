function [events, info] = decode_Barbieri_event_header(trcFile)
% decode_Barbieri_event_header  Extract the visible event-related header labels.
% Save this as decode_Barbieri_event_header.m
%
% Usage:
%   [events, info] = decode_Barbieri_event_header('D:\...\Subj01_F12.TRC');
%
% What it does:
%   - Confirms header labels occur once each
%   - Stores their positions
%   - Creates a minimal header-event structure
%   - This is still NOT the final sample-by-sample event parser

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
labels = {'EVENT A','EVENT B','TRIGGER','BRAINIMG'};
positions = struct();
for i = 1:numel(labels)
    lab = labels{i};
    positions.(matlab.lang.makeValidName(lab)) = strfind(ascii, lab);
end

events = struct('label', {}, 'type', {}, 'position', {});
for i = 1:numel(labels)
    lab = labels{i};
    pos = positions.(matlab.lang.makeValidName(lab));
    if ~isempty(pos)
        events(end+1).label = lab; %#ok<AGROW>
        events(end).type = 'header_label';
        events(end).position = pos(1);
    end
end

info = struct();
info.trcFile = trcFile;
info.labels = labels;
info.positions = positions;
info.note = 'Header labels are single-occurrence only; final event parser still requires format-specific decoding beyond the header.';
end