%% =========================================================================
% STEP12C_v4A_TFRINF_GRID_TRIALWISE
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
    'STEP12C_v4A_TFRINF_GRID_TRIALWISE');

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
% TRIALWISE
%% ------------------------------------------------------------

cfgTFRINF.trainRatio = 0.80;

cfgTFRINF.testRatio = 0.20;

cfgTFRINF.kfold = 4;

cfgTFRINF.numIterations = 25;

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
% TRIALWISE
%% ============================================================

Results_TrialWise = struct();

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

    for iIter = 1:cfgTFRINF.numIterations

        fprintf('\n');
        fprintf('--------------------------------\n');
        fprintf('ITERATION %d/%d\n', ...
            iIter,...
            cfgTFRINF.numIterations);

        %% =====================================================
        % SPLIT
        %% =====================================================

        [TrainTrials,...
            TestTrials] = ...
            split_trialwise_trials( ...
            TFRINF_Dataset,...
            cfgTFRINF);

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

            sd(sd==0)=1;

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
                min( ...
                cfgTFRINF.nPCs,...
                size(scoreTrain,2));

            Xtrain = ...
                scoreTrain(:,1:nComp);

            Xtest = ...
                (Xtest-muPCA) * ...
                coeff(:,1:nComp);

            fprintf('\n');

            fprintf('PCA Components : %d\n', ...
                nComp);

            fprintf( ...
                'Explained Variance : %.2f %%\n',...
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

        IterResult = struct();

        IterResult.classifier = ...
            classifierName;

        IterResult.iteration = ...
            iIter;

        IterResult.nTrainTrials = ...
            numel(TrainTrials);

        IterResult.nTestTrials = ...
            numel(TestTrials);

        IterResult.nFeatures = ...
            Features.nFeatures;

        IterResult.FeatureNames = ...
            Features.FeatureNames;

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
% ITERATION TABLE
%% ============================================================

for iClf = 1:numel(cfgTFRINF.classifiers)

    classifierName = ...
        cfgTFRINF.classifiers{iClf};

    T = table();

    for iIter = 1:cfgTFRINF.numIterations

        T.Iteration(iIter,1) = iIter;

        T.ACC(iIter,1) = ...
            Results_TrialWise.(classifierName).Iter(iIter).TestMetrics.ACC;

        T.BA(iIter,1) = ...
            Results_TrialWise.(classifierName).Iter(iIter).TestMetrics.BA;

        T.F1(iIter,1) = ...
            Results_TrialWise.(classifierName).Iter(iIter).TestMetrics.F1;

        T.MCC(iIter,1) = ...
            Results_TrialWise.(classifierName).Iter(iIter).TestMetrics.MCC;

    end

    writetable( ...
        T,...
        fullfile( ...
        outdir,...
        sprintf('%s_IterationMetrics.csv',...
        classifierName)));

end

%% ============================================================
% SUMMARY
%% ============================================================

for iClf = 1:numel(cfgTFRINF.classifiers)

    classifierName = ...
        cfgTFRINF.classifiers{iClf};

    allACC = arrayfun(@(x)x.TestMetrics.ACC,...
        Results_TrialWise.(classifierName).Iter);

    allBA = arrayfun(@(x)x.TestMetrics.BA,...
        Results_TrialWise.(classifierName).Iter);

    allF1 = arrayfun(@(x)x.TestMetrics.F1,...
        Results_TrialWise.(classifierName).Iter);

    allMCC = arrayfun(@(x)x.TestMetrics.MCC,...
        Results_TrialWise.(classifierName).Iter);

    Results_TrialWise.(classifierName).MeanAccuracy = ...
        mean(allACC);

    Results_TrialWise.(classifierName).MeanBalancedAccuracy = ...
        mean(allBA);

    Results_TrialWise.(classifierName).MeanF1 = ...
        mean(allF1,'omitnan');

    Results_TrialWise.(classifierName).MeanMCC = ...
        mean(allMCC,'omitnan');

    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf('Mean ACC : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).MeanAccuracy);

    fprintf('Mean BA  : %.2f %%\n', ...
        100*Results_TrialWise.(classifierName).MeanBalancedAccuracy);

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
    'STEP12C_v4A_TFRINF_GRID_TRIALWISE.mat'),...
    'Results_TrialWise',...
    'cfgTFRINF',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP12C_v4A COMPLETED\n');
fprintf('================================\n');