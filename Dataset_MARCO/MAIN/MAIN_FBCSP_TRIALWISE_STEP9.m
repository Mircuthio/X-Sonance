%% =========================================================================
% MAIN_FBCSP_TRIALWISE_STEP9
%
% PIPELINE
%
% subj_list
%     ↓
% build_fbcsp_dataset
%     ↓
% Stratified Hold-Out Split
%
% Train Trials = 80%
% Test Trials  = 20%
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
% Repeated N times using different random train/test splits.
%
% NOTE:
% CSP and MI are estimated ONLY on training trials.
% No information from the test trials contributes to the model.
%
%% =========================================================================


clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

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
    'STEP9_FBCSP_TRIALWISE');

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

cfgFBCSP.classifiers = { ...
    'QDA',...
    'KNN'};


%% ------------------------------------------------------------
% DATASET FIELDS
%% ------------------------------------------------------------

cfgFBCSP.eventField = 'eventLabel';
cfgFBCSP.subjectField = 'subj_id';

%% ------------------------------------------------------------
% TRIALWISE PARAMETERS
%% ------------------------------------------------------------

cfgFBCSP.trainRatio = 0.80;
cfgFBCSP.testRatio  = 0.20;

cfgFBCSP.numIterations = 100;

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
% VALIDATION STRATEGY
%% ============================================================
%
% Iteration 1:
%   Random 80/20 split
%
% Iteration 2:
%   New random 80/20 split
%
% ...
%
% Iteration N:
%   New random 80/20 split
%
%% ============================================================
% TRIAL-WISE
%% ============================================================

Results_TrialWise = struct();

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

    for iIter = 1:cfgFBCSP.numIterations

        fprintf('\n');
        fprintf('--------------------------------\n');
        fprintf('ITERATION %d/%d\n', ...
            iIter,...
            cfgFBCSP.numIterations);

        [TrainTrials,...
         TestTrials] = ...
         split_trialwise_trials( ...
         FBCSP_Dataset,...
         cfgFBCSP);

        Results_TrialWise.(classifierName).Iter(iIter) = ...
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
        [Results_TrialWise.(classifierName).Iter.BATest];

    allACC = ...
        [Results_TrialWise.(classifierName).Iter.ACCtest];

    Results_TrialWise.(classifierName).MeanAccuracy = ...
        mean(allACC);

    Results_TrialWise.(classifierName).StdAccuracy = ...
        std(allACC);

    Results_TrialWise.(classifierName).MeanBalancedAccuracy = ...
        mean(allBA);

    Results_TrialWise.(classifierName).StdBalancedAccuracy = ...
        std(allBA);

    Results_TrialWise.(classifierName).cfg = cfgFBCSP;
    
    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf('Mean Accuracy          : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).MeanAccuracy);

    fprintf('Std Accuracy           : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).StdAccuracy);

    fprintf('Mean BalancedAccuracy  : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).MeanBalancedAccuracy);

    fprintf('Std BalancedAccuracy   : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).StdBalancedAccuracy);

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'STEP9_FBCSP_TRIALWISE.mat'),...
    'Results_TrialWise',...
    'FBCSP_Dataset',...
    'cfgFBCSP',...
    '-v7.3');