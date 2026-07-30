function info = inspect_Barbieri_binary_after_header(trcFile, startByte)
% inspect_Barbieri_binary_after_header  Inspect non-ASCII bytes after header area.
% Save this as inspect_Barbieri_binary_after_header.m
%
% Usage:
%   info = inspect_Barbieri_binary_after_header('D:\...\Subj01_F12.TRC', 1209);
%
% Paste back:
%   info.firstBytes
%   info.summary

if nargin < 2 || isempty(startByte)
    startByte = 1209;
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);

endByte = min(numel(bytes), startByte + 200);
seg = bytes(startByte:endByte);
info = struct();
info.trcFile = trcFile;
info.byteRange = [startByte endByte];
info.firstBytes = seg(1:min(80,numel(seg)))';
info.summary = struct();
info.summary.min = min(seg);
info.summary.max = max(seg);
info.summary.mean = mean(double(seg));
info.summary.std = std(double(seg));
info.summary.numPrintable = sum(seg >= 32 & seg <= 126);
info.summary.numControl = sum(seg < 32 | seg > 126);
end