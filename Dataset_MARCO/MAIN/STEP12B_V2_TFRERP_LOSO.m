%% =========================================================================
% STEP12B_V2_TFRERP_LOSO
%% =========================================================================

clear
close all
clc

origState = ...
    get(0,'DefaultFigureVisible');

set(0,'DefaultFigureVisible','off');

disable_eeglab();

%% ============================================================
% PATHS
%% ============================================================

step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

outdir = ...
    fullfile( ...
    step2_indir,...
    'STEP12B_V2_TFRERP_LOSO');

if ~exist(outdir,'dir')

    mkdir(outdir);

end

%% ============================================================
% LOAD DATASET
%% ============================================================

load( ...
    fullfile( ...
    step2_indir,...
    'STEP12A_V2_TFRERP_DATASETS',...
    'TFRINF_Dataset_CD_FULL.mat'));

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('TFRERP DATASET\n');
fprintf('================================\n');

fprintf('Trials   : %d\n', ...
    numel(TFRINF_Dataset.trials));

fprintf('Features : %d\n', ...
    TFRINF_Dataset.nFeatures);

disp(TFRINF_Dataset.FeatureNames(:))

%% ============================================================
% CONFIG
%% ============================================================

cfgTFR = struct();

cfgTFR.randomSeed = 10;

cfgTFR.useZScore = true;

cfgTFR.useMRMR = true;

cfgTFR.nKeepFeatures = 40;

cfgTFR.classifiers = { ...
    'QDA'};

rng('default');
rng(cfgTFR.randomSeed);

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

for iClf = 1:numel(cfgTFR.classifiers)

    classifierName = ...
        cfgTFR.classifiers{iClf};

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

        fprintf('TEST SUBJECT : %s\n', ...
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
        % FEATURES
        %% ----------------------------------------------------

        Xtrain = ...
            vertcat( ...
            TrainTrials.TFRERP);

        Xtest = ...
            vertcat( ...
            TestTrials.TFRERP);

        Ytrain = ...
            [TrainTrials.trialType]';

        Ytest = ...
            [TestTrials.trialType]';

        %% ----------------------------------------------------
        % REMOVE CONSTANT FEATURES
        %% ----------------------------------------------------

        idxVar = ...
            var(Xtrain,[],1) > 1e-12;

        Xtrain = ...
            Xtrain(:,idxVar);

        Xtest = ...
            Xtest(:,idxVar);

        FeatureNamesUsed = ...
            TFRINF_Dataset.FeatureNames(idxVar);

        %% ----------------------------------------------------
        % MRMR
        %% ----------------------------------------------------

        if cfgTFR.useMRMR

            rankIdx = ...
                fscmrmr( ...
                Xtrain,...
                Ytrain);

            k = min( ...
                cfgTFR.nKeepFeatures,...
                numel(rankIdx));

            keepIdx = ...
                rankIdx(1:k);

            Xtrain = ...
                Xtrain(:,keepIdx);

            Xtest = ...
                Xtest(:,keepIdx);

            FeatureNamesUsed = ...
                FeatureNamesUsed(keepIdx);

        end

        %% ----------------------------------------------------
        % Z-SCORE
        %% ----------------------------------------------------

        if cfgTFR.useZScore

            mu = ...
                mean(Xtrain,1);

            sd = ...
                std(Xtrain,[],1);

            sd(sd==0)=1;

            Xtrain = ...
                (Xtrain-mu)./sd;

            Xtest = ...
                (Xtest-mu)./sd;

        end

        %% ----------------------------------------------------
        % BUILD STRUCTS
        %% ----------------------------------------------------

        TrainEEG = struct();

        TestEEG = struct();

        for iT = 1:size(Xtrain,1)

            TrainEEG(iT).TFRERP = ...
                Xtrain(iT,:);

            TrainEEG(iT).timeTFRERP = ...
                1:size(Xtrain,2);

            TrainEEG(iT).trialType = ...
                Ytrain(iT);

        end

        for iT = 1:size(Xtest,1)

            TestEEG(iT).TFRERP = ...
                Xtest(iT,:);

            TestEEG(iT).timeTFRERP = ...
                1:size(Xtest,2);

            TestEEG(iT).trialType = ...
                Ytest(iT);

        end

        %% ----------------------------------------------------
        % CLASSIFIER
        %% ----------------------------------------------------

        parClassifier = struct();

        parClassifier.InField = ...
            'TFRERP';

        [TrainEEG,...
         TestEEG,...
         outClassifier,...
         PredField,...
         ProbField] = ...
            run_classifier_fold( ...
            TrainEEG,...
            TestEEG,...
            classifierName,...
            parClassifier);

        %% ----------------------------------------------------
        % PREDICTION
        %% ----------------------------------------------------

        parPredict = ...
            mdlPredictParams();

        parPredict.InField = ...
            'TFRERP';

        parPredict.OutField = ...
            PredField;

        parPredict.ProbField = ...
            ProbField;

        parPredict.mdl = ...
            outClassifier.mdl;

        [TestEEG,~] = ...
            mdlPredict( ...
            TestEEG,...
            parPredict);

        %% ----------------------------------------------------
        % METRICS
        %% ----------------------------------------------------

        Ypred = ...
            [TestEEG.(PredField)]';

        Metrics = ...
            compute_classification_metrics( ...
            Ytest,...
            Ypred);

        FoldResult = struct();

        FoldResult.testSubject = ...
            testSubject;

        FoldResult.nFeatures = ...
            size(Xtrain,2);

        FoldResult.FeatureNames = ...
            FeatureNamesUsed;

        FoldResult.TestMetrics = ...
            Metrics;

        Results_LOSO.(classifierName).Fold(iSub) = ...
            FoldResult;

    end

end

%% ============================================================
% SUMMARY
%% ============================================================

for iClf = 1:numel(cfgTFR.classifiers)

    classifierName = ...
        cfgTFR.classifiers{iClf};

    allACC = ...
        arrayfun(@(x) ...
        x.TestMetrics.ACC,...
        Results_LOSO.(classifierName).Fold);

    allBA = ...
        arrayfun(@(x) ...
        x.TestMetrics.BA,...
        Results_LOSO.(classifierName).Fold);

    allF1 = ...
        arrayfun(@(x) ...
        x.TestMetrics.F1,...
        Results_LOSO.(classifierName).Fold);

    allMCC = ...
        arrayfun(@(x) ...
        x.TestMetrics.MCC,...
        Results_LOSO.(classifierName).Fold);

    fprintf('\n');
    fprintf('================================\n');
    fprintf('%s SUMMARY\n', ...
        classifierName);
    fprintf('================================\n');

    fprintf('Mean ACC : %.2f %%\n', ...
        100*mean(allACC));

    fprintf('Mean BA  : %.2f %%\n', ...
        100*mean(allBA));

    fprintf('Mean F1  : %.4f\n', ...
        mean(allF1,'omitnan'));

    fprintf('Mean MCC : %.4f\n', ...
        mean(allMCC,'omitnan'));

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'STEP12B_V2_TFRERP_LOSO.mat'),...
    'Results_LOSO',...
    'cfgTFR',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP12B_V2 COMPLETED\n');
fprintf('================================\n');