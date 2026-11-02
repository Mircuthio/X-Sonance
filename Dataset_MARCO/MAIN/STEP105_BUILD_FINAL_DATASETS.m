%% =========================================================================
% STEP105_BUILD_FINAL_DATASETS
%% =========================================================================

clear
close all
clc

%% =========================================================================
% LOAD
%% =========================================================================

projectRoot = ...
'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

load(fullfile( ...
    projectRoot,...
    'STEP10_FEATURE_REDUCTION',...
    'ReducedDataset.mat'));

%% =========================================================================
% OUTPUT
%% =========================================================================

outdir = fullfile( ...
    projectRoot,...
    'STEP11_FINAL_DATASETS');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% =========================================================================
% FULL
%% =========================================================================

FULL = ReducedDataset;

FULL.nTrials = size(FULL.X,1);
FULL.nFeatures = size(FULL.X,2);

save( ...
    fullfile(outdir,...
    'DATASET_FULL.mat'),...
    'FULL',...
    '-v7.3');

%% =========================================================================
% ERP ONLY
%% =========================================================================

idxERP = strcmp( ...
    ReducedDataset.FeatureFamily,...
    'ERP');

ERP_ONLY = struct();

ERP_ONLY.X = ...
    ReducedDataset.X(:,idxERP);

ERP_ONLY.Y = ...
    ReducedDataset.Y;

ERP_ONLY.SubjectID = ...
    ReducedDataset.SubjectID;

ERP_ONLY.TrialID = ...
    ReducedDataset.TrialID;

ERP_ONLY.EventLabel = ...
    ReducedDataset.EventLabel;

ERP_ONLY.FeatureNames = ...
    ReducedDataset.FeatureNames(idxERP);

ERP_ONLY.FeatureFamily = ...
    ReducedDataset.FeatureFamily(idxERP);

ERP_ONLY.cfg = ...
    ReducedDataset.cfg;

ERP_ONLY.nTrials = ...
    size(ERP_ONLY.X,1);

ERP_ONLY.nFeatures = ...
    size(ERP_ONLY.X,2);

save( ...
    fullfile(outdir,...
    'DATASET_ERP_ONLY.mat'),...
    'ERP_ONLY',...
    '-v7.3');

%% =========================================================================
% BANDPOWER ONLY
%% =========================================================================

idxBP = strcmp( ...
    ReducedDataset.FeatureFamily,...
    'BandPower');

BANDPOWER_ONLY = struct();

BANDPOWER_ONLY.X = ...
    ReducedDataset.X(:,idxBP);

BANDPOWER_ONLY.Y = ...
    ReducedDataset.Y;

BANDPOWER_ONLY.SubjectID = ...
    ReducedDataset.SubjectID;

BANDPOWER_ONLY.TrialID = ...
    ReducedDataset.TrialID;

BANDPOWER_ONLY.EventLabel = ...
    ReducedDataset.EventLabel;

BANDPOWER_ONLY.FeatureNames = ...
    ReducedDataset.FeatureNames(idxBP);

BANDPOWER_ONLY.FeatureFamily = ...
    ReducedDataset.FeatureFamily(idxBP);

BANDPOWER_ONLY.cfg = ...
    ReducedDataset.cfg;

BANDPOWER_ONLY.nTrials = ...
    size(BANDPOWER_ONLY.X,1);

BANDPOWER_ONLY.nFeatures = ...
    size(BANDPOWER_ONLY.X,2);

save( ...
    fullfile(outdir,...
    'DATASET_BANDPOWER_ONLY.mat'),...
    'BANDPOWER_ONLY',...
    '-v7.3');

%% =========================================================================
% ERP + BANDPOWER
%% =========================================================================

idxERPBP = idxERP | idxBP;

ERP_BANDPOWER = struct();

ERP_BANDPOWER.X = ...
    ReducedDataset.X(:,idxERPBP);

ERP_BANDPOWER.Y = ...
    ReducedDataset.Y;

ERP_BANDPOWER.SubjectID = ...
    ReducedDataset.SubjectID;

ERP_BANDPOWER.TrialID = ...
    ReducedDataset.TrialID;

ERP_BANDPOWER.EventLabel = ...
    ReducedDataset.EventLabel;

ERP_BANDPOWER.FeatureNames = ...
    ReducedDataset.FeatureNames(idxERPBP);

ERP_BANDPOWER.FeatureFamily = ...
    ReducedDataset.FeatureFamily(idxERPBP);

ERP_BANDPOWER.cfg = ...
    ReducedDataset.cfg;

ERP_BANDPOWER.nTrials = ...
    size(ERP_BANDPOWER.X,1);

ERP_BANDPOWER.nFeatures = ...
    size(ERP_BANDPOWER.X,2);

save( ...
    fullfile(outdir,...
    'DATASET_ERP_BANDPOWER.mat'),...
    'ERP_BANDPOWER',...
    '-v7.3');

%% =========================================================================
% SUMMARY
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('FINAL DATASETS\n');
fprintf('====================================\n');

fprintf('FULL            : %d features\n', ...
    FULL.nFeatures);

fprintf('ERP_ONLY        : %d features\n', ...
    ERP_ONLY.nFeatures);

fprintf('BANDPOWER_ONLY  : %d features\n', ...
    BANDPOWER_ONLY.nFeatures);

fprintf('ERP_BANDPOWER   : %d features\n', ...
    ERP_BANDPOWER.nFeatures);

fprintf('\n');

fprintf('Trials          : %d\n', ...
    FULL.nTrials);

fprintf('\n');
fprintf('STEP11 COMPLETED\n');
fprintf('====================================\n');