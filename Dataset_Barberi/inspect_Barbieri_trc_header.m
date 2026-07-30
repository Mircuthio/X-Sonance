function [hdr, names] = inspect_Barbieri_trc_header(trcFile)
% inspect_Barbieri_trc_header  Inspect first bytes and ASCII tokens in TRC.
% Save this as inspect_Barbieri_trc_header.m
%
% Usage:
%   [hdr, names] = inspect_Barbieri_trc_header('D:\...\Subj01_F12.TRC');

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, 1024, '*uint8');
fclose(fid);

ascii = char(bytes(bytes >= 32 & bytes <= 126))';
words = regexp(ascii, '[A-Za-z0-9_\-]+', 'match');

hdr = struct();
hdr.file = trcFile;
hdr.first1024 = bytes;
hdr.ascii = ascii;
hdr.words = unique(words);

names = hdr.words;
end