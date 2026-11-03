%% =========================================================================
% STEP105_BUILD_FINAL_DATASETS
%
% Creates final datasets for classification benchmark
%
% OUTPUT
%
% DATASET_FULL_264
% DATASET_ERP_ONLY_156
% DATASET_BANDPOWER_ONLY_108
% DATASET_REDUCED_29
%
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
    'STEP101_MASTER_DATASET',...
    'MASTER_FEATURE_DATASET.mat'));

load(fullfile( ...
    projectRoot,...
    'STEP104_FEATURE_REDUCTION',...
    'ReducedDataset.mat'));

%% =========================================================================
% OUTPUT DIR
%% =========================================================================

outdir = fullfile( ...
    projectRoot,...
    'STEP105_FINAL_DATASETS');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% =========================================================================
% DATASET 1
% FULL_264
%% =========================================================================

FULL_264 = struct();

FULL_264.X = MasterDataset.X;
FULL_264.Y = MasterDataset.Y;

FULL_264.SubjectID = MasterDataset.SubjectID;
FULL_264.TrialID = MasterDataset.TrialID;
FULL_264.EventLabel = MasterDataset.EventLabel;

FULL_264.FeatureNames = MasterDataset.FeatureNames;
FULL_264.FeatureFamily = MasterDataset.FeatureFamily;

FULL_264.nTrials = MasterDataset.nTrials;
FULL_264.nFeatures = MasterDataset.nFeatures;

FULL_264.cfg = MasterDataset.cfg;

save( ...
    fullfile(outdir,...
    'DATASET_FULL_264.mat'),...
    'FULL_264',...
    '-v7.3');

%% =========================================================================
% DATASET 2
% ERP_ONLY_156
%% =========================================================================

idxERP = MasterDataset.FeatureIndex.ERP;

ERP_ONLY_156 = struct();

ERP_ONLY_156.X = ...
    MasterDataset.X(:,idxERP);

ERP_ONLY_156.Y = MasterDataset.Y;

ERP_ONLY_156.SubjectID = MasterDataset.SubjectID;
ERP_ONLY_156.TrialID = MasterDataset.TrialID;
ERP_ONLY_156.EventLabel = MasterDataset.EventLabel;

ERP_ONLY_156.FeatureNames = ...
    MasterDataset.FeatureNames(idxERP);

ERP_ONLY_156.FeatureFamily = ...
    MasterDataset.FeatureFamily(idxERP);

ERP_ONLY_156.nTrials = ...
    size(ERP_ONLY_156.X,1);

ERP_ONLY_156.nFeatures = ...
    size(ERP_ONLY_156.X,2);

ERP_ONLY_156.cfg = MasterDataset.cfg;

save( ...
    fullfile(outdir,...
    'DATASET_ERP_ONLY_156.mat'),...
    'ERP_ONLY_156',...
    '-v7.3');

%% =========================================================================
% DATASET 3
% BANDPOWER_ONLY_108
%% =========================================================================

idxBP = MasterDataset.FeatureIndex.BandPower;

BANDPOWER_ONLY_108 = struct();

BANDPOWER_ONLY_108.X = ...
    MasterDataset.X(:,idxBP);

BANDPOWER_ONLY_108.Y = ...
    MasterDataset.Y;

BANDPOWER_ONLY_108.SubjectID = ...
    MasterDataset.SubjectID;

BANDPOWER_ONLY_108.TrialID = ...
    MasterDataset.TrialID;

BANDPOWER_ONLY_108.EventLabel = ...
    MasterDataset.EventLabel;

BANDPOWER_ONLY_108.FeatureNames = ...
    MasterDataset.FeatureNames(idxBP);

BANDPOWER_ONLY_108.FeatureFamily = ...
    MasterDataset.FeatureFamily(idxBP);

BANDPOWER_ONLY_108.nTrials = ...
    size(BANDPOWER_ONLY_108.X,1);

BANDPOWER_ONLY_108.nFeatures = ...
    size(BANDPOWER_ONLY_108.X,2);

BANDPOWER_ONLY_108.cfg = ...
    MasterDataset.cfg;

save( ...
    fullfile(outdir,...
    'DATASET_BANDPOWER_ONLY_108.mat'),...
    'BANDPOWER_ONLY_108',...
    '-v7.3');

%% =========================================================================
% DATASET 4
%% =========================================================================
% DATASET 4
% REDUCED_29
%% =========================================================================

REDUCED_29 = ReducedDataset;

REDUCED_29.SubjectID = MasterDataset.SubjectID;
REDUCED_29.TrialID = MasterDataset.TrialID;
REDUCED_29.EventLabel = MasterDataset.EventLabel;

REDUCED_29.nTrials = size(REDUCED_29.X,1);
REDUCED_29.nFeatures = size(REDUCED_29.X,2);
REDUCED_29.cfg = MasterDataset.cfg;

save( ...
    fullfile(outdir,...
    'DATASET_REDUCED_29.mat'),...
    'REDUCED_29',...
    '-v7.3');
%% =========================================================================
% SANITY CHECKS
%% =========================================================================

assert(size(FULL_264.X,1) == length(FULL_264.Y), ...
    'FULL_264: X/Y mismatch');

assert(size(ERP_ONLY_156.X,2) == 156, ...
    'ERP_ONLY_156 feature mismatch');

assert(size(BANDPOWER_ONLY_108.X,2) == 108, ...
    'BANDPOWER_ONLY_108 feature mismatch');

assert(size(REDUCED_29.X,2) == 29, ...
    'REDUCED_29 feature mismatch');

assert(size(REDUCED_29.X,1) == length(REDUCED_29.Y), ...
    'REDUCED_29: X/Y mismatch');

assert(length(unique(REDUCED_29.FeatureNames)) == ...
    REDUCED_29.nFeatures, ...
    'Duplicate feature names detected');
%% =========================================================================
% SUMMARY
%% =========================================================================

fprintf('\n');
fprintf('=================================================\n');
fprintf('FINAL DATASETS CREATED\n');
fprintf('=================================================\n');

fprintf('FULL_264           : %d features\n', ...
    FULL_264.nFeatures);

fprintf('ERP_ONLY_156       : %d features\n', ...
    ERP_ONLY_156.nFeatures);

fprintf('BANDPOWER_ONLY_108 : %d features\n', ...
    BANDPOWER_ONLY_108.nFeatures);

fprintf('REDUCED_29         : %d features\n', ...
    REDUCED_29.nFeatures);

fprintf('\n');

fprintf('Trials             : %d\n', ...
    FULL_264.nTrials);

fprintf('\n');
fprintf('STEP105 COMPLETED\n');
fprintf('=================================================\n');
