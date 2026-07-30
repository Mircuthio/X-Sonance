function info = inspect_Barbieri_block_after_event_header(trcFile)
% inspect_Barbieri_block_after_event_header  Search after event header for numeric/binary block.
% Save this as inspect_Barbieri_block_after_event_header.m
%
% Usage:
%   info = inspect_Barbieri_block_after_event_header('D:\...\Subj01_F12.TRC');
%
% Paste back:
%   info.asciiSnippet
%   info.firstNonAsciiOffset

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);

startPos = 240;
endPos = min(numel(bytes), 1200);
seg = bytes(startPos:endPos);
nonAsciiIdx = find(seg < 32 | seg > 126, 1, 'first');
if isempty(nonAsciiIdx)
    nonAsciiIdx = NaN;
end

info = struct();
info.trcFile = trcFile;
info.byteRange = [startPos endPos];
info.firstNonAsciiOffset = nonAsciiIdx;
info.rawBytes = seg;
info.asciiSnippet = char(seg(seg>=32 & seg<=126))';
end