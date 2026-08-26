%% =========================================================================
% MAIN_FBCSP_LOSO_STEP9
%
% PIPELINE
%
% subj_list
%     ↓
% build_fbcsp_dataset
%     ↓
% LOSO Split
%
% Test Subject = Subject i
%
% Train Subjects = All Remaining Subjects
%
%     ↓
% FilterBankCompute (TRAIN / TEST)
%
%     ↓
% CSP Model (TRAIN ONLY)
%
%     ↓
% CSP Encode (TRAIN / TEST)
%
%     ↓
% MI Model (TRAIN ONLY)
%
%     ↓
% MI Encode (TRAIN / TEST)
%
%     ↓
% QDA Model (TRAIN ONLY)
%
%     ↓
% Prediction (TRAIN / TEST)
%
%     ↓
% Accuracy
% Balanced Accuracy
% Confusion Matrix
%
% NOTE:
% CSP and MI are estimated ONLY on the training subjects.
% No information from the test subject contributes to the model.
%
%% =========================================================================
clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

disable_eeglab();
PATH_XSONANCE_FBCSP
%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'STEP9_FBCSP_LOSO');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgFBCSP = struct();

%% ------------------------------------------------------------
% RANDOM SEED
%% ------------------------------------------------------------

cfgFBCSP.randomSeed = 10;

rng('default')
rng(cfgFBCSP.randomSeed)

%% ------------------------------------------------------------
% CLASSES
%% ------------------------------------------------------------

cfgFBCSP.class_labels = { ...
    'Consonant',...
    'Dissonant'};

cfgFBCSP.class_codes = [7 8];

cfgFBCSP.labelMap.Consonant = 1;
cfgFBCSP.labelMap.Dissonant = 2;

%% ------------------------------------------------------------
% TIME WINDOW
%% ------------------------------------------------------------

cfgFBCSP.time_window = [-0.5 1.0];

%% ------------------------------------------------------------
% FILTER BANK
%% ------------------------------------------------------------

cfgFBCSP.useFilterBank = true;
cfgFBCSP.filterBankName = 'EEGbands';

%% ------------------------------------------------------------
% CSP
%% ------------------------------------------------------------

cfgFBCSP.csp_components = 4;

%% ------------------------------------------------------------
% MUTUAL INFORMATION
%% ------------------------------------------------------------

cfgFBCSP.useMI = true;
cfgFBCSP.mi_k = 5;

%% ------------------------------------------------------------
% CLASSIFIERS
%% ------------------------------------------------------------

cfgFBCSP.classifiers = { ...
    'QDA',...
    'SVC',...
    'KNN',...
    'NB'};

%% ------------------------------------------------------------
% DATASET FIELDS
%% ------------------------------------------------------------

cfgFBCSP.eventField = 'eventLabel';
cfgFBCSP.subjectField = 'subj_id';

%% ------------------------------------------------------------
% PERFORMANCE
%% ------------------------------------------------------------

cfgFBCSP.primaryMetric = ...
    'BalancedAccuracy';

%% ============================================================
% BUILD DATASET
%% ============================================================

FBCSP_Dataset = build_fbcsp_dataset( ...
    subj_list,...
    cfgFBCSP);

%% ============================================================
% SUBJECTS
%% ============================================================

subjectIDs = unique( ...
    {FBCSP_Dataset.trials.subjectID});

nSubjects = numel(subjectIDs);

fprintf('\n');
fprintf('================================\n');
fprintf('LOSO SETUP\n');
fprintf('================================\n');

fprintf('Subjects: %d\n',nSubjects);

%% ============================================================
% VALIDATION STRATEGY
%% ============================================================
%
% LOSO:
%  Subject 1 → Test
%  Subjects 2..N → Train
%
%  Subject 2 → Test
%  Remaining Subjects → Train
%

%% ============================================================
% LOSO
%% ============================================================

Results_LOSO = struct();

for iClf = 1:numel(cfgFBCSP.classifiers)

    classifierName = ...
        cfgFBCSP.classifiers{iClf};

    cfgFBCSP.classifier = ...
        classifierName;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CLASSIFIER: %s\n', ...
        classifierName);
    fprintf('================================\n');

    for iSub = 1:nSubjects

        testSubject = ...
            subjectIDs{iSub};

        fprintf('\n');
        fprintf('--------------------------------\n');
        fprintf('LOSO FOLD %d/%d\n', ...
            iSub,nSubjects);

        fprintf('Test Subject: %s\n', ...
            testSubject);

        [TrainTrials,...
         TestTrials] = ...
         split_loso_trials( ...
         FBCSP_Dataset,...
         testSubject);

        Results_LOSO.(classifierName).Fold(iSub) = ...
            run_fbcsp_fold( ...
            TrainTrials,...
            TestTrials,...
            cfgFBCSP);

    end

end
%% ============================================================
% SUMMARY
%% ============================================================

for iClf = 1:numel(cfgFBCSP.classifiers)

    classifierName = ...
        cfgFBCSP.classifiers{iClf};

    allBA = ...
        [Results_LOSO.(classifierName).Fold.BATest];

    allACC = ...
        [Results_LOSO.(classifierName).Fold.ACCtest];

    Results_LOSO.(classifierName).MeanAccuracy = ...
        mean(allACC);

    Results_LOSO.(classifierName).StdAccuracy = ...
        std(allACC);

    Results_LOSO.(classifierName).MeanBalancedAccuracy = ...
        mean(allBA);

    Results_LOSO.(classifierName).StdBalancedAccuracy = ...
        std(allBA);

    Results_LOSO.(classifierName).cfg = cfgFBCSP;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf('Mean Accuracy          : %.2f %%\n', ...
        100 * Results_LOSO.(classifierName).MeanAccuracy);

    fprintf('Std Accuracy           : %.2f %%\n', ...
        100 * Results_LOSO.(classifierName).StdAccuracy);

    fprintf('Mean BalancedAccuracy  : %.2f %%\n', ...
        100 * Results_LOSO.(classifierName).MeanBalancedAccuracy);

    fprintf('Std BalancedAccuracy   : %.2f %%\n', ...
        100 * Results_LOSO.(classifierName).StdBalancedAccuracy);

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'STEP9_FBCSP_LOSO.mat'),...
    'Results_LOSO',...
    'FBCSP_Dataset',...
    'cfgFBCSP',...
    '-v7.3');