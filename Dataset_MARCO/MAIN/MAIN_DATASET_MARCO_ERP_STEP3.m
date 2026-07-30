%% ============================================================
% MAIN_DATASET_MARCO_ERP_STEP3.m
% Carica i dati STEP2 e instrada analisi single o group
%% ============================================================
clear; close all; clc
origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');
addpath(genpath('D:\eeglab2026.0.0\'))

%% 1) PATH
step2_indir = ...
'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA';
if ~exist(step2_indir, 'dir')
    error('Cartella STEP2 non trovata: %s', step2_indir);
end
%% 2) LOAD FILES STEP2
files = dir(fullfile(step2_indir, '*_epochData.mat'));
if isempty(files)
    error('Nessun file *_epochData.mat trovato in %s', step2_indir);
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

comparisonName = 'Difference';
switch comparisonName
    case 'Consonance'
        cfg.conditions = { ...
            'Consonant',...
            'Dissonant'};
    case 'Difference'
        cfg.conditions = { ...
            'ConsonantGOAL',...
            'DissonantNoGOAL'};
    case 'Goal'
        cfg.conditions = { ...
            'ConsonantGOAL',...
            'DissonantGOAL'};
    case 'NoGoal'
        cfg.conditions = { ...
            'ConsonantNoGOAL',...
            'DissonantNoGOAL'};

    case 'Control'
        cfg.conditions = { ...
            'ControlGOAL',...
            'ControlNoGOAL'};
    case 'All'
        cfg.conditions = { ...
            'ConsonantGOAL',...
            'DissonantGOAL',...
            'ControlGOAL',...
            'ConsonantNoGOAL',...
            'DissonantNoGOAL',...
            'ControlNoGOAL',...
            'Consonant',...
            'Dissonant'};
end

cfg.cond_field = 'eventLabel';
MAIN_ROI
cfg.rois = ROI;
cfg.time_field = 'time';
cfg.baseline_win = [-0.2 0];
cfg.analysis_win = [-0.2 0.8];
cfg.subject_ids = {};
cfg.target_time_units = 's';
cfg.generate_difference_plots = true;

fprintf('\n');
fprintf('================================\n');
fprintf('ERP CONFIGURATION\n');
fprintf('================================\n');

disp(cfg.conditions)

fprintf('Cond field : %s\n',cfg.cond_field);
fprintf('Baseline   : %.3f %.3f s\n', ...
    cfg.baseline_win);

fprintf('Analysis   : %.3f %.3f s\n', ...
    cfg.analysis_win);
% outputdir
step4_outdir = fullfile(step2_indir,comparisonName);

cfgPlot.smooth_plot = false;
cfgPlot.smooth_window = 5;
cfgDiff.smooth_plot = false;
cfgDiff.smooth_window = 5;
if cfgPlot.smooth_plot
    step4_outdir = fullfile(step4_outdir,'SMOOTH');
end
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
            save_dir = fullfile(step4_outdir, 'ERP_plots', roiName);
            if ~exist(save_dir, 'dir'), mkdir(save_dir); end
            cfgPlot.save_path = fullfile(save_dir, sprintf('ERP_%s_%s.png', safeID, roiName));
            Subj_plot = plot_erp_waveforms(roi_erp, cfgPlot);
            if cfg.generate_difference_plots && ...
                    numel(cfg.conditions)==2
                cfgDiff = struct();
                cfgDiff.title_str = sprintf( ...
                    'Difference ERP %s - %s',string(subj_curr.subj_id),roiName);
                cfgDiff.save_path = fullfile( ...
                    save_dir,sprintf('ERP_Difference_%s_%s.png',safeID,roiName));
                plot_difference_wave(roi_erp,cfgDiff);
            end
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
    cfgPlot.save_path = fullfile(step4_outdir, 'ERP_plots', roiName, sprintf('ERP_Pooled_%s.png', roiName));
    [plot_dir,~,~] = fileparts(cfgPlot.save_path);
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    Pooled_plot = plot_erp_waveforms(ERP_Pooled.(roiName), cfgPlot);
    if cfg.generate_difference_plots && ...
            numel(cfg.conditions)==2
        cfgDiff = struct();
        cfgDiff.title_str = sprintf('Pooled Difference ERP - %s',roiName);
        cfgDiff.save_path = fullfile( ...
            step4_outdir,'ERP_plots',roiName,sprintf('ERP_Pooled_Difference_%s.png',roiName));
        plot_difference_wave(ERP_Pooled.(roiName),cfgDiff);
    end
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
    cfgPlot.save_path = fullfile(step4_outdir, 'ERP_plots', roiName, sprintf('ERP_Group_%s.png', roiName));
    [plot_dir,~,~] = fileparts(cfgPlot.save_path);
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    Group_plot = plot_erp_waveforms(ERP_Group.(roiName), cfgPlot);
    if numel(cfg.conditions)==2
        cfgDiff = struct();
        cfgDiff.title_str = sprintf('Difference ERP - %s',roiName);
        cfgDiff.save_path = ...
            fullfile(step4_outdir,'ERP_plots',roiName,sprintf('ERP_Difference_%s.png',roiName));
        Diff_plot = plot_difference_wave(ERP_Group.(roiName),cfgDiff);
    end
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
    cfgLimoPlot.save_path = fullfile(step4_outdir, 'ERP_plots', roiName, sprintf('Limo_Group_%s.png', roiName));
    [plot_dir,~,~] = fileparts(cfgLimoPlot.save_path);
    if ~exist(plot_dir, 'dir'), mkdir(plot_dir); end
    Limo_plot = plot_limo_erp_comparison(limo_input.(roiName),cfgLimoPlot);
end
save( ...
    fullfile(step4_outdir,'ERP_STEP3_RESULTS.mat'), ...
    'ERP_subj', ...
    'ERP_Pooled', ...
    'ERP_Group', ...
    'limo_input', ...
    'cfg', ...
    '-v7.3');

return
%% TOPOPLOT
subj_topo = select_roi_channels(subj_list, ROI.ERAN);

cfg.erpWindows = struct();
cfg.erpWindows.ERAN = [0.15 0.25];
cfg.erpWindows.N5   = [0.45 0.55];
cfg.erpWindows.MMN  = [0.10 0.20];

cfgTopo = struct();
cfgTopo.conditions = cfg.conditions;
cfgTopo.cond_field = cfg.cond_field;
cfgTopo.time_field = cfg.time_field;

cfgTopo.window = cfg.erpWindows.ERAN;
cfgTopo.window = cfg.erpWindows.N5;
cfgTopo.window = [0.18 0.23];
cfgTopo.measure = 'min';

ERPTopo = create_difference_topography(subj_list,cfgTopo);
[min(ERPTopo.values) max(ERPTopo.values)]
T = table( ...
string({ERPTopo.chanlocs.labels})', ...
ERPTopo.subject_values(3,:)', ...
'VariableNames',{'Channel','Value'});

sortrows(T,'Value','descend')

figure
for s=1:size(ERPTopo.subject_values,1)
    subplot(2,3,s)
    topoplot( ...
        ERPTopo.subject_values(s,:), ...
        ERPTopo.chanlocs, ...
        'electrodes','off');
    title(sprintf('Subj%d',s))
end

cfgTopoPlot = struct();
cfgTopoPlot.title_str ='ERAN Difference Topography';
cfgTopoPlot.clim = [];
plot_difference_topoplot(ERPTopo,cfgTopoPlot);


set(0,'DefaultFigureVisible',origState);