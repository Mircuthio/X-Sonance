%% =========================================================================
% STEP12B_v4A_TFRINF_GRID_LOSO
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
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

%% ============================================================
% OUTPUT
%% ============================================================

outdir = ...
    fullfile( ...
    step2_indir,...
    'STEP12B_v4A_TFRINF_GRID_LOSO');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% LOAD DATASET
%% ============================================================

load( ...
    fullfile( ...
    step2_indir,...
    'STEP12A_v4A_TFRINF_GRID',...
    'TFRINF_GRID_CD.mat'));

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgTFRINF = struct();

cfgTFRINF.randomSeed = 10;

rng('default')
rng(cfgTFRINF.randomSeed)

%% ------------------------------------------------------------
% FEATURE PREPROCESSING
%% ------------------------------------------------------------

cfgTFRINF.useZScore = true;

cfgTFRINF.usePCA = true;

cfgTFRINF.nPCs = 20;

%% ------------------------------------------------------------
% CLASSIFIERS
%% ------------------------------------------------------------

cfgTFRINF.classifiers = { ...
    'QDA'};

%% ------------------------------------------------------------
% FEATURE SET
%% ------------------------------------------------------------

cfgTFRINF.feature_set = ...
    TFRINF_Dataset.FeatureNames;

%% ------------------------------------------------------------
% LOSO
%% ------------------------------------------------------------

cfgTFRINF.kfold = 4;

cfgTFRINF.numIterations = 100;

%% ============================================================
% DATASET SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('DATASET SUMMARY\n');
fprintf('================================\n');

fprintf('Trials   : %d\n', ...
    TFRINF_Dataset.nTrials);

fprintf('Subjects : %d\n', ...
    TFRINF_Dataset.nSubjects);

fprintf('Features : %d\n', ...
    TFRINF_Dataset.nFeatures);

%% ============================================================
% SUBJECTS
%% ============================================================

subjectIDs = unique( ...
    {TFRINF_Dataset.trials.subjectID});

nSubjects = ...
    numel(subjectIDs);

fprintf('\n');
fprintf('================================\n');
fprintf('LOSO SETUP\n');
fprintf('================================\n');

fprintf('Subjects : %d\n', ...
    nSubjects);

%% ============================================================
% LOSO
%% ============================================================

Results_LOSO = struct();

for iClf = 1:numel(cfgTFRINF.classifiers)

    classifierName = ...
        cfgTFRINF.classifiers{iClf};

    cfgTFRINF.classifier = ...
        classifierName;

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CLASSIFIER : %s\n', ...
        classifierName);
    fprintf('================================\n');

    for iSub = 1:nSubjects

        testSubject = ...
            subjectIDs{iSub};

        fprintf('\n');
        fprintf('--------------------------------\n');
        fprintf('LOSO FOLD %d/%d\n', ...
            iSub,...
            nSubjects);

        fprintf('Test Subject : %s\n', ...
            testSubject);

        %% =====================================================
        % SPLIT
        %% =====================================================

        [TrainTrials,...
            TestTrials] = ...
            split_loso_trials( ...
            TFRINF_Dataset,...
            testSubject);

        %% =====================================================
        % MATRIX
        %% =====================================================

        Xtrain = ...
            vertcat(TrainTrials.TFRINF);

        Xtest = ...
            vertcat(TestTrials.TFRINF);

        %% =====================================================
        % ZSCORE
        %% =====================================================

        if cfgTFRINF.useZScore

            mu = mean(Xtrain,1);

            sd = std(Xtrain,[],1);

            sd(sd==0) = 1;

            Xtrain = ...
                (Xtrain-mu)./sd;

            Xtest = ...
                (Xtest-mu)./sd;

        end

        %% =====================================================
        % PCA
        %% =====================================================

        if cfgTFRINF.usePCA

            [coeff,...
                scoreTrain,...
                ~,...
                ~,...
                explained,...
                muPCA] = pca(Xtrain);

            nComp = ...
                min(cfgTFRINF.nPCs,...
                size(scoreTrain,2));

            Xtrain = ...
                scoreTrain(:,1:nComp);

            Xtest = ...
                (Xtest-muPCA) * ...
                coeff(:,1:nComp);

            fprintf('\n');
            fprintf('PCA Components : %d\n', ...
                nComp);

            fprintf('Explained Variance : %.2f %%\n', ...
                sum(explained(1:nComp)));

        end

        %% =====================================================
        % REINJECT FEATURES
        %% =====================================================

        for iT = 1:numel(TrainTrials)

            TrainTrials(iT).TFRINF = ...
                Xtrain(iT,:);

        end

        for iT = 1:numel(TestTrials)

            TestTrials(iT).TFRINF = ...
                Xtest(iT,:);

        end

        %% =====================================================
        % FEATURES STRUCT
        %% =====================================================

        Features = struct();

        Features.TrainEEG = ...
            TrainTrials;

        Features.TestEEG = ...
            TestTrials;

        Features.SignalField = ...
            'TFRINF';

        Features.FeatureNames = ...
            TFRINF_Dataset.FeatureNames;

        if cfgTFRINF.usePCA

            Features.nFeatures = ...
                size(Xtrain,2);

        else

            Features.nFeatures = ...
                numel(TrainTrials(1).TFRINF);

        end
        fprintf('Feature dimension : %d\n', ...
            Features.nFeatures);
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

        Results_LOSO.(classifierName).Fold(iSub) = ...
            FoldResult;

    end

