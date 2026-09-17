%% =========================================================================
% STEP10BA_BUILD_ERPINF_DATASET
%% =========================================================================

clear
close all
clc

origState = ...
    get(0,'DefaultFigureVisible');

set(0,'DefaultFigureVisible','off');

disable_eeglab();

%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load( ...
    fullfile( ...
    step2_indir,...
    'subj_list.mat'));

%% ============================================================
% OUTPUT
%% ============================================================

outdir = ...
    fullfile( ...
    step2_indir,...
    'STEP10BA_ERPINF_DATASET');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CONFIG
%% ============================================================

cfgINF = struct();

cfgINF.class_labels = { ...
    'Consonant',...
    'Dissonant'};

cfgINF.class_codes = [7 8];

cfgINF.analysis_window = ...
    [-0.5 1.0];

cfgINF.eventField = ...
    'eventLabel';

cfgINF.subjectField = ...
    'subj_id';

MAIN_ROI

cfgINF.rois = ROI;

%% ============================================================
% BUILD DATASET
%% ============================================================

ERPINF_Dataset = ...
    build_bandpower_dataset( ...
    subj_list,...
    cfgINF);

%% ============================================================
% FEATURE EXTRACTION
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('COMPUTE ERPINF FEATURES\n');
fprintf('================================\n');

nTrials = ...
    numel(ERPINF_Dataset.trials);

for iTr = 1:nTrials

    if mod(iTr,100)==0

        fprintf( ...
            'Trial %d/%d\n',...
            iTr,...
            nTrials);

    end

    tr = ...
        ERPINF_Dataset.trials(iTr);

    [tmp,FeatureNames] = ...
        compute_erp_informed_features( ...
        tr,...
        cfgINF,...
        'ERPINF');

    ERPINF_Dataset.trials(iTr).ERPINF = ...
        tmp.ERPINF;

    ERPINF_Dataset.trials(iTr).timeERPINF = ...
        tmp.timeERPINF;

end

ERPINF_Dataset.FeatureNames = ...
    FeatureNames;

ERPINF_Dataset.nFeatures = ...
    numel(FeatureNames);

%% ============================================================
% CHECK
%% ============================================================

fprintf('\n');

fprintf('Trials    : %d\n', ...
    ERPINF_Dataset.nTrials);

fprintf('Features  : %d\n', ...
    ERPINF_Dataset.nFeatures);

fprintf('Subjects  : %d\n', ...
    ERPINF_Dataset.nSubjects);

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'ERPINF_Dataset_CACHED.mat'),...
    'ERPINF_Dataset',...
    'cfgINF',...
    '-v7.3');

fprintf('\n');
fprintf('================================\n');
fprintf('ERPINF DATASET SAVED\n');
fprintf('================================\n');