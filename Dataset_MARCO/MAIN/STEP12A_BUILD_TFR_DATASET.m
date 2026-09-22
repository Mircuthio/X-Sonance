%% ============================================================
% STEP12A_BUILD_TFR_DATASET
%% ============================================================

clear
close all
clc

disable_eeglab();

%% ============================================================
% LOAD
%% ============================================================

step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

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
    'STEP12A_TFR_DATASET');

if ~exist(outdir,'dir')

    mkdir(outdir);

end

%% ============================================================
% CONFIG
%% ============================================================

cfgTFR = struct();

cfgTFR.randomSeed = 10;

cfgTFR.class_codes = [7 8];

cfgTFR.class_labels = ...
    {'Consonant','Dissonant'};

cfgTFR.time_window = ...
    [-0.5 1.0];

%% ------------------------------------------------------------
% ROI
%% ------------------------------------------------------------

MAIN_ROI

cfgTFR.rois = ROI;

%% ------------------------------------------------------------
% BANDS
%% ------------------------------------------------------------

cfgTFR.Bands.Theta = ...
    [4 7];

cfgTFR.Bands.Alpha = ...
    [8 12];

cfgTFR.Bands.BetaLow = ...
    [13 20];

cfgTFR.Bands.BetaMid = ...
    [20 30];

%% ------------------------------------------------------------
% WINDOWS
%% ------------------------------------------------------------

cfgTFR.Windows.T1 = ...
    [0.15 0.25];

cfgTFR.Windows.T2 = ...
    [0.25 0.35];

cfgTFR.Windows.T3 = ...
    [0.35 0.50];

%% ============================================================
% BUILD DATASET
%% ============================================================

TFR_Dataset = ...
    build_tfr_dataset( ...
    subj_list,...
    cfgTFR);

fprintf('\n');
fprintf('================================\n');
fprintf('TFR DATASET CREATED\n');
fprintf('================================\n');
fprintf('Trials   : %d\n', ...
    TFR_Dataset.nTrials);

fprintf('Subjects : %d\n', ...
    TFR_Dataset.nSubjects);

%% ============================================================
% FEATURE EXTRACTION
%% ============================================================

TFR_Dataset = ...
    compute_tfr_features( ...
    TFR_Dataset,...
    cfgTFR);

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('FEATURE SUMMARY\n');
fprintf('================================\n');

fprintf('nFeatures : %d\n', ...
    TFR_Dataset.nFeatures);

disp( ...
    TFR_Dataset.FeatureNames(:));

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'TFR_Dataset.mat'),...
    'TFR_Dataset',...
    'cfgTFR',...
    '-v7.3');

fprintf('\n');
fprintf('================================\n');
fprintf('STEP12A COMPLETED\n');
fprintf('================================\n');