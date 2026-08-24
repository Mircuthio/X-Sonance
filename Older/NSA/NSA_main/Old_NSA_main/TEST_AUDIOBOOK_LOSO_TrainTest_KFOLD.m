%% TEST_AUDIOBOOK_LOSO_TrainTest

clear; close all;

par.irng = 10;
rng(par.irng);
EEG_all = struct();
result = struct();
for indsub=1:21
    signal_name                     = 'eeg';
    signal_process                  = 'CSP';

    %% Extract and Arrange Data
    par.extractAudiobook.signal_name    = signal_name;
    par.extractAudiobook.InField        = 'train';
    par.extractAudiobook.it_start       = 0;
    par.extractAudiobook.it_end         = 10;
    par.extractAudiobook.multiEpoch     = true;
    [EEG_trials_sub,fsample]            = extractAudiobook(indsub,par.extractAudiobook);

    % Time Interpolation and selection Trials
    par.TimeSelect               = TimeSelectParams;
    par.TimeSelect.t1            = 0.0; % in s from ZeroEvent time
    par.TimeSelect.t2            = 600.0; % in s from ZeroEvent time
    par.TimeSelect.InField       = signal_name;
    par.TimeSelect.OutField      = signal_name;

    EEG_trials_sub = TimeSelect(EEG_trials_sub,par.TimeSelect);

    % Filter Bank
    par.FilterBankCompute            = FilterBankComputeParams();
    par.FilterBankCompute.InField    = signal_name;
    par.FilterBankCompute.OutField   = signal_name;
    % par.FilterBankCompute.f_min      = 0.1; % min frequency range in Hz
    % par.FilterBankCompute.f_max      = 30;
    par.FilterBankCompute.FilterBank = 'One';
    par.FilterBankCompute.fsample    = fsample;

    %% epochCompute
    par.epochCompute                    = epochComputeParams();
    par.epochCompute.InField            = signal_name;
    par.epochCompute.OutField           = signal_name;
    par.epochCompute.fample             = fsample;
    par.epochCompute.t_epoch            = 2.5; % duration of a single intervals in s
    par.epochCompute.overlap_percent    = 0; % in percentage

    par.exec.funname ={'FilterBankCompute','epochCompute'};
    [EEG_trials_sub,out_trials] = run_trials(EEG_trials_sub,par);


    itr1 = round(out_trials.epochCompute.time_intervals(:,1),2);
    itr2 = round(out_trials.epochCompute.time_intervals(:,2),2);

    par.multiEEG.Infield = signal_name;
    EEG_trials_sub = multiEEG(EEG_trials_sub,par.multiEEG);

    EEG_all(indsub).data = EEG_trials_sub;
