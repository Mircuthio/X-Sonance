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
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

%% ============================================================
% OUTPUT
%% ============================================================

Cases = ...
    build_erp_informed_cases();

iCase = 1;

CaseCfg = Cases(iCase);
CaseCfg.name = 'CD_TRIALWISE';
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
% LOAD DATASET
%% ============================================================

% % STEP 1
% load( ...
%     fullfile( ...
%     step2_indir,...
%     'STEP10F_CONTROL_DATASETS',...
%     'ERPINF_Dataset_CON_CONTROL_FULL.mat'));
% outdir = ...
%     fullfile(outdir,...
%     'CON_CONTROL');

% % STEP 2
% load( ...
%     fullfile( ...
%     step2_indir,...
%     'STEP10F_CONTROL_DATASETS',...
%     'ERPINF_Dataset_DIS_CONTROL_FULL.mat'));
%
% outdir = ...
%     fullfile(outdir,...
%     'DIS_CONTROL');


% % STEP 3
% load( ...
%     fullfile( ...
%     step2_indir,...
%     'STEP10F_CONTROL_DATASETS',...
%     'ERPINF_Dataset_CD_CONTROL_FULL.mat'));
% 
% outdir = ...
%     fullfile(outdir,...
%     'CONDIS_CONTROL');

%STEP 4
load( ...
    fullfile( ...
    step2_indir,...
    'STEP10F_CONTROL_DATASETS',...
    'ERPINF_Dataset_CD_FULL.mat'));

outdir = ...
    fullfile(outdir,...
    'CONDIS_FULL');

%% ============================================================
% LOAD DATASET
%% ============================================================
% % ERPINDEX
% ERPINF_Dataset = ...
%     select_erpinf_features( ...
%     ERPINF_Dataset,...
%     {'ERPINDEX'});
% outdir = fullfile(outdir,'ERPINDEX');

% % ERPINDEX + ERAN_B
% ERPINF_Dataset = ...
%     select_erpinf_features( ...
%     ERPINF_Dataset,...
%     {'ERPINDEX','ERAN_B'});
% outdir = fullfile(outdir,'ERPINDEX_ERANB');

% % BETALOW
% ERPINF_Dataset = ...
%     select_erpinf_features( ...
%     ERPINF_Dataset,...
%     {'BETALOW'});
% outdir = fullfile(outdir,'BETALOW');
%
% ALL
ERPINF_Dataset = ...
    select_erpinf_features( ...
    ERPINF_Dataset,...
    {'ERPINDEX','ERAN_B','BETALOW'});

outdir = fullfile(outdir,'ERPINDEX_ERANB_BETALOW');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

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
% FEATURE PREPROCESSING
%% ------------------------------------------------------------

cfgINF.useZScore = true;

cfgINF.usePCA = true;

cfgINF.pcaMode = 'variance';

cfgINF.pcaVarianceThreshold = 95;
%% ------------------------------------------------------------
% RUN NAME
%% ------------------------------------------------------------

runName = "";

if cfgINF.useZScore
    runName = runName + "_Z";
end

if cfgINF.usePCA

    switch lower(cfgINF.pcaMode)

        case 'variance'

            runName = runName + ...
                sprintf('_PCA%gVAR', ...
                cfgINF.pcaVarianceThreshold);

        case 'fixed'

            runName = runName + ...
                sprintf('_PCA%d', ...
                cfgINF.nPCs);

    end

end

if strlength(runName)==0
    runName = "_RAW";
end

outdir = fullfile(outdir,char(runName));

if ~exist(outdir,'dir')
    mkdir(outdir);
end
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

cfgINF.feature_set = ...
    ERPINF_Dataset.FeatureNames;

cfgINF = ...
    update_erpinf_feature_flags( ...
    cfgINF,...
    ERPINF_Dataset.FeatureNames);

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

