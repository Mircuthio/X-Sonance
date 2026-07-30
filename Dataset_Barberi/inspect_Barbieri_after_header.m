function info = inspect_Barbieri_after_header(trcFile)
% inspect_Barbieri_after_header  Inspect bytes after the visible header keywords.
% Save this as inspect_Barbieri_after_header.m
%
% Usage:
%   info = inspect_Barbieri_after_header('D:\...\Subj01_F12.TRC');
%
% Paste back:
%   info.ascii
%   info.byteRange

if nargin < 1 || isempty(trcFile)
    error('trcFile is required.');
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);

startPos = 230;
endPos = 600;
seg = bytes(startPos:endPos);
info = struct();
info.trcFile = trcFile;
info.byteRange = [startPos endPos];
info.rawBytes = seg;
info.ascii = char(seg(seg>=32 & seg<=126))';
end