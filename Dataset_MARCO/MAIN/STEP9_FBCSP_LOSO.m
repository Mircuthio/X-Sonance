%% =========================================================================
% STEP9_FBCSP_LOSO
% MAIN_FBCSP_LOSO_STEP9
%% =========================================================================
% PIPELINE
%
% subj_list
%     ↓
% build_fbcsp_dataset
%
%     ↓
% apply_fbcsp_filterbank
%
%         eeg  → eegFB
%
%     ↓
% LOSO Split
%
%         Test Subject  = Subject i
%         Train Subjects = All Remaining Subjects
%
%     ↓
% CSP Model (TRAIN ONLY)
%
%     ↓
% CSP Encode (TRAIN / TEST)
%
%     ↓
% MI Model (TRAIN ONLY)
%
%     ↓
% MI Encode (TRAIN / TEST)
%
%     ↓
% Classifier Model (TRAIN ONLY)
%
%         QDA
%         KNN
%         NB
%         SVC
%
%     ↓
% Prediction (TRAIN / TEST)
%
%     ↓
% Accuracy
% Balanced Accuracy
% Confusion Matrix
%
%
% NOTES
%
% - FilterBank is applied once on the complete dataset before
%   train/test splitting.
%
% - CSP is estimated ONLY on training subjects.
%
% - MI feature selection is estimated ONLY on training subjects.
%
% - No information from the test subject contributes to model training.
%
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
outputdirCASE = 'STEP9_FBCSP_LOSO\EPOCHED';

