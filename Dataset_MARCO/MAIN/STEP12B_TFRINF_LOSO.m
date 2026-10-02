%% =========================================================================
% STEP12B_TFRINF_LOSO
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
    'STEP12B_TFRINF_LOSO');

if ~exist(outdir,'dir')

    mkdir(outdir);

end

%% ============================================================
% LOAD DATASET
%% ============================================================

load( ...
    fullfile( ...
    step2_indir,...
    'STEP12A_TFRINF_DATASETS',...
    'TFRINF_Dataset_CD_FULL.mat'));

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgTFRINF = struct();

cfgTFRINF.randomSeed = 10;

cfgTFRINF.useZScore = false;

rng('default')
rng(cfgTFRINF.randomSeed)

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

%% ============================================================
% SUMMARY
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

disp(TFRINF_Dataset.FeatureNames(:))

%% ============================================================
% SUBJECTS
%% ============================================================

subjectIDs = unique( ...
    {TFRINF_Dataset.trials.subjectID});

nSubjects = ...
    numel(subjectIDs);

%% ============================================================
% LOSO
%% ============================================================

Results_LOSO = struct();

for iClf = 1:numel(cfgTFRINF.classifiers)

    classifierName = ...
        cfgTFRINF.classifiers{iClf};

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CLASSIFIER : %s\n', ...
        classifierName);
    fprintf('================================\n');

    for iSub = 1:nSubjects

        testSubject = ...
            subjectIDs{iSub};

        fprintf('\n');
        fprintf('LOSO %d/%d\n', ...
            iSub,...
            nSubjects);

        fprintf('Test Subject : %s\n', ...
            testSubject);

        %% ----------------------------------------------------
        % SPLIT
        %% ----------------------------------------------------

        [TrainTrials,...
         TestTrials] = ...
            split_loso_trials( ...
            TFRINF_Dataset,...
            testSubject);

        %% ----------------------------------------------------
        % OPTIONAL Z-SCORE
        %% ----------------------------------------------------

        if cfgTFRINF.useZScore

            Xtrain = ...
                vertcat( ...
                TrainTrials.TFRINF);

            Xtest = ...
                vertcat( ...
                TestTrials.TFRINF);

            mu = ...
                mean(Xtrain,1);

            sd = ...
                std(Xtrain,[],1);

            sd(sd==0)=1;

            Xtrain = ...
                (Xtrain-mu)./sd;

            Xtest = ...
                (Xtest-mu)./sd;

            for iT = 1:numel(TrainTrials)

                TrainTrials(iT).TFRINF = ...
                    Xtrain(iT,:);

            end

            for iT = 1:numel(TestTrials)

                TestTrials(iT).TFRINF = ...
                    Xtest(iT,:);

            end

        end

        %% ----------------------------------------------------
        % FEATURES
        %% ----------------------------------------------------

        Features = struct();

        Features.TrainEEG = ...
            TrainTrials;

        Features.TestEEG = ...
            TestTrials;

        Features.SignalField = ...
            'TFRINF';

        Features.FeatureNames = ...
            TFRINF_Dataset.FeatureNames;

        Features.nFeatures = ...
            numel( ...
            TrainTrials(1).TFRINF);

        %% ----------------------------------------------------
        % CLASSIFIER
        %% ----------------------------------------------------

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

        %% ----------------------------------------------------
        % PREDICT
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
        % STORE
        %% ----------------------------------------------------

        FoldResult = struct();

        FoldResult.testSubject = ...
            testSubject;

        FoldResult.nFeatures = ...
            Features.nFeatures;

        FoldResult.FeatureNames = ...
            Features.FeatureNames;

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

        Results_LOSO.(classifierName).Fold(iSub) = ...
            FoldResult;

    end

end

%% ============================================================
% SUMMARY
%% ============================================================
for iClf = 1:numel(cfgTFRINF.classifiers)
    classifierName = cfgTFRINF.classifiers{iClf};
    
    allACC = arrayfun(@(x) x.TestMetrics.ACC, Results_LOSO.(classifierName).Fold);
    allBA  = arrayfun(@(x) x.TestMetrics.BA,  Results_LOSO.(classifierName).Fold);
    allF1  = arrayfun(@(x) x.TestMetrics.F1,  Results_LOSO.(classifierName).Fold);
    allMCC = arrayfun(@(x) x.TestMetrics.MCC, Results_LOSO.(classifierName).Fold);
    
    % Salva medie e deviazioni standard dentro Results_LOSO
    Results_LOSO.(classifierName).MeanAccuracy = mean(allACC);
    Results_LOSO.(classifierName).StdAccuracy  = std(allACC);
    Results_LOSO.(classifierName).MeanBA       = mean(allBA);
    Results_LOSO.(classifierName).StdBA        = std(allBA);
    Results_LOSO.(classifierName).MeanF1       = mean(allF1,'omitnan');
    Results_LOSO.(classifierName).StdF1        = std(allF1,'omitnan');
    Results_LOSO.(classifierName).MeanMCC      = mean(allMCC,'omitnan');
    Results_LOSO.(classifierName).StdMCC       = std(allMCC,'omitnan');
    Results_LOSO.(classifierName).cfg          = cfgTFRINF;
    
    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', classifierName);
    fprintf('================================\n');
    fprintf('Mean ACC : %.2f %%\n', 100 * Results_LOSO.(classifierName).MeanAccuracy);
    fprintf('Mean BA  : %.2f %%\n', 100 * Results_LOSO.(classifierName).MeanBA);
    fprintf('Mean F1  : %.4f\n', Results_LOSO.(classifierName).MeanF1);
    fprintf('Mean MCC : %.4f\n', Results_LOSO.(classifierName).MeanMCC);
end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'STEP12B_TFRINF_LOSO_QDA.mat'),...
    'Results_LOSO',...
    'cfgTFRINF',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP12B COMPLETED\n');
fprintf('================================\n');