%% =========================================================================
% MAIN_FBCSP_STEP9
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'STEP9_FBCSP');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgFBCSP = struct();

%% ------------------------------------------------------------
% RANDOM SEED
%% ------------------------------------------------------------

cfgFBCSP.randomSeed = 10;

rng('default')
rng(cfgFBCSP.randomSeed)
%% ------------------------------------------------------------
% CLASSES
%% ------------------------------------------------------------

cfgFBCSP.class_labels = { ...
    'Consonant',...
    'Dissonant'};

cfgFBCSP.class_codes = [7 8];

cfgFBCSP.labelMap.Consonant = 1;
cfgFBCSP.labelMap.Dissonant = 2;

%% ------------------------------------------------------------
% TIME WINDOW
%% ------------------------------------------------------------

cfgFBCSP.time_window = [-0.5 1.0];

%% ------------------------------------------------------------
% CHANNEL SELECTION
%% ------------------------------------------------------------

cfgFBCSP.channelSelection = 'All';

%% ------------------------------------------------------------
% ROI SUPPORT (FUTURE)
%% ------------------------------------------------------------

cfgFBCSP.useROI = false;

cfgFBCSP.roiName = 'All';

MAIN_ROI
cfgFBCSP.rois = ROI;
%% ------------------------------------------------------------
% FILTER BANK
%% ------------------------------------------------------------

cfgFBCSP.useFilterBank = true;

cfgFBCSP.filterBankName = 'EEGbands';

%% ------------------------------------------------------------
% CSP
%% ------------------------------------------------------------

cfgFBCSP.csp_components = 4;

%% ------------------------------------------------------------
% FEATURE SELECTION
%% ------------------------------------------------------------

cfgFBCSP.useMI = true;

cfgFBCSP.mi_k = 5;

%% ------------------------------------------------------------
% CLASSIFIER
%% ------------------------------------------------------------

cfgFBCSP.classifier = 'QDA';
% QDA | KNN | SVM | RF
%% ------------------------------------------------------------
% TRAIN / TEST SPLIT
%% ------------------------------------------------------------

cfgFBCSP.trainRatio = 0.80;

cfgFBCSP.testRatio = 0.20;

%% ------------------------------------------------------------
% CROSS VALIDATION
%% ------------------------------------------------------------

cfgFBCSP.kfold = 5;

cfgFBCSP.numIterations = 100;

%% ------------------------------------------------------------
% VALIDATION MODES
%% ------------------------------------------------------------

cfgFBCSP.runTrialWise = true;

cfgFBCSP.runLOSO = true;

%% ------------------------------------------------------------
% PERFORMANCE METRIC
%% ------------------------------------------------------------

cfgFBCSP.primaryMetric = ...
    'BalancedAccuracy';
%% ------------------------------------------------------------
% DATASET FIELDS
%% ------------------------------------------------------------

cfgFBCSP.eventField = 'eventLabel';

cfgFBCSP.subjectField = 'subj_id';

%% ============================================================
% DATASET
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('BUILD DATASET\n');
fprintf('================================\n');

FBCSP_Dataset = build_fbcsp_dataset( ...
    subj_list,...
    cfgFBCSP);
fprintf('Trials: %d\n', ...
    FBCSP_Dataset.nTrials);

fprintf('Subjects: %d\n', ...
    FBCSP_Dataset.nSubjects);
fprintf('Class 1: %d\n', ...
    sum([FBCSP_Dataset.trials.label]==1));

fprintf('Class 2: %d\n', ...
    sum([FBCSP_Dataset.trials.label]==2));


%% ============================================================
% FILTER BANK TEST
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('FILTER BANK TEST\n');
fprintf('================================\n');

signal_name                     = 'eeg';
signal_process                  = 'CSP';

EEG_trials = FBCSP_Dataset.trials;
for iTr = 1:length(FBCSP_Dataset.trials)
    EEG_trials(iTr).timeeeg     = double(FBCSP_Dataset.trials(iTr).time);
    EEG_trials(iTr).eeg         = double(FBCSP_Dataset.trials(iTr).eeg);
    EEG_trials(iTr).trialType   = FBCSP_Dataset.trials(iTr).label;
    EEG_trials(iTr).subjectID   = FBCSP_Dataset.trials(iTr).subjectID;
    EEG_trials(iTr).trialID     = FBCSP_Dataset.trials(iTr).trialID;
