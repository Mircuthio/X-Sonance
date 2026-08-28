function Features = ...
    run_bandpower_features( ...
    TrainTrials,...
    TestTrials,...
    cfgBP)

%% ============================================================
% INPUT CHECK
%% ============================================================
assert(~isempty(TrainTrials), ...
    'TrainTrials is empty');

assert(~isempty(TestTrials), ...
    'TestTrials is empty');

%% ============================================================
% INITIALIZATION
%% ============================================================
TrainEEG = TrainTrials;
TestEEG  = TestTrials;

featureField = 'BandPower';

%% ============================================================
% TRAIN FEATURES
%% ============================================================
for iTrial = 1:numel(TrainEEG)

    x = ...
        extract_bandpower_mean_features( ...
        TrainEEG(iTrial),...
        cfgBP);

    TrainEEG(iTrial).(featureField) = ...
        x(:)';

end

%% ============================================================
% TEST FEATURES
%% ============================================================
for iTrial = 1:numel(TestEEG)

    x = ...
        extract_bandpower_mean_features( ...
        TestEEG(iTrial),...
        cfgBP);

    TestEEG(iTrial).(featureField) = ...
        x(:)';

end

%% ============================================================
% MATRICES
%% ============================================================
Xtrain = ...
    vertcat( ...
    TrainEEG.(featureField));

Xtest = ...
    vertcat( ...
    TestEEG.(featureField));

%% ============================================================
% LABELS
%% ============================================================
Ytrain = ...
    [TrainEEG.trialType]';

Ytest = ...
    [TestEEG.trialType]';

%% ============================================================
% OUTPUT
%% ============================================================
Features = struct();

Features.FeatureExtractor = ...
    'BandPower';

Features.FeatureField = ...
    featureField;

Features.SignalField = ...
    featureField;

Features.TrainEEG = ...
    TrainEEG;

Features.TestEEG = ...
    TestEEG;

Features.Xtrain = ...
    Xtrain;

Features.Xtest = ...
    Xtest;

Features.Ytrain = ...
    Ytrain;

Features.Ytest = ...
    Ytest;

Features.nFeatures = ...
    size(Xtrain,2);

end