end

%% ============================================================
% SUBJECT TABLE
%% ============================================================

for iClf = 1:numel(cfgTFRINF.classifiers)

    classifierName = ...
        cfgTFRINF.classifiers{iClf};

    T = table();

    for iSub = 1:nSubjects

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
        sprintf('%s_SubjectMetrics.csv',...
        classifierName)));

end

%% ============================================================
% SUMMARY
%% ============================================================

for iClf = 1:numel(cfgTFRINF.classifiers)

    classifierName = ...
        cfgTFRINF.classifiers{iClf};

    allACC = arrayfun(@(x) x.TestMetrics.ACC,...
        Results_LOSO.(classifierName).Fold);

    allBA = arrayfun(@(x) x.TestMetrics.BA,...
        Results_LOSO.(classifierName).Fold);

    allF1 = arrayfun(@(x) x.TestMetrics.F1,...
        Results_LOSO.(classifierName).Fold);

    allMCC = arrayfun(@(x) x.TestMetrics.MCC,...
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
    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf('Mean ACC : %.2f %%\n', ...
        100*Results_LOSO.(classifierName).MeanAccuracy);

    fprintf('Mean BA  : %.2f %%\n', ...
        100*Results_LOSO.(classifierName).MeanBalancedAccuracy);

    fprintf('Mean F1  : %.4f\n', ...
        Results_LOSO.(classifierName).MeanF1);

    fprintf('Mean MCC : %.4f\n', ...
        Results_LOSO.(classifierName).MeanMCC);
end

%% ============================================================
% SUMMARY TABLE
%% ============================================================

SummaryTable = table();

for iClf = 1:numel(cfgTFRINF.classifiers)

    classifierName = ...
        cfgTFRINF.classifiers{iClf};

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

    SummaryTable.ZScore(iClf,1) = ...
        cfgTFRINF.useZScore;

    SummaryTable.PCA(iClf,1) = ...
        cfgTFRINF.usePCA;

    SummaryTable.nPCs(iClf,1) = ...
        cfgTFRINF.nPCs;
    cfgTFRINF.featureName = ...
        'TFR_GRID_V4A';
    SummaryTable.FeatureSet{iClf,1} = ...
        cfgTFRINF.featureName;
end

writetable( ...
    SummaryTable,...
    fullfile(outdir,...
    'ClassifierSummary.csv'));
%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'STEP12B_v4A_TFRINF_GRID_LOSO.mat'),...
    'Results_LOSO',...
    'SummaryTable',...
    'cfgTFRINF',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP12B_v4A COMPLETED\n');
fprintf('================================\n');