%% TEST_AUDIOBOOK_SOUND_MIXED

clear; close all;

par.irng = 10;
rng(par.irng);
result = struct();

load("Delay_ALL.mat");

starting_time = 0;
ending_time = 2.5;

for indsub=2:11
    signal_name                     = 'eeg';
    signal_process                  = 'CSP';
    
    %% Extract and Arrange TRAIN AUDIOBOOK                                              Data
    par.extractAudiobook.signal_name    = signal_name;
    par.extractAudiobook.InField        = 'train';
    par.extractAudiobook.it_end         = 600;
    par.extractAudiobook.multiEpoch     = true;
    [EEG_trialsAudiobook,fsample]       = extractAudiobook(indsub,par.extractAudiobook);

    % Time Interpolation and selection Trials
    par.TimeSelect               = TimeSelectParams;
    par.TimeSelect.t1            = 0.0; % in s from ZeroEvent time
    par.TimeSelect.t2            = 600.0; % in s from ZeroEvent time
    par.TimeSelect.InField       = signal_name;
    par.TimeSelect.OutField      = signal_name;

    EEG_trialsAudiobook = TimeSelect(EEG_trialsAudiobook,par.TimeSelect);

    % Filter Bank
    par.FilterBankCompute            = FilterBankComputeParams();
    par.FilterBankCompute.InField    = signal_name;
    par.FilterBankCompute.OutField   = signal_name;
    % par.FilterBankCompute.f_min      = 0.1; % min frequency range in Hz
    % par.FilterBankCompute.f_max      = 49.5;
    par.FilterBankCompute.FilterBank = 'Nine';
    par.FilterBankCompute.fsample    = fsample;

    %% epochCompute
    par.epochCompute                    = epochComputeParams();
    par.epochCompute.InField            = signal_name;
    par.epochCompute.OutField           = signal_name;
    par.epochCompute.fample             = fsample;
    par.epochCompute.t_epoch            = 2.5; % duration of a single intervals in s
    par.epochCompute.overlap_percent    = 0; % in percentage

    par.exec.funname ={'FilterBankCompute','epochCompute'};
    [EEG_trialsAudiobook,out_trials] = run_trials(EEG_trialsAudiobook,par);

    itr1 = round(out_trials.epochCompute.time_intervals(:,1),2);
    itr2 = round(out_trials.epochCompute.time_intervals(:,2),2);

    par.multiEEG.Infield = signal_name;
    EEG_trialsAudiobook = multiEEG(EEG_trialsAudiobook,par.multiEEG);

    % EEG_train = EEG_trialsAudiobook;
    
    %% Extract Test Sound
    indsubSound = [1,2,6,7,8,11,12,13,19,20,21];

    %% Extract and Arrange Data
    par.extractSound.signal_name    = signal_name;
    par.extractSound.InField        = 'train';
    par.extractSound.it_end         = 2.5;
    par.extractSound.multiEpoch     = true;
    [EEG_trialsSound,fsample]       = extractSound(indsubSound(indsub),par.extractSound);
    
    %% Extract Stimulus data
    delay_sub = Delay_ALL(indsub).trials;
    t_start = NaN(length(EEG_trialsSound),1);
    for iTr=1:length(EEG_trialsSound)
        idx = find(delay_sub(:, 1) == iTr);
        if ~isempty(idx)
            t_start(iTr) = delay_sub(idx,2);
        else
            % Altrimenti, assegna 0.8
            t_start(iTr) = starting_time;
        end
    end

    % Time Interpolation and selection Trials
    par.TimeSelectSoundDelay               = TimeSelectParams;
    par.TimeSelectSoundDelay.t1            = t_start; % in s from ZeroEvent time
    par.TimeSelectSoundDelay.t2            = t_start + ending_time; % in s from ZeroEvent time
    par.TimeSelectSoundDelay.InField       = signal_name;
    par.TimeSelectSoundDelay.OutField      = signal_name;

    par.exec.funname ={'TimeSelectSoundDelay'};
    [EEG_trialsSound,out_trialsSound] = run_trials(EEG_trialsSound,par);

    % remapTypes
    par.remapTypes           = remapTypesParams();
    par.remapTypes.selection = {1,2,3,4};

    StartClass = unique([EEG_trialsSound.trialType]);

    its1 = starting_time;
    its2 = ending_time;

    % Filter Bank
    par.FilterBankCompute            = FilterBankComputeParams();
    par.FilterBankCompute.InField    = signal_name;
    par.FilterBankCompute.OutField   = signal_name;
    % par.FilterBankCompute.f_min      = 1; % min frequency range in Hz
    % par.FilterBankCompute.f_max      = 90; % max frequency range in Hz
    par.FilterBankCompute.FilterBank = 'Nine';
    par.FilterBankCompute.fsample    = fsample;

    %% epochCompute
    par.epochCompute                    = epochComputeParams();
    par.epochCompute.InField            = signal_name;
    par.epochCompute.OutField           = signal_name;
    par.epochCompute.fample             = fsample;
    par.epochCompute.t_epoch            = 2.5; % duration of a single intervals in s
    par.epochCompute.overlap_percent    = 0; % in percentage

    par.exec.funname ={'remapTypes','FilterBankCompute'};
    [EEG_trialsSound,out_trials] = run_trials(EEG_trialsSound,par);
    
    Label_testStart = [EEG_trialsSound.trialType];

    EEG_testSound = EEG_trialsSound;
    for iTr=1:length(EEG_testSound)
        if EEG_testSound(iTr).trialType == 3
            EEG_testSound(iTr).trialType = 1;
        elseif EEG_testSound(iTr).trialType == 4
            EEG_testSound(iTr).trialType = 1;
        end
    end
    
    %% Training Test split
    k_perc = 0.2;

    class_1 = find([EEG_testSound.trialType]==1);
    class_2 = find([EEG_testSound.trialType]==2);
    
    n1=length(class_1);
    n2=length(class_2);

    % Select class 1
    train_idx_1 = 1:round(k_perc * n1); % primi k_perc% di classe 1
    test_idx_1  = (round(k_perc * n1) + 1):n1; % ultimi 100-k_perc% di classe 1

    % Select class 2
    train_idx_2 = (n1 + 1):(n1 + round(k_perc * n2)); % primi k_perc% di classe 2
    test_idx_2  = (n1 + round(k_perc * n2) + 1):(n1 + n2); % ultimi 100-k_perc% di classe 2
    

    %% train test
    EEG_trainSound = EEG_testSound([train_idx_1, train_idx_2], :);

    EEG_test = EEG_testSound([test_idx_1, test_idx_2], :);
    Label_testStart = Label_testStart([test_idx_1, test_idx_2]);
    % Trova tutti i campi unici
    commonFields = intersect(fieldnames(EEG_trialsAudiobook), fieldnames(EEG_trainSound),'stable');
    EEG_train1 = struct();
    EEG_train2 = struct();
    for i = 1:numel(EEG_trialsAudiobook)
        for j = 1:numel(commonFields)
            field = commonFields{j};
            EEG_train1(i).(field) = EEG_trialsAudiobook(i).(field);
        end
    end

    for i = 1:numel(EEG_trainSound)
        for j = 1:numel(commonFields)
            field = commonFields{j};
            EEG_train2(i).(field) = EEG_trainSound(i).(field);
        end
    end

    % Concatenazione delle strutture con solo i campi comuni
    EEG_train = [EEG_train1, EEG_train2]';
    % EEG_train = [EEG_trialsAudiobook;EEG_trainSound];
    %% Classification
    resQDA          = struct();

    outQDA          = struct();

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
    EEG_train = run_trials(EEG_train,par);
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
    par.miEncode.IndMI         = out.miModel.IndMI;

    par.exec.funname ={'miEncode'};
    [EEG_train, out]=run_trials(EEG_train,par);
    V_train = out.miEncode.V;
    [EEG_test, out]=run_trials(EEG_test,par);
    V_test = out.miEncode.V;

    %% Step 3. Model Classification on CSP

    % qdaModel
    par.qdaModel                      = qdaModelParams;
    par.qdaModel.InField              = 'CSP';
    par.qdaModel.numIterations        = 100;
    par.qdaModel.kfold                = 5;
    [~, outQDA.Iter]                  = qdaModel(EEG_train,par.qdaModel);

    % predictQDA
    par.mdlPredict                  = mdlPredictParams;
    par.mdlPredict.InField          = 'CSP';
    par.mdlPredict.OutField         = 'QDApred';
    par.mdlPredict.ProbField        = 'QDAProb';
    par.mdlPredict.mdl              = outQDA.Iter.mdl;
    [EEG_train,resQDA.train]        = mdlPredict(EEG_train,par.mdlPredict);
    [EEG_test,resQDA.test]          = mdlPredict(EEG_test,par.mdlPredict);
    
    Label_test = [EEG_test.trialType];
    Lab_testPredictQDA   = [EEG_test.QDApred];
    Label_compare = [Label_test;Label_testStart;Lab_testPredictQDA]';
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
    params.createStructResult.subj       = indsub;
    params.createStructResult.method     = 'CSP';
    params.createStructResult.file       = 'Sound';
    params.createStructResult.train_name = 'AudioSoundTrain';
    params.createStructResult.train_tr1  = itr1;
    params.createStructResult.train_tr2  = itr2;
    params.createStructResult.test_name  = 'SoundTest';
    params.createStructResult.test_ts1   = itr1;
    params.createStructResult.test_ts2   = itr2;
    params.createStructResult.m             = par.cspModel.m;
    params.createStructResult.class         = {1,2};
    params.createStructResult.irng          = par.irng;
    params.createStructResult.Filter        = par.FilterBankCompute.FilterBank;
    params.createStructResult.n_Features    = size(EEG_train(1).(signal_process),2);
    params.createStructResult.indMi         = par.miModel.k;
    params.createStructResult.attenuation   = par.FilterBankCompute.attenuation;
    params.createStructResult.TotalFeatures = TotalFeatures;
    params.createStructResult.kfold         = 0.8;

    params.createStructResult.kappa = 0;
    [~,ResultQDA_Acc,ResultQDA_class_Acc] = createStructResult(resultQDA,params.createStructResult);

    saveDir = pwd;

    % Update Tab Result
    params.updateTab.dir        = saveDir;
    params.updateTab.name       = 'FBCSP_AudioSoundMix';
    params.updateTab.sheetnames = 'QDA';

    updated_Result_tableAccQDA = updateTab(ResultQDA_Acc,params.updateTab);

    result(indsub).QDA.train.Accuracy = resQDA.train.Accuracy;
    result(indsub).QDA.train.Accuracy_class = resQDA.train.Accuracy_class;
    result(indsub).QDA.test.Accuracy = AccuracyQDA_test;
    result(indsub).QDA.test.Accuracy_class = accuracyQDA_class_test;
    result(indsub).QDA.train.kappaValue = resQDA.train.kappaValue;
    result(indsub).QDA.test.kappaValue = resQDA.test.kappaValue;
end
save(fullfile(saveDir, 'FBCSP_AudioSoundMix.mat'), 'result');