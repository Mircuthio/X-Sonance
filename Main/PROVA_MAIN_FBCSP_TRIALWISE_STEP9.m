%% =========================================================================
% PROVA_MAIN_FBCSP_TRIALWISE_STEP9
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
% CLASSIFIER
%% ------------------------------------------------------------

cfgFBCSP.classifier = 'QDA';

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

cfgFBCSP.numIterations = 1;

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
% TRIAL-WISE
%% ============================================================

Results_TrialWise = struct();

for iIter = 1:1

    fprintf('\n');
    fprintf('--------------------------------\n');
    fprintf('ITERATION %d/%d\n', ...
        iIter,...
        cfgFBCSP.numIterations);

    %% ---------------------------------------------
    % TRAIN / TEST SPLIT
    %% ---------------------------------------------

    [TrainTrials,...
        TestTrials] = ...
        split_trialwise_trials( ...
        FBCSP_Dataset,...
        cfgFBCSP);

    fprintf('\n');
    fprintf('Train Trials: %d\n',length(TrainTrials));
    fprintf('Test Trials : %d\n',length(TestTrials));

    fprintf('Train Class1: %d\n', ...
        sum([TrainTrials.label]==1));

    fprintf('Train Class2: %d\n', ...
        sum([TrainTrials.label]==2));

    fprintf('Test Class1 : %d\n', ...
        sum([TestTrials.label]==1));

    fprintf('Test Class2 : %d\n', ...
        sum([TestTrials.label]==2));

    %% ---------------------------------------------
    % RUN COMPLETE FBCSP PIPELINE
    %% ---------------------------------------------

    Results_TrialWise.Iter(iIter) = ...
        run_fbcsp_loso_fold( ...
        TrainTrials,...
        TestTrials,...
        cfgFBCSP);

end
Results_TrialWise.Iter(1).ACCtest

Results_TrialWise.Iter(1).BATest

Results_TrialWise.Iter(1).CMtest
%% ============================================================
% SUMMARY
%% ============================================================

allBA = ...
    [Results_TrialWise.Iter.BATest];

allACC = ...
    [Results_TrialWise.Iter.ACCtest];

Results_TrialWise.MeanAccuracy = ...
    mean(allACC);

Results_TrialWise.StdAccuracy = ...
    std(allACC);

Results_TrialWise.MeanBalancedAccuracy = ...
    mean(allBA);

Results_TrialWise.StdBalancedAccuracy = ...
    std(allBA);

fprintf('\n');
fprintf('================================\n');
fprintf('TRIALWISE SUMMARY\n');
fprintf('================================\n');

fprintf('Mean Accuracy          : %.2f %%\n', ...
    100*Results_TrialWise.MeanAccuracy);

fprintf('Std Accuracy           : %.2f %%\n', ...
    100*Results_TrialWise.StdAccuracy);

fprintf('Mean BalancedAccuracy  : %.2f %%\n', ...
    100*Results_TrialWise.MeanBalancedAccuracy);

fprintf('Std BalancedAccuracy   : %.2f %%\n', ...
    100*Results_TrialWise.StdBalancedAccuracy);
