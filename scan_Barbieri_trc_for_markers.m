function info = scan_Barbieri_trc_for_markers(trcFile)
% scan_Barbieri_trc_for_markers  Heuristic scan for Micromed TRC marker block.
% Save this as scan_Barbieri_trc_for_markers.m

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
words = regexp(ascii, '[A-Za-z0-9_\-]+', 'match');

searchWindow = bytes(1:min(numel(bytes),100000));
searchStr = char(searchWindow(:)');
patterns = {'EVENT','TRIGGER','MONTAGE','LABCOD','TRONCA','NOTE','ORDER','IMPED'};
cands = struct();
for i = 1:numel(patterns)
    pat = patterns{i};
    idx = strfind(searchStr, pat);
    cands.(matlab.lang.makeValidName(pat)) = idx;
end

info = struct();
info.trcFile = trcFile;
info.fileBytes = numel(bytes);
info.headerAscii = ascii;
info.tokens = unique(words);
info.candidateOffsets = cands;
info.notes = 'If EVENT/TRIGGER offsets look plausible, we can attempt a format-specific event parse next.';
end