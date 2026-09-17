TrainTrials = ERPINF_Dataset.trials(1:100);

TestTrials = ERPINF_Dataset.trials(101:120);

Features = ...
    run_erp_informed_features( ...
    TrainTrials,...
    TestTrials,...
    cfgINF);

Features.nFeatures

size(Features.TrainEEG(1).ERPINF)

size(Features.TestEEG(1).ERPINF)