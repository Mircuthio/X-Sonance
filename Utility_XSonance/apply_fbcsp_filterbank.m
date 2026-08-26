function FBCSP_Dataset = ...
    apply_fbcsp_filterbank( ...
    FBCSP_Dataset,...
    cfgFBCSP)

%% ============================================================
% INFO
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('APPLY FILTER BANK\n');
fprintf('================================\n');

%% ============================================================
% PARAMETERS
%% ============================================================

par = struct();

par.FilterBankCompute = ...
    FilterBankComputeParams();

par.FilterBankCompute.exec = false;

par.FilterBankCompute.InField = ...
    'eeg';

par.FilterBankCompute.OutField = ...
    'eegFB';

par.FilterBankCompute.FilterBank = ...
    cfgFBCSP.filterBankName;

par.FilterBankCompute.fsample = ...
    FBCSP_Dataset.trials(1).srate;

par.exec.funname = ...
    {'FilterBankCompute'};
%% ============================================================
% PREPARE Dataset
%% ============================================================

FBCSP_Dataset.trials = prepare_fbcsp_trials( ...
    FBCSP_Dataset.trials);
%% ============================================================
% COMPUTE FILTER BANK
%% ============================================================

[FBCSP_Dataset.trials,~] = ...
    run_trials( ...
    FBCSP_Dataset.trials,...
    par);

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('Trials processed: %d\n', ...
    length(FBCSP_Dataset.trials));

fprintf('FilterBank: %s\n', ...
    cfgFBCSP.filterBankName);

fprintf('--------------------------------\n');

end