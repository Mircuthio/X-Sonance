%% =========================================================================
% STEP10_BANDPOWER_TRIALWISE
% MAIN_BANDPOWER_TRIALWISE_STEP10
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

disable_eeglab();

%% ============================================================
% LOAD DATA
%% ============================================================
step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile( ...
    step2_indir,...
    'subj_list.mat'));

%% ============================================================
% OUTPUT
%% ============================================================
outdir = fullfile( ...
    step2_indir,...
    'STEP10_BANDPOWER_TRIALWISE');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CONFIGURATION
%% ============================================================
cfgBP = struct();

%% ------------------------------------------------------------
% RANDOM SEED
%% ------------------------------------------------------------
cfgBP.randomSeed = 10;

rng('default')
rng(cfgBP.randomSeed)

%% ------------------------------------------------------------
% CLASSES
%% ------------------------------------------------------------
cfgBP.class_labels = { ...
    'Consonant',...
    'Dissonant'};

cfgBP.class_codes = [7 8];

cfgBP.labelMap.Consonant = 1;
cfgBP.labelMap.Dissonant = 2;

%% ------------------------------------------------------------
% TIME WINDOW
%% ------------------------------------------------------------
cfgBP.analysis_window = ...
    [-0.5 1.0];

%% ------------------------------------------------------------
% POWER MODE
%% ------------------------------------------------------------
cfgBP.power_mode = ...
    'log';

%% ------------------------------------------------------------
% FREQUENCY BANDS
%% ------------------------------------------------------------
cfgBP.bands.Delta     = [1 4];
cfgBP.bands.Theta     = [4 8];
cfgBP.bands.Alpha     = [8 13];
cfgBP.bands.BetaLow   = [13 20];
cfgBP.bands.BetaHigh  = [20 30];
cfgBP.bands.GammaLow  = [30 40];
cfgBP.bands.GammaHigh = [40 90];

%% ------------------------------------------------------------
% ROI
%% ------------------------------------------------------------
MAIN_ROI

cfgBP.rois = ROI;

cfgBP.analysis_rois = { ...
    'ERAN',...
    'MMN',...
    'N5'};

%% ------------------------------------------------------------
% CLASSIFIERS
%% ------------------------------------------------------------
cfgBP.classifiers = { ...
    'QDA',...
    'SVC',...
    'KNN',...
    'NB'};

%% ------------------------------------------------------------
% DATASET FIELDS
%% ------------------------------------------------------------
cfgBP.eventField = ...
    'eventLabel';

cfgBP.subjectField = ...
    'subjectID';

%% ------------------------------------------------------------
% TRIALWISE PARAMETERS
%% ------------------------------------------------------------
cfgBP.trainRatio = 0.80;

cfgBP.testRatio = 0.20;

cfgBP.kfold = 4;

cfgBP.numIterations = 100;

%% ------------------------------------------------------------
% PERFORMANCE
%% ------------------------------------------------------------
cfgBP.primaryMetric = ...
    'BalancedAccuracy';

%% ============================================================
% BUILD DATASET
%% ============================================================
BandPower_Dataset = ...
    build_bandpower_dataset( ...
    subj_list,...
    cfgBP);

%% ============================================================
% TRIAL-WISE VALIDATION
%% ============================================================
Results_TrialWise = struct();

for iClf = 1:numel(cfgBP.classifiers)

    classifierName = ...
        cfgBP.classifiers{iClf};

    cfgBP.classifier = ...
        classifierName;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CLASSIFIER: %s\n', ...
        classifierName);
    fprintf('================================\n');

    for iIter = 1:cfgBP.numIterations

        fprintf('\n');
        fprintf('--------------------------------\n');
        fprintf( ...
            'ITERATION %d/%d\n',...
            iIter,...
            cfgBP.numIterations);

        %% ----------------------------------------------------
        % SPLIT
        %% ----------------------------------------------------
        [TrainTrials,...
         TestTrials] = ...
         split_trialwise_trials( ...
         BandPower_Dataset,...
         cfgBP);

        %% ----------------------------------------------------
        % BANDPOWER FEATURES
        %% ----------------------------------------------------
        Features = ...
            run_bandpower_features( ...
            TrainTrials,...
            TestTrials,...
            cfgBP);

        %% ----------------------------------------------------
        % CLASSIFIER
        %% ----------------------------------------------------
        parClassifier = struct();

        [TrainEEG,...
         TestEEG,...
         outClassifier,...
         PredField,...
         ProbField] = ...
         run_classifier_fold( ...
         Features.TrainEEG,...
         Features.TestEEG,...
         classifierName,...
         parClassifier);

        %% ----------------------------------------------------
        % PREDICTION
        %% ----------------------------------------------------
        parPredict = ...
            mdlPredictParams();

        parPredict.InField = ...
            Features.SignalField;

        parPredict.OutField = ...
            PredField;

        parPredict.ProbField = ...
            ProbField;

        parPredict.mdl = ...
            outClassifier.mdl;

        [TrainEEG,resTrain] = ...
            mdlPredict( ...
            TrainEEG,...
            parPredict);

        [TestEEG,resTest] = ...
            mdlPredict( ...
            TestEEG,...
            parPredict);

        %% ----------------------------------------------------
        % LABELS
        %% ----------------------------------------------------
        Ytrain_true = ...
            [TrainEEG.trialType]';

        Ytrain_pred = ...
            [TrainEEG.(PredField)]';

        Ytest_true = ...
            [TestEEG.trialType]';

        Ytest_pred = ...
            [TestEEG.(PredField)]';

        %% ----------------------------------------------------
        % METRICS
        %% ----------------------------------------------------
        TrainMetrics = ...
            compute_classification_metrics( ...
            Ytrain_true,...
            Ytrain_pred);

        TestMetrics = ...
            compute_classification_metrics( ...
            Ytest_true,...
            Ytest_pred);

        %% ----------------------------------------------------
        % STORE RESULTS
        %% ----------------------------------------------------
        IterResult = struct();

        IterResult.classifier = ...
            classifierName;

        IterResult.nTrainTrials = ...
            numel(TrainTrials);

        IterResult.nTestTrials = ...
            numel(TestTrials);

        IterResult.nFeatures = ...
            Features.nFeatures;

        IterResult.Model = ...
            outClassifier;

        IterResult.TrainMetrics = ...
            TrainMetrics;

        IterResult.TestMetrics = ...
            TestMetrics;

        IterResult.Ytrain_true = ...
            Ytrain_true;

        IterResult.Ytrain_pred = ...
            Ytrain_pred;

        IterResult.Ytest_true = ...
            Ytest_true;

        IterResult.Ytest_pred = ...
            Ytest_pred;

        IterResult.resTrain = ...
            resTrain;

        IterResult.resTest = ...
            resTest;

        Results_TrialWise.(classifierName).Iter(iIter) = ...
            IterResult;

    end

end

%% ============================================================
% SUMMARY
%% ============================================================
for iClf = 1:numel(cfgBP.classifiers)

    classifierName = ...
        cfgBP.classifiers{iClf};

    allACC = ...
        arrayfun( ...
        @(x) x.TestMetrics.ACC,...
        Results_TrialWise.(classifierName).Iter);

    allBA = ...
        arrayfun( ...
        @(x) x.TestMetrics.BA,...
        Results_TrialWise.(classifierName).Iter);

    allF1 = ...
        arrayfun( ...
        @(x) x.TestMetrics.F1,...
        Results_TrialWise.(classifierName).Iter);

    allMCC = ...
        arrayfun( ...
        @(x) x.TestMetrics.MCC,...
        Results_TrialWise.(classifierName).Iter);

    Results_TrialWise.(classifierName).MeanAccuracy = ...
        mean(allACC);

    Results_TrialWise.(classifierName).StdAccuracy = ...
        std(allACC);

    Results_TrialWise.(classifierName).MeanBalancedAccuracy = ...
        mean(allBA);

    Results_TrialWise.(classifierName).StdBalancedAccuracy = ...
        std(allBA);

    Results_TrialWise.(classifierName).MeanF1 = ...
        mean(allF1,'omitnan');

    Results_TrialWise.(classifierName).StdF1 = ...
        std(allF1,'omitnan');

    Results_TrialWise.(classifierName).MeanMCC = ...
        mean(allMCC,'omitnan');

    Results_TrialWise.(classifierName).StdMCC = ...
        std(allMCC,'omitnan');

    Results_TrialWise.(classifierName).cfg = ...
        cfgBP;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf('Mean Accuracy         : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).MeanAccuracy);

    fprintf('Std Accuracy          : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).StdAccuracy);

    fprintf('Mean BalancedAccuracy : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).MeanBalancedAccuracy);

    fprintf('Std BalancedAccuracy  : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).StdBalancedAccuracy);

    fprintf('Mean F1               : %.4f\n', ...
        Results_TrialWise.(classifierName).MeanF1);

    fprintf('Std F1                : %.4f\n', ...
        Results_TrialWise.(classifierName).StdF1);

    fprintf('Mean MCC              : %.4f\n', ...
        Results_TrialWise.(classifierName).MeanMCC);

    fprintf('Std MCC               : %.4f\n', ...
        Results_TrialWise.(classifierName).StdMCC);

end

%% ============================================================
% SAVE
%% ============================================================
save( ...
    fullfile( ...
    outdir,...
    'STEP10_BANDPOWER_TRIALWISE.mat'),...
    'Results_TrialWise',...
    'BandPower_Dataset',...
    'cfgBP',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP10 BANDPOWER TRIALWISE COMPLETED\n');
fprintf('================================\n');