%% =========================================================================
% STEP10_MASTER_FEATURE_DATASET
%
% Creates unified trial-wise feature dataset
%
% ERP
% +
% BandPower
%
%% =========================================================================

clear
close all
clc

%% ============================================================
% LOAD
%% ============================================================

step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% CONFIG
%% ============================================================

cfgFD = struct();

cfgFD.class_labels = { ...
    'Consonant',...
    'Dissonant'};

cfgFD.class_codes = [7 8];

cfgFD.analysis_window = [-0.5 1.0];

cfgFD.baseline_win = [-0.2 0];

%% ============================================================
% AUDIT WINDOWS
%% ============================================================

cfgFD.windows = struct();

cfgFD.windows.EARLY = [0.170 0.210];

cfgFD.windows.CORE  = [0.240 0.310];

cfgFD.windows.LATE  = [0.470 0.530];

%% ============================================================
% AUDIT ROIS
%% ============================================================

MAIN_ROI

cfgFD.rois = ROI;

cfgFD.analysis_rois = { ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};

assert(all( ...
    isfield(cfgFD.rois,...
    cfgFD.analysis_rois)), ...
    'Una o piu ROI non esistono in MAIN_ROI');

cfgFD.window_order = { ...
    'EARLY',...
    'CORE',...
    'LATE'};
%% ============================================================
% ERP FEATURES
%% ============================================================

cfgFD.erp_features = { ...
    'Mean',...
    'MinPeak',...
    'MaxPeak',...
    'AUC',...
    'LatencyMin',...
    'LatencyMax',...
    'RMS',...
    'Std'};

cfgFD.erp_complex_features = { ...
    'PeakToPeak',...
    'ERPIndex'};

%% ============================================================
% BANDS
%% ============================================================

cfgFD.bands.Theta     = [4 8];
cfgFD.bands.Alpha     = [8 13];
cfgFD.bands.BetaLow   = [13 20];
cfgFD.bands.BetaHigh  = [20 30];
cfgFD.bands.GammaLow  = [30 40];
cfgFD.bands.GammaHigh = [40 90];

cfgFD.analysis_bands = { ...
    'Theta',...
    'Alpha',...
    'BetaLow',...
    'BetaHigh',...
    'GammaLow',...
    'GammaHigh'};

%% ============================================================
% DATASET BUILD
%% ============================================================

MasterDataset = ...
    build_master_feature_dataset( ...
    subj_list,...
    cfgFD);

fprintf('\n');
fprintf('====================================\n');
fprintf('DATASET CHECK\n');
fprintf('====================================\n');

fprintf('Trials      : %d\n', ...
    MasterDataset.nTrials);

fprintf('Features    : %d\n', ...
    MasterDataset.nFeatures);

fprintf('ERP Features: %d\n', ...
    sum(MasterDataset.FeatureIndex.ERP));

fprintf('BP Features : %d\n', ...
    sum(MasterDataset.FeatureIndex.BandPower));
%% ============================================================
% SAVE
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'STEP10_MASTER_DATASET');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

save( ...
    fullfile(outdir,...
    'MASTER_FEATURE_DATASET.mat'),...
    'MasterDataset',...
    'cfgFD',...
    '-v7.3');

fprintf('\n');
fprintf('====================================\n');
fprintf('MASTER DATASET CREATED\n');
fprintf('====================================\n');
fprintf('Trials   : %d\n', ...
    size(MasterDataset.X,1));
fprintf('Features : %d\n', ...
    size(MasterDataset.X,2));
fprintf('====================================\n');