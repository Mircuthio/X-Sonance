%% =========================================================================
% STEP10BB_CREATE_FEATURE_SUBSETS
%% =========================================================================

clear
close all
clc

%% ============================================================
% PATHS
%% ============================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

indir = fullfile( ...
    step2_indir,...
    'STEP10BA_ERPINF_DATASET');

load( ...
    fullfile( ...
    indir,...
    'ERPINF_Dataset_CACHED.mat'));

%% ============================================================
% FEATURE NAMES
%% ============================================================

FeatureNames = ...
    ERPINF_Dataset.FeatureNames;

disp('FEATURES')
disp(FeatureNames(:))

%% ============================================================
% SUBSET DEFINITIONS
%% ============================================================

ERPINDEX_idx = 1:4;

ERPINDEX_ERANB_idx = 1:10;

FULL_idx = ...
    1:numel(FeatureNames);

%% ============================================================
% CREATE DATASETS
%% ============================================================

create_subset_dataset( ...
    ERPINF_Dataset,...
    ERPINDEX_idx,...
    fullfile(indir,...
    'ERPINF_Dataset_ERPINDEX.mat'));

create_subset_dataset( ...
    ERPINF_Dataset,...
    ERPINDEX_ERANB_idx,...
    fullfile(indir,...
    'ERPINF_Dataset_ERPINDEX_ERANB.mat'));

create_subset_dataset( ...
    ERPINF_Dataset,...
    FULL_idx,...
    fullfile(indir,...
    'ERPINF_Dataset_FULL.mat'));

fprintf('\n');
fprintf('================================\n');
fprintf('FEATURE SUBSETS CREATED\n');
fprintf('================================\n');