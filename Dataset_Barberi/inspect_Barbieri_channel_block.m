function info = inspect_Barbieri_channel_block(trcFile, startByte, nBytes)
% inspect_Barbieri_channel_block  Inspect binary block after header to infer channel table.
% Save this as inspect_Barbieri_channel_block.m
%
% Usage:
%   info = inspect_Barbieri_channel_block('D:\...\Subj01_F12.TRC', 1209, 4000);
%
% Paste back:
%   info.ascii
%   info.firstWords
%   info.summary

if nargin < 2 || isempty(startByte)
    startByte = 1209;
end
if nargin < 3 || isempty(nBytes)
    nBytes = 4000;
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);

endByte = min(numel(bytes), startByte + nBytes - 1);
seg = bytes(startByte:endByte);
ascii = char(seg(seg>=32 & seg<=126))';
words = regexp(ascii, '[A-Za-z0-9_\-]+', 'match');

info = struct();
info.trcFile = trcFile;
info.byteRange = [startByte endByte];
info.rawBytes = seg;
info.ascii = ascii;
info.firstWords = unique(words);
info.summary = struct();
info.summary.min = min(seg);
info.summary.max = max(seg);
info.summary.mean = mean(double(seg));
info.summary.std = std(double(seg));
info.summary.numPrintable = sum(seg >= 32 & seg <= 126);
info.summary.numControl = sum(seg < 32 | seg > 126);
end