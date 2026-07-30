function out = inspect_Barbieri_event_window(trcFile, centerPos, win)
% inspect_Barbieri_event_window  Inspect raw bytes around a header position.
% Save this as inspect_Barbieri_event_window.m
%
% Usage:
%   out = inspect_Barbieri_event_window('D:\...\Subj01_F12.TRC', 234, 120);
%
% What to paste back:
%   out.ascii
%   out.rawBytes

if nargin < 2 || isempty(centerPos)
    error('Provide centerPos, e.g. 234.');
end
if nargin < 3 || isempty(win)
    win = 120;
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);

a = max(1, centerPos-win);
b = min(numel(bytes), centerPos+win);
seg = bytes(a:b);
out = struct();
out.trcFile = trcFile;
out.centerPos = centerPos;
out.startByte = a;
out.endByte = b;
out.rawBytes = seg;
out.ascii = char(seg(seg>=32 & seg<=126))';
end