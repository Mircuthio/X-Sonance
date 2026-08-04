%% =========================================================================
% MAIN_ERAN_STEP5
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgERAN = struct();

cfgERAN.conditions = { ...
    'Consonant' ...
    'Dissonant'};

cfgERAN.cond_field = 'eventLabel';

cfgERAN.analysis_rois = { ...
    'ERAN',...
    'ERAN_RIGHT',...
    'ERAN_CORE'};

cfgERAN.windows = { ...
    [0.08 0.15] ...
    [0.15 0.25] ...
    [0.10 0.25]};

cfgERAN.window_names = { ...
    'ERAN_Early' ...
    'ERAN_Late' ...
    'ERAN_Full'};

%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI

cfgERAN.rois = ROI;

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'STEP5_ERAN');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% SUBJECT FEATURES
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL ERAN\n');
fprintf('================================\n');

ERAN_Subj = extract_eran_metrics( ...
    subj_list,...
    cfgERAN);

%% ============================================================
% GROUP SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL ERAN\n');
fprintf('================================\n');

ERAN_Group = average_group_eran( ...
    ERAN_Subj,...
    cfgERAN);

%% ============================================================
% STATISTICS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('ERAN STATISTICS\n');
fprintf('================================\n');

ERAN_Stats = run_eran_statistics( ...
    ERAN_Subj,...
    cfgERAN);

%% ============================================================
% ERP WAVEFORMS
%% ============================================================

plot_eran_waveforms( ...
    subj_list,...
    cfgERAN,...
    outdir);
%% ============================================================
% ERAN ZOOM
%% ============================================================

plot_eran_zoom( ...
    subj_list,...
    cfgERAN,...
    outdir);
%% ============================================================
% FEATURE PLOTS
%% ============================================================

plot_eran_metrics( ...
    ERAN_Subj,...
    ERAN_Stats,...
    cfgERAN,...
    outdir);

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'ERAN_STEP5.mat'),...
    'ERAN_Subj',...
    'ERAN_Group',...
    'ERAN_Stats',...
    'cfgERAN',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP5 ERAN COMPLETED\n');
fprintf('================================\n');