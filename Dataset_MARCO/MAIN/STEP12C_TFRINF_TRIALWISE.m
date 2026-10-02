%% =========================================================================
% STEP12C_TFRINF_TRIALWISE
%% =========================================================================

clear
close all
clc

origState = ...
    get(0,'DefaultFigureVisible');

set(0,'DefaultFigureVisible','off');

disable_eeglab();

%% ============================================================
% ROOT
%% ============================================================

step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

%% ============================================================
% OUTPUT
%% ============================================================

outdir = ...
    fullfile( ...
    step2_indir,...
    'STEP12C_TFRINF_TRIALWISE');

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
% CONFIG
%% ============================================================

cfgTFRINF = struct();

cfgTFRINF.randomSeed = 10;

cfgTFRINF.useZScore = false;

cfgTFRINF.nIterations = 100;

cfgTFRINF.testFraction = 0.20;

rng('default')
rng(cfgTFRINF.randomSeed)

%% ============================================================
% CLASSIFIER
%% ============================================================

classifierName = ...
    'QDA';

%% ============================================================
% TRIALS
%% ============================================================

AllTrials = ...
    TFRINF_Dataset.trials;

nTrials = ...
    numel(AllTrials);

fprintf('\n');
fprintf('================================\n');
fprintf('TRIALWISE SETUP\n');
fprintf('================================\n');

fprintf('Trials   : %d\n', ...
    nTrials);

fprintf('Features : %d\n', ...
    TFRINF_Dataset.nFeatures);

%% ============================================================
% ITERATIONS
%% ============================================================

Results = struct();

for iIter = 1:cfgTFRINF.nIterations

    fprintf('Iteration %d / %d\n', ...
        iIter,...
        cfgTFRINF.nIterations);

    %% --------------------------------------------------------
    % SPLIT
    %% --------------------------------------------------------

    cv = cvpartition( ...
        [AllTrials.trialType],...
        'HoldOut',...
        cfgTFRINF.testFraction);

    TrainTrials = ...
        AllTrials(training(cv));

    TestTrials = ...
        AllTrials(test(cv));

    %% --------------------------------------------------------
    % ZSCORE
    %% --------------------------------------------------------

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

    %% --------------------------------------------------------
    % FEATURES
    %% --------------------------------------------------------

    Features = struct();

    Features.TrainEEG = ...
        TrainTrials;

    Features.TestEEG = ...
        TestTrials;

    Features.SignalField = ...
        'TFRINF';

    %% --------------------------------------------------------
    % CLASSIFIER
    %% --------------------------------------------------------

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

    %% --------------------------------------------------------
    % PREDICT
    %% --------------------------------------------------------

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

    [TrainEEG,~] = ...
        mdlPredict( ...
        TrainEEG,...
        parPredict);

    [TestEEG,~] = ...
        mdlPredict( ...
        TestEEG,...
        parPredict);

    %% --------------------------------------------------------
    % LABELS
    %% --------------------------------------------------------

    Ytest_true = ...
        [TestEEG.trialType]';

    Ytest_pred = ...
        [TestEEG.(PredField)]';

    %% --------------------------------------------------------
    % METRICS
    %% --------------------------------------------------------

    Metrics = ...
        compute_classification_metrics( ...
        Ytest_true,...
        Ytest_pred);

    Results.Iter(iIter).Metrics = ...
        Metrics;

end

%% ============================================================
% SUMMARY
%% ============================================================
allACC = arrayfun(@(x) x.Metrics.ACC, Results.Iter);
allBA  = arrayfun(@(x) x.Metrics.BA,  Results.Iter);
allF1  = arrayfun(@(x) x.Metrics.F1,  Results.Iter);
allMCC = arrayfun(@(x) x.Metrics.MCC, Results.Iter);

% Salva medie e deviazioni standard dentro Results
Results.MeanAccuracy = mean(allACC);
Results.StdAccuracy  = std(allACC);
Results.MeanBA       = mean(allBA);
Results.StdBA        = std(allBA);
Results.MeanF1       = mean(allF1,'omitnan');
Results.StdF1        = std(allF1,'omitnan');
Results.MeanMCC      = mean(allMCC,'omitnan');
Results.StdMCC       = std(allMCC,'omitnan');

fprintf('\n');
fprintf('================================\n');
fprintf('TFRINF TRIALWISE SUMMARY\n');
fprintf('================================\n');
fprintf('Mean ACC : %.2f %%\n', 100 * Results.MeanAccuracy);
fprintf('Mean BA  : %.2f %%\n', 100 * Results.MeanBA);
fprintf('Mean F1  : %.4f\n', Results.MeanF1);
fprintf('Mean MCC : %.4f\n', Results.MeanMCC);

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'STEP12C_TFRINF_TRIALWISE_QDA.mat'),...
    'Results',...
    'cfgTFRINF',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP12C COMPLETED\n');
fprintf('================================\n');