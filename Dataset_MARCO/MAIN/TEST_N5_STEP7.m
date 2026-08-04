%% =========================================================================
% TEST_N5_STEP7
%% =========================================================================
%
% TEST VERSION
%
% Uses first 3 subjects only
%
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
'D:\X-SONANCE\Dataset_MARCO';

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

cfgN5 = struct();

cfgN5.conditions = { ...
    'Consonant' ...
    'Dissonant'};

cfgN5.cond_field = 'eventLabel';

%% ============================================================
% ROI
%% ============================================================

cfgN5.analysis_rois = { ...
    'N5',...
    'N5_FRONT',...
    'N5_CENTRAL'};

%% ============================================================
% WINDOWS
%% ============================================================

cfgN5.windows = { ...
    [0.30 0.40] ...
    [0.40 0.55] ...
    [0.30 0.55]};

cfgN5.window_names = { ...
    'N5_Early' ...
    'N5_Late' ...
    'N5_Full'};

cfgN5.zoom_window = [0.20 0.60];

%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI

cfgN5.rois = ROI;

%% ============================================================
% ROI CHECK
%% ============================================================

assert(isfield(ROI,'N5'), ...
    'ROI.N5 not found');

assert(isfield(ROI,'N5_FRONT'), ...
    'ROI.N5_FRONT not found');

assert(isfield(ROI,'N5_CENTRAL'), ...
    'ROI.N5_CENTRAL not found');

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'TEST_N5_STEP7');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% SUBJECT FEATURES
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL N5\n');
fprintf('================================\n');

N5_Subj = extract_n5_metrics( ...
    subj_list,...
    cfgN5);

%% ============================================================
% GROUP SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL N5\n');
fprintf('================================\n');

N5_Group = average_group_n5( ...
    N5_Subj,...
    cfgN5);

%% ============================================================
% STATISTICS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('N5 STATISTICS\n');
fprintf('================================\n');

N5_Stats = run_n5_statistics( ...
    N5_Subj,...
    cfgN5);

%% ============================================================
% WAVEFORMS
%% ============================================================

fprintf('\n');
fprintf('Generating Waveforms...\n');

plot_n5_waveforms( ...
    subj_list,...
    cfgN5,...
    outdir);

%% ============================================================
% ZOOM
%% ============================================================

fprintf('Generating Zoom Plots...\n');

plot_n5_zoom( ...
    subj_list,...
    cfgN5,...
    outdir);

%% ============================================================
% FEATURE PLOTS
%% ============================================================

fprintf('Generating Metric Plots...\n');

plot_n5_metrics( ...
    N5_Subj,...
    N5_Stats,...
    cfgN5,...
    outdir);

%% ============================================================
% QUICK STRUCTURE CHECK
%% ============================================================

subs = fieldnames(N5_Subj);

fprintf('\n');
fprintf('================================\n');
fprintf('QUICK STRUCTURE CHECK\n');
fprintf('================================\n');

fprintf('\n');
fprintf('N5 WINDOWS:\n');

disp(fieldnames( ...
    N5_Subj.(subs{1}).N5));

fprintf('\n');
fprintf('N5_Full -> Difference Metrics:\n');

disp(fieldnames( ...
    N5_Subj.(subs{1}) ...
    .N5 ...
    .N5_Full ...
    .Difference));

fprintf('\n');
fprintf('Example p-value:\n');

try

    disp( ...
        N5_Stats ...
        .N5 ...
        .N5_Full ...
        .PeakAmplitude ...
        .p)

catch

    warning('Statistics structure check failed');

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'TEST_N5_STEP7.mat'),...
    'N5_Subj',...
    'N5_Group',...
    'N5_Stats',...
    'cfgN5');

%% ============================================================
% FINISH
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('TEST N5 STEP7 COMPLETED\n');
fprintf('================================\n');
fprintf('\n');

disp(outdir);