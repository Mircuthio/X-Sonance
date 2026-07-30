% ERP_N400_TOPOPLOT.m
%% MAIN
% questo main realizza il plot degli andamenti ERP di tre classi tra 1-
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
save_dirAll = 'D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\NEW_FIGURE\TOPOPLOT\AllSUBJ\ROI\';

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
    
    badT = badTrials(indsub).trials;
    if ~isempty(badT)

        allIDs = [EEG_trials_sub.trialId];

        idxRemove = ismember(allIDs, badT);

        EEG_trials_sub(idxRemove) = [];
    end

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

%% Pre stimulus

for nfield   = fieldnames(EEG_allPreStim)'
    namefield   = nfield{1};
    cellsfield  = {EEG_allPreStim.(namefield)};
    EEG_dataPreStim    = cat(1,cellsfield{:});
end

for iTr=1:length(EEG_dataPreStim)
    EEG_dataPreStim(iTr).trialId = iTr;
end
EEG_trialsPreStim = EEG_dataPreStim;

%% Stimulus Data
for nfield   = fieldnames(EEG_all)'
    namefield   = nfield{1};
    cellsfield  = {EEG_all.(namefield)};
    EEG_data    = cat(1,cellsfield{:});
end

for iTr=1:length(EEG_data)
    EEG_data(iTr).trialId = iTr;
end
EEG_trials = EEG_data;

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

[EEG_FilterPreStim, par.execinfo]=run_trials(EEG_trialsPreStim,par);
[EEG_Filter, par.execinfo]=run_trials(EEG_trials,par);

%% Baseline Removing
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

%% Select Center Midline Electrodes
load("D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\chanloc.mat");

roi = {'Cz','C1','C2','C3','C4','C5','C6','C7','C8',...
    'FC1','FC2','FC3','FC4','FC5','FC6','FC7','FC8',...
    'CP1', 'CP2', 'CP3', 'CP4','CP5', 'CP6','CP7', 'CP8',...
    'Pz', 'P1','P2','P3','P4','P5','P6','P7','P8'};

roi_memb = ismember({chanloc.labels}, roi);
roi_el = {chanloc(roi_memb).labels};
chan_id = 1:length(chanloc);
roi_id = chan_id(roi_memb);

ScalpArea = {roi_id};
Scalp_memb = {roi_memb};
ScalpArea_name = {'Frontal-Central-Parietal'};
ScalpSaveName = {'FrCePa'};