Cases = build_fbcsp_cases();
numiCase =1;
for iCase = 1:numel(numiCase)
    try
        CaseCfg = Cases(numiCase(iCase));

        outdir = fullfile( ...
            step2_indir,...
            outputdirCASE,...
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

        cfgFBCSP.class_labels = ...
            CaseCfg.class_labels;

        cfgFBCSP.class_codes = ...
            CaseCfg.class_codes;

        %% ------------------------------------------------------------
        % TIME WINDOW
        %% ------------------------------------------------------------

        cfgFBCSP.time_window = CaseCfg.time_window;

        %% ------------------------------------------------------------
        % SUBEPOCHS
        %% ------------------------------------------------------------
        cfgFBCSP.useSubEpochs = true;
            % CaseCfg.useSubEpochs;

        cfgFBCSP.subEpochLength = 0.1;
            % CaseCfg.subEpochLength;

        cfgFBCSP.subEpochOverlap = 50;
            % CaseCfg.subEpochOverlap;
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

        cfgFBCSP.useMI = CaseCfg.useMI;

        cfgFBCSP.mi_k = CaseCfg.mi_k;

        %% ------------------------------------------------------------
        % CLASSIFIERS
        %% ------------------------------------------------------------

        cfgFBCSP.classifiers = ...
            CaseCfg.classifiers;

        %% ------------------------------------------------------------
        % DATASET FIELDS
        %% ------------------------------------------------------------

        cfgFBCSP.eventField = 'eventLabel';
        cfgFBCSP.subjectField = 'subj_id';

        %% ------------------------------------------------------------
        % SIGNAL FIELD
        %% ------------------------------------------------------------

        cfgFBCSP.signalField = 'eegFB';
        %% ------------------------------------------------------------
        % LOSO PARAMETERS
        %% ------------------------------------------------------------

        cfgFBCSP.kfold = 4;
        cfgFBCSP.numIterations = 100;


        %% ============================================================
        % BUILD DATASET
        %% ============================================================

        FBCSP_Dataset = build_fbcsp_dataset( ...
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
                FBCSP_Dataset.srate;

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
        % SUBJECTS
        %% ============================================================

        subjectIDs = unique( ...
            {FBCSP_Dataset.trials.subjectID});

        nSubjects = numel(subjectIDs);

        fprintf('\n');
        fprintf('================================\n');
        fprintf('LOSO SETUP\n');
        fprintf('================================\n');

        fprintf('Subjects: %d\n',nSubjects);

        %% ============================================================
        % VALIDATION STRATEGY
        %% ============================================================
        %
        % LOSO:
        %  Subject 1 → Test
        %  Subjects 2..N → Train
        %
        %  Subject 2 → Test
        %  Remaining Subjects → Train
        %

        %% ============================================================
        % LOSO
        %% ============================================================

        Results_LOSO = struct();

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

            for iSub = 1:nSubjects

                testSubject = ...
                    subjectIDs{iSub};

                fprintf('\n');
                fprintf('--------------------------------\n');
                fprintf('LOSO FOLD %d/%d\n', ...
                    iSub,nSubjects);

                fprintf('Test Subject: %s\n', ...
                    testSubject);

                [TrainTrials,...
                    TestTrials] = ...
                    split_loso_trials( ...
                    FBCSP_Dataset,...
                    testSubject);

                %% ------------------------------------------------------------
                % FEATURE EXTRACTION
                %% ------------------------------------------------------------
                Features = ...
                    run_fbcsp_features( ...
                    TrainTrials,...
                    TestTrials,...
                    cfgFBCSP);

                %% ------------------------------------------------------------
                % CLASSIFIER
                %% ------------------------------------------------------------
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

                %% ------------------------------------------------------------
                % PREDICTION
                %% ------------------------------------------------------------
                parPredict = ...
                    mdlPredictParams();

                parPredict.InField = Features.SignalField;

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

                %% ------------------------------------------------------------
                % LABELS
                %% ------------------------------------------------------------
                Ytrain_true = ...
                    [TrainEEG.trialType]';

                Ytrain_pred = ...
                    [TrainEEG.(PredField)]';

                Ytest_true = ...
                    [TestEEG.trialType]';

                Ytest_pred = ...
                    [TestEEG.(PredField)]';

                %% ------------------------------------------------------------
                % METRICS
                %% ------------------------------------------------------------
                TrainMetrics = ...
                    compute_classification_metrics( ...
                    Ytrain_true,...
                    Ytrain_pred);

                TestMetrics = ...
                    compute_classification_metrics( ...
                    Ytest_true,...
                    Ytest_pred);

                %% ------------------------------------------------------------
                % STORE RESULTS
                %% ------------------------------------------------------------
                FoldResult = struct();

                FoldResult.classifier = ...
                    classifierName;

                FoldResult.testSubjects = ...
                    unique({TestTrials.subjectID});

                FoldResult.trainSubjects = ...
                    unique({TrainTrials.subjectID});

                FoldResult.nTrainTrials = ...
                    numel(TrainTrials);

                FoldResult.nTestTrials = ...
                    numel(TestTrials);

                FoldResult.nFeatures = ...
                    Features.nFeatures;

                % FoldResult.Features = ...
                %     Features;

                FoldResult.CSPModel = ...
                    Features.CSPModel;

                FoldResult.MIModel = ...
                    Features.MIModel;

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
        % SUMMARY
        %% ============================================================

        for iClf = 1:numel(cfgFBCSP.classifiers)

            classifierName = ...
                cfgFBCSP.classifiers{iClf};

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

            Results_LOSO.(classifierName).cfg = cfgFBCSP;

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

            fprintf('Mean Accuracy          : %.2f %%\n', ...
                100*Results_LOSO.(classifierName).MeanAccuracy);

            fprintf('Std Accuracy           : %.2f %%\n', ...
                100*Results_LOSO.(classifierName).StdAccuracy);

            fprintf('Mean BalancedAccuracy  : %.2f %%\n', ...
                100*Results_LOSO.(classifierName).MeanBalancedAccuracy);

            fprintf('Std BalancedAccuracy   : %.2f %%\n', ...
                100*Results_LOSO.(classifierName).StdBalancedAccuracy);

            fprintf('Mean F1               : %.4f\n', ...
                Results_LOSO.(classifierName).MeanF1);

            fprintf('Std F1                : %.4f\n', ...
                Results_LOSO.(classifierName).StdF1);

            fprintf('Mean MCC              : %.4f\n', ...
                Results_LOSO.(classifierName).MeanMCC);

            fprintf('Std MCC               : %.4f\n', ...
                Results_LOSO.(classifierName).StdMCC);
        end

        %% ============================================================
        % SAVE
        %% ============================================================
        save( ...
            fullfile(outdir,...
            sprintf('%s.mat', ...
            CaseCfg.name)),...
            'Results_LOSO',...
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