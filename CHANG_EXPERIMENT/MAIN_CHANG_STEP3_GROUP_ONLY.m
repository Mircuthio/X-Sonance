%% ============================================================
% MAIN_CHANG_STEP3_GROUP_ONLY
%
% Rebuild only:
%   - ERP_Pooled
%   - ERP_Group
%   - ERP Topographies
%
% Using saved subj_list.mat
%% ============================================================

clear; close all; clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

addpath('C:\Users\mirco\Desktop\eeglab2026.1.0')
eeglab nogui
%% ============================================================
% LOAD SUBJ_LIST
%% ============================================================

load('C:\Users\mirco\Desktop\X-SONANCE\CHANG_EXPERIMENT\EPOCH_DATA\subj_list.mat','subj_list');

fprintf('Subjects loaded: %d\n',numel(subj_list));

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI_CHANG_DATASET

cfg = struct();

cfg.comparisonName = 'All';

cfg.conditions = { ...
    'Condition101',...
    'Condition102',...
    'Condition103'};

cfg.cond_field = 'eventLabel';

availableLabels = ...
    {subj_list(1).data_trials(1).chanlocs.labels};

roiNames = fieldnames(ROI);

for r = 1:numel(roiNames)

    ROI.(roiNames{r}) = ...
        intersect( ...
        ROI.(roiNames{r}), ...
        availableLabels, ...
        'stable');

end

cfg.rois = ROI;

cfg.time_field = 'time';
cfg.baseline_win = [-0.2 0];
cfg.analysis_win = [-0.2 0.8];
cfg.target_time_units = 's';

%% ============================================================
% OUTPUT
%% ============================================================

outdir = ...
    fullfile( ...
    pwd,...
    'STEP3_ERP\GROUP_ONLY');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CREATE POOLED STRUCTURE
%% ============================================================

num_trials = ...
    cellfun(@numel,{subj_list.data_trials});

current_idx = 1;

pooled_trials_subject = struct();
pooled_trials_subject(1).subj_id = 'PooledSubjects';

for iSub = 1:numel(subj_list)

    dt_temp = subj_list(iSub).data_trials;

    for k = 1:numel(dt_temp)

        dt_temp(k).subj_id = ...
            subj_list(iSub).subj_id;

    end

    end_idx = ...
        current_idx + numel(dt_temp) - 1;

    pooled_trials_subject(1).data_trials( ...
        current_idx:end_idx) = dt_temp(:);

    current_idx = end_idx + 1;

end

fprintf('Total pooled trials: %d\n', ...
    numel(pooled_trials_subject.data_trials));

%% ============================================================
% ERP
%% ============================================================

ERP_Pooled = struct();
ERP_Group  = struct();

roiNames = fieldnames(cfg.rois);

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    fprintf('\n================================\n');
    fprintf('ROI: %s\n',roiName);
    fprintf('================================\n');

    cfg_curr = cfg;
    cfg_curr.roi_labels = cfg.rois.(roiName);

    %% --------------------------------------------------------
    % POOLED ERP
    %% --------------------------------------------------------

    pooledERP = ...
        extract_roi_erp( ...
        pooled_trials_subject,...
        cfg_curr);

    if isempty(pooledERP)

        fprintf('POOLED EMPTY\n');
        continue

    end

    pooledERP.roiName = roiName;

    ERP_Pooled.(roiName) = pooledERP;

    fprintf('POOLED OK\n');

    %% --------------------------------------------------------
    % GROUP ERP
    %% --------------------------------------------------------

    groupERP = ...
        extract_roi_erp( ...
        subj_list,...
        cfg_curr);

    if isempty(groupERP)

        fprintf('GROUP EMPTY\n');
        continue

    end

    groupERP.roiName = roiName;

    ERP_Group.(roiName) = groupERP;

    fprintf('GROUP OK\n');

    %% --------------------------------------------------------
    % PLOT POOLED
    %% --------------------------------------------------------

    cfgPlot = struct();

    cfgPlot.line_colors = [
        0.00 0.35 0.90
        0.85 0.20 0.20
        0.10 0.60 0.25
        ];

    cfgPlot.patch_alpha = 0.08;

    cfgPlot.cond_idx = 1:3;

    cfgPlot.show_zero = true;
    cfgPlot.show_error = true;

    cfgPlot.smooth_plot = true;
    cfgPlot.smooth_window = 11;

    cfgPlot.error_type = 'sem';
    cfgPlot.error_data = ...
        ERP_Group.(roiName).grand_se;

    cfgPlot.title_str = ...
        sprintf('Pooled ERP - %s',roiName);

    cfgPlot.save_path = ...
        fullfile( ...
        outdir,...
        sprintf( ...
        'ERP_Pooled_%s.png',...
        roiName));

    plot_erp_waveforms( ...
        ERP_Pooled.(roiName),...
        cfgPlot);

    %% --------------------------------------------------------
    % PLOT GROUP
    %% --------------------------------------------------------

    cfgPlot = struct();

    cfgPlot.line_colors = [
        0.00 0.35 0.90
        0.85 0.20 0.20
        0.10 0.60 0.25
        ];

    cfgPlot.patch_alpha = 0.08;

    cfgPlot.cond_idx = 1:3;

    cfgPlot.show_zero = true;
    cfgPlot.show_error = true;

    cfgPlot.smooth_plot = true;
    cfgPlot.smooth_window = 11;

    cfgPlot.error_type = 'sem';
    cfgPlot.error_data = ...
        ERP_Group.(roiName).grand_se;

    cfgPlot.title_str = ...
        sprintf('Group ERP - %s',roiName);

    cfgPlot.save_path = ...
        fullfile( ...
        outdir,...
        sprintf( ...
        'ERP_Group_%s.png',...
        roiName));

    plot_erp_waveforms( ...
        ERP_Group.(roiName),...
        cfgPlot);

end

%% ============================================================
% TOPOGRAPHY
%% ============================================================

cfgERPTopo = struct();

cfgERPTopo.erpWindows.ERAN = [0.15 0.25];
cfgERPTopo.erpWindows.MMN  = [0.10 0.20];
cfgERPTopo.erpWindows.N5   = [0.45 0.55];

windowNames = ...
    fieldnames(cfgERPTopo.erpWindows);

ERP_Topography = struct();

for w = 1:numel(windowNames)

    windowName = windowNames{w};

    cfgTopo = struct();

    cfgTopo.conditions = cfg.conditions;

    cfgTopo.cond_field = cfg.cond_field;
    cfgTopo.time_field = cfg.time_field;

    cfgTopo.window = ...
        cfgERPTopo.erpWindows.(windowName);

    cfgTopo.measure = 'mean';

    cfgTopo.baseline_win = ...
        cfg.baseline_win;

    cfgTopo.analysis_win = ...
        cfg.analysis_win;

    for c = 1:numel(cfg.conditions)

        condName = cfg.conditions{c};

        ERPTopoCond = ...
            create_condition_topography( ...
            subj_list,...
            cfgTopo,...
            condName);

        ERP_Topography.(windowName).( ...
            matlab.lang.makeValidName(condName)) = ...
            ERPTopoCond;

    end

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'ERP_GROUP_ONLY.mat'), ...
    'ERP_Group',...
    'ERP_Pooled',...
    'ERP_Topography',...
    'cfg',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('====================================\n');
fprintf('GROUP ONLY COMPLETED\n');
fprintf('====================================\n');