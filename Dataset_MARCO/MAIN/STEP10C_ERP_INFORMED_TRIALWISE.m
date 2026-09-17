%% =========================================================================
% STEP10C_ERP_INFORMED_TRIALWISE
%% =========================================================================
%
% ERP-INFORMED CLASSIFICATION
%
% Selected features:
%
%   ERPIndex
%   ERAN_B
%   BetaLow
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
% ROOT DIR
%% ============================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

%% ============================================================
% OUTPUT
%% ============================================================

Cases = ...
    build_erp_informed_cases();

iCase = 1;

CaseCfg = Cases(iCase);

outdir = ...
    fullfile( ...
    step2_indir,...
    'STEP10C_ERP_INFORMED_TRIALWISE',...
    CaseCfg.group,...
    CaseCfg.name);

if ~exist(outdir,'dir')
    mkdir(outdir);
end
%% ============================================================
% BUILD DATASET
%% ============================================================

load( ...
    fullfile( ...
    step2_indir,...
    'STEP10BA_ERPINF_DATASET',...
    'ERPINF_Dataset_CACHED.mat'));
assert( ...
    isfield(ERPINF_Dataset.trials,'ERPINF'), ...
    'ERPINF field missing');

assert( ...
    isfield(ERPINF_Dataset.trials,'timeERPINF'), ...
    'timeERPINF field missing');

fprintf('ERPINF Features : %d\n', ...
    ERPINF_Dataset.nFeatures);

disp(ERPINF_Dataset.FeatureNames(:))
%% ============================================================
% CONFIGURATION
%% ============================================================

cfgINF = struct();

cfgINF.randomSeed = 10;

rng('default')
rng(cfgINF.randomSeed)

%% ------------------------------------------------------------
% CLASSES
%% ------------------------------------------------------------

cfgINF.class_labels = ...
    CaseCfg.class_labels;

cfgINF.class_codes = ...
    CaseCfg.class_codes;

%% ------------------------------------------------------------
% FEATURE SET
%% ------------------------------------------------------------

cfgINF.feature_set = { ...
    'ERPIndex',...
    'ERAN_B',...
    'BetaLow'};

cfgINF.useERPIndex = true;
cfgINF.useERANB    = true;
cfgINF.useBetaLow  = true;

%% ------------------------------------------------------------
% DATASET WINDOW
%% ------------------------------------------------------------

cfgINF.analysis_window = ...
    CaseCfg.analysis_window;

%% ------------------------------------------------------------
% ROI
%% ------------------------------------------------------------

MAIN_ROI

cfgINF.rois = ROI;

%% ------------------------------------------------------------
% CLASSIFIERS
%% ------------------------------------------------------------

cfgINF.classifiers = { ...
    'QDA'};

%% ------------------------------------------------------------
% TRIALWISE PARAMETERS
%% ------------------------------------------------------------

cfgINF.trainRatio = 0.80;
cfgINF.testRatio  = 0.20;

cfgINF.kfold = 4;

cfgINF.numIterations = 100;

fprintf('\n');
fprintf('================================\n');
fprintf('DATASET SUMMARY\n');
fprintf('================================\n');

fprintf('Trials   : %d\n', ...
    ERPINF_Dataset.nTrials);

fprintf('Subjects : %d\n', ...
    ERPINF_Dataset.nSubjects);

%% ============================================================
% TRIALWISE
%% ============================================================

Results_TrialWise = struct();

for iClf = 1:numel(cfgINF.classifiers)

    classifierName = ...
        cfgINF.classifiers{iClf};

    cfgINF.classifier = ...
        classifierName;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CLASSIFIER: %s\n', ...
        classifierName);
    fprintf('================================\n');

    for iIter = 1:cfgINF.numIterations

        fprintf('\n');
        fprintf('--------------------------------\n');

        fprintf( ...
            'ITERATION %d/%d\n',...
            iIter,...
            cfgINF.numIterations);

        %% =====================================================
        % SPLIT
        %% =====================================================

        [TrainTrials,...
         TestTrials] = ...
            split_trialwise_trials( ...
            ERPINF_Dataset,...
            cfgINF);

        %% =====================================================
        % ERP-INFORMED FEATURES
        %% =====================================================

        Features = struct();

        Features.TrainEEG = ...
            TrainTrials;

        Features.TestEEG = ...
            TestTrials;

        Features.SignalField = ...
            'ERPINF';

        Features.FeatureNames = ...
            ERPINF_Dataset.FeatureNames;

        Features.nFeatures = ...
            numel(TrainTrials(1).ERPINF);
        %% =====================================================
        % CLASSIFIER
        %% =====================================================

        parClassifier = struct();

        parClassifier.InField = ...
            Features.SignalField;

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

        IterResult = struct();

        IterResult.classifier = ...
            classifierName;

        IterResult.nTrainTrials = ...
            numel(TrainTrials);

        IterResult.nTestTrials = ...
            numel(TestTrials);

        IterResult.nFeatures = ...
            Features.nFeatures;

        IterResult.FeatureNames = ...
            Features.FeatureNames;

        IterResult.SelectedFeatures = ...
            cfgINF.feature_set;

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

for iClf = 1:numel(cfgINF.classifiers)

    classifierName = ...
        cfgINF.classifiers{iClf};

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
        cfgINF;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf('Mean ACC : %.2f %%\n', ...
        100 * ...
        Results_TrialWise.(classifierName).MeanAccuracy);

    fprintf('Mean BA  : %.2f %%\n', ...
        100 * ...
        Results_TrialWise.(classifierName).MeanBalancedAccuracy);

    fprintf('Mean F1  : %.4f\n', ...
        Results_TrialWise.(classifierName).MeanF1);

    fprintf('Mean MCC : %.4f\n', ...
        Results_TrialWise.(classifierName).MeanMCC);

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'STEP10C_ERP_INFORMED_TRIALWISE.mat'),...
    'Results_TrialWise',...
    'cfgINF',...
    'CaseCfg',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP10C ERP INFORMED TRIALWISE COMPLETED\n');
fprintf('================================\n');