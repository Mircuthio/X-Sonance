%% =========================================================================
% STEP10A ERP-INFORMED FEATURE DISCOVERY
%% =========================================================================
%
% OBIETTIVO
%
% Identificare feature ERP e BandPower
% realmente informative per:
%
%       Consonant vs Dissonant
%
% Nessuna classificazione.
%
% Produce:
%
%   - Ranking AUC
%   - Ranking Effect Size
%   - Top Features
%   - Heatmaps
%   - Correlation Matrix
%
%% =========================================================================

clear
close all
clc

origState = ...
    get(0,'DefaultFigureVisible');

set(0,'DefaultFigureVisible','off');

disable_eeglab();

%% =========================================================================
% LOAD DATA
%% =========================================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load( ...
    fullfile( ...
    step2_indir,...
    'subj_list.mat'));

%% =========================================================================
% OUTPUT
%% =========================================================================

outdir = fullfile( ...
    step2_indir,...
    'STEP10A_FEATURE_DISCOVERY');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% =========================================================================
% CONFIG
%% =========================================================================

cfgFD = step10A_config();

%% =========================================================================
% ROI
%% =========================================================================

MAIN_ROI

cfgFD.rois = ROI;

%% =========================================================================
% BUILD FEATURE DATASET
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('BUILD FEATURE DATASET\n');
fprintf('====================================\n');

FeatureDataset = ...
    step10A_build_feature_dataset( ...
    subj_list,...
    cfgFD);

fprintf('\n');
fprintf('Trials   : %d\n', ...
    size(FeatureDataset.X,1));

fprintf('Features : %d\n', ...
    size(FeatureDataset.X,2));

%% =========================================================================
% FEATURE SCREENING
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('FEATURE SCREENING\n');
fprintf('====================================\n');

Results = ...
    step10A_feature_screening( ...
    FeatureDataset,...
    cfgFD);

%% =========================================================================
% FEATURE RANKING
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('FEATURE RANKING\n');
fprintf('====================================\n');

Ranking = ...
    step10A_rank_features( ...
    Results,...
    cfgFD);

%% =========================================================================
% REDUNDANCY ANALYSIS
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('FEATURE CORRELATION\n');
fprintf('====================================\n');

CorrResults = ...
    step10A_feature_correlation( ...
    FeatureDataset,...
    cfgFD);

%% =========================================================================
% PLOTS
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('PLOTS\n');
fprintf('====================================\n');

step10A_plot_ranking( ...
    Ranking,...
    cfgFD,...
    outdir);

step10A_plot_heatmaps( ...
    Results,...
    cfgFD,...
    outdir);

step10A_plot_correlation( ...
    CorrResults,...
    FeatureDataset,...
    cfgFD,...
    outdir);

%% =========================================================================
% SAVE
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('SAVE\n');
fprintf('====================================\n');

step10A_save_results( ...
    FeatureDataset,...
    Results,...
    Ranking,...
    CorrResults,...
    cfgFD,...
    outdir);

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('====================================\n');
fprintf('STEP10A COMPLETED\n');
fprintf('====================================\n');