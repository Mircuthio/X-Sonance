%% =========================================================================
% TEST_MMN_STEP6
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
    [0.10 0.20] ...
    [0.15 0.25] ...
    [0.10 0.25]};

cfgMMN.window_names = { ...
    'MMN_Early' ...
    'MMN_Late' ...
    'MMN_Full'};

cfgMMN.zoom_window = [0.00 0.30];

%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI

cfgMMN.rois = ROI;

%% ============================================================
% ROI CHECK
%% ============================================================

assert(isfield(ROI,'MMN'), ...
    'ROI.MMN not found');

assert(isfield(ROI,'aMMN'), ...
    'ROI.aMMN not found');

assert(isfield(ROI,'afMMN'), ...
    'ROI.afMMN not found');

assert(isfield(ROI,'ERAN_CORE'), ...
    'ROI.ERAN_CORE not found');

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'TEST_MMN_STEP6');

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

fprintf('\n');
fprintf('Generating Waveforms...\n');

plot_mmn_waveforms( ...
    subj_list,...
    cfgMMN,...
    outdir);

%% ============================================================
% ZOOM
%% ============================================================

fprintf('Generating Zoom Plots...\n');

plot_mmn_zoom( ...
    subj_list,...
    cfgMMN,...
    outdir);

%% ============================================================
% FEATURE PLOTS
%% ============================================================

fprintf('Generating Metric Plots...\n');

plot_mmn_metrics( ...
    MMN_Subj,...
    MMN_Stats,...
    cfgMMN,...
    outdir);

%% ============================================================
% ERAN VS MMN
%% ============================================================

fprintf('Generating ERAN/MMN Comparison...\n');

plot_eran_mmn_comparison( ...
    subj_list,...
    cfgMMN,...
    outdir);

%% ============================================================
% QUICK STRUCTURE CHECK
%% ============================================================

subs = fieldnames(MMN_Subj);

fprintf('\n');
fprintf('================================\n');
fprintf('QUICK STRUCTURE CHECK\n');
fprintf('================================\n');

fprintf('\n');
fprintf('MMN WINDOWS:\n');

disp(fieldnames( ...
    MMN_Subj.(subs{1}).MMN));

fprintf('\n');
fprintf('MMN_Full -> Difference Metrics:\n');

disp(fieldnames( ...
    MMN_Subj.(subs{1}) ...
    .MMN ...
    .MMN_Full ...
    .Difference));

fprintf('\n');
fprintf('Example p-value:\n');

try

    disp( ...
        MMN_Stats ...
        .MMN ...
        .MMN_Full ...
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
    'TEST_MMN_STEP6.mat'),...
    'MMN_Subj',...
    'MMN_Group',...
    'MMN_Stats',...
    'cfgMMN');

%% ============================================================
% FINISH
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('TEST MMN STEP6 COMPLETED\n');
fprintf('================================\n');
fprintf('\n');

disp(outdir);
