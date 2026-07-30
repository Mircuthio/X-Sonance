% ========================================================================
% MAIN_DATASET_REPORT_MARCO
% ========================================================================
clear; clc; close all

rootFolderAllTrials = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials';
rootFoldersingleTrials = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\';
reportFolder = fullfile(rootFolderAllTrials,'DATASET_REPORT');

if ~exist(reportFolder,'dir')
    mkdir(reportFolder);
end

subjectDirs = dir(fullfile(rootFolderAllTrials,'Subj*'));
subjectDirs = subjectDirs([subjectDirs.isdir]);

subjectSummary = [];
trialSummary = [];

allTriggers = [];
allISI = [];
allTransitions = zeros(8,8);

rowSubj = 0;
rowTrial = 0;

for s = 1:numel(subjectDirs)

    subjName = subjectDirs(s).name;

    subjFolder = fullfile(rootFolderAllTrials,subjName);

    % ==========================================================
    % CONTINUOUS FILE
    % ==========================================================
    contFile = dir(fullfile(subjFolder,'*_trial.mat'));

    if ~isempty(contFile)

        tmp = load(fullfile(subjFolder,contFile(1).name));

        y = tmp.y;

        time = y(1,:);
        trigger = y(end,:);

        Fs = round(1/mean(diff(time)));

        durationMin = size(y,2)/Fs/60;

        eventOnsets = find(diff([0 trigger~=0])==1);

        eventCodes = trigger(eventOnsets);

        eventTimes = time(eventOnsets);

        ISI = diff(eventTimes);

        rowSubj = rowSubj + 1;

        subjectSummary.subjectID{rowSubj,1} = subjName;
        subjectSummary.durationMin(rowSubj,1) = durationMin;
        subjectSummary.nEvents(rowSubj,1) = numel(eventOnsets);
        subjectSummary.eventsPerMin(rowSubj,1) = ...
            numel(eventOnsets)/durationMin;

        subjectSummary.minISI(rowSubj,1) = min(ISI);
        subjectSummary.meanISI(rowSubj,1) = mean(ISI);
        subjectSummary.medianISI(rowSubj,1) = median(ISI);
        subjectSummary.maxISI(rowSubj,1) = max(ISI);

        allTriggers = [allTriggers ; eventCodes(:)];
        allISI = [allISI ; ISI(:)];

        for k = 1:numel(eventCodes)-1
            a = eventCodes(k);
            b = eventCodes(k+1);
            validTriggers = 1:8;

            if ~ismember(a,validTriggers) || ...
                    ~ismember(b,validTriggers)
                continue
            end
            allTransitions(a,b) = ...
                allTransitions(a,b) + 1;
        end

    end

    % ==========================================================
    % SINGLE TRIAL FILES
    % ==========================================================
    subjFolderTrial = fullfile(rootFoldersingleTrials,subjName);
    trialFiles = dir(fullfile(subjFolderTrial,'*_trial*.mat'));

    for t = 1:numel(trialFiles)

        if isempty(regexp( ...
                trialFiles(t).name,...
                'trial\d+\.mat$',...
                'once'))
            continue
        end

        tmp = load(fullfile(subjFolderTrial,...
            trialFiles(t).name));

        y = tmp.y;

        Fs = round(1/mean(diff(y(1,:))));

        durationMin = size(y,2)/Fs/60;

        trigger = y(end,:);

        nEvents = ...
            sum(diff([0 trigger~=0])==1);

        rowTrial = rowTrial + 1;

        trialSummary.subjectID{rowTrial,1} = subjName;
        trialSummary.fileName{rowTrial,1} = trialFiles(t).name;
        trialSummary.durationMin(rowTrial,1) = durationMin;
        trialSummary.nEvents(rowTrial,1) = nEvents;

    end

end

%% ==========================================================
% TABLE SUBJECTS
% ==========================================================

subjectSummaryTable = struct2table(subjectSummary);

writetable( ...
    subjectSummaryTable,...
    fullfile(reportFolder,...
    'SUBJECT_SUMMARY.csv'));

%% ==========================================================
% TABLE TRIALS
% ==========================================================

trialSummaryTable = struct2table(trialSummary);

writetable( ...
    trialSummaryTable,...
    fullfile(reportFolder,...
    'TRIAL_SUMMARY.csv'));

%% ==========================================================
% GLOBAL TRIGGER DISTRIBUTION
% ==========================================================

triggerCounts = zeros(8,1);

for k = 1:8
    triggerCounts(k) = sum(allTriggers==k);
end

triggerTable = table( ...
    (1:8)',...
    triggerCounts,...
    'VariableNames',...
    {'Trigger','Count'});

writetable( ...
    triggerTable,...
    fullfile(reportFolder,...
    'GLOBAL_TRIGGER_COUNTS.csv'));

%% ==========================================================
% GLOBAL ISI FIGURE
% ==========================================================

fig = figure('Color','w');

histogram(allISI,100)

xlabel('ISI (s)')
ylabel('Count')

title(sprintf( ...
    'Global ISI Distribution\nMin=%.3f  Mean=%.3f  Median=%.3f',...
    min(allISI),...
    mean(allISI),...
    median(allISI)));

saveas(fig,...
    fullfile(reportFolder,...
    'GLOBAL_ISI_DISTRIBUTION.png'));

close(fig)

%% ==========================================================
% GLOBAL TRIGGER DISTRIBUTION FIGURE
% ==========================================================

fig = figure('Color','w');

bar(1:8,triggerCounts)

xlabel('Trigger')
ylabel('Count')

title('Global Trigger Distribution')

saveas(fig,...
    fullfile(reportFolder,...
    'GLOBAL_TRIGGER_DISTRIBUTION.png'));

close(fig)

%% ==========================================================
% GLOBAL TRANSITION MATRIX
% ==========================================================

fig = figure('Color','w');

imagesc(allTransitions)

axis square
colorbar

xlabel('Next Trigger')
ylabel('Current Trigger')

title('Global Transition Matrix')

saveas(fig,...
    fullfile(reportFolder,...
    'GLOBAL_TRANSITION_MATRIX.png'));

close(fig)

%% ==========================================================
% SUBJECT DURATIONS
% ==========================================================

fig = figure('Color','w');

bar(subjectSummaryTable.durationMin)

xticks(1:height(subjectSummaryTable))
xticklabels(subjectSummaryTable.subjectID)

ylabel('Minutes')

title('Recording Duration')

saveas(fig,...
    fullfile(reportFolder,...
    'SUBJECT_DURATIONS.png'));

close(fig)

%% ==========================================================
% SAVE REPORT STRUCT
% ==========================================================

reportData.subjectSummary = subjectSummaryTable;
reportData.trialSummary = trialSummaryTable;
reportData.triggerTable = triggerTable;
reportData.allISI = allISI;
reportData.allTransitions = allTransitions;

save(fullfile(reportFolder,...
    'DATASET_REPORT.mat'),...
    'reportData');

fprintf('\nREPORT CREATED\n');
fprintf('%s\n',reportFolder);

fprintf('\n');
fprintf('====================================\n');
fprintf('DATASET SUMMARY\n');
fprintf('====================================\n');

fprintf('Subjects          : %d\n', ...
    height(subjectSummaryTable));

fprintf('Total events      : %d\n', ...
    sum(triggerCounts));

fprintf('Min ISI           : %.3f s\n', ...
    min(allISI));

fprintf('Mean ISI          : %.3f s\n', ...
    mean(allISI));

fprintf('Median ISI        : %.3f s\n', ...
    median(allISI));

fprintf('Suggested Window  : [-0.5 1.5] s\n');
fprintf('====================================\n');