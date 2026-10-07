%% =========================================================================
% STEP10C_ERP_INFORMED_LOSO
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
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

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
    'STEP10C_ERP_INFORMED_LOSO',...
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

% ERPINDEX + ERAN_B
ERPINF_Dataset = ...
    select_erpinf_features( ...
    ERPINF_Dataset,...
    {'ERPINDEX','ERAN_B'});
outdir = fullfile(outdir,'ERPINDEX_ERANB');

% % BETALOW
% ERPINF_Dataset = ...
%     select_erpinf_features( ...
%     ERPINF_Dataset,...
%     {'BETALOW'});
% outdir = fullfile(outdir,'BETALOW');
%

% % ALL
% ERPINF_Dataset = ...
%     select_erpinf_features( ...
%     ERPINF_Dataset,...
%     {'ERPINDEX','ERAN_B','BETALOW'});
% 
% outdir = fullfile(outdir,'ERPINDEX_ERANB_BETALOW');


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
            Features.nFeatures = size(Xtrain,2);
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

        if cfgINF.usePCA

            FoldResult.nPCs = ...
                nComp;

            FoldResult.ExplainedVariance = ...
                cumExplained(nComp);

        end
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

        FoldResult.PCAMode = ...
            cfgINF.pcaMode;

        FoldResult.PCAVarianceThreshold = ...
            cfgINF.pcaVarianceThreshold;

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
    
    % Pre-allocate table with all subjects at once
    nSub = numel(subjectIDs);
    T = table( ...
        cell(nSub,1), ...      % Subject
        zeros(nSub,1), ...     % ACC
        zeros(nSub,1), ...     % BA
        zeros(nSub,1), ...     % F1
        zeros(nSub,1), ...     % MCC
        'VariableNames', ...
        {'Subject','ACC','BA','F1','MCC'});
    
    for iSub = 1:nSub
        T.Subject{iSub} = ...
            Results_LOSO.(classifierName).Fold(iSub).testSubject;
        T.ACC(iSub) = ...
            Results_LOSO.(classifierName).Fold(iSub).TestMetrics.ACC;
        T.BA(iSub) = ...
            Results_LOSO.(classifierName).Fold(iSub).TestMetrics.BA;
        T.F1(iSub) = ...
            Results_LOSO.(classifierName).Fold(iSub).TestMetrics.F1;
        T.MCC(iSub) = ...
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
            Results_LOSO.(classifierName).Fold(1).nPCs;
        
        SummaryTable.ActualExplainedVariance(iClf,1) = ...
            Results_LOSO.(classifierName).Fold(1).ExplainedVariance;
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
        'STEP10C_ERP_INFORMED_LOSO_%s%s.mat', ...
        cfgINF.classifiers{1}, ...
        char(runName));

else

    allClf = strjoin( ...
        cfgINF.classifiers,...
        '_');

    saveName = sprintf( ...
        'STEP10C_ERP_INFORMED_LOSO_%s%s.mat',...
        allClf,...
        char(runName));

end

save( ...
    fullfile(outdir,saveName),...
    'Results_LOSO',...
    'cfgINF',...
    'CaseCfg',...
    'runName',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP10C ERP INFORMED COMPLETED\n');
fprintf('================================\n');