function info = inspect_Barbieri_after_trigger(trcFile)
% inspect_Barbieri_after_trigger  Inspect the TRC region after TRIGGER.
% Save this as inspect_Barbieri_after_trigger.m
%
% Usage:
%   info = inspect_Barbieri_after_trigger('D:\...\Subj01_F12.TRC');
%
% Paste back:
%   info.asciiSnippet
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

startPos = 234;
endPos = min(numel(bytes), 1800);
seg = bytes(startPos:endPos);
idx = strfind(char(seg(:)'),'TRIGGER');
if isempty(idx)
    trigPos = 1;
else
    trigPos = idx(1) + numel('TRIGGER');
end
sub = seg(trigPos:min(numel(seg), trigPos+800));
info = struct();
info.trcFile = trcFile;
info.byteRange = [startPos+trigPos-1 min(numel(bytes), startPos+trigPos-1+800)];
info.rawBytes = sub;
info.asciiSnippet = char(sub(sub>=32 & sub<=126))';
end