for sa = 1:length(ScalpArea)
    if ROI == 1
        selected_area = ScalpArea{sa};
        chanlocSelected = chanloc(Scalp_memb{sa});
    else
        selected_area = 1:size(EEG_FilterRB(1).eeg,1); % all Channels
    end
    %% Select Area
    EEG_FilterCH = EEG_FilterRB;
    for iTr=1:length(EEG_FilterRB)
        EEG_FilterCH(iTr).eeg = EEG_FilterRB(iTr).(signal_name)(selected_area,:,:);
    end
    EEG_ERP = EEG_FilterCH;
    for iTr=1:length(EEG_ERP)
        EEG_ERP(iTr).(signal_name) = EEG_ERP(iTr).(signal_name)(:,1:fsample*end_plot,:);
    end
    if strcmp(par.FilterBankCompute.FilterBank,'One')
        bands = {strcat('[',num2str(par.FilterBankCompute.f_min),'-',num2str(par.FilterBankCompute.f_max),'] Hz')};
        band_name = {'OneBand'};

    else
        bands = {'Delta [1-4] Hz','Theta [4-8] Hz','Alpha [8-13] Hz','Beta Low [13-20] Hz',...
            'Beta High [20-30] Hz','gamma Low [30-40] Hz','gamma High [40-90] Hz'};
        band_name = {'Delta','Teta','Alpha','BetaLow','BetaHigh','GammaLow','GammaHigh'};
    end


    startClass = unique([EEG_ERP.trialType]);
    Erp = struct();
    for nclass = 1:length(startClass)
        Erp(nclass).data = EEG_ERP([EEG_ERP.trialType]==startClass(nclass));
        Erp(nclass).data4D = cat(4,Erp(nclass).data.(signal_name));
    end

    %% Creazione ERP per banda per Condizione
    for nclass = 1:length(Erp)
        for iband = 1:size(Erp(nclass).data4D,3)
            Erp(nclass).data3D = squeeze(Erp(nclass).data4D(:,:,iband,:));
            Erp(nclass).chan = mean(Erp(nclass).data3D,3);
            Erp(nclass).(band_name{iband}) = mean(Erp(nclass).chan);
        end
    end
    %% Definisco i confronti tra le classi da fare
    sub = {1,2,3,4,5};
    Erp1 = Erp(sub{1});
    Erp2 = Erp(sub{2});
    Erp3 = Erp(sub{3});
    Erp4 = Erp(sub{4});
    Erp5 = Erp(sub{5});
    Classes = cell2mat(sub);
    legendLab = cell(1,length(Classes));
    colors = cell(1,length(Classes));
    saveclass = cell(1,length(Classes));
    n=1;
    if ismember(1,Classes)
        legendLab{1,n} = 'Congruent Eng';
        colors{1,n} = 'b';
        saveclass{1,n} = 'CE';
        n=n+1;
    end
    if ismember(2,Classes)
        legendLab{1,n} = 'Congruent Ita';
        colors{1,n} = 'r';
        saveclass{1,n} = 'CI';
        n=n+1;
    end
    if ismember(3,Classes)
        legendLab{1,n} = 'Incongruent Eng';
        colors{1,n} = 'g'; %'[0.9290 0.6940 0.1250]'; %'[0.3010 0.7450 0.9330]';
        saveclass{1,n} = 'IE';
        n=n+1;
    end
    if ismember(4,Classes)
        legendLab{1,n} = 'Incongruent Ita';
        colors{1,n} = 'c'; %'[0.4940 0.1840 0.5560]'; %'m'; %
        saveclass{1,n} = 'II';
        n=n+1;
    end
    if ismember(5,Classes)
        legendLab{1,n} = 'Scrambled';
        colors{1,n} = 'm';
        saveclass{1,n} = 'SW';
        n=n+1;
    end


    % save_class = strjoin(saveclass, '_');

    sel_classes = cell2mat(sub);
    for iband = 1:size(Erp(1).data4D,3)
        C1_4D = Erp1.data4D;
        C2_4D = Erp2.data4D;
        C3_4D = Erp3.data4D;
        C4_4D = Erp4.data4D;
        C5_4D = Erp5.data4D;


        C1_3D = squeeze(C1_4D(:,:,iband,:));
        C2_3D = squeeze(C2_4D(:,:,iband,:));
        C3_3D = squeeze(C3_4D(:,:,iband,:));
        C4_3D = squeeze(C4_4D(:,:,iband,:));
        C5_3D = squeeze(C5_4D(:,:,iband,:));


        C1_chan = mean(C1_3D,3);
        C2_chan = mean(C2_3D,3);
        C3_chan = mean(C3_3D,3);
        C4_chan = mean(C4_3D,3);
        C5_chan = mean(C5_3D,3);

        %
        % C1 = mean(C1_chan);
        % C2 = mean(C2_chan);
        % C3 = mean(C3_chan);
        % C4 = mean(C4_chan);
        % C5 = mean(C5_chan);

        addpath(genpath("D:\eeglab2023.1\"))

        %% Define time interval of ERP
        t_start = 0.15;
        t_stop = 0.25;

        if t_start == 0
            id_start = 1;
            id_stop = t_stop*fsample;
        else
            id_start = t_start*fsample;
            id_stop = t_stop*fsample;
        end

        C1_chan = C1_chan(:,id_start:id_stop);
        C2_chan = C2_chan(:,id_start:id_stop);
        C3_chan = C3_chan(:,id_start:id_stop);
        C4_chan = C4_chan(:,id_start:id_stop);
        C5_chan = C5_chan(:,id_start:id_stop);

        % C = {C1_int, C2_int, C3_int, C4_int, C5_int};
        C = {C1_chan, C2_chan, C3_chan, C4_chan, C5_chan};
        %% Mean On time Topoplot
        for id_class=1:length(C)
            C_class = C{id_class};
            C_class = mean(C_class,2);
            if ROI ==1
                C_class58 = NaN(58, 1);
                C_class58(roi_id) = C_class;
            else
                C_class58 = C_class;
            end
            figure
            topoplot(C_class58,chanloc, 'maplimits', 'absmax', 'electrodes','pts','style', 'both', 'emarkersize', 10)
            title(saveclass{id_class})
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            Topoplotname1 = strcat('Topoplot_ERP_', bands{iband},'_',ScalpArea_name{sa},'_',saveclass{id_class});

            % plot saving params
            save_dir1 = [save_dirAll,'MeanTIME\'];
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\','Interval\',erase(num2str(t_start),'.'),'_',erase(num2str(t_stop),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = Topoplotname1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all
        end
        %% Time evolution Topoplot
        C_te = {C1_chan, C2_chan, C3_chan, C4_chan, C5_chan};
        time_step = 0.1;
        for id_class=1:length(C_te)
            C_class = C_te{id_class};
            time_seconds = 0:time_step: size(C_class, 2)/fsample;
            time_points = round(time_seconds * fsample);
            if time_points(1) == 0
                time_points(1) = 1;
            end
            num_topoplot = length(time_points);
            sqrt_num = sqrt(num_topoplot);
            rows = round(sqrt_num);
            cols = ceil(num_topoplot / rows);
            while rows * cols < num_topoplot
                cols = cols + 1;
            end
            % time_points = round(linspace(1, size(C_class,2), num_topoplot)); % campioni temporali da visualizzare
            if ROI==1
                C_class58 = NaN(58, size(C_class,2));
                C_class58(roi_id,:) = C_class;
            else
                C_class58 = C_class;
            end
            figure;
            for i = 1:num_topoplot
                subplot(rows, cols, i);
                time_in_seconds = time_points(i)/fsample;
                topoplot(C_class58(:, time_points(i)), chanloc);
                title(['Time: ', num2str(time_in_seconds), ' sec']);
            end
            sgtitle(saveclass{id_class});

            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            Topoplotname1 = strcat('Topoplot_ERP_', bands{iband},'_',ScalpArea_name{sa},'_',saveclass{id_class});

            % plot saving params
            save_dir1 =[save_dirAll,'TimeEvolution\'];
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\','Interval\',erase(num2str(t_start),'.'),'_',erase(num2str(t_stop),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = Topoplotname1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all
        end

        %% Mean Time evolution topoplot
        C_mte = {C1_chan, C2_chan, C3_chan, C4_chan, C5_chan};
        num_topoplot = 8;
        sqrt_num = sqrt(num_topoplot);
        rows = round(sqrt_num);
        cols = ceil(num_topoplot / rows);
        while rows * cols < num_topoplot
            cols = cols + 1;
        end
        for id_class = 1:length(C_mte)
            C_class = C_mte{id_class};
            num_samples = size(C_class, 2); % Numero di campioni temporali
            interval_size = floor(num_samples / num_topoplot); % Dimensione di ciascun intervallo
            intervals = zeros(num_topoplot, 2);
            for i = 1:num_topoplot
                intervals(i, 1) = (i - 1) * interval_size + 1;
                if i == num_topoplot
                    intervals(i, 2) = num_samples;
                else
                    intervals(i, 2) = i * interval_size;
                end
            end

            % Calcola le medie in ciascun intervallo
            mean_values = zeros(size(C_class, 1), num_topoplot);
            for i = 1:num_topoplot
                mean_values(:, i) = mean(C_class(:, intervals(i, 1):intervals(i, 2)), 2);
            end

            % Crea i topoplot
            if ROI ==1
                C_class58 = NaN(58, num_topoplot);
                C_class58(roi_id, :) = mean_values;
            else
                C_class58 = mean_values;
            end
            figure;
            for i = 1:num_topoplot
                subplot(rows, cols, i);
                % Calcola i tempi in secondi
                time_start = (intervals(i, 1) - 1) / fsample;
                time_end = intervals(i, 2) / fsample;
                topoplot(C_class58(:, i), chanloc);
                title(['Interval ', num2str(time_start), '-', num2str(time_end), ' sec']);
            end

            set(gcf, 'PaperPositionMode', 'auto');
            set(gcf, 'WindowState', 'maximized');
            sgtitle(saveclass{id_class});
            Topoplotname1 = strcat('Topoplot_ERP_', bands{iband}, '_', ScalpArea_name{sa}, '_', saveclass{id_class});

            sgtitle(saveclass{id_class});
            % plot saving params
            save_dir1 =[save_dirAll,'MeanTimeEvolution\'];
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\','Interval\',erase(num2str(t_start),'.'),'_',erase(num2str(t_stop),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = Topoplotname1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all
        end
    end
end