function out = find_Barbieri_event_occurrences(trcFile)
% find_Barbieri_event_occurrences  Count occurrences of header event labels.
% Save this as find_Barbieri_event_occurrences.m
%
% Usage:
%   out = find_Barbieri_event_occurrences('D:\...\Subj01_F12.TRC');
%
% What to paste back:
%   out.counts
%   out.firstPositions

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
out = struct();
out.counts = struct();
out.firstPositions = struct();
for i = 1:numel(labels)
    lab = labels{i};
    pos = strfind(ascii, lab);
    out.counts.(matlab.lang.makeValidName(lab)) = numel(pos);
    if isempty(pos)
        out.firstPositions.(matlab.lang.makeValidName(lab)) = [];
    else
        out.firstPositions.(matlab.lang.makeValidName(lab)) = pos(1:min(10,numel(pos)));
    end
end
end