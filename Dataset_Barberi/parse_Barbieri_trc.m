function [events, info] = parse_Barbieri_trc(trcFile)
% parse_Barbieri_trc  Read Micromed TRC header tokens and event area.
% Save this as parse_Barbieri_trc.m
%
% Usage:
%   [events, info] = parse_Barbieri_trc('D:\X-SONANCE\Dataset_Barberi\Raw_newborns\Subj01\Subj01_F12.TRC');
%
% Current purpose:
%   - Confirms the file is Micromed Brain-Quick format
%   - Extracts ASCII header tokens
%   - Searches for event-related keywords
%   - Still returns empty events until the event block structure is decoded

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, 4096, '*uint8');
fclose(fid);

ascii = char(bytes(bytes >= 32 & bytes <= 126))';
words = regexp(ascii, '[A-Za-z0-9_\-]+', 'match');

info = struct();
info.trcFile = trcFile;
info.fileBytes = dir(trcFile).bytes;
info.ascii = ascii;
info.tokens = unique(words);
info.isMicromed = any(strcmpi(words, 'MICROMED')) || any(strcmpi(words, 'Brain-Quick'));
info.eventTokens = intersect(info.tokens, {'EVENT','TRIGGER','NOTE','ORDER','TRONCA','MONTAGE','LABCOD'});
info.note = 'TRC header confirmed; event block still requires offset-specific parsing.';

% Placeholder events - empty until the event block is identified.
events = struct('sample', {}, 'type', {}, 'label', {}, 'duration', {}, 'condition', {});
end