% =========================
% File: inspect_Barbieri_subject.m
% Save this file in MATLAB, then run:
%   inspect_Barbieri_subject('D:\X-SONANCE\Dataset_Barberi\Raw_newborns\Subj01')
% =========================
function inspect_Barbieri_subject(subjectFolder)

if nargin < 1 || isempty(subjectFolder)
    subjectFolder = pwd;
end

fprintf('Subject folder: %s\n', subjectFolder);

mats = dir(fullfile(subjectFolder, '*.mat'));
trcs = dir(fullfile(subjectFolder, '*.TRC'));

fprintf('\nMAT files (%d):\n', numel(mats));
for i = 1:numel(mats)
    fprintf('  %s\n', mats(i).name);
end

fprintf('\nTRC files (%d):\n', numel(trcs));
for i = 1:numel(trcs)
    fprintf('  %s\n', trcs(i).name);
end

for i = 1:min(numel(mats), 3)
    f = fullfile(subjectFolder, mats(i).name);
    fprintf('\n=== Inspecting %s ===\n', mats(i).name);
    A = load(f);
    disp('Top-level fields:');
    disp(fieldnames(A));
    if isfield(A, 'data')
        d = A.data;
        fprintf('data class: %s\n', class(d));
        fprintf('data size: '); disp(size(d));
        try
            fprintf('squeezed size: '); disp(size(squeeze(d)));
        catch
        end
        try
            fprintf('min/max: %g / %g\n', min(d(:)), max(d(:)));
        catch
        end
    end
    if isfield(A, 'allsubj')
        s = A.allsubj;
        fprintf('allsubj class: %s\n', class(s));
        if isstruct(s)
            disp('allsubj fields:');
            disp(fieldnames(s));
        end
    end
end
end