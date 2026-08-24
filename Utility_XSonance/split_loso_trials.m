function [TrainTrials,TestTrials] = ...
    split_loso_trials( ...
    FBCSP_Dataset,...
    testSubject)

%% ============================================================
% INITIALIZATION
%% ============================================================

allTrials = ...
    FBCSP_Dataset.trials;

isTest = false(length(allTrials),1);

%% ============================================================
% FIND TEST SUBJECT
%% ============================================================

for iTr = 1:length(allTrials)

    isTest(iTr) = ...
        strcmp( ...
        allTrials(iTr).subjectID,...
        testSubject);

end

%% ============================================================
% SPLIT
%% ============================================================

TestTrials = ...
    allTrials(isTest);

TrainTrials = ...
    allTrials(~isTest);

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');

fprintf('Test Subject : %s\n', ...
    testSubject);

fprintf('Train Trials : %d\n', ...
    length(TrainTrials));

fprintf('Test Trials  : %d\n', ...
    length(TestTrials));

fprintf('Class1 Train : %d\n', ...
    sum([TrainTrials.label] == 1));

fprintf('Class2 Train : %d\n', ...
    sum([TrainTrials.label] == 2));

fprintf('Class1 Test  : %d\n', ...
    sum([TestTrials.label] == 1));

fprintf('Class2 Test  : %d\n', ...
    sum([TestTrials.label] == 2));

end