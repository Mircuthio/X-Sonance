%% =========================================================================
% STEP6_MMN
% MAIN_MMN_STEP6
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
'D:\X-SONANCE\Dataset_MARCO';

load(fullfile(step2_indir,'subj_list.mat'));
%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
step6_outroot = ...
    fullfile( ...
    'D:\X-SONANCE\Dataset_MARCO');

if ~exist(step6_outroot,'dir')
    mkdir(step6_outroot);
end
%% ============================================================
% CONFIGURATION
%% ============================================================

cfgMMN = struct();

cfgMMN.conditions = { ...
    'Consonant' ...
    'Dissonant'};

cfgMMN.cond_field = 'eventLabel';

%% ============================================================
% ROI
%% ============================================================

cfgMMN.analysis_rois = { ...
    'MMN',...
    'aMMN',...
    'afMMN'};

%% ============================================================
% WINDOWS
%% ============================================================

cfgMMN.windows = { ...
    [0.10 0.20]
    [0.15 0.25]
    [0.10 0.25]
    [0.17 0.22]
    [0.20 0.30]};

cfgMMN.window_names = { ...
    'MMN_Early' ...
    'MMN_Late' ...
    'MMN_Full',...
    'MMN_Derived',...
    'MMN_LateDerived'};

cfgMMN.zoom_window = [0.00 0.30];

%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI

cfgMMN.rois = ROI;

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step6_outroot,...
    'STEP6_MMN');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% SUBJECT FEATURES
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL MMN\n');
fprintf('================================\n');

MMN_Subj = extract_mmn_metrics( ...
    subj_list,...
    cfgMMN);

%% ============================================================
% GROUP SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL MMN\n');
fprintf('================================\n');

MMN_Group = average_group_mmn( ...
    MMN_Subj,...
    cfgMMN);

%% ============================================================
% STATISTICS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('MMN STATISTICS\n');
fprintf('================================\n');

MMN_Stats = run_mmn_statistics( ...
    MMN_Subj,...
    cfgMMN);

%% ============================================================
% WAVEFORMS
%% ============================================================

plot_mmn_waveforms( ...
    subj_list,...
    cfgMMN,...
    outdir);

%% ============================================================
% ZOOM
%% ============================================================

plot_mmn_zoom( ...
    subj_list,...
    cfgMMN,...
    outdir);

%% ============================================================
% FEATURE PLOTS
%% ============================================================

plot_mmn_metrics( ...
    MMN_Subj,...
    MMN_Stats,...
    cfgMMN,...
    outdir);

%% ============================================================
% ERAN VS MMN
%% ============================================================

plot_eran_mmn_comparison( ...
    subj_list,...
    cfgMMN,...
    outdir);

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'MMN_STEP6.mat'),...
    'MMN_Subj',...
    'MMN_Group',...
    'MMN_Stats',...
    'cfgMMN',...
    'ROI',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP6 MMN COMPLETED\n');
fprintf('================================\n');