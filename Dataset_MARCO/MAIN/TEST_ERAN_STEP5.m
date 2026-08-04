%% =========================================================================
% TEST_ERAN_STEP5
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
'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% TEST SUBJECTS
%% ============================================================

subj_list = ...
    subj_list(1:min(3,numel(subj_list)));

fprintf('\n');
fprintf('TEST MODE\n');
fprintf('Subjects: %d\n',numel(subj_list));

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
    'TEST_ERAN_STEP5');

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
% FEATURE PLOTS
%% ============================================================

plot_eran_metrics( ...
    ERAN_Subj,...
    ERAN_Group,...
    ERAN_Stats,...
    cfgERAN,...
    outdir);

%% ============================================================
% QUICK CHECKS
%% ============================================================

subs = fieldnames(ERAN_Subj);

fprintf('\n');
fprintf('================================\n');
fprintf('QUICK STRUCTURE CHECK\n');
fprintf('================================\n');

disp(fieldnames( ...
    ERAN_Subj.(subs{1}).ERAN_CORE))

disp(fieldnames( ...
    ERAN_Subj.(subs{1}) ...
    .ERAN_CORE ...
    .ERAN_Full ...
    .Difference))
%% ============================================================
% ERAN ZOOM
%% ============================================================
cfgERAN.zoom_window = [0.00 0.30];
plot_eran_zoom( ...
    subj_list,...
    cfgERAN,...
    outdir);
%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'TEST_ERAN_STEP5.mat'),...
    'ERAN_Subj',...
    'ERAN_Group',...
    'ERAN_Stats',...
    'cfgERAN');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('TEST ERAN STEP5 COMPLETED\n');
fprintf('================================\n');