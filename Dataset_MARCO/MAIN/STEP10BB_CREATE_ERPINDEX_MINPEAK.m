%% =========================================================================
% STEP10BB_CREATE_ERPINDEX_MINPEAK
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

%% ============================================================
% LOAD FULL DATASET
%% ============================================================

load( ...
    fullfile( ...
    indir,...
    'ERPINF_Dataset_CACHED.mat'));

%% ============================================================
% FEATURES
%% ============================================================

disp('AVAILABLE FEATURES')
disp(ERPINF_Dataset.FeatureNames(:))

%% ============================================================
% KEEP FEATURES
%%
% 1 ERAN_CORE_ERPIndex
% 2 MMN_ERPIndex
% 3 ERAN_RIGHT_ERPIndex
% 4 N5_CENTRAL_ERPIndex
%
% 9 ERAN_CORE_ERAN_B_MinPeak
% 10 MMN_ERAN_B_MinPeak
%% ============================================================

keepIdx = [1 2 3 4 9 10];

DatasetOut = ERPINF_Dataset;

for iTr = 1:numel(DatasetOut.trials)

    DatasetOut.trials(iTr).ERPINF = ...
        DatasetOut.trials(iTr).ERPINF(keepIdx);

    DatasetOut.trials(iTr).timeERPINF = ...
        1:numel(keepIdx);

end

DatasetOut.FeatureNames = ...
    DatasetOut.FeatureNames(keepIdx);

DatasetOut.nFeatures = ...
    numel(keepIdx);

%% ============================================================
% CHECK
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('ERPINDEX + MINPEAK DATASET\n');
fprintf('================================\n');

fprintf('Features kept : %d\n', ...
    DatasetOut.nFeatures);

disp(DatasetOut.FeatureNames(:))

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    indir,...
    'ERPINF_Dataset_ERPINDEX_MINPEAK.mat'),...
    'DatasetOut',...
    '-v7.3');

fprintf('\n');
fprintf('================================\n');
fprintf('DATASET SAVED\n');
fprintf('================================\n');