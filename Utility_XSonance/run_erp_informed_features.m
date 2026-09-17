function Features = ...
    run_erp_informed_features( ...
    TrainTrials,...
    TestTrials,...
    cfgINF)

%% ============================================================
% SETTINGS
%% ============================================================

SignalField = 'ERPINF';

%% ============================================================
% TRAIN
%% ============================================================

[TrainEEG,FeatureNames] = ...
    compute_erp_informed_features( ...
    TrainTrials,...
    cfgINF,...
    SignalField);

%% ============================================================
% TEST
%% ============================================================

[TestEEG,~] = ...
    compute_erp_informed_features( ...
    TestTrials,...
    cfgINF,...
    SignalField);

%% ============================================================
% OUTPUT
%% ============================================================

Features = struct();

Features.TrainEEG = ...
    TrainEEG;

Features.TestEEG = ...
    TestEEG;

Features.SignalField = ...
    SignalField;

Features.FeatureNames = ...
    FeatureNames;

if isempty(TrainEEG)

    Features.nFeatures = 0;

else

    Features.nFeatures = ...
        numel( ...
        TrainEEG(1).(SignalField));

end

end