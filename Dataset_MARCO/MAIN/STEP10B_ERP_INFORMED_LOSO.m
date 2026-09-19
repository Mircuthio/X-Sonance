%% =========================================================================
% STEP10B_ERP_INFORMED_LOSO
%% =========================================================================
%
% ERP-INFORMED CLASSIFICATION
%
% Feature discovery completed in STEP10A.
%
% Selected features:
%
%   ERPIndex
%   ERAN_B
%   BetaLow
%
%
% PIPELINE
%
% subj_list
%       ↓
%
% load dataset
%
%       ↓
%
% LOSO Split
%
%       ↓
%
% ERP-Informed Features
%
%       ↓
%
% Classifier
%
%       QDA
%       SVC
%       KNN
%       NB
%
%       ↓
%
% Prediction
%
%       ↓
%
% Metrics
%
%       ACC
%       BA
%       F1
%       MCC
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
    'STEP10B_ERP_INFORMED_LOSO',...
    CaseCfg.group,...
    CaseCfg.name);

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% LOAD DATASET
%% ============================================================
load( ...
    fullfile( ...
    step2_indir,...
    'STEP10BA_ERPINF_DATASET',...
    'ERPINF_Dataset_ERPINDEX_ERANB.mat'));

ERPINF_Dataset = DatasetOut;
outdir = ...
    fullfile(outdir,'ERPINDEX_ERANB');

if ~exist(outdir,'dir')
    mkdir(outdir);
end
% load( ...
%     fullfile( ...
%     step2_indir,...
%     'STEP10BA_ERPINF_DATASET',...
%     'ERPINF_Dataset_ERPINDEX.mat'));
% 
% ERPINF_Dataset = DatasetOut;
% outdir = ...
%     fullfile(outdir,'ERPINDEX');
% 
% if ~exist(outdir,'dir')
%     mkdir(outdir);
% end

% load( ...
%     fullfile( ...
%     step2_indir,...
%     'STEP10BA_ERPINF_DATASET',...
%     'ERPINF_Dataset_CACHED.mat'));

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
    'ERPIndex', ...
    'ERAN_B', ...
    'BetaLow'};
%% ------------------------------------------------------------
% FEATURE FAMILIES
%% ------------------------------------------------------------

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
    'KNN',...
    'NB',...
    'SVC'};

%% ------------------------------------------------------------
% LOSO PARAMETERS
%% ------------------------------------------------------------

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
% SUBJECTS
%% ============================================================

subjectIDs = unique( ...
    {ERPINF_Dataset.trials.subjectID});

nSubjects = ...
    numel(subjectIDs);

fprintf('\n');
fprintf('================================\n');
fprintf('LOSO SETUP\n');
fprintf('================================\n');

fprintf('Subjects: %d\n', ...
    nSubjects);

%% ============================================================
% LOSO
%% ============================================================

Results_LOSO = struct();

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

    for iSub = 1:nSubjects

        testSubject = ...
            subjectIDs{iSub};

        fprintf('\n');
        fprintf('--------------------------------\n');

        fprintf( ...
            'LOSO FOLD %d/%d\n',...
            iSub,...
            nSubjects);

        fprintf( ...
            'Test Subject: %s\n',...
            testSubject);

        %% =====================================================
        % LOSO SPLIT
        %% =====================================================

        [TrainTrials,...
            TestTrials] = ...
            split_loso_trials( ...
            ERPINF_Dataset,...
            testSubject);

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
            numel( ...
            TrainTrials(1).ERPINF);

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

        FoldResult.FeatureNames = ...
            Features.FeatureNames;

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

        FoldResult.SelectedFeatures = ...
            cfgINF.feature_set;

        Results_LOSO.(classifierName).Fold(iSub) = ...
            FoldResult;
    end
end
%% ============================================================
% SUBJECT TABLE
%% ============================================================

for iClf = 1:numel(cfgINF.classifiers)

    classifierName = ...
        cfgINF.classifiers{iClf};

    T = table();

    for iSub = 1:numel(subjectIDs)

        T.Subject{iSub,1} = ...
            Results_LOSO.(classifierName).Fold(iSub).testSubject;

        T.ACC(iSub,1) = ...
            Results_LOSO.(classifierName).Fold(iSub).TestMetrics.ACC;

        T.BA(iSub,1) = ...
            Results_LOSO.(classifierName).Fold(iSub).TestMetrics.BA;

        T.F1(iSub,1) = ...
            Results_LOSO.(classifierName).Fold(iSub).TestMetrics.F1;

        T.MCC(iSub,1) = ...
            Results_LOSO.(classifierName).Fold(iSub).TestMetrics.MCC;

    end

    writetable( ...
        T,...
        fullfile( ...
        outdir,...
        sprintf( ...
        '%s_SubjectMetrics.csv',...
        classifierName)));

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
    cfgINF;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf( ...
        'Mean ACC : %.2f %%\n',...
        100 * ...
        Results_LOSO.(classifierName).MeanAccuracy);

    fprintf( ...
        'Mean BA  : %.2f %%\n',...
        100 * ...
        Results_LOSO.(classifierName).MeanBalancedAccuracy);

    fprintf( ...
        'Mean F1  : %.4f\n',...
        Results_LOSO.(classifierName).MeanF1);

    fprintf( ...
        'Mean MCC : %.4f\n',...
        Results_LOSO.(classifierName).MeanMCC);

end
SummaryTable = table();

for iClf = 1:numel(cfgINF.classifiers)

    classifierName = ...
        cfgINF.classifiers{iClf};

    SummaryTable.Classifier{iClf,1} = ...
        classifierName;

    SummaryTable.ACC(iClf,1) = ...
        Results_LOSO.(classifierName).MeanAccuracy;

    SummaryTable.BA(iClf,1) = ...
        Results_LOSO.(classifierName).MeanBalancedAccuracy;

    SummaryTable.F1(iClf,1) = ...
        Results_LOSO.(classifierName).MeanF1;

    SummaryTable.MCC(iClf,1) = ...
        Results_LOSO.(classifierName).MeanMCC;

    SummaryTable.nFeatures(iClf,1) = ...
    Results_LOSO.(classifierName).Fold(1).nFeatures;

end

writetable( ...
    SummaryTable,...
    fullfile( ...
    outdir,...
    'ClassifierSummary.csv'));
%% ============================================================
% SAVE
%% ============================================================

if numel(cfgINF.classifiers) == 1

    saveName = sprintf( ...
        'STEP10B_ERP_INFORMED_LOSO_%s.mat', ...
        cfgINF.classifiers{1});

else

    allClf = strjoin( ...
        cfgINF.classifiers,...
        '_');

    saveName = sprintf( ...
        'STEP10B_ERP_INFORMED_LOSO_%s.mat',...
        allClf);

end

save( ...
    fullfile(outdir,saveName),...
    'Results_LOSO',...
    'cfgINF',...
    'CaseCfg',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP10B ERP INFORMED COMPLETED\n');
fprintf('================================\n');