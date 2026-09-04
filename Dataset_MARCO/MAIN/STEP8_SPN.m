%% =========================================================================
% STEP8_SPN
% MAIN_SPN_STEP8
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

set(groot,...
    'defaultTextInterpreter','tex');
set(groot,...
    'defaultAxesTickLabelInterpreter','tex');
set(groot,...
    'defaultLegendInterpreter','tex');
%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
    fullfile( ...
    'D:\X-SONANCE\Dataset_MARCO',...
    'DATA_SUBJECTS',...
    'All_trials',...
    'EXTRACTED_DATA');

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
step8_outroot = ...
    fullfile( ...
    'D:\X-SONANCE\Dataset_MARCO');

if ~exist(step8_outroot,'dir')
    mkdir(step8_outroot);
end
%% ============================================================
% CONFIGURATION
%% ============================================================

cfgSPN = struct();

cfgSPN.preStim  = 1.5;
cfgSPN.postStim = 0.5;

cfgSPN.baseline = [-1.5 -1.2];

cfgSPN.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgSPN.validTriggers = [7 8];

%% ============================================================
% SPN WINDOWS
%% ============================================================

cfgSPN.windows = { ...
    [-1.5 -1.0]
    [-1.0 -0.5]
    [-0.5  0.0]
    [-1.5  0.0]
    [-0.3  0.0]};

cfgSPN.window_names = { ...
    'SPN_Early'
    'SPN_Middle'
    'SPN_Late'
    'SPN_Full'
    'SPN_Derived'};

cfgSPN.zoom_window = [-1.5 0.1];

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

cfgSPN.rois = ROI;

cfgSPN.analysis_rois = { ...
    'SPN_FRONTAL',...
    'SPN_CENTRAL',...
    'SPN_POSTERIOR',...
    'SPN_GLOBAL'};
%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step8_outroot,...
    'STEP8_SPN');

if ~exist(outdir,'dir')
    mkdir(outdir);
end
%% ============================================================
% BUILD SPN EPOCHS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('BUILD SPN EPOCHS\n');
fprintf('================================\n');

subj_list_spn = build_spn_subject_list( ...
    step2_indir,...
    cfgSPN);

%% ============================================================
% SUBJECT FEATURES
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL SPN\n');
fprintf('================================\n');

SPN_Subj = extract_spn_metrics( ...
    subj_list_spn,...
    cfgSPN);

%% ============================================================
% GROUP SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL SPN\n');
fprintf('================================\n');

SPN_Group = average_group_spn( ...
    SPN_Subj,...
    cfgSPN);

%% ============================================================
% STATISTICS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SPN STATISTICS\n');
fprintf('================================\n');

SPN_Stats = run_spn_statistics( ...
    SPN_Subj,...
    cfgSPN);

%% ============================================================
% WAVEFORMS
%% ============================================================

plot_spn_waveforms( ...
    subj_list_spn,...
    cfgSPN,...
    outdir);

%% ============================================================
% ZOOM
%% ============================================================

plot_spn_zoom( ...
    subj_list_spn,...
    cfgSPN,...
    outdir);
%% ============================================================
% TOPOPLOTS
%% ============================================================

plot_spn_topoplots( ...
    subj_list_spn,...
    cfgSPN,...
    outdir);
%% ============================================================
% FEATURE PLOTS
%% ============================================================

plot_spn_metrics( ...
    SPN_Subj,...
    SPN_Stats,...
    cfgSPN,...
    outdir);

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'SPN_STEP8.mat'),...
    'subj_list_spn',...
    'SPN_Subj',...
    'SPN_Group',...
    'SPN_Stats',...
    'cfgSPN',...
    'ROI',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP8 SPN COMPLETED\n');
fprintf('================================\n');