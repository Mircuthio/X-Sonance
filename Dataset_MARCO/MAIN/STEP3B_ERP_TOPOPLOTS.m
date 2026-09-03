%% =========================================================================
% STEP3B_ERP_TOPOPLOTS
%
% Fast ERP topography generation
%
% Uses STEP2 epoch data directly
% without recomputing ERP waveforms
%
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

addpath(genpath('D:\eeglab2026.0.0\'))

%% ============================================================
% INPUT DIRECTORY
%% ============================================================

step2_indir = ...
    fullfile( ...
    'D:\X-SONANCE\Dataset_MARCO',...
    'DATA_SUBJECTS',...
    'All_trials',...
    'EPOCH_DATA');

if ~exist(step2_indir,'dir')
    error('STEP2 directory not found');
end

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================

outdir = ...
    fullfile( ...
    'D:\X-SONANCE\Dataset_MARCO',...
    'STEP3B_ERP_TOPOPLOTS');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% LOAD SUBJECTS
%% ============================================================

files = dir(fullfile(step2_indir,'*_epochData.mat'));

if isempty(files)
    error('No epoch files found');
end

nFiles = numel(files);

subj_list = struct( ...
    'subj_id',cell(nFiles,1), ...
    'data_trials',cell(nFiles,1));

for i = 1:nFiles

    S = load(fullfile( ...
        files(i).folder,...
        files(i).name));

    subjData = S.subjectEpochData;

    subj_list(i).subj_id = ...
        subjData.subjectID;

    subj_list(i).data_trials = ...
        subjData.data_trials;

    fprintf('[%02d/%02d] %s loaded\n',...
        i,nFiles,...
        string(subjData.subjectID));

end

%% ============================================================
% COMPARISON
%% ============================================================

cfg = struct();

cfg.comparisonName = 'Consonance';

cfg.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfg.cond_field = 'eventLabel';

cfg.time_field = 'time';

cfg.baseline_win = [-0.2 0];

cfg.analysis_win = [-0.2 0.8];

%% ============================================================
% TOPOGRAPHY WINDOWS
%% ============================================================

erpWindows = struct();

% Classical
erpWindows.MMN = [0.10 0.20];
erpWindows.ERAN = [0.15 0.25];
erpWindows.N5 = [0.45 0.55];

% Data-driven
erpWindows.EarlyNeg = [0.17 0.22];

erpWindows.Rebound = [0.22 0.32];

erpWindows.Late = [0.45 0.55];

%% ============================================================
% MEASURES
%% ============================================================

measureList = { ...
    'mean',...
    'min',...
    'max'};

%% ============================================================
% RUN
%% ============================================================

ERP_Topography = struct();

windowNames = fieldnames(erpWindows);

for m = 1:numel(measureList)

    measureName = measureList{m};

    fprintf('\n');
    fprintf('===============================\n');
    fprintf('MEASURE: %s\n',measureName);
    fprintf('===============================\n');

    measure_outdir = ...
        fullfile(outdir,upper(measureName));

    if ~exist(measure_outdir,'dir')
        mkdir(measure_outdir);
    end

    for w = 1:numel(windowNames)

        windowName = ...
            windowNames{w};

        fprintf('%s\n',windowName);

        cfgTopo = struct();

        cfgTopo.conditions = ...
            cfg.conditions;

        cfgTopo.cond_field = ...
            cfg.cond_field;

        cfgTopo.time_field = ...
            cfg.time_field;

        cfgTopo.window = ...
            erpWindows.(windowName);

        cfgTopo.measure = ...
            measureName;

        cfgTopo.baseline_win = ...
            cfg.baseline_win;

        cfgTopo.analysis_win = ...
            cfg.analysis_win;

        %% ----------------------------------------------------
        % CONDITIONS
        %% ----------------------------------------------------

        for c = 1:numel(cfg.conditions)

            condName = ...
                cfg.conditions{c};

            ERPTopoCond = ...
                create_condition_topography( ...
                subj_list,...
                cfgTopo,...
                condName);

            ERP_Topography ...
                .(measureName) ...
                .(windowName) ...
                .(matlab.lang.makeValidName(condName)) = ...
                ERPTopoCond;

            cfgPlot = struct();

            cfgPlot.title_str = ...
                sprintf( ...
                '%s | %s | %s',...
                windowName,...
                condName,...
                upper(measureName));

            cfgPlot.save_path = ...
                fullfile( ...
                measure_outdir,...
                sprintf( ...
                'ERP_TOPO_%s_%s_%s.png',...
                windowName,...
                condName,...
                upper(measureName)));

            plot_erp_topoplot( ...
                ERPTopoCond,...
                cfgPlot);

        end

        %% ----------------------------------------------------
        % DIFFERENCE
        %% ----------------------------------------------------

        ERPTopoDiff = ...
            create_difference_topography( ...
            subj_list,...
            cfgTopo);

        ERP_Topography ...
            .(measureName) ...
            .(windowName) ...
            .Difference = ...
            ERPTopoDiff;

        cfgPlot = struct();

        cfgPlot.title_str = ...
            sprintf( ...
            '%s Difference (%s)',...
            windowName,...
            upper(measureName));

        cfgPlot.save_path = ...
            fullfile( ...
            measure_outdir,...
            sprintf( ...
            'ERP_TOPO_%s_DIFFERENCE_%s.png',...
            windowName,...
            upper(measureName)));

        plot_difference_topoplot( ...
            ERPTopoDiff,...
            cfgPlot);

    end
end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'ERP_TOPOLOGY_REANALYSIS.mat'),...
    'ERP_Topography',...
    'erpWindows',...
    '-v7.3');

close all

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP3B ERP TOPOPLOTS COMPLETED\n');
fprintf('================================\n');