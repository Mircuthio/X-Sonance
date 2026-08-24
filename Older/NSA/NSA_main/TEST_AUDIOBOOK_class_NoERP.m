%% TEST_AUDIOBOOK_class_NoERP.m

clear; close all;

par.irng = 10;
rng(par.irng);

load("Delay_ALL.mat");

%% Extract Test Sound

EEG_Sound_all = struct();

starting_time = 0;
ending_time = 2.5;

signal_name                     = 'eeg';
signal_process                  = 'CSP';

% idsub = [2:6,8:18,21];
idsub = 1:21;
EEG_manifold = struct();
for indsub=1:length(idsub)
    signal_name                     = 'eeg';
    signal_process                  = 'CSP';

    %% Extract and Arrange Data
    par.extractAudiobook.signal_name    = signal_name;
    par.extractAudiobook.InField        = 'train';
    par.extractAudiobook.it_start       = 0;
    par.extractAudiobook.it_end         = 10;
    par.extractAudiobook.multiEpoch     = true;
    [EEG_trialsAudio_sub,fsample]       = extractAudiobook(idsub(indsub),par.extractAudiobook);

    % Time Interpolation and selection Trials
    par.TimeSelect               = TimeSelectParams;
    par.TimeSelect.t1            = 0.0; % in s from ZeroEvent time
    par.TimeSelect.t2            = 600.0; % in s from ZeroEvent time
    par.TimeSelect.InField       = signal_name;
    par.TimeSelect.OutField      = signal_name;

    EEG_trialsAudio_sub = TimeSelect(EEG_trialsAudio_sub,par.TimeSelect);

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
    [EEG_trialsAudio_sub,out_trials] = run_trials(EEG_trialsAudio_sub,par);


    itr1 = round(out_trials.epochCompute.time_intervals(:,1),2);
    itr2 = round(out_trials.epochCompute.time_intervals(:,2),2);

    par.multiEEG.Infield = signal_name;
    EEG_trialsAudio_sub = multiEEG(EEG_trialsAudio_sub,par.multiEEG);

    EEG_manifold(indsub).data = EEG_trialsAudio_sub;
end
% labels_manifold = unique([EEG_manifold(1).data.trialType]);
% EEG_manifold_Lab = struct();
% for num_lab = 1:length(labels_manifold)
%     for ind_sub=1:length(EEG_manifold)
%         EEG_audio_sub = EEG_manifold(ind_sub).data;
%         idx_lab = find([EEG_audio_sub.trialType]==num_lab);
%         EEG_manifold_Lab(num_lab).sub(ind_sub).data = EEG_audio_sub(idx_lab);
%         EEG_manifold_Lab(num_lab).sub(ind_sub).trialType = num_lab;
%     end
% end
% 
% EEG_manifold_meanLab = struct();
% EEG_manifold_mean =struct();
% for num_lab=1:length(EEG_manifold_Lab)
%     EEG_manifold_subLab = EEG_manifold_Lab(num_lab).sub;
%     for n_subj = 1:length(EEG_manifold_subLab)
%         EEG_manifold_sub = EEG_manifold_subLab(n_subj).data;
%         for n_trial = 1:length(EEG_manifold_sub)
%             EEG_manifold_mean(n_trial).eeg(:,:,n_subj) = EEG_manifold_sub(n_trial).eeg;
%             EEG_manifold_mean(n_trial).trialType = num_lab;
%             EEG_manifold_mean(n_trial).timeeeg = EEG_manifold_sub(n_trial).timeeeg;
%         end
%     end
%     EEG_manifold_meanLab(num_lab).data = EEG_manifold_mean;
% end
% 
% EEG_manifold_meanALL = [EEG_manifold_meanLab(:).data];
% EEG_manifold_final = struct();
% for n_trials = 1:length(EEG_manifold_meanALL)
%     eeg_app = EEG_manifold_meanALL(n_trials).eeg;
%     EEG_manifold_final(n_trials).eeg = mean(eeg_app, 3);
%     EEG_manifold_final(n_trials).trialType = EEG_manifold_meanALL(n_trials).trialType;
%     EEG_manifold_final(n_trials).timeeeg = EEG_manifold_meanALL(n_trials).timeeeg;
% end

for nfield   = fieldnames(EEG_manifold)'
    namefield   = nfield{1};
    cellsfield  = {EEG_manifold.(namefield)};
    EEG_manifold    = cat(1,cellsfield{:});
end

for iTr=1:length(EEG_manifold)
    EEG_manifold(iTr).trialId = iTr;
end
EEG_manifold_final = EEG_manifold;


%% Step 2. perform CSP
% CSP Dictionary evaluation on train
par.cspModel                  = cspModelParams;
par.cspModel.m                = 4;
par.cspModel.InField          = signal_name;
par.cspModel.OutField         = signal_process;

[~,out.cspModel] = cspModel(EEG_manifold_final,par.cspModel);

% CSP Encode on train and test data
par.cspEncode                  = cspEncodeParams;
par.cspEncode.InField          = signal_name;
par.cspEncode.OutField         = signal_process;
par.cspEncode.W                = out.cspModel.W;

par.exec.funname ={'cspEncode'};
EEG_manifold_final = run_trials(EEG_manifold_final,par);

TotalFeatures = size(EEG_manifold_final(1).(signal_process),2);

% Mutual Information
par.miModel               = miModelParams;
par.miModel.InField       = signal_process;
par.miModel.m             = par.cspModel.m;
par.miModel.k             = 5;

[~, out.miModel]=miModel(EEG_manifold_final,par.miModel);

par.miEncode               = miEncodeParams;
par.miEncode.InField       = signal_process;
par.miEncode.OutField      = signal_process;
par.miEncode.nclass        = unique([EEG_manifold_final.trialType]');
par.miEncode.IndMI         = out.miModel.IndMI;

par.exec.funname ={'miEncode'};
[EEG_manifold_final, out]=run_trials(EEG_manifold_final,par);
% [EEG_manifold_final,resQDAManifold.test]  = mdlPredict(EEG_manifold_final,par.mdlPredict);
    


EEG_train = EEG_manifold_final;

resQDA          = struct();

outQDA          = struct();

resKNN          = struct();

outKNN          = struct();

resSVC          = struct();

outSVC          = struct();

%% Step 3. Model identification on Train

% qdaModel
par.qdaModel                      = qdaModelParams;
par.qdaModel.InField              = 'CSP';
par.qdaModel.numIterations        = 100;
par.qdaModel.kfold                = 5;
[~, outQDA.Iter]                  = qdaModel(EEG_train,par.qdaModel);

% % knnModel
% par.knnModel                      = knnModelParams;
% par.knnModel.InField              = 'CSP';
% par.knnModel.numIterations        = 100;
% par.knnModel.kfold                = 5;
% [~, outKNN.Iter]                  = knnModel(EEG_train,par.knnModel);
% 
% % svcModel
% par.svcModel                      = svcModelParams;
% par.svcModel.InField              = 'CSP';
% par.svcModel.numIterations        = 100;
% par.svcModel.kfold                = 5;
% [~, outSVC.Iter]                  = svcModel(EEG_train,par.svcModel);


class_analysis = {2};
load("badTrials.mat")
% badTrialsBlocchi = splitBadTrialsRandom(badTrials, 4, 40);
for indsubSound = 1:length(idsub)
    %% Extract and Arrange Data Sound
    par.extractSound.signal_name    = signal_name;
    par.extractSound.InField        = 'train';
    par.extractSound.it_end         = 2.5;
    par.extractSound.multiEpoch     = true;
    [EEG_trialsSound_sub,fsample]   = extractSound(idsub(indsubSound),par.extractSound);
    
   
    %% Extract Stimulus data
    delay_sub = Delay_ALL(indsubSound).trials;
    t_start = NaN(length(EEG_trialsSound_sub),1);
    for iTr=1:length(EEG_trialsSound_sub)
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
    [EEG_trialsSound_sub,out_trialsSound] = run_trials(EEG_trialsSound_sub,par);

    % remapTypes
    par.remapTypes           = remapTypesParams();
    par.remapTypes.selection = class_analysis;

    StartClass = unique([EEG_trialsSound_sub.trialType]);

    par.exec.funname ={'remapTypes'};
    [EEG_trialsSound_sub,~] = run_trials(EEG_trialsSound_sub,par);
    

    badT = badTrials(indsubSound).trials;
    if ~isempty(badT)

        allIDs = [EEG_trialsSound_sub.trialId];

        idxRemove = ismember(allIDs, badT);

        EEG_trialsSound_sub(idxRemove) = [];
    end

    its1 = starting_time;
    its2 = ending_time;

    % Filter Bank
    par.FilterBankCompute            = FilterBankComputeParams();
    par.FilterBankCompute.InField    = signal_name;
    par.FilterBankCompute.OutField   = signal_name;
    par.FilterBankCompute.f_min      = 0.1; % min frequency range in Hz
    par.FilterBankCompute.f_max      = 30; % max frequency range in Hz
    par.FilterBankCompute.FilterBank = 'One';
    par.FilterBankCompute.fsample    = fsample;

    %% epochCompute
    par.epochCompute                    = epochComputeParams();
    par.epochCompute.InField            = signal_name;
    par.epochCompute.OutField           = signal_name;
    par.epochCompute.fample             = fsample;
    par.epochCompute.t_epoch            = 2.5; % duration of a single intervals in s
    par.epochCompute.overlap_percent    = 0; % in percentage

    % par.exec.funname ={'remapTypes','FilterBankCompute','epochCompute'};
    % [EEG_trialsSound_sub,out_trials] = run_trials(EEG_trialsSound_sub,par);

    par.exec.funname ={'FilterBankCompute','epochCompute'};
    [EEG_trialsSound_sub,out_trials] = run_trials(EEG_trialsSound_sub,par);

    Label_testStart = [EEG_trialsSound_sub.trialType];

    end_class = unique([EEG_trialsSound_sub.trialType]);

    par.multiEEG.Infield = signal_name;
    EEG_trialsSound_sub = multiEEG(EEG_trialsSound_sub,par.multiEEG);

    EEG_Sound_all(indsubSound).data = EEG_trialsSound_sub;

end


labels = unique([EEG_Sound_all(1).data.trialType]);
EEG_Lab = struct();
for num_lab = 1:length(labels)
    for ind_sub=1:length(EEG_Sound_all)
        EEG_sound_sub = EEG_Sound_all(ind_sub).data;
        idx_lab = find([EEG_sound_sub.trialType]==num_lab);
        EEG_Lab(num_lab).sub(ind_sub).data = EEG_sound_sub(idx_lab);
        EEG_Lab(num_lab).sub(ind_sub).trialType = num_lab;
    end
end

EEG_meanLab = struct();
EEG_mean =struct();
for num_lab=1:length(EEG_Lab)
    EEG_subLab = EEG_Lab(num_lab).sub;
    for n_subj = 1:length(EEG_subLab)
        EEG_sub = EEG_subLab(n_subj).data;
        for n_trial = 1:length(EEG_sub)
            EEG_mean(n_trial).eeg(:,:,n_subj) = EEG_sub(n_trial).eeg;
            EEG_mean(n_trial).trialType = num_lab;
            EEG_mean(n_trial).timeeeg = EEG_sub(n_trial).timeeeg;
        end
    end
    EEG_meanLab(num_lab).data = EEG_mean;
end

EEG_meanALL = [EEG_meanLab(:).data];

EEG_final = struct();
for n_trials = 1:length(EEG_meanALL)
    eeg_app = EEG_meanALL(n_trials).eeg;
    EEG_final(n_trials).eeg = mean(eeg_app, 3);
    EEG_final(n_trials).trialType = EEG_meanALL(n_trials).trialType;
    EEG_final(n_trials).timeeeg = EEG_meanALL(n_trials).timeeeg;
end

par.exec.funname ={'cspEncode','miEncode'};
EEG_final = run_trials(EEG_final,par);
result = struct();
for n_class = 1:length(unique([EEG_final.trialType]))
    EEG_test = EEG_final([EEG_final.trialType]==n_class);
    %% Preditcion of model on TEST
    % predictQDA
    par.mdlPredict                  = mdlPredictParams;
    par.mdlPredict.InField          = 'CSP';
    par.mdlPredict.OutField         = 'QDApred';
    par.mdlPredict.ProbField        = 'QDAProb';
    par.mdlPredict.mdl              = outQDA.Iter.mdl;
    [EEG_train,resQDA.train]        = mdlPredict(EEG_train,par.mdlPredict);
    [EEG_test,resQDA.test]          = mdlPredict(EEG_test,par.mdlPredict);
    

    % % predictKNN
    % par.mdlPredict                  = mdlPredictParams;
    % par.mdlPredict.InField          = 'CSP';
    % par.mdlPredict.OutField         = 'KNNpred';
    % par.mdlPredict.ProbField        = 'KNNProb';
    % par.mdlPredict.mdl              = outKNN.Iter.mdl;
    % [EEG_train,resKNN.train]        = mdlPredict(EEG_train,par.mdlPredict);
    % [EEG_test,resKNN.test]          = mdlPredict(EEG_test,par.mdlPredict);

    % % predictSVC
    % par.mdlPredict                  = mdlPredictParams;
    % par.mdlPredict.InField          = 'CSP';
    % par.mdlPredict.OutField         = 'SVCpred';
    % par.mdlPredict.ProbField        = 'SVCProb';
    % par.mdlPredict.mdl              = outSVC.Iter.mdl;
    % [EEG_train,resSVC.train]        = mdlPredict(EEG_train,par.mdlPredict);
    % [EEG_test,resSVC.test]          = mdlPredict(EEG_test,par.mdlPredict);
    
    for n_trials = 1:length(EEG_test)
        result(n_class).QDA(n_trials).QDApred = EEG_test(n_trials).QDApred;
        result(n_class).QDA(n_trials).QDAProb = EEG_test(n_trials).QDAProb;

        % result(n_class).KNN(n_trials).KNNpred = EEG_test(n_trials).KNNpred;
        % result(n_class).KNN(n_trials).KNNProb = EEG_test(n_trials).KNNProb;

        % result(n_class).SVC(n_trials).SVCpred = EEG_test(n_trials).SVCpred;
        % result(n_class).SVC(n_trials).SVCProb = EEG_test(n_trials).SVCProb;
    end
    result(n_class).AccuracyQDA = resQDA.test.Accuracy;
    result(n_class).Accuracy_classQDA = resQDA.test.Accuracy_class;
    result(n_class).Accuracy_CmatrixQDA = resQDA.test.Cmatrxix;

    % result(n_class).AccuracyKNN = resKNN.test.Accuracy;
    % result(n_class).Accuracy_classKNN = resKNN.test.Accuracy_class;
    % result(n_class).Accuracy_CmatrixKNN = resKNN.test.Cmatrxix;

    % result(n_class).AccuracySVC = resSVC.test.Accuracy;
    % result(n_class).Accuracy_classSVC = resSVC.test.Accuracy_class;
    % result(n_class).Accuracy_CmatrixSVC = resSVC.test.Cmatrxix;
   
end

y_pred = [result.QDA.QDApred];
acc_class(1,1) = 100*sum(y_pred == 1)/length(y_pred);
acc_class(1,2) = 100-acc_class(1,1);
acc_class

acc_class = nan(5,1);
for i=1:5
    y_pred = [result(i).QDA.QDApred];
    acc_class(i,1) = 100*sum(y_pred == 1)/length(y_pred);
    acc_class(i,2) = 100-acc_class(i,1);
end
saveDir = pwd;

Result.result           = result;
Result.AccuracyClass    = acc_class;
save(fullfile(saveDir, 'Try_CLASSIFICATION_NoROI_AllSubj.mat'), 'result');

%% PROB mean
MeanPob = struct();
for n_class = 1:length(result)
    probQDA = nan(length(result(n_class).QDA),length(result));
    % probKNN = nan(length(result(n_class).QDA),length(result));
    % probSVC = nan(length(result(n_class).QDA),length(result));

    for n_trials=1:length(result(n_class).QDA)
        probQDA(n_trials,1) = result(n_class).QDA(n_trials).QDAProb(1);
        probQDA(n_trials,2) = result(n_class).QDA(n_trials).QDAProb(2);

        % probKNN(n_trials,1) = result(n_class).KNN(n_trials).KNNProb(1);
        % probKNN(n_trials,2) = result(n_class).KNN(n_trials).KNNProb(2);

        % probSVC(n_trials,1) = result(n_class).SVC(n_trials).SVCProb(1);
        % probSVC(n_trials,2) = result(n_class).SVC(n_trials).SVCProb(2);
    end

    MeanPob(n_class).QDA = mean(probQDA);
    % MeanPob(n_class).KNN = mean(probKNN);
    % MeanPob(n_class).SVC = mean(probSVC);

end
acc_class = nan(5,1);
for i=1:5
y_pred = [result(i).QDA.QDApred];
acc_class(i,1) = 100*sum(y_pred == 1)/20;
acc_class(i,2) = 100-acc_class(i,1);
end

size(EEG_test(1).CSP,2)
