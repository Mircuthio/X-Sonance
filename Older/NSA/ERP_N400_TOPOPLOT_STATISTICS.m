% ERP_N400_TOPOPLOT_STATISTIC.m
%% MAIN
% questo main realizza la statistica dei TOPOPLOT degli andamenti ERP di 1-
% Congruente Inglese (Congruent Eng), 2-Congruente Italiano (Congruent Ita) 3-
% Incongruente Inglese (Congruente Eng) 4-Incongruente Italiano (Congruente Ita) e 5-
% Scrambled (Scr) ed in 7 differenti bande EEG (indicate in seguito)
% ottenute come ERP medi tra gli andamenti nel tempo in un intervallo 0-2.5
% tra tutti i canali e tutti i soggetti proiettati poi fino ad un end_point

%Escludiamo il soggetto 6-DEMA in attesa di verifica della coerenza delle
%label

% Specifics:
% label indexes
% 1: Congruent ENGLISH
% 2: Congruent ITALIAN
% 3: INCongruent ENGLISH
% 4: INCongruent ITALIAN
% 5: SCRAMBLED

clear; close all;

par.irng = 10;
rng(par.irng);

EEG_all = struct();
EEG_allPreStim = struct();

load("Delay_ALL.mat");
load("badTrials.mat")
ROI = 1;
save_dirAll = 'D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\NEW_FIGURE\TOPOPLOT_STATISTIC\ROI\';

starting_time = 0;
ending_time = 2.5;

start_plot  = 0;
end_plot    = 0.8;

% idsub = [2:6,8:18,21];
idsub = 1:21;
for indsub = 1:length(idsub)
    signal_name                     = 'eeg';
    signal_process                  = 'erp';

    %% Extract and Arrange Data
    par.extractSound.signal_name    = signal_name;
    par.extractSound.InField        = 'train';
    par.extractSound.it_end         = 2.5;
    par.extractSound.multiEpoch     = true;
    [EEG_trials_sub,fsample]        = extractSound(idsub(indsub),par.extractSound);

    % badT = badTrials(indsub).trials;
    % if ~isempty(badT)
    %
    %     allIDs = [EEG_trials_sub.trialId];
    %
    %     idxRemove = ismember(allIDs, badT);
    %
    %     EEG_trials_sub(idxRemove) = [];
    % end

    %% Extract Pre-Stimulus data
    t_preStim_start = -0.2;
    t_preStim_end = 0;
    % Time Interpolation and selection Trials
    par.TimeSelectSoundDelay               = TimeSelectParams;
    par.TimeSelectSoundDelay.t1            = t_preStim_start*ones(1,length(EEG_trials_sub));
    par.TimeSelectSoundDelay.t2            = t_preStim_end*ones(1,length(EEG_trials_sub));
    par.TimeSelectSoundDelay.InField       = signal_name;
    par.TimeSelectSoundDelay.OutField      = signal_name;

    par.exec.funname ={'TimeSelectSoundDelay'};
    [EEG_trials_subPreStim,out_trialsPreStim] = run_trials(EEG_trials_sub,par);

    %% Extract Stimulus data
    delay_sub = Delay_ALL(indsub).trials;
    t_start = NaN(length(EEG_trials_sub),1);
    for iTr=1:length(EEG_trials_sub)
        idx = find(delay_sub(:, 1) == iTr);
        if ~isempty(idx)
            t_start(iTr) = delay_sub(idx,2);
        else
            % Altrimenti, assegna 0.8
            t_start(iTr) = starting_time;
        end
    end

    % Time Interpolation and selection Trials
    par.TimeSelectSoundDelay               = TimeSelectParams;
    par.TimeSelectSoundDelay.t1            = t_start; % in s from ZeroEvent time
    par.TimeSelectSoundDelay.t2            = t_start + ending_time; % in s from ZeroEvent time
    par.TimeSelectSoundDelay.InField       = signal_name;
    par.TimeSelectSoundDelay.OutField      = signal_name;

    par.exec.funname ={'TimeSelectSoundDelay'};
    [EEG_trials_sub,out_trials] = run_trials(EEG_trials_sub,par);

    % % remapTypes
    % par.remapTypes           = remapTypesParams();
    % par.remapTypes.selection = {1,2};
    %
    % EEG_trials_subPreStim = remapTypes(EEG_trials_subPreStim,par.remapTypes);
    % EEG_trials_sub = remapTypes(EEG_trials_sub,par.remapTypes);

    StartClass = unique([EEG_trials_sub.trialType]);

    EEG_all(indsub).data = EEG_trials_sub;
    EEG_allPreStim(indsub).data = EEG_trials_subPreStim;
end

% %% Pre stimulus
% for nfield   = fieldnames(EEG_allPreStim)'
%     namefield   = nfield{1};
%     cellsfield  = {EEG_allPreStim.(namefield)};
%     EEG_dataPreStim    = cat(1,cellsfield{:});
% end
%
% for iTr=1:length(EEG_dataPreStim)
%     EEG_dataPreStim(iTr).trialId = iTr;
% end
% EEG_trialsPreStim = EEG_dataPreStim;

% %% Stimulus Data
% for nfield   = fieldnames(EEG_all)'
%     namefield   = nfield{1};
%     cellsfield  = {EEG_all.(namefield)};
%     EEG_data    = cat(1,cellsfield{:});
% end
%
% for iTr=1:length(EEG_data)
%     EEG_data(iTr).trialId = iTr;
% end
% EEG_trials = EEG_data;

%% Filter Bank
par.FilterBankCompute            = FilterBankComputeParams();
par.FilterBankCompute.InField    = signal_name;
par.FilterBankCompute.OutField   = signal_name;
% par.FilterBankCompute.f_min      = 1;
% par.FilterBankCompute.f_max      = 90;
% par.FilterBankCompute.FilterBank = 'EEGbands';
par.FilterBankCompute.FilterBank = 'One';
par.FilterBankCompute.f_min  = 0.1; % min frequency range in Hz
par.FilterBankCompute.f_max  = 30; % Max frequency range in Hz 20 30 o 40 oppure delta e Tetha
par.FilterBankCompute.fsample    = fsample;

if strcmp(par.FilterBankCompute.FilterBank,'EEGbands')
    ylim1 = [-0.3 0.3];
else
    ylim1 = [-4 4];
end
par.exec.funname ={'FilterBankCompute'};

EEG_FilterPreStim_sub = struct();
EEG_Filter_sub = struct();
for nsub=1:length(EEG_all)
    [EEG_FilterPreStim_sub(nsub).data, par.execinfo]=run_trials(EEG_allPreStim(nsub).data,par);
    [EEG_Filter_sub(nsub).data, par.execinfo]=run_trials(EEG_all(nsub).data,par);
end

%% Baseline Removing
EEG_FilterRB_sub = struct();
EEG_FilterPreStimRB_sub = struct();
for n_sub = 1:length(EEG_Filter_sub)
    EEG_Filter = EEG_Filter_sub(n_sub).data;
    EEG_FilterPreStim = EEG_FilterPreStim_sub(n_sub).data;
    EEG_FilterRB = EEG_Filter;
    EEG_FilterPreStimRB = EEG_FilterPreStim;
    for iTr=1:length(EEG_Filter)
        baseline = EEG_FilterPreStim(iTr).(signal_name);
        eeg_data  = EEG_Filter(iTr).(signal_name);
        eeg_dataRB = NaN(size(eeg_data));
        eeg_preStmRB = NaN(size(baseline));
        for nbands = 1:size(eeg_data,3)
            eeg_data_band = eeg_data(:,:,nbands);
            baseline_band = baseline(:,:,nbands);
            for nch =1:size(eeg_data_band,1)
                mean_base = mean(baseline_band(nch,:));
                eeg_dataRB(nch,:,nbands) = eeg_data_band(nch,:)-mean_base;
                eeg_preStmRB(nch,:,nbands) = baseline_band(nch,:)-mean_base;
            end
        end
        EEG_FilterRB(iTr).(signal_name) = eeg_dataRB;
        EEG_FilterPreStimRB(iTr).(signal_name) = eeg_preStmRB;
    end
    EEG_FilterRB_sub(n_sub).data = EEG_FilterRB;
    EEG_FilterPreStimRB_sub(n_sub).data  = EEG_FilterPreStimRB;
end

EEG_sub = struct();
for nsub=1:length(EEG_FilterRB_sub)
    EEG_app = EEG_FilterRB_sub(nsub).data;
    ERP = struct();
    for nclass = 1:length(StartClass)
        ERP(nclass).data = EEG_app([EEG_app.trialType]==StartClass(nclass));
    end
    EEG_sub(nsub).data = ERP;
end

ERP_sub = struct();
for n_sub=1:length(EEG_sub)
    EEG_app = EEG_sub(n_sub).data;
    ERP_app = struct();
    for n_class=1:length(EEG_app)
        EEG_app_data = EEG_app(n_class).data;
        ERP_app(n_class).data = cat(3,EEG_app_data.(signal_name));
        ERP_app(n_class).data_mean = mean(ERP_app(n_class).data,3);
    end
    ERP_sub(n_sub).data = ERP_app;
end

ERP_All = struct();
for nclass=1:length(StartClass)
    ERPsubj = cell(length(ERP_sub),1);
    for nsub=1:length(ERP_sub)
        ERPsubj{nsub,1} = ERP_sub(nsub).data(nclass).data_mean;
    end
    ERP_All(nclass).data = ERPsubj;
end

%% Select Center Midline Electrodes
load("D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\chanloc.mat");

roi = {'Cz','C1','C2','C3','C4','C5','C6','C7','C8',...
    'FC1','FC2','FC3','FC4','FC5','FC6','FC7','FC8',...
    'CP1', 'CP2', 'CP3', 'CP4','CP5', 'CP6','CP7', 'CP8',...
    'Pz', 'P1','P2','P3','P4','P5','P6','P7','P8'};

roi_memb = ismember({chanloc.labels}, roi);
chan_id = 1:length(chanloc);
roi_id = chan_id(roi_memb);

ScalpArea = {roi_id};
Scalp_memb = {roi_memb};
ERP_final = struct();
for sa = 1:length(ScalpArea)
    if ROI == 1
        selected_area = ScalpArea{sa};
        chanlocSelected = chanloc(Scalp_memb{sa});
    else
        selected_area = 1:size(EEG_FilterRB(1).eeg,1); % all Channels
    end
    %% Select Area
    for nclass=1:length(StartClass)
        ERP_app = ERP_All(nclass).data;
        ERP_chan = cell(size(ERP_app));
        for iTr=1:length(ERP_app)
            ERP_chan{iTr,1} = ERP_app{iTr,1}(selected_area,:);
        end
        ERP_final(nclass).data = ERP_chan;
    end
end
%% Five Group Statistic
addpath(genpath('D:\topographic_analyses_eeg-main'))
%% TCT test
cfg_tct = [];
% cfg.latency = 'all';
cfg_tct.normalize= 'yes';
cfg_tct.numrandomization = 500;
cfg_tct.parameter = 'raw';
TCT_class = struct();
for n_class=1:length(StartClass)
    ERP_TCT = ERP_final(n_class).data';
    [stat_cond1] = topostats_SingleConditionTCT(cfg_tct, ERP_TCT{:});
    TCT_class(n_class).stats = stat_cond1;
end

%% TANOVA test
N_subj = 21;
N_cond = 5;
Subj = 1:N_subj;
Conditions = 1:N_cond;

cfg_tanova = [];

% Conditions (IVAR) -> [1...1, 2...2, 3...3, 4...4, 5...5]
Row_cond = repmat(Conditions, N_subj, 1);
Row_cond = reshape(Row_cond, 1, []); % row vector

% Row 2: Subj (UVAR) -> [1..21, 1..21, 1..21, 1..21, 1..21]
Row_subj = repmat(Subj, 1, N_cond);

cfg_tanova.design = [Row_cond; Row_subj];

% 3.Id row
cfg_tanova.ivar = 1; % Conditions 1st row
cfg_tanova.uvar = 2; % Subjects 2nd row

% 4. options
cfg_tanova.parameter = 'raw';          % data type: double channel*bin
cfg_tanova.numrandomization = 10000;   % icrease precision
cfg_tanova.normalize = 'yes';          % normalization
cfg_tanova.clusteralpha = 0.05;
cfg_tanova.alpha = 0.05;

data_tanova = cell(1,N_subj*N_cond);
m = 1;
for c = 1:N_cond
    for s = 1:N_subj
        data_tanova{1,m} = ERP_final(c).data{s,1};
        m=m+1;
    end
end

% size check
if length(data_tanova) ~= size(cfg_tanova.design, 2)
    error('Error: The number of observations in the data does not match the design.');
end

% TANOVA test
fprintf('\nStarting TANOVA with %d permutation...\n', cfg_tanova.numrandomization);
[stat_TANOVA] = topostats_DEPsamplesTANOVA(cfg_tanova, data_tanova{:});

fprintf('\n--- TANOVA RESULTS---\n');
fprintf('Omnibus Probability: %.4f\n', stat_TANOVA.omnibus_prob);

if stat_TANOVA.omnibus_prob <= cfg_tanova.alpha
    disp('There is a topographical difference.');
else
    disp('No significant result');
end

if ~isempty(stat_TANOVA.clusters)
    fprintf('Found %d cluster. \nP-value significant cluster (<= %.2f):\n', ...
        numel(stat_TANOVA.clusters), cfg_tanova.alpha);
    for i = 1:numel(stat_TANOVA.clusters)
        if stat_TANOVA.clusters(i).prob <= cfg_tanova.alpha
            fprintf('  - Cluster %d (Dimension: %d samples): p = %.4f\n', ...
                i, stat_TANOVA.clusters(i).clusterstat, stat_TANOVA.clusters(i).prob);
        end
    end
else
    disp('No sgnificant cluster');
end

% GFP test
cfg_GFP = cfg_tanova;
fprintf('\nStarting GFP with %d permutation...\n', cfg_GFP.numrandomization);
[stat_GFP] = topostats_DEPsamplesGFPcontrast(cfg_GFP, data_tanova{:});

fprintf('\n--- GFP RESULTS---\n');
fprintf('Omnibus Probability: %.4f\n', stat_GFP.omnibus_prob);

if stat_GFP.omnibus_prob <= cfg_GFP.alpha
    disp('There is a topographical difference.');
else
    disp('No significant result');
end

if ~isempty(stat_GFP.clusters)
    fprintf('Found %d cluster. \nP-value significant cluster (<= %.2f):\n', ...
        numel(stat_GFP.clusters), cfg_GFP.alpha);
    for i = 1:numel(stat_GFP.clusters)
        if stat_GFP.clusters(i).prob <= cfg_GFP.alpha
            fprintf('  - Cluster %d (Dimension: %d samples): p = %.4f\n', ...
                i, stat_GFP.clusters(i).clusterstat, stat_GFP.clusters(i).prob);
        end
    end
else
    disp('No sgnificant cluster');
end

%% Report
cfg_cluster = [];
cfg_cluster.alpha = 0.05;
cluster_TCT = struct();
for nclass = 1:length(StartClass)
    cluster_TCT(nclass).cluster   = topostats_ReportStats(cfg_cluster, TCT_class(nclass).stats);
end
cluster_TANOVA = topostats_ReportStats(cfg_cluster, stat_TANOVA);
cluster_GFP   = topostats_ReportStats(cfg_cluster, stat_GFP);

% save Report
output_dir = save_dirAll;
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end
save_dir = fullfile(output_dir, 'TableResult.mat');
save(save_dir, 'cluster_TCT', 'cluster_TANOVA','cluster_GFP');

%% Significant interval
id_start = stat_TANOVA.clusters(1).cluster_idx(1);
id_stop = stat_TANOVA.clusters(1).cluster_idx(end);

starting_time = stat_TANOVA.time(id_start) * 1000;
ending_time = stat_TANOVA.time(id_stop) * 1000;

fprintf('The significant time interval is approximately between %.1f ms e %.1f ms.\n', starting_time, ending_time);

%% plot
for nclass = 1:length(StartClass)
    topostats_PlotStats(TCT_class(nclass).stats);
    set(gcf, 'WindowState', 'maximized');
    name_plotTCT = ['TCT_plot_class',num2str(nclass)];
    % plot saving params
    save_dir                        = [save_dirAll,'TCT',filesep];
    par.savePlotEpsPdfMat.dir_png   = strcat(save_dir,'\PNGs');
    par.savePlotEpsPdfMat.dir_pdf   = strcat(save_dir,'PDFs\');
    par.savePlotEpsPdfMat.dir_mat   = strcat(save_dir,'MATfiles\');
    par.savePlotEpsPdfMat.file_name = name_plotTCT;
    savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
    close
end
% plot TANOVA
topostats_PlotStats(stat_TANOVA);
set(gcf, 'WindowState', 'maximized');
name_plotTANOVA                     = 'TANOVA_plot';
save_dir                            = [save_dirAll,'TANOVA',filesep];
par.savePlotEpsPdfMat.dir_png       = strcat(save_dir,'\PNGs');
par.savePlotEpsPdfMat.dir_pdf       = strcat(save_dir,'PDFs\');
par.savePlotEpsPdfMat.dir_mat       = strcat(save_dir,'MATfiles\');
par.savePlotEpsPdfMat.file_name     = name_plotTANOVA;
savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
close
% plot GFP
topostats_PlotStats(stat_GFP);
set(gcf, 'WindowState', 'maximized');
name_plotGFP                        = 'GFP_plot';
save_dir                            = [save_dirAll,'GFP',filesep];
par.savePlotEpsPdfMat.dir_png       = strcat(save_dir,'\PNGs');
par.savePlotEpsPdfMat.dir_pdf       = strcat(save_dir,'PDFs\');
par.savePlotEpsPdfMat.dir_mat       = strcat(save_dir,'MATfiles\');
par.savePlotEpsPdfMat.file_name     = name_plotGFP;
savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
close
%% Test CE CI TANOVA
coupleEval = {{1,2},{1,3},{2,3}};
for cpeval = 1:length(coupleEval)
    Eval_Class = coupleEval{cpeval};
    %% TANOVA test
    N_subj = 21;
    N_cond = length(Eval_Class);
    Subj = 1:N_subj;
    Conditions = 1:N_cond;

    cfg_tanova2 = [];

    % Conditions (IVAR) -> [1...1, 2...2]
    Row_cond2 = repmat(Conditions, N_subj, 1);
    Row_cond2 = reshape(Row_cond2, 1, []); % row vector

    % Row 2: Subj (UVAR) -> [1..21, 1..21, 1..21, 1..21, 1..21]
    Row_subj2 = repmat(Subj, 1, N_cond);

    cfg_tanova2.design = [Row_cond2; Row_subj2];

    % 3.Id row
    cfg_tanova2.ivar = 1; % Conditions 1st row
    cfg_tanova2.uvar = 2; % Subjects 2nd row

    % 4. options
    cfg_tanova2.parameter = 'raw';          % data type: double channel*bin
    cfg_tanova2.numrandomization = 10000;   % icrease precision
    cfg_tanova2.normalize = 'yes';          % normalization
    cfg_tanova2.clusteralpha = 0.05;
    cfg_tanova2.alpha = 0.05;

    data_tanova2 = cell(1,N_subj*N_cond);
    m2 = 1;
    for c = 1:length(Eval_Class)
        for s = 1:N_subj
            data_tanova2{1,m2} = ERP_final(Eval_Class{c}).data{s,1};
            m2=m2+1;
        end
    end

    % size check
    if length(data_tanova2) ~= size(cfg_tanova2.design, 2)
        error('Error: The number of observations in the data does not match the design.');
    end

    % TANOVA test
    fprintf('\nStarting TANOVA with %d permutation...\n', cfg_tanova2.numrandomization);
    [stat_TANOVA2] = topostats_DEPsamplesTANOVA(cfg_tanova2, data_tanova2{:});

    fprintf('\n--- TANOVA RESULTS---\n');
    fprintf('Omnibus Probability: %.4f\n', stat_TANOVA2.omnibus_prob);

    if stat_TANOVA2.omnibus_prob <= cfg_tanova2.alpha
        disp('There is a topographical difference.');
    else
        disp('No significant result');
    end

    if ~isempty(stat_TANOVA2.clusters)
        fprintf('Found %d cluster. \nP-value significant cluster (<= %.2f):\n', ...
            numel(stat_TANOVA2.clusters), cfg_tanova2.alpha);
        for i = 1:numel(stat_TANOVA2.clusters)
            if stat_TANOVA2.clusters(i).prob <= cfg_tanova2.alpha
                fprintf('  - Cluster %d (Dimension: %d samples): p = %.4f\n', ...
                    i, stat_TANOVA2.clusters(i).clusterstat, stat_TANOVA2.clusters(i).prob);
            end
        end
    else
        disp('No sgnificant cluster');
    end

    % GFP test
    cfg_GFP2 = cfg_tanova2;
    fprintf('\nStarting GFP with %d permutation...\n', cfg_GFP2.numrandomization);
    [stat_GFP2] = topostats_DEPsamplesGFPcontrast(cfg_GFP2, data_tanova2{:});

    fprintf('\n--- GFP RESULTS---\n');
    fprintf('Omnibus Probability: %.4f\n', stat_GFP2.omnibus_prob);

    if stat_GFP2.omnibus_prob <= cfg_GFP2.alpha
        disp('There is a topographical difference.');
    else
        disp('No significant result');
    end

    if ~isempty(stat_GFP2.clusters)
        fprintf('Found %d cluster. \nP-value significant cluster (<= %.2f):\n', ...
            numel(stat_GFP2.clusters), cfg_GFP2.alpha);
        for i = 1:numel(stat_GFP2.clusters)
            if stat_GFP2.clusters(i).prob <= cfg_GFP2.alpha
                fprintf('  - Cluster %d (Dimension: %d samples): p = %.4f\n', ...
                    i, stat_GFP2.clusters(i).clusterstat, stat_GFP2.clusters(i).prob);
            end
        end
    else
        disp('No sgnificant cluster');
    end

    %% Report
    cfg_cluster = [];
    cfg_cluster.alpha = 0.05;
    cluster_TANOVA2 = topostats_ReportStats(cfg_cluster, stat_TANOVA2);
    cluster_GFP2   = topostats_ReportStats(cfg_cluster, stat_GFP2);

    % save Report
    name = cell(length(Eval_Class),1);
    for nclass=1:length(Eval_Class)
        if Eval_Class{nclass} == 1
            name{nclass} = 'CE';
        elseif Eval_Class{nclass} == 2
            name{nclass} = 'CI';
        elseif Eval_Class{nclass} == 3
            name{nclass} = 'IE';
        elseif Eval_Class{nclass} == 4
            name{nclass} = 'II';
        else
            name{nclass} = 'SW';
        end
    end

    output_dir = save_dirAll;
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    save_dir = fullfile(output_dir, ['TableResult_',strjoin(name, '_'),'.mat']);
    save(save_dir,'cluster_TANOVA2','cluster_GFP2');

    %% plot TANOVA

    topostats_PlotStats(stat_TANOVA2);
    set(gcf, 'WindowState', 'maximized');
    name_plotTANOVA2                     = ['TANOVA_plot',strjoin(name, '_')];
    save_dir                            = [save_dirAll,'TANOVA',filesep,strjoin(name, '_'),filesep  ];
    par.savePlotEpsPdfMat.dir_png       = strcat(save_dir,'\PNGs');
    par.savePlotEpsPdfMat.dir_pdf       = strcat(save_dir,'PDFs\');
    par.savePlotEpsPdfMat.dir_mat       = strcat(save_dir,'MATfiles\');
    par.savePlotEpsPdfMat.file_name     = name_plotTANOVA2;
    savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
    close
    % plot GFP
    topostats_PlotStats(stat_GFP2);
    set(gcf, 'WindowState', 'maximized');
    name_plotGFP2                       = ['GFP_plot_',strjoin(name, '_')];
    save_dir                            = [save_dirAll,'GFP',filesep,strjoin(name, '_'),filesep];
    par.savePlotEpsPdfMat.dir_png       = strcat(save_dir,'\PNGs');
    par.savePlotEpsPdfMat.dir_pdf       = strcat(save_dir,'PDFs\');
    par.savePlotEpsPdfMat.dir_mat       = strcat(save_dir,'MATfiles\');
    par.savePlotEpsPdfMat.file_name     = name_plotGFP2;
    savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
    close
end