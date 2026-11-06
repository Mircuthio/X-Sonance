%% =========================================================================
% STEP11B_NSA_PCA
%
% BUILD NEURAL MANIFOLD
%
% INPUT
%
%   STEP11A_NSA_DATASET
%
% OUTPUT
%
%   NSA_PCA_Model
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
    'STEP11A_NSA_DATASET',...
    'NSA_Dataset.mat'));

data_trials = ...
    NSA_Dataset.trials;

%% =========================================================================
% CONFIG
%% =========================================================================

cfgNSA = struct();

cfgNSA.binWidth = 30;
cfgNSA.kernSD   = 150;

cfgNSA.signal_name = 'eeg';
cfgNSA.signal_process = 'dpca';

cfgNSA.pcaPerc = 99;

%% =========================================================================
% STEP 1
% NORMALIZE EEG
%% =========================================================================

par.signalNormalize = ...
    signalNormalizeParams;

par.signalNormalize.InField = ...
    cfgNSA.signal_name;

par.signalNormalize.OutField = ...
    cfgNSA.signal_process;

%% =========================================================================
% STEP 2
% SMOOTHING
%% =========================================================================

par.SmoothWindow = ...
    SmoothWindowParams;

par.SmoothWindow.InField = ...
    cfgNSA.signal_process;

par.SmoothWindow.OutField = ...
    cfgNSA.signal_process;

par.SmoothWindow.binWidth = ...
    cfgNSA.binWidth;

%% =========================================================================
% STEP 3
% REMOVE INACTIVE
%% =========================================================================

par.removeInactive = ...
    removeInactiveParams;

par.removeInactive.InField = ...
    cfgNSA.signal_process;

par.removeInactive.OutField = ...
    cfgNSA.signal_process;

%% =========================================================================
% PREPROCESS
%% =========================================================================

par.exec.funname = { ...
    'signalNormalize',...
    'SmoothWindow',...
    'removeInactive'};

data_trials = ...
    run_trials( ...
    data_trials,...
    par);

%% =========================================================================
% STEP 4
% MEAN CONDITIONS
%% =========================================================================

par.meanData = ...
    meanDataParams;

par.meanData.trialTypes = ...
    unique([data_trials.trialType]);

par.meanData.InField = ...
    cfgNSA.signal_process;

par.meanData.OutField = ...
    cfgNSA.signal_process;

%% =========================================================================
% STEP 5
% AVERAGE WINDOW
%% =========================================================================

par.AverageWindow = ...
    AverageWindowParams;

par.AverageWindow.useSqrt = false;

par.AverageWindow.InField = ...
    cfgNSA.signal_process;

par.AverageWindow.OutField = ...
    cfgNSA.signal_process;

par.AverageWindow.binWidth = ...
    cfgNSA.binWidth;

%% =========================================================================
% STEP 6
% GAUSSIAN SMOOTHER
%% =========================================================================

par.GaussianSmoother = ...
    GaussianSmootherParams;

par.GaussianSmoother.InField = ...
    cfgNSA.signal_process;

par.GaussianSmoother.OutField = ...
    cfgNSA.signal_process;

par.GaussianSmoother.kernSD = ...
    cfgNSA.kernSD;

par.GaussianSmoother.stepSize = ...
    cfgNSA.binWidth;

%% =========================================================================
% STEP 7
% PCA MODEL
%% =========================================================================

par.pcaModel = ...
    pcaModelParams();

par.pcaModel.numComponents = 0;

par.pcaModel.perc = ...
    cfgNSA.pcaPerc;

par.pcaModel.InField = ...
    cfgNSA.signal_process;

par.pcaModel.OutField = ...
    cfgNSA.signal_process;

%% =========================================================================
% PCA ON CLASS AVERAGES
%% =========================================================================

par.exec.funname = { ...
    'meanData',...
    'AverageWindow',...
    'GaussianSmoother',...
    'pcaModel'};

[data_trials_class,out] = ...
    run_trials( ...
    data_trials,...
    par);

%% =========================================================================
% STEP 8
% ENCODE CLASS TRAJECTORIES
%% =========================================================================

par.pcaEncode = ...
    pcaEncodeParams();

par.pcaEncode.Wpca = ...
    out.pcaModel.Wpca;

par.pcaEncode.mu = ...
    out.pcaModel.mu;

par.pcaEncode.explained = ...
    out.pcaModel.explained;

par.pcaEncode.InField = ...
    cfgNSA.signal_process;

par.pcaEncode.OutField = ...
    cfgNSA.signal_process;

par.exec.funname = { ...
    'pcaEncode'};

data_trials_class = ...
    run_trials( ...
    data_trials_class,...
    par);

%% =========================================================================
% RESULTS
%% =========================================================================

NSA_PCA_Model = struct();

NSA_PCA_Model.cfgNSA = ...
    cfgNSA;

NSA_PCA_Model.pcaModel = ...
    out.pcaModel;

NSA_PCA_Model.data_trials_class = ...
    data_trials_class;

NSA_PCA_Model.Wpca = ...
    out.pcaModel.Wpca;

NSA_PCA_Model.mu = ...
    out.pcaModel.mu;

NSA_PCA_Model.explained = ...
    out.pcaModel.explained;

NSA_PCA_Model.numComponents = ...
    out.pcaModel.numComponents;

%% =========================================================================
% SUMMARY
%% =========================================================================

fprintf('\n');

fprintf('================================\n');
fprintf('NSA PCA MODEL\n');
fprintf('================================\n');

fprintf('Trials        : %d\n', ...
    numel(data_trials));

fprintf('Components    : %d\n', ...
    NSA_PCA_Model.numComponents);

fprintf('Variance Goal : %.1f %%\n', ...
    cfgNSA.pcaPerc);

fprintf('Variance Real : %.2f %%\n', ...
    sum(NSA_PCA_Model.explained));

fprintf('================================\n');

%% =========================================================================
% SAVE
%% =========================================================================

outdir = fullfile( ...
    projectRoot,...
    'STEP11B_NSA_PCA');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

save( ...
    fullfile( ...
    outdir,...
    'NSA_PCA_Model.mat'),...
    'NSA_PCA_Model',...
    '-v7.3');

fprintf('\n');
fprintf('STEP11B COMPLETED\n');
fprintf('\n');