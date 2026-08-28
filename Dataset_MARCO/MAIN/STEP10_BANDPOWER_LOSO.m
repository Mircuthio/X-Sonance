%% =========================================================================
% STEP10_BANDPOWER_LOSO
% MAIN_BANDPOWER_LOSO_STEP10
%% =========================================================================
%
% PIPELINE
%
% subj_list
%       ↓
% build_bandpower_dataset
%
%       ↓
% LOSO Split
%
%       ↓
% BandPower Features
%
%           ROI × Band
%
%       ↓
% Classifier Model (TRAIN ONLY)
%
%           QDA
%           KNN
%           NB
%           SVC
%
%       ↓
% Prediction (TRAIN / TEST)
%
%       ↓
% Metrics
%
%           ACC
%           BA
%           F1
%           MCC
%
%% =========================================================================

clear
close all
clc

origState = ...
    get(0,'DefaultFigureVisible');

set(0,'DefaultFigureVisible','off');

disable_eeglab();

%% ============================================================
% LOAD DATA
%% ============================================================
step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load( ...
    fullfile( ...
    step2_indir,...
    'subj_list.mat'));

%% ============================================================
% OUTPUT
%% ============================================================
outdir = ...
    fullfile( ...
    step2_indir,...
    'STEP10_BANDPOWER_LOSO');

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
% CLASSIFIER PARAMETERS
%% ------------------------------------------------------------
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
% SUBJECTS
%% ============================================================
subjectIDs = unique( ...
    {BandPower_Dataset.trials.subjectID});

nSubjects = ...
    numel(subjectIDs);

fprintf('\n');

fprintf('================================\n');
fprintf('LOSO SETUP\n');
fprintf('================================\n');

fprintf( ...
    'Subjects: %d\n',...
    nSubjects);

%% ============================================================
% LOSO
%% ============================================================
Results_LOSO = struct();

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

    for iSub = 1:nSubjects

        testSubject = ...
            subjectIDs{iSub};

        fprintf('\n');

        fprintf('--------------------------------\n');
        fprintf( ...
            'LOSO FOLD %d/%d\n',...
            iSub,nSubjects);
        fprintf( ...
            'Test Subject: %s\n',...
            testSubject);

        %% =====================================================
        % LOSO SPLIT
        %% =====================================================
        [TrainTrials,...
         TestTrials] = ...
            split_loso_trials( ...
            BandPower_Dataset,...
            testSubject);

        %% =====================================================
        % BANDPOWER FEATURES
        %% =====================================================
        Features = ...
            run_bandpower_features( ...
            TrainTrials,...
            TestTrials,...
            cfgBP);

        %% =====================================================
        % CLASSIFIER
        %% =====================================================
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

        %% =====================================================
        % PREDICTION
        %% =====================================================
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

        %% =====================================================
        % LABELS
        %% =====================================================
        Ytrain_true = ...
            [TrainEEG.trialType]';

        Ytrain_pred = ...
            [TrainEEG.(PredField)]';

        Ytest_true = ...
            [TestEEG.trialType]';

        Ytest_pred = ...
            [TestEEG.(PredField)]';

        %% =====================================================
        % METRICS
        %% =====================================================
        TrainMetrics = ...
            compute_classification_metrics( ...
            Ytrain_true,...
            Ytrain_pred);

        TestMetrics = ...
            compute_classification_metrics( ...
            Ytest_true,...
            Ytest_pred);

        %% =====================================================
        % STORE RESULTS
        %% =====================================================
        FoldResult = struct();

        FoldResult.classifier = ...
            classifierName;

        FoldResult.testSubject = ...
            testSubject;

        FoldResult.nTrainTrials = ...
            numel(TrainTrials);

        FoldResult.nTestTrials = ...
            numel(TestTrials);

        FoldResult.nFeatures = ...
            Features.nFeatures;

        FoldResult.Model = ...
            outClassifier;

        FoldResult.TrainMetrics = ...
            TrainMetrics;

        FoldResult.TestMetrics = ...
            TestMetrics;

        FoldResult.Ytrain_true = ...
            Ytrain_true;

        FoldResult.Ytrain_pred = ...
            Ytrain_pred;

        FoldResult.Ytest_true = ...
            Ytest_true;

        FoldResult.Ytest_pred = ...
            Ytest_pred;

        FoldResult.resTrain = ...
            resTrain;

        FoldResult.resTest = ...
            resTest;

        Results_LOSO.(classifierName).Fold(iSub) = ...
            FoldResult;

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
        Results_LOSO.(classifierName).Fold);

    allBA = ...
        arrayfun( ...
        @(x) x.TestMetrics.BA,...
        Results_LOSO.(classifierName).Fold);

    allF1 = ...
        arrayfun( ...
        @(x) x.TestMetrics.F1,...
        Results_LOSO.(classifierName).Fold);

    allMCC = ...
        arrayfun( ...
        @(x) x.TestMetrics.MCC,...
        Results_LOSO.(classifierName).Fold);

    Results_LOSO.(classifierName).MeanAccuracy = ...
        mean(allACC);

    Results_LOSO.(classifierName).StdAccuracy = ...
        std(allACC);

    Results_LOSO.(classifierName).MeanBalancedAccuracy = ...
        mean(allBA);

    Results_LOSO.(classifierName).StdBalancedAccuracy = ...
        std(allBA);

    Results_LOSO.(classifierName).MeanF1 = ...
        mean(allF1,'omitnan');

    Results_LOSO.(classifierName).StdF1 = ...
        std(allF1,'omitnan');

    Results_LOSO.(classifierName).MeanMCC = ...
        mean(allMCC,'omitnan');

    Results_LOSO.(classifierName).StdMCC = ...
        std(allMCC,'omitnan');

    Results_LOSO.(classifierName).cfg = ...
        cfgBP;

    fprintf('\n');

    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf( ...
        'Mean Accuracy          : %.2f %%\n',...
        100 * ...
        Results_LOSO.(classifierName).MeanAccuracy);

    fprintf( ...
        'Std Accuracy           : %.2f %%\n',...
        100 * ...
        Results_LOSO.(classifierName).StdAccuracy);

    fprintf( ...
        'Mean BalancedAccuracy  : %.2f %%\n',...
        100 * ...
        Results_LOSO.(classifierName).MeanBalancedAccuracy);

    fprintf( ...
        'Std BalancedAccuracy   : %.2f %%\n',...
        100 * ...
        Results_LOSO.(classifierName).StdBalancedAccuracy);

    fprintf( ...
        'Mean F1                : %.4f\n',...
        Results_LOSO.(classifierName).MeanF1);

    fprintf( ...
        'Std F1                 : %.4f\n',...
        Results_LOSO.(classifierName).StdF1);

    fprintf( ...
        'Mean MCC               : %.4f\n',...
        Results_LOSO.(classifierName).MeanMCC);

    fprintf( ...
        'Std MCC                : %.4f\n',...
        Results_LOSO.(classifierName).StdMCC);

end

%% ============================================================
% SAVE
%% ============================================================
save( ...
    fullfile( ...
    outdir,...
    'STEP10_BANDPOWER_LOSO.mat'),...
    'Results_LOSO',...
    'BandPower_Dataset',...
    'cfgBP',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP10 BANDPOWER LOSO COMPLETED\n');
fprintf('================================\n');