function Features = run_fbcsp_features( ...
    TrainTrials,...
    TestTrials,...
    cfgFBCSP)

%% ============================================================
% INITIALIZATION
%% ============================================================
signal_name    = cfgFBCSP.signalField;
signal_process = 'CSP';

TrainEEG = TrainTrials;
TestEEG  = TestTrials;

%% ============================================================
% INPUT VALIDATION
%% ============================================================
assert(~isempty(TrainEEG), ...
    'TrainEEG is empty');

assert(~isempty(TestEEG), ...
    'TestEEG is empty');

%% ============================================================
% CSP MODEL (TRAIN ONLY)
%% ============================================================
par.cspModel = ...
    cspModelParams();

par.cspModel.m = ...
    cfgFBCSP.csp_components;

par.cspModel.InField = ...
    signal_name;

par.cspModel.OutField = ...
    signal_process;

[~,out.cspModel] = ...
    cspModel( ...
    TrainEEG,...
    par.cspModel);

%% ============================================================
% CSP ENCODE PARAMETERS
%% ============================================================
par.cspEncode = ...
    cspEncodeParams();

par.cspEncode.InField = ...
    signal_name;

par.cspEncode.OutField = ...
    signal_process;

par.cspEncode.W = ...
    out.cspModel.W;

par.exec.funname = ...
    {'cspEncode'};

%% ============================================================
% CSP ENCODE TRAIN
%% ============================================================
TrainEEG = ...
    run_trials( ...
    TrainEEG,...
    par);

%% ============================================================
% CSP ENCODE TEST
%% ============================================================
TestEEG = ...
    run_trials( ...
    TestEEG,...
    par);

%% ============================================================
% MI MODEL (TRAIN ONLY)
%% ============================================================
par.miModel = ...
    miModelParams();

par.miModel.InField = ...
    signal_process;

par.miModel.m = ...
    par.cspModel.m;

par.miModel.k = ...
    cfgFBCSP.mi_k;

[~,out.miModel] = ...
    miModel( ...
    TrainEEG,...
    par.miModel);

%% ============================================================
% MI ENCODE PARAMETERS
%% ============================================================
par.miEncode = ...
    miEncodeParams();

par.miEncode.InField = ...
    signal_process;

par.miEncode.OutField = ...
    signal_process;

par.miEncode.nclass = ...
    unique([TrainEEG.trialType]');

par.miEncode.IndMI = ...
    out.miModel.IndMI;

par.exec.funname = ...
    {'miEncode'};

%% ============================================================
% MI ENCODE TRAIN
%% ============================================================
TrainEEG = ...
    run_trials( ...
    TrainEEG,...
    par);

%% ============================================================
% MI ENCODE TEST
%% ============================================================
TestEEG = ...
    run_trials( ...
    TestEEG,...
    par);

%% ============================================================
% DIMENSIONS
%% ============================================================
nTrain = numel(TrainEEG);
nTest  = numel(TestEEG);

assert(nTrain > 0, ...
    'No training trials available');

assert(nTest > 0, ...
    'No test trials available');

nFeatures = ...
    numel( ...
    TrainEEG(1).(signal_process));

%% ============================================================
% PREALLOCATION
%% ============================================================
Xtrain = zeros( ...
    nTrain,...
    nFeatures);

Ytrain = zeros( ...
    nTrain,...
    1);

Xtest = zeros( ...
    nTest,...
    nFeatures);

Ytest = zeros( ...
    nTest,...
    1);

%% ============================================================
% BUILD TRAIN MATRICES
%% ============================================================
for i = 1:nTrain

    Xtrain(i,:) = ...
        TrainEEG(i).(signal_process);

    Ytrain(i) = ...
        TrainEEG(i).trialType;

end

%% ============================================================
% BUILD TEST MATRICES
%% ============================================================
for i = 1:nTest

    Xtest(i,:) = ...
        TestEEG(i).(signal_process);

    Ytest(i) = ...
        TestEEG(i).trialType;

end

%% ============================================================
% CONSISTENCY CHECKS
%% ============================================================
assert( ...
    size(Xtrain,2) == size(Xtest,2), ...
    'Feature mismatch between train and test');

assert( ...
    all(isfinite(Xtrain(:))), ...
    'Non-finite values detected in Xtrain');

assert( ...
    all(isfinite(Xtest(:))), ...
    'Non-finite values detected in Xtest');

%% ============================================================
% OUTPUT
%% ============================================================
Features = struct();

%% ------------------------------------------------------------
% IDENTIFIERS
%% ------------------------------------------------------------
Features.FeatureExtractor = ...
    'FBCSP';

Features.FeatureField = ...
    signal_process;

Features.SignalField = ...
    signal_process;

%% ------------------------------------------------------------
% FEATURE MATRICES
%% ------------------------------------------------------------
Features.Xtrain = ...
    Xtrain;

Features.Ytrain = ...
    Ytrain;

Features.Xtest = ...
    Xtest;

Features.Ytest = ...
    Ytest;

%% ------------------------------------------------------------
% EEG STRUCTURES
%% ------------------------------------------------------------
Features.TrainEEG = ...
    TrainEEG;

Features.TestEEG = ...
    TestEEG;

%% ------------------------------------------------------------
% CSP
%% ------------------------------------------------------------
Features.W = ...
    out.cspModel.W;

Features.CSPModel = ...
    out.cspModel;

%% ------------------------------------------------------------
% MI
%% ------------------------------------------------------------
Features.IndMI = ...
    out.miModel.IndMI;

Features.MIModel = ...
    out.miModel;

%% ------------------------------------------------------------
% DATASET INFO
%% ------------------------------------------------------------
Features.nTrainTrials = ...
    nTrain;

Features.nTestTrials = ...
    nTest;

Features.nFeatures = ...
    nFeatures;

Features.trainSubjects = ...
    unique({TrainTrials.subjectID});

Features.testSubjects = ...
    unique({TestTrials.subjectID});

%% ============================================================
% SUMMARY
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('FBCSP FEATURES\n');
fprintf('================================\n');

fprintf('Train Trials : %d\n', ...
    Features.nTrainTrials);

fprintf('Test Trials  : %d\n', ...
    Features.nTestTrials);

fprintf('Features     : %d\n', ...
    Features.nFeatures);

fprintf('Extractor    : %s\n', ...
    Features.FeatureExtractor);

fprintf('Field        : %s\n', ...
    Features.FeatureField);

fprintf('--------------------------------\n');

end