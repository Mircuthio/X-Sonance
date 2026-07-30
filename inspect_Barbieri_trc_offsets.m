function out = inspect_Barbieri_trc_offsets(trcFile, offsets)
% inspect_Barbieri_trc_offsets  Show raw bytes around EVENT/TRIGGER offsets.
% Save this as inspect_Barbieri_trc_offsets.m
%
% Usage:
%   out = inspect_Barbieri_trc_offsets('D:\...\Subj01_F12.TRC', [369 385 401]);
%
% What to paste back:
%   out.segments(1).ascii
%   out.segments(2).ascii
%   out.segments(3).ascii

if nargin < 2 || isempty(offsets)
    error('Provide offsets, e.g. [369 385 401].');
end
if exist(trcFile, 'file') ~= 2
    error('TRC file not found: %s', trcFile);
end

fid = fopen(trcFile, 'r');
bytes = fread(fid, inf, '*uint8');
fclose(fid);

out = struct();
out.trcFile = trcFile;
out.offsets = offsets(:)';
out.segments = struct([]);
for i = 1:numel(offsets)
    o = offsets(i);
    a = max(1, o-32);
    b = min(numel(bytes), o+128);
    seg = bytes(a:b);
    out.segments(i).offset = o;
    out.segments(i).startByte = a;
    out.segments(i).endByte = b;
    out.segments(i).rawBytes = seg;
    out.segments(i).ascii = char(seg(seg>=32 & seg<=126))';
end
end