end
%% Training Test split
for iLoso = 1:length(EEG_all)
    % Test Subject
    EEG_testAll = EEG_all(iLoso).data;
    % select 20% Test Subject to Train Set
    % kfoldSplit = 0.2;
    kfoldSplit = 5;
    labs = [EEG_testAll.trialType]'; %true labels
    cvp = cvpartition(labs,'kfold',kfoldSplit,'Stratify',true);
    % cvp = cvpartition(labs,'HoldOut', kfoldSplit, 'Stratify', true);
    for i=1:kfoldSplit
        indices = training(cvp,i);
        test = (indices == 0);
        train = ~test;
        EEG_testTrain = EEG_testAll(train);
        EEG_test = EEG_testAll(test);

        % Train Subject
        EEG_dataTrain = EEG_all([1:iLoso-1, iLoso+1:end]);

        for nfield   = fieldnames(EEG_dataTrain)'
            namefield   = nfield{1};
            cellsfield  = {EEG_dataTrain.(namefield)};
            EEG_train    = cat(1,cellsfield{:});
        end

        for iTr=1:length(EEG_train)
            EEG_train(iTr).trialId = iTr;
        end

        resQDA          = struct();

        outQDA          = struct();

        LabpredictQDA   = struct();

        Label_train     = struct();

        %% Step 2. perform CSP
        % CSP Dictionary evaluation on train
        par.cspModel                  = cspModelParams;
        par.cspModel.m                = 2;
        par.cspModel.InField          = signal_name;
        par.cspModel.OutField         = signal_process;

        [~,out.cspModel] = cspModel(EEG_train,par.cspModel);

        % CSP Encode on train and test data
        par.cspEncode                  = cspEncodeParams;
        par.cspEncode.InField          = signal_name;
        par.cspEncode.OutField         = signal_process;
        par.cspEncode.W                = out.cspModel.W;

        par.exec.funname ={'cspEncode'};
        EEG_train = run_trials(EEG_train,par); %Manifold
        EEG_testTrain = run_trials(EEG_testTrain,par);
        EEG_test = run_trials(EEG_test,par);

        TotalFeatures = size(EEG_test(1).(signal_process),2);

        % Mutual Information
        par.miModel               = miModelParams;
        par.miModel.InField       = signal_process;
        par.miModel.m             = par.cspModel.m;
        % par.miModel.k             = 5;

        [~, out.miModel]=miModel(EEG_train,par.miModel);

        par.miEncode               = miEncodeParams;
        par.miEncode.InField       = signal_process;
        par.miEncode.OutField      = signal_process;
        par.miEncode.nclass        = unique([EEG_train.trialType]');  %Manifold
        par.miEncode.IndMI         = out.miModel.IndMI;

        par.exec.funname ={'miEncode'};
        [EEG_train, out]=run_trials(EEG_train,par);
        V_train = out.miEncode.V;
        [EEG_testTrain, out]=run_trials(EEG_testTrain,par);
        V_testTrain = out.miEncode.V;
        [EEG_test, out]=run_trials(EEG_test,par);
        V_test = out.miEncode.V;

        %% Step 3. Model Classification on CSP

        % qdaModel
        par.qdaModel                      = qdaModelParams;
        par.qdaModel.InField              = 'CSP';
        par.qdaModel.numIterations        = 100;
        par.qdaModel.kfold                = 5;
        [~, outQDA.Iter]                  = qdaModel(EEG_testTrain,par.qdaModel);

        % predictQDA
        par.mdlPredict                  = mdlPredictParams;
        par.mdlPredict.InField          = 'CSP';
        par.mdlPredict.OutField         = 'QDApred';
        par.mdlPredict.ProbField        = 'QDAProb';
        par.mdlPredict.mdl              = outQDA.Iter.mdl;
        [EEG_testTrain,resQDA.train]        = mdlPredict(EEG_testTrain,par.mdlPredict);
        [EEG_test,resQDA.test]          = mdlPredict(EEG_test,par.mdlPredict);

        %% Accuracy and Kappa

        AccuracyQDA_train = resQDA.train.Accuracy;
        accuracyQDA_class_train = resQDA.train.Accuracy_class;

        AccuracyQDA_test = resQDA.test.Accuracy;
        accuracyQDA_class_test = resQDA.test.Accuracy_class;

        % QDA save result
        resultQDA.train.Accuracy = AccuracyQDA_train;
        resultQDA.train.Accuracy_class = accuracyQDA_class_train;
        resultQDA.test.Accuracy = AccuracyQDA_test;
        resultQDA.test.Accuracy_class = accuracyQDA_class_test;
        resultQDA.train.kappaValue = NaN;
        resultQDA.test.kappaValue = NaN;

        % Save Result
        %% create Tab Result
        params.createStructResult.subjTrain  = 'All';
        params.createStructResult.subjTest   = iLoso;
        params.createStructResult.method     = 'CSP';
        params.createStructResult.file       = 'Audio';
        params.createStructResult.train_name = 'AudioTrain';
        params.createStructResult.train_tr1  = itr1;
        params.createStructResult.train_tr2  = itr2;
        params.createStructResult.test_name  = 'Audiotest';
        params.createStructResult.test_ts1   = 0;
        params.createStructResult.test_ts2   = 2.5;
        params.createStructResult.m             = par.cspModel.m;
        params.createStructResult.class         = {1,2};
        params.createStructResult.irng          = par.irng;
        params.createStructResult.Filter        = par.FilterBankCompute.FilterBank;
        params.createStructResult.n_Features    = size(EEG_train(1).(signal_process),2);
        params.createStructResult.indMi         = par.miModel.k;
        params.createStructResult.attenuation   = par.FilterBankCompute.attenuation;
        params.createStructResult.TotalFeatures = TotalFeatures;
        params.createStructResult.kfold         = kfoldSplit;
        params.createStructResult.ProbMean      = 100*mean([EEG_test.QDAProb],2)';


        params.createStructResult.kappa = 0;
        [~,ResultQDA_Acc,ResultQDA_class_Acc] = createStructResult(resultQDA,params.createStructResult);

        saveDir = pwd;

        % Update Tab Result
        params.updateTab.dir        = saveDir;
        params.updateTab.name       = 'FBCSP_AudBLOSO_TrainTest25_KFoldPC';
        params.updateTab.sheetnames = 'QDA';

        updated_Result_tableAccQDA = updateTab(ResultQDA_Acc,params.updateTab);


        params.updateTab.name     = 'FBCSP_AudBLOSO_TrainTest_KFoldPC25_Class';
        params.updateTab.sheetnames = 'QDA';
        updated_Resultclass_tableAccQDA = updateTab(ResultQDA_class_Acc,params.updateTab);


        result(iLoso).QDA(i).train.Accuracy = resQDA.train.Accuracy;
        result(iLoso).QDA(i).train.Accuracy_class = resQDA.train.Accuracy_class;
        result(iLoso).QDA(i).test.Accuracy = AccuracyQDA_test;
        result(iLoso).QDA(i).test.Accuracy_class = accuracyQDA_class_test;
        result(iLoso).QDA(i).train.kappaValue = resQDA.train.kappaValue;
        result(iLoso).QDA(i).test.kappaValue = resQDA.test.kappaValue;
        result(iLoso).QDA(i).train.TrialType = [EEG_testTrain.trialType]';
        result(iLoso).QDA(i).train.pred = [EEG_testTrain.QDApred]';
        result(iLoso).QDA(i).test.TrialType = [EEG_test.trialType]';
        result(iLoso).QDA(i).test.pred = [EEG_test.QDApred]';
        result(iLoso).QDA(i).test.Probability = [EEG_test.QDAProb]';
    end
end
save(fullfile(saveDir, 'FBCSP_AudBLOSO_TrainTest_KFoldPC25.mat'), 'result');