cfgINF.numIterations = 50;

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
        % NORMALIZATION
        %% =====================================================

        Xtrain = vertcat(TrainTrials.ERPINF);
        Xtest  = vertcat(TestTrials.ERPINF);

        %% =====================================================
        % ZSCORE
        %% =====================================================

        if cfgINF.useZScore

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

        if cfgINF.usePCA

            [coeff,...
                scoreTrain,...
                latent,...
                ~,...
                explained,...
                muPCA] = pca(Xtrain);

            cumExplained = ...
                cumsum(explained);

            switch lower(cfgINF.pcaMode)

                case 'variance'

                    nComp = ...
                        find( ...
                        cumExplained >= ...
                        cfgINF.pcaVarianceThreshold,...
                        1,...
                        'first');

                    if isempty(nComp)
                        nComp = size(scoreTrain,2);
                    end

                    fprintf('Compression Ratio : %.2f %%\n', ...
                        100*nComp/size(coeff,1));

                case 'fixed'

                    nComp = ...
                        min(cfgINF.nPCs,...
                        size(scoreTrain,2));

                otherwise

                    error('Unknown PCA mode');

            end

            Xtrain = ...
                scoreTrain(:,1:nComp);

            Xtest = ...
                (Xtest - muPCA) * ...
                coeff(:,1:nComp);

            fprintf('\n');
            fprintf('================================\n');
            fprintf('PCA ENABLED\n');
            fprintf('================================\n');

            fprintf('Mode : %s\n', ...
                cfgINF.pcaMode);

            fprintf('Components : %d\n', ...
                nComp);

            fprintf('Explained Variance : %.2f %%\n', ...
                cumExplained(nComp));

            fprintf('Original Features : %d\n', ...
                size(coeff,1));

            fprintf('Retained Components : %d\n', ...
                nComp);

        end

        for iT = 1:numel(TrainTrials)

            TrainTrials(iT).ERPINF = ...
                Xtrain(iT,:);

        end

        for iT = 1:numel(TestTrials)

            TestTrials(iT).ERPINF = ...
                Xtest(iT,:);

        end
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

        if cfgINF.usePCA
            Features.nFeatures = ...
                size(Xtrain,2);
        else
            Features.nFeatures = ...
                numel(TrainTrials(1).ERPINF);
        end
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
        if cfgINF.usePCA

            IterResult.nPCs = ...
                nComp;

            IterResult.ExplainedVariance = ...
                cumExplained(nComp);

        end

        IterResult.PCAMode = ...
            cfgINF.pcaMode;

        IterResult.PCAVarianceThreshold = ...
            cfgINF.pcaVarianceThreshold;

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
% ITERATION METRICS
%% ============================================================

for iClf = 1:numel(cfgINF.classifiers)

    classifierName = ...
        cfgINF.classifiers{iClf};

    T = table();

    for iIter = 1:cfgINF.numIterations

        T.Iteration(iIter,1) = ...
            iIter;

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
        sprintf( ...
        '%s_IterationMetrics.csv',...
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
% SUMMARY TABLE
%% ============================================================

SummaryTable = table();

for iClf = 1:numel(cfgINF.classifiers)

    classifierName = ...
        cfgINF.classifiers{iClf};

    SummaryTable.Classifier{iClf,1} = ...
        classifierName;

    SummaryTable.ACC(iClf,1) = ...
        Results_TrialWise.(classifierName).MeanAccuracy;

    SummaryTable.BA(iClf,1) = ...
        Results_TrialWise.(classifierName).MeanBalancedAccuracy;

    SummaryTable.F1(iClf,1) = ...
        Results_TrialWise.(classifierName).MeanF1;

    SummaryTable.MCC(iClf,1) = ...
        Results_TrialWise.(classifierName).MeanMCC;

    SummaryTable.nFeatures(iClf,1) = ...
        Results_TrialWise.(classifierName).Iter(1).nFeatures;
    SummaryTable.ZScore(iClf,1) = ...
        cfgINF.useZScore;
    SummaryTable.PCA(iClf,1) = ...
        cfgINF.usePCA;

    SummaryTable.PCAMode{iClf,1} = ...
        cfgINF.pcaMode;

    SummaryTable.PCAVariance(iClf,1) = ...
        cfgINF.pcaVarianceThreshold;

    SummaryTable.RunName{iClf,1} = ...
        char(runName);

    if cfgINF.usePCA
        SummaryTable.nPCs(iClf,1) = ...
            Results_TrialWise.(classifierName).Iter(1).nPCs;
        SummaryTable.ActualExplainedVariance(iClf,1) = ...
            Results_TrialWise.(classifierName).Iter(1).ExplainedVariance;
    else
        SummaryTable.nPCs(iClf,1) = 0;
        SummaryTable.ActualExplainedVariance(iClf,1) = 0;
    end
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
        'STEP10C_ERP_INFORMED_TRIALWISE_%s%s.mat', ...
        cfgINF.classifiers{1}, ...
        char(runName));

else

    allClf = strjoin( ...
        cfgINF.classifiers,...
        '_');

    saveName = sprintf( ...
        'STEP10C_ERP_INFORMED_TRIALWISE_%s%s.mat',...
        allClf,...
        char(runName));

end

save( ...
    fullfile(outdir,saveName),...
    'Results_TrialWise',...
    'cfgINF',...
    'CaseCfg',...
    'runName',...
    '-v7.3');

save( ...
    fullfile(outdir,...
    'ClassifierSummary.mat'),...
    'SummaryTable');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP10C ERP INFORMED TRIALWISE COMPLETED\n');
fprintf('================================\n');