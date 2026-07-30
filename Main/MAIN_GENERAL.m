%% ============================================================
% MAIN_ERP.m
% Carica i dati STEP2 e instrada analisi single o group
%% ============================================================
clear; close all; clc
origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');
%% 1) PATH
step2_outdir = 'D:\X-SONANCE\Goldman\Output\STEP2_OUTPUT';
if ~exist(step2_outdir, 'dir')
    error('Cartella STEP2 non trovata: %s', step2_outdir);
end

%% 2) LOAD FILES STEP2
files = dir(fullfile(step2_outdir, '*_epochData.mat'));
if isempty(files)
    error('Nessun file *_epochData.mat trovato in %s', step2_outdir);
end

nFiles = numel(files);
subj_list = struct('subj_id', cell(nFiles,1), 'data_trials', cell(nFiles,1));

for i = 1:nFiles
    S = load(fullfile(files(i).folder, files(i).name));

    if ~isfield(S, 'subjectEpochData')
        error('Nel file %s non trovo subjectEpochData.', files(i).name);
    end

    subjData = S.subjectEpochData;

    if isfield(subjData, 'subjectID')
        subj_list(i).subj_id = subjData.subjectID;
    else
        subj_list(i).subj_id = regexprep(files(i).name, '_epochData\.mat$', '');
    end

    if isfield(subjData, 'data_trials')
        subj_list(i).data_trials = subjData.data_trials;
    else
        error('Nel file %s non trovo data_trials.', files(i).name);
    end

    fprintf('Caricato soggetto %s\n', string(subj_list(i).subj_id));
end

%% 3) PARAMETERS
%% ERP ANALYSES
%
% 1. Subject-level ERP
% 2. Pooled-trial ERP
% 3. Group-average ERP
% 4. LIMO input preparation
cfg = struct();
cfg.conditions    = {'consonant','dissonant'};
cfg.cond_field    = 'trialName';     % oppure 'trialType'

MAIN_ROI
cfg.rois = ROI;

cfg.time_field        = 'time';
cfg.baseline_win      = [-200 0];
cfg.analysis_win      = [-200 800];
cfg.subject_ids       = {};              % vuoto = tutti
cfg.target_time_units = 's'; % or 'ms'

%% 4) ERP and PLOT
ERP_subj = struct();
for iSub = 1:numel(subj_list)
    try
        subj_curr = subj_list(iSub);
        subj_in   = subj_curr;   % struct 1x1, singolo soggetto
        subj_id = subj_curr.subj_id;
        fprintf('\n==============================\n');
        fprintf('Soggetto: %s\n', string(subj_curr.subj_id));
        fprintf( ...
            'Trial disponibili: %d\n',...
            numel(subj_curr.data_trials));
        fprintf('==============================\n');
        roiNames = fieldnames(cfg.rois);
        for r = 1:numel(roiNames)
            roiName = roiNames{r};
            cfg_curr = cfg;
            cfg_curr.roi_labels = cfg.rois.(roiName);
            roi_erp = extract_roi_erp( ...
                subj_in, ...
                cfg_curr);
            roi_erp.roiName = roiName;
            if isempty(roi_erp)
                warning('No ERP extracted for %s', ...
                    string(subj_curr.subj_id));
                continue
            end
            ERP_subj.(subj_id).(roiName) = roi_erp;
            % ERP PLOT
            cfgPlot = struct();
            cfgPlot.cond_idx  = 1:numel(cfg.conditions);
            cfgPlot.show_zero = true;
            cfgPlot.show_error = true;
            cfgPlot.error_type = 'sem';
            cfgPlot.error_data = roi_erp.grand_se;
            cfgPlot.title_str = sprintf('ERP %s - %s',string(subj_curr.subj_id),roiName);
            safeID = regexprep(string(subj_curr.subj_id),'[^\w]','_');
            save_dir = fullfile(step2_outdir, 'ERP_plots', roiName);
            if ~exist(save_dir, 'dir'), mkdir(save_dir); end
            cfgPlot.save_path = fullfile(save_dir, sprintf('ERP_%s_%s.png', safeID, roiName));
            Subj_plot = plot_erp_waveforms(roi_erp, cfgPlot);
        end
    catch ME
        fprintf('\nERP ERROR %s\n', ...
            string(subj_curr.subj_id));
        fprintf('%s\n',ME.message);
    end
end

%% GROUP MODE: concatenate all trials, build pooled ERP per ROI
num_trials = nan(1, numel(subj_list));
for iSub = 1:numel(subj_list)
    num_trials(iSub) = numel(subj_list(iSub).data_trials);
end
total_trials = sum(num_trials);
current_idx = 1;
pooled_trials_subject = struct();
pooled_trials_subject(1).subj_id = 'PooledSubjects';
for iSub = 1:numel(subj_list)
    dt_temp = subj_list(iSub).data_trials;
    n_subj_trials = num_trials(iSub);
    for k = 1:n_subj_trials
        dt_temp(k).subj_id = subj_list(iSub).subj_id;
    end
    end_idx = current_idx + n_subj_trials - 1;
    pooled_trials_subject(1).data_trials(current_idx:end_idx) = dt_temp(:);
    current_idx = end_idx + 1;
end
roiNames = fieldnames(cfg.rois);
ERP_Pooled = struct();
ERP_Group = struct();
for r = 1:numel(roiNames)
    roiName = roiNames{r};
    cfg_curr = cfg;
    cfg_curr.roi_labels = cfg.rois.(roiName);
    %% POOLED-TRIAL ERP
    % Concatenate all trials from all subjects and build
    % a single ERP waveform per ROI.
    roi_erp = extract_roi_erp(pooled_trials_subject, cfg_curr);
    if isempty(roi_erp)
        warning('No ERP extracted for ROI %s', roiName);
        continue
    end
    roi_erp.roiName = roiName;
    ERP_Pooled.(roiName) = roi_erp;
    % ERP Pooled PLOT
    cfgPlot = struct();
    cfgPlot.cond_idx = 1:numel(cfg.conditions);
    cfgPlot.title_str = sprintf('Pooled-Trial ERP - %s', roiName);
    cfgPlot.show_zero = true;
    cfgPlot.show_error = true;
    cfgPlot.error_type = 'sem';
    cfgPlot.error_data = ERP_Pooled.(roiName).grand_se;
    cfgPlot.save_path = fullfile(step2_outdir, 'ERP_plots', roiName, sprintf('ERP_Pooled_%s.png', roiName));
    [plot_dir,~,~] = fileparts(cfgPlot.save_path);
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    Pooled_plot = plot_erp_waveforms(ERP_Pooled.(roiName), cfgPlot);
    %% Group-average ERP
    roi_erp = extract_roi_erp(subj_list, cfg_curr);
    if isempty(roi_erp)
        warning('No ERP extracted for ROI %s', roiName);
        continue
    end
    roi_erp.roiName = roiName;
    ERP_Group.(roiName) = roi_erp;
    % ERP Group PLOT
    cfgPlot = struct();
    cfgPlot.cond_idx = 1:numel(cfg.conditions);
    cfgPlot.title_str = sprintf('Group ERP - %s', roiName);
    cfgPlot.show_zero = true;
    cfgPlot.show_error = true;
    cfgPlot.error_type = 'sem';
    cfgPlot.error_data = ERP_Group.(roiName).grand_se;
    cfgPlot.save_path = fullfile(step2_outdir, 'ERP_plots', roiName, sprintf('ERP_Group_%s.png', roiName));
    [plot_dir,~,~] = fileparts(cfgPlot.save_path);
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    Group_plot = plot_erp_waveforms(ERP_Group.(roiName), cfgPlot);
    %% Prepare ROI-by-subject matrices for LIMO
    cfgLIMO = struct();
    cfgLIMO.conditions = cfg.conditions;
    cfgLIMO.cond_field = cfg.cond_field;
    cfgLIMO.rois       = cfg.rois;
    cfgLIMO.time_field = cfg.time_field;
    cfgLIMO.target_time_units = cfg.target_time_units;
    limo_input = create_group_erp_by_roi( ...
        subj_list, ...
        cfgLIMO);
    cfgLimoPlot = struct();
    cfgLimoPlot.conditions = cfg.conditions;
    cfgLimoPlot.alpha = 0.05;
    cfgLimoPlot.trim_percent = 0;
    cfgLimoPlot.line_colors = [
        0 0.4470 0.7410
        0.8500 0.3250 0.0980
        ];
    cfgLimoPlot.ci_alpha = 0.15;
    cfgLimoPlot.title_str =  sprintf('Limo-Group ERP - %s', roiName);
    cfgLimoPlot.save_path = fullfile(step2_outdir, 'ERP_plots', roiName, sprintf('Limo_Group_%s.png', roiName));
    [plot_dir,~,~] = fileparts(cfgLimoPlot.save_path);
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    Limo_plot = plot_limo_erp_comparison(limo_input.(roiName),cfgLimoPlot);
end

set(0,'DefaultFigureVisible',origState);