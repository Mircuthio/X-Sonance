%% TEST_VERIFICA_STEP3_DATASET_MARCO
clear; close all; clc
%% 1) PATH
step2_outdir = ...
'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA';
if ~exist(step2_outdir, 'dir')
    error('Cartella STEP2 non trovata: %s', step2_outdir);
end

%% 2) LOAD FILES STEP2
files = dir(fullfile(step2_outdir, '*_epochData.mat'));
if isempty(files)
    error('Nessun file *_epochData.mat trovato in %s', step2_outdir);
end

nFiles = numel(files);
subj_list = struct('subj_id', cell(nFiles,1), 'data_trials', cell(nFiles,1));

for i = 1:nFiles
    S = load(fullfile(files(i).folder, files(i).name));

    if ~isfield(S, 'subjectEpochData')
        error('Nel file %s non trovo subjectEpochData.', files(i).name);
    end

    subjData = S.subjectEpochData;

    if isfield(subjData, 'subjectID')
        subj_list(i).subj_id = subjData.subjectID;
    else
        subj_list(i).subj_id = regexprep(files(i).name, '_epochData\.mat$', '');
    end

    if isfield(subjData, 'data_trials')
        subj_list(i).data_trials = subjData.data_trials;
    else
        error('Nel file %s non trovo data_trials.', files(i).name);
    end

    fprintf('Caricato soggetto %s\n', string(subj_list(i).subj_id));
end
fprintf('\n');
fprintf('========================\n');
fprintf('DATASET SUMMARY\n');
fprintf('========================\n');

for i = 1:numel(subj_list)

    fprintf('%s\n', ...
        subj_list(i).subj_id);

    fprintf('Trials: %d\n',...
        numel(subj_list(i).data_trials));

end


fprintf('\n');
fprintf('========================\n');
fprintf('DATASET SUMMARY\n');
fprintf('========================\n');

for i = 1:numel(subj_list)

    fprintf('%s\n', ...
        subj_list(i).subj_id);

    fprintf('Trials: %d\n',...
        numel(subj_list(i).data_trials));

end

%Verifica struttura trial
trial0 = subj_list(1).data_trials(1);
disp(fieldnames(trial0))

%Verifica distribuzione eventi
for i = 1:numel(subj_list)
    labels = ...
        {subj_list(i).data_trials.eventLabel};
    fprintf('\n%s\n',...
        subj_list(i).subj_id);
    disp(tabulate(labels'))
end

% Verifica asse temporale
t = subj_list(1).data_trials(1).time;

fprintf('\n');
fprintf('Time start : %.3f\n',min(t));
fprintf('Time end   : %.3f\n',max(t));
fprintf('Samples    : %d\n',numel(t));

% roi check
MAIN_ROI

roiNames = fieldnames(ROI);
disp(roiNames)

labels0 = {subj_list(1).data_trials(1).chanlocs.labels};

for r = 1:numel(roiNames)
    roiLabels = ROI.(roiNames{r});
    fprintf('\nROI %s\n',roiNames{r});
    disp(intersect(labels0,roiLabels))
end