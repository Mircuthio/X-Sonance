%% =========================================================================
% STEP9_FBCSP_TRIALWISE
% MAIN_FBCSP_TRIALWISE_STEP9
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

disable_eeglab();

%% ============================================================
% LOAD DATA
%% ============================================================
step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% OUTPUT
%% ============================================================
Cases = build_fbcsp_cases();

numiCase = [2,3,4];
for iCase = 1:numel(numiCase)
    try

        CaseCfg = Cases(numiCase(iCase));

        outdir = fullfile( ...
            step2_indir,...
            'STEP9_FBCSP_TRIALWISE',...
            CaseCfg.group,...
            CaseCfg.name);

        if ~exist(outdir,'dir')
            mkdir(outdir);
        end

        %% ============================================================
        % CONFIGURATION
        %% ============================================================
        cfgFBCSP = struct();

        fprintf('\n');
        fprintf('================================\n');
        fprintf('EXPERIMENT\n');
        fprintf('================================\n');
        fprintf('Group : %s\n', ...
            CaseCfg.group);
        fprintf('Case  : %s\n', ...
            CaseCfg.name);

        %% ------------------------------------------------------------
        % RANDOM SEED
        %% ------------------------------------------------------------
        cfgFBCSP.randomSeed = 10;

        rng('default')
        rng(cfgFBCSP.randomSeed)

        %% ------------------------------------------------------------
        % CLASSES
        %% ------------------------------------------------------------
        cfgFBCSP.class_labels = CaseCfg.class_labels;

        cfgFBCSP.class_codes = CaseCfg.class_codes;

        %% ------------------------------------------------------------
        % TIME WINDOW
        %% ------------------------------------------------------------
        cfgFBCSP.time_window = CaseCfg.time_window;

        %% ------------------------------------------------------------
        % SUBEPOCHS
        %% ------------------------------------------------------------
        cfgFBCSP.useSubEpochs = ...
            CaseCfg.useSubEpochs;

        cfgFBCSP.subEpochLength = ...
            CaseCfg.subEpochLength;

        cfgFBCSP.subEpochOverlap = ...
            CaseCfg.subEpochOverlap;
        %% ------------------------------------------------------------
        % FILTER BANK
        %% ------------------------------------------------------------
        cfgFBCSP.useFilterBank = ...
            CaseCfg.useFilterBank;

        cfgFBCSP.filterBankName = ...
            CaseCfg.filterBankName;

        %% ------------------------------------------------------------
        % CSP
        %% ------------------------------------------------------------
        cfgFBCSP.csp_components = ...
            CaseCfg.csp_components;

        %% ------------------------------------------------------------
        % MUTUAL INFORMATION
        %% ------------------------------------------------------------
        cfgFBCSP.useMI = ...
            CaseCfg.useMI;

        cfgFBCSP.mi_k = ...
            CaseCfg.mi_k;

        %% ------------------------------------------------------------
        % CLASSIFIERS
        %% ------------------------------------------------------------
        cfgFBCSP.classifiers = ...
            CaseCfg.classifiers;

        %% ------------------------------------------------------------
        % DATASET FIELDS
        %% ------------------------------------------------------------
        cfgFBCSP.eventField = 'eventLabel';

        cfgFBCSP.subjectField = ...
            'subj_id';

        %% ------------------------------------------------------------
        % SIGNAL FIELD
        %% ------------------------------------------------------------
        cfgFBCSP.signalField = ...
            'eegFB';

        %% ------------------------------------------------------------
        % TRIALWISE PARAMETERS
        %% ------------------------------------------------------------
        cfgFBCSP.trainRatio = 0.80;

        cfgFBCSP.testRatio = 0.20;

        cfgFBCSP.kfold = 4;

        cfgFBCSP.numIterations = 50;

        %% ============================================================
        % BUILD DATASET
        %% ============================================================
        FBCSP_Dataset = ...
            build_fbcsp_dataset( ...
            subj_list,...
            cfgFBCSP);

        %% ============================================================
        % FILTER BANK
        %% ============================================================
        FBCSP_Dataset = ...
            apply_fbcsp_filterbank( ...
            FBCSP_Dataset,...
            cfgFBCSP);
        %% ============================================================
        % SUBEPOCHS
        %% ============================================================
        if cfgFBCSP.useSubEpochs

            parEpoch = ...
                epochComputeParams();

            parEpoch.InField = ...
                cfgFBCSP.signalField;

            parEpoch.OutField = ...
                cfgFBCSP.signalField;

            parEpoch.fample = ...
                FBCSP_Dataset.fsample;

            parEpoch.t_epoch = ...
                cfgFBCSP.subEpochLength;

            parEpoch.overlap_percent = ...
                cfgFBCSP.subEpochOverlap;

            [FBCSP_Dataset.trials,~] = ...
                epochCompute( ...
                FBCSP_Dataset.trials,...
                parEpoch);

            parMulti = struct();

            parMulti.Infield = ...
                cfgFBCSP.signalField;

            FBCSP_Dataset.trials = ...
                multiEEG( ...
                FBCSP_Dataset.trials,...
                parMulti);
            fprintf('Trials after subepoching: %d\n', ...
                numel(FBCSP_Dataset.trials));
            fprintf('\n');
            fprintf('================================\n');
            fprintf('SUBEPOCHING\n');
            fprintf('================================\n');
            fprintf('Length  : %.3f s\n', ...
                cfgFBCSP.subEpochLength);
            fprintf('Overlap : %.1f %%\n', ...
                cfgFBCSP.subEpochOverlap);

        end
        %% ============================================================
        % TRIAL-WISE VALIDATION
        %% ============================================================
        Results_TrialWise = struct();

        for iClf = 1:numel(cfgFBCSP.classifiers)

            classifierName = ...
                cfgFBCSP.classifiers{iClf};

            cfgFBCSP.classifier = ...
                classifierName;

            fprintf('\n');
            fprintf('================================\n');
            fprintf('CLASSIFIER: %s\n', ...
                classifierName);
            fprintf('================================\n');

            for iIter = 1:cfgFBCSP.numIterations

                fprintf('\n');
                fprintf('--------------------------------\n');
                fprintf('ITERATION %d/%d\n', ...
                    iIter,...
                    cfgFBCSP.numIterations);

                %% ----------------------------------------------------
                % SPLIT
                %% ----------------------------------------------------
                [TrainTrials,...
                    TestTrials] = ...
                    split_trialwise_trials( ...
                    FBCSP_Dataset,...
                    cfgFBCSP);

                %% ----------------------------------------------------
                % FEATURE EXTRACTION
                %% ----------------------------------------------------
                Features = ...
                    run_fbcsp_features( ...
                    TrainTrials,...
                    TestTrials,...
                    cfgFBCSP);

                %% ----------------------------------------------------
                % CLASSIFIER
                %% ----------------------------------------------------
                parClassifier = struct();
                parClassifier.InField = Features.SignalField;

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
                % PREDICTION
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
                % STORE RESULTS
                %% ----------------------------------------------------
                IterResult = struct();

                IterResult.classifier = ...
                    classifierName;

                IterResult.nTrainTrials = ...
                    numel(TrainTrials);

                IterResult.nTestTrials = ...
                    numel(TestTrials);

                IterResult.nFeatures = ...
                    Features.nFeatures;

                IterResult.CSPModel = ...
                    Features.CSPModel;

                IterResult.MIModel = ...
                    Features.MIModel;

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
        for iClf = 1:numel(cfgFBCSP.classifiers)

            classifierName = ...
                cfgFBCSP.classifiers{iClf};

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
                cfgFBCSP;

            fprintf('\n');
            fprintf('================================\n');
            fprintf('%s SUMMARY\n', ...
                classifierName);
            fprintf('================================\n');

            fprintf('Mean Accuracy         : %.2f %%\n', ...
                100*Results_TrialWise.(classifierName).MeanAccuracy);

            fprintf('Std Accuracy          : %.2f %%\n', ...
                100*Results_TrialWise.(classifierName).StdAccuracy);

            fprintf('Mean BalancedAccuracy : %.2f %%\n', ...
                100*Results_TrialWise.(classifierName).MeanBalancedAccuracy);

            fprintf('Std BalancedAccuracy  : %.2f %%\n', ...
                100*Results_TrialWise.(classifierName).StdBalancedAccuracy);

            fprintf('Mean F1               : %.4f\n', ...
                Results_TrialWise.(classifierName).MeanF1);

            fprintf('Std F1                : %.4f\n', ...
                Results_TrialWise.(classifierName).StdF1);

            fprintf('Mean MCC              : %.4f\n', ...
                Results_TrialWise.(classifierName).MeanMCC);

            fprintf('Std MCC               : %.4f\n', ...
                Results_TrialWise.(classifierName).StdMCC);

        end

        %% ============================================================
        % SAVE
        %% ============================================================
        save( ...
            fullfile(outdir,...
            sprintf('%s.mat', ...
            CaseCfg.name)),...
            'Results_TrialWise',...
            'cfgFBCSP',...
            'CaseCfg',...
            '-v7.3');
        % 'FBCSP_Dataset',...
    catch ME

        fprintf('\n');
        fprintf('================================\n');
        fprintf('CASE FAILED\n');
        fprintf('Case : %s\n',CaseCfg.name);
        fprintf('%s\n',ME.message);
        fprintf('================================\n');

    end
end