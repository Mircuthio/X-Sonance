function Features = run_masterdataset_features( ...
    Xtrain,...
    Ytrain,...
    Xtest,...
    Ytest)
%% ============================================================
% RUN MASTERDATASET FEATURES
%
% Convert feature matrices into EEG-like structures
% compatible with:
%
%   run_classifier_fold
%   mdlPredict
%
%% ============================================================
%% ============================================================
% INPUT VALIDATION
%% ============================================================
assert(~isempty(Xtrain), ...
    'Xtrain is empty');
assert(~isempty(Xtest), ...
    'Xtest is empty');

assert(size(Xtrain,1) == numel(Ytrain), ...
    'Xtrain / Ytrain size mismatch');
assert(size(Xtest,1) == numel(Ytest), ...
    'Xtest / Ytest size mismatch');

assert( ...
    size(Xtrain,2) == size(Xtest,2), ...
    'Feature mismatch between train and test');

%% ============================================================
% DIMENSIONS
%% ============================================================
nTrain = size(Xtrain,1);
nTest  = size(Xtest,1);
nFeatures = size(Xtrain,2);

%% ============================================================
% SIGNAL FIELD
%% ============================================================
signal_process = 'FEATURES';

%% ============================================================
% PREALLOCATION
%% ============================================================
TrainTemplate = struct( ...
    'FEATURES',     [], ...
    'timeFEATURES', [], ...
    'trialType',    []);

TestTemplate = TrainTemplate;

TrainEEG = repmat(TrainTemplate,nTrain,1);
TestEEG  = repmat(TestTemplate,nTest,1);

%% ============================================================
% BUILD TRAIN EEG
%% ============================================================
for iTrial = 1:nTrain
    TrainEEG(iTrial).FEATURES = ...
        Xtrain(iTrial,:);
    TrainEEG(iTrial).timeFEATURES = ...
        1:nFeatures;
    TrainEEG(iTrial).trialType = ...
        Ytrain(iTrial);
end

%% ============================================================
% BUILD TEST EEG
%% ============================================================
for iTrial = 1:nTest
    TestEEG(iTrial).FEATURES = ...
        Xtest(iTrial,:);
    TestEEG(iTrial).timeFEATURES = ...
        1:nFeatures;
    TestEEG(iTrial).trialType = ...
        Ytest(iTrial);
end

%% ============================================================
% FEATURE MATRICES
%% ============================================================
Features = struct();

%% ------------------------------------------------------------
% IDENTIFIERS
%% ------------------------------------------------------------
Features.FeatureExtractor = ...
    'MASTERDATASET';
Features.FeatureField = ...
    signal_process;
Features.SignalField = ...
    signal_process;

%% ------------------------------------------------------------
% MATRICES
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
% DATASET INFO
%% ------------------------------------------------------------
Features.nTrainTrials = ...
    nTrain;
Features.nTestTrials = ...
    nTest;
Features.nFeatures = ...
    nFeatures;

%% ============================================================
% SUMMARY
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('MASTERDATASET FEATURES\n');
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