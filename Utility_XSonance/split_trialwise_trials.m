function [TrainTrials,TestTrials] = ...
    split_trialwise_trials( ...
    FBCSP_Dataset,...
    cfgFBCSP)

%% ============================================================
% LABELS
%% ============================================================

allTrials = ...
    FBCSP_Dataset.trials;

labels = ...
    [allTrials.label]';

%% ============================================================
% STRATIFIED HOLDOUT
%% ============================================================

cvp = cvpartition( ...
    labels,...
    'HoldOut',...
    cfgFBCSP.testRatio);

%% ============================================================
% SPLIT
%% ============================================================

idxTrain = ...
    training(cvp);

idxTest = ...
    test(cvp);

TrainTrials = ...
    allTrials(idxTrain);

TestTrials = ...
    allTrials(idxTest);

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');

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