end


par = struct();

par.FilterBankCompute = FilterBankComputeParams();
par.FilterBankCompute.exec = false;
par.FilterBankCompute.InField = signal_name;
par.FilterBankCompute.OutField = signal_name;
par.FilterBankCompute.FilterBank = 'EEGbands';
par.FilterBankCompute.fsample = FBCSP_Dataset.srate;

par.exec.funname = {'FilterBankCompute'};
[EEG_trials,~] = run_trials(EEG_trials,par);

disp('Size eeg after FilterBank:')
size(EEG_trials(1).eeg)

disp('Class eeg:')
class(EEG_trials(1).eeg)

disp('Number of dimensions:')
ndims(EEG_trials(1).eeg)

tmp = EEG_trials(1).eeg;

for d = 1:ndims(tmp)
    fprintf('Dimension %d = %d\n', ...
        d,size(tmp,d));
end

%% ============================================================
% CSP
%% ============================================================

par.cspModel                  = cspModelParams;
par.cspModel.m                = 4;
par.cspModel.InField          = signal_name;
par.cspModel.OutField         = signal_process;

[~,out.cspModel] = cspModel(EEG_trials,par.cspModel);
% CSP Encode on train and test data
par.cspEncode                  = cspEncodeParams;
par.cspEncode.InField          = signal_name;
par.cspEncode.OutField         = signal_process;
par.cspEncode.W                = out.cspModel.W;

par.exec.funname ={'cspEncode'};
EEG_trials = run_trials(EEG_trials,par);

TotalFeatures = size(EEG_trials(1).(signal_process),2);
%% ============================================================
% MUTUAL INFORMATION
%% ============================================================

% Mutual Information
par.miModel               = miModelParams;
par.miModel.InField       = signal_process;
par.miModel.m             = par.cspModel.m;
par.miModel.k             = cfgFBCSP.mi_k;

[~, out.miModel]=miModel(EEG_trials,par.miModel);

par.miEncode               = miEncodeParams;
par.miEncode.InField       = signal_process;
par.miEncode.OutField      = signal_process;
par.miEncode.nclass        = unique([EEG_trials.trialType]');
par.miEncode.IndMI         = out.miModel.IndMI;

par.exec.funname ={'miEncode'};
[EEG_trials, out]=run_trials(EEG_trials,par);
%% ============================================================
% FEATURE EXTRACTION
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('COMPUTE FBCSP FEATURES\n');
fprintf('================================\n');

FBCSP_Features = compute_fbcsp_features( ...
    FBCSP_Dataset,...
    cfgFBCSP);

size(FBCSP_Features.features)

unique(FBCSP_Features.labels)

length(FBCSP_Features.subjectIDs)

FBCSP_Features.nFeatures
%% ============================================================
% TRIAL-WISE CLASSIFICATION
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('TRIAL-WISE CLASSIFICATION\n');
fprintf('================================\n');

Results_TrialWise = ...
    run_fbcsp_classifier( ...
    FBCSP_Features,...
    cfgFBCSP,...
    'TrialWise');

%% ============================================================
% LOSO CLASSIFICATION
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('LOSO CLASSIFICATION\n');
fprintf('================================\n');

Results_LOSO = ...
    run_fbcsp_classifier( ...
    FBCSP_Features,...
    cfgFBCSP,...
    'LOSO');

%% ============================================================
% RESULTS PLOTS
%% ============================================================

plot_fbcsp_results( ...
    Results_TrialWise,...
    Results_LOSO,...
    outdir);

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'STEP9_FBCSP.mat'),...
    'FBCSP_Dataset',...
    'FBCSP_Features',...
    'Results_TrialWise',...
    'Results_LOSO',...
    'cfgFBCSP',...
    '-v7.3');

%% ============================================================
% FINISH
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP9 FBCSP COMPLETED\n');
fprintf('================================\n');