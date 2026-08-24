function FBCSP_Features = compute_fbcsp_features( ...
    FBCSP_Dataset,...
    cfgFBCSP)

%% ============================================================
% INITIALIZATION
%% ============================================================

fprintf('\n');
fprintf('Preparing FBCSP Features...\n');

%% ============================================================
% CONVERT DATASET
%% ============================================================

nTrials = FBCSP_Dataset.nTrials;

EEG_trials = struct();

for iTr = 1:nTrials

    EEG_trials(iTr).eeg = ...
        FBCSP_Dataset.trials(iTr).eeg;

    EEG_trials(iTr).timeeeg = ...
        FBCSP_Dataset.trials(iTr).time;

    EEG_trials(iTr).trialType = ...
        FBCSP_Dataset.trials(iTr).label;

    EEG_trials(iTr).subjectID = ...
        FBCSP_Dataset.trials(iTr).subjectID;

    EEG_trials(iTr).trialID = ...
        FBCSP_Dataset.trials(iTr).trialID;

end

%% ============================================================
% FILTER BANK
%% ============================================================

if cfgFBCSP.useFilterBank

    fprintf('Filter Bank...\n');

    parFB = FilterBankComputeParams();

    parFB.exec = false;

    parFB.InField = 'eeg';

    parFB.OutField = 'eegFB';

    parFB.FilterBank = 'EEGbands';

    parFB.fsample = ...
        FBCSP_Dataset.srate;

    [EEG_trials,~] = ...
        FilterBankCompute( ...
        EEG_trials,...
        parFB);

    signalField = 'eegFB';

else

    signalField = 'eeg';

end

%% ============================================================
% CSP MODEL
%% ============================================================

fprintf('CSP Model...\n');

parCSP = cspModelParams();

parCSP.exec = false;

parCSP.m = ...
    cfgFBCSP.csp_components;

parCSP.InField = ...
    signalField;

[~,outCSP] = ...
    cspModel( ...
    EEG_trials,...
    parCSP);

%% ============================================================
% CSP ENCODE
%% ============================================================

fprintf('CSP Encode...\n');

parCSPenc = cspEncodeParams();

parCSPenc.exec = false;

parCSPenc.InField = ...
    signalField;

parCSPenc.OutField = ...
    'CSP';

parCSPenc.xfld = ...
    'time';

parCSPenc.W = ...
    outCSP.W;

[EEG_trials,~] = ...
    cspEncode( ...
    EEG_trials,...
    parCSPenc);

%% ============================================================
% MUTUAL INFORMATION
%% ============================================================

if cfgFBCSP.useMI

    fprintf('Mutual Information...\n');

    parMI = miModelParams();

    parMI.exec = false;

    parMI.InField = 'CSP';

    parMI.m = ...
        cfgFBCSP.csp_components;

    parMI.k = ...
        cfgFBCSP.mi_k;

    [~,outMI] = ...
        miModel( ...
        EEG_trials,...
        parMI);

    %% --------------------------------------------------------
    % MI ENCODE
    %% --------------------------------------------------------

    fprintf('MI Encode...\n');

    parMIenc = miEncodeParams();

    parMIenc.exec = false;

    parMIenc.InField = 'CSP';

    parMIenc.OutField = 'CSP_MI';

    parMIenc.xfld = 'time';

    parMIenc.nclass = ...
        unique([EEG_trials.trialType]);

    parMIenc.IndMI = ...
        outMI.IndMI;

    [EEG_trials,~] = ...
        miEncode( ...
        EEG_trials,...
        parMIenc);

    featureField = 'CSP_MI';

else

    featureField = 'CSP';

    outMI = struct();

end

%% ============================================================
% FEATURE MATRIX
%% ============================================================

features = ...
    cat(1,EEG_trials.(featureField));

labels = ...
    [EEG_trials.trialType]';

trialIDs = ...
    [EEG_trials.trialID]';

subjectIDs = ...
    {EEG_trials.subjectID}';

%% ============================================================
% OUTPUT
%% ============================================================

FBCSP_Features = struct();

FBCSP_Features.features = ...
    features;

FBCSP_Features.labels = ...
    labels;

FBCSP_Features.trialIDs = ...
    trialIDs;

FBCSP_Features.subjectIDs = ...
    subjectIDs;

FBCSP_Features.W = ...
    outCSP.W;

if cfgFBCSP.useMI

    FBCSP_Features.IndMI = ...
        outMI.IndMI;

end

FBCSP_Features.nTrials = ...
    size(features,1);

FBCSP_Features.nFeatures = ...
    size(features,2);

FBCSP_Features.featureField = ...
    featureField;

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');

fprintf('================================\n');
fprintf('FBCSP FEATURES READY\n');
fprintf('================================\n');

fprintf('Trials   : %d\n', ...
    FBCSP_Features.nTrials);

fprintf('Features : %d\n', ...
    FBCSP_Features.nFeatures);

fprintf('Field    : %s\n', ...
    featureField);

fprintf('\n');

end