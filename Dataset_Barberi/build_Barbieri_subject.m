function S = build_Barbieri_subject(subjectFolder)
% build_Barbieri_subject  Load MAT files and build a unified subject container.
% Save this as build_Barbieri_subject.m
%
% Usage:
%   S = build_Barbieri_subject('D:\X-SONANCE\Dataset_Barberi\Raw_newborns\Subj01');

if nargin < 1 || isempty(subjectFolder)
    subjectFolder = pwd;
end

S = struct();
S.subjectFolder = subjectFolder;
S.created = datestr(now);
S.files = struct();
S.raw = struct();
S.summary = struct();

mats = dir(fullfile(subjectFolder, '*.mat'));
trcs = dir(fullfile(subjectFolder, '*.TRC'));

S.files.mat = {mats.name};
S.files.trc = {trcs.name};

for i = 1:numel(mats)
    f = fullfile(subjectFolder, mats(i).name);
    key = matlab.lang.makeValidName(erase(mats(i).name, '.mat'));
    A = load(f);
    S.raw.(key) = A;
    info = struct();
    info.fields = fieldnames(A);
    if isfield(A, 'data')
        d = A.data;
        info.dataClass = class(d);
        info.dataSize = size(d);
        info.dataSqueezedSize = size(squeeze(d));
        info.dataMin = min(d(:));
        info.dataMax = max(d(:));
    end
    S.summary.(key) = info;
end

outDir = fullfile(subjectFolder, 'MATLAB');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
save(fullfile(outDir, 'Barbieri_subject_container.mat'), 'S', '-v7.3');
end