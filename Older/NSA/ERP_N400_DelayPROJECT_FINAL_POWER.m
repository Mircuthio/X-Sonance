% ERP_N400_DelayPROJECT_FINAL_POWER.m
%% MAIN
% questo main realizza il plot degli andamenti ERP di due classi: Coerente Inglese
% (Coherent Eng) e Coerente Italiano (Coherent Ita) in 7 differenti bande
% EEG (indicate in seguito) ottenute come ERP medi tra gli andamenti nel
% tempo in un intervallo 0-2.5 tra tutti i canali e tutti i soggetti

%Escludiamo il soggetto 6-DEMA in attesa di verifica della coerenza delle label

% Specifics:
% label indexes
% 1: COHERENT ENGLISH
% 2: COHERENT ITALIAN
% 3: INCOHERENT ENGLISH
% 4: INCOHERENT ITALIAN
% 5: SCUMBLED

clear; close all;

par.irng = 10;
rng(par.irng);

interval = 0;

EEG_all = struct();
EEG_allPreStim = struct();

load("Delay_ALL.mat");

starting_time = 0;
ending_time = 2.5;

start_plot  = 0;
end_plot    = 0.8;

for indsub = 1:21
    signal_name                     = 'eeg';
    signal_process                  = 'erp';

    %% Extract and Arrange Data
    par.extractSound.signal_name    = signal_name;
    par.extractSound.InField        = 'train';
    par.extractSound.it_end         = 2.5;
    par.extractSound.multiEpoch     = true;
    [EEG_trials_sub,fsample]        = extractSound(indsub,par.extractSound);

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
par.FilterBankCompute.f_min      = 1;
par.FilterBankCompute.f_max      = 90;
par.FilterBankCompute.FilterBank = 'EEGbands';
% par.FilterBankCompute.FilterBank = 'One';
% par.FilterBankCompute.f_min  = 0.1; % min frequency range in Hz
% par.FilterBankCompute.f_max  = 30; % Max frequency range in Hz 20 30 o 40 oppure delta e Tetha
par.FilterBankCompute.fsample    = fsample;

ylim1 = 'auto';

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
addpath(genpath("D:\eeglab2023.1\"))

%% Select Center Midline Electrodes
load("D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\chanloc.mat");
% Definizione dei gruppi basati sui nomi degli elettrodi
frontal = {'FPz','FP1','FP2',...
    'Fz', 'F1','F2','F3','F4','F5','F6','F7','F8',...
    'AFz','AF1','AF2','AF3','AF4','AF5','AF6','AF7','AF8'...
    'FCz','FC1','FC2','FC3','FC4','FC5','FC6','FC7','FC8',...
    'FT1','FT2','FT3','FT4','FT5','FT6','FT7','FT8'};
central = {'Cz','C1','C2','C3','C4','C5','C6','C7','C8',...
    'FC1','FC2','FC3','FC4','FC5','FC6','FC7','FC8',...
    'CP1', 'CP2', 'CP3', 'CP4','CP5', 'CP6','CP7', 'CP8'};
parietal = {'Pz', 'P1','P2','P3','P4','P5','P6','P7','P8'...
    'CP1', 'CP2','CP3','CP4','CP5','CP6''CP7','CP8'};
temporal = {'T1','T2','T3','T4','T5','T6','T7','T8'...
    'TP1','TP2','TP3','TP4','TP5','TP6','TP7','TP8'};
occipital = {'Oz','O1','O2','O3','O4','O5','O6','O7','O8'...
    'PO1','PO2','PO3','PO4','PO5','PO6','PO7','PO8'};
midline = {'Fz','FPz','FCz','Cz','CPz','Pz','POz','Oz'};

roi = {'Cz','C1','C2','C3','C4','C5','C6','C7','C8',...
    'FC1','FC2','FC3','FC4','FC5','FC6','FC7','FC8',...
    'CP1', 'CP2', 'CP3', 'CP4','CP5', 'CP6','CP7', 'CP8',...
    'Pz', 'P1','P2','P3','P4','P5','P6','P7','P8'};
roi2 = {'Cz','C1','C2','C3','C4','C5','C6','C7','C8',...
    'FCz','FC1','FC2','FC3','FC4','FC5','FC6','FC7','FC8',...
    'CPz','CP1', 'CP2', 'CP3', 'CP4','CP5', 'CP6','CP7', 'CP8',...
    'Pz', 'P1','P2','P3','P4','P5','P6','P7','P8'};

% Creazione dei gruppi
frontali = ismember({chanloc.labels}, frontal);
parietali = ismember({chanloc.labels}, parietal);
temporali = ismember({chanloc.labels}, temporal);
occipital = ismember({chanloc.labels}, occipital);
lineamediana = ismember({chanloc.labels}, midline);
roi_memb = ismember({chanloc.labels}, roi);
roi_memb2 = ismember({chanloc.labels}, roi2);

frontal_el = {chanloc(frontali).labels};
parietal_el = {chanloc(parietali).labels};
temporal_el = {chanloc(temporali).labels};
occipital_el = {chanloc(occipital).labels};
midline_el = {chanloc(lineamediana).labels};
roi_el = {chanloc(roi_memb).labels};
roi_el2 = {chanloc(roi_memb2).labels};

chan_id = 1:length(chanloc);
frontal_id = chan_id(frontali);
parietal_id = chan_id(parietali);
temporal_id = chan_id(temporali);
occipital_id = chan_id(occipital);
midline_id = chan_id(lineamediana);
mid_noO_id = [1,58,20,47,10,42];

roi_id = chan_id(roi_memb);
roi_id2 = chan_id(roi_memb2);
% ScalpArea = {frontal_id;parietal_id;temporal_id;occipital_id;midline_id;mid_noO_id};
% ScalpArea = {1;20;10};
% ScalpArea_name = {'Fz';'Cz';'Pz'};
ScalpArea = {roi_id}; %roi_id2}; %frontal_id;parietal_id;temporal_id;occipital_id;midline_id};
Scalp_memb = {roi_memb}; %roi_memb2};

ScalpArea_name = {'Frontal-Central-Parietal';'Frontal-Central-Midline-Parietal';'Frontal';'Parietal';'Temporal';'Occipital';'Center Midline'};
ScalpSaveName = {'FrCePa';'FrCeMiPa';'Frontal';'Centr';'Par';'Temp';'Occip';'Cent_Mid'};
for sa = 1:length(ScalpArea)
    selected_area = ScalpArea{sa};
    chanlocSelected = chanloc(Scalp_memb{sa});
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

    %% calcolo trasformata di hilbert
    for nclass = 1:length(Erp)
        for iband = 1:length(band_name)
            Erp(nclass).Hb.(band_name{iband}) = hilbert(Erp(nclass).(band_name{iband}));
            Erp(nclass).Hb_mod.(band_name{iband}) = abs(Erp(nclass).Hb.(band_name{iband})).^2;
            Erp(nclass).Hb_ph.(band_name{iband}) = angle(Erp(nclass).Hb.(band_name{iband}));
        end
    end

    % Calcolo trasformata di hilbert per canale mediando i trials
    Erp_app = struct();
    for nclass = 1:length(Erp)
        for iband = 1:length(band_name)
            Erp_app(nclass).data3D = squeeze(Erp(nclass).data4D(:,:,iband,:));
            Erp_app(nclass).chan = mean(Erp(nclass).data3D,3);
            Erp_app_ch = Erp_app(nclass).chan;
            Erp_app_hb = NaN(size(Erp_app(nclass).chan));
            for n_chan=1:size(Erp_app(nclass).chan,1)
                Erp_app_hb(n_chan,:) = hilbert(Erp_app_ch(n_chan,:));
            end
            Erp_app(nclass).Hb.(band_name{iband}).ch = Erp_app_hb;
            Erp_app(nclass).Hb_mod.(band_name{iband}).ch = abs(Erp_app_hb).^2;
            Erp_app(nclass).Hb_ph.(band_name{iband}).ch = angle(Erp_app_hb);
        end
    end
    
    %% HILBERT ERP
    % calcolo la trasformata per ogni canale e per ogni trials poi medio
    Erp_hilb = struct();
    for nclass = 1:length(Erp)
        for iband = 1:length(band_name)
            Erp_app3D = squeeze(Erp(nclass).data4D(:,:,iband,:));
            data_hilbert_pow = nan(size(Erp_app3D));
            data_hilbert_phase = nan(size(Erp_app3D));
            for ch = 1:size(Erp_app3D,1)
                for ntr = 1:size(Erp_app3D,3)
                    data_hilbert_pow(ch,:,ntr) = abs(hilbert(squeeze(Erp_app3D(ch,:,ntr)))).^2;
                    data_hilbert_phase(ch,:,ntr) = angle(hilbert(squeeze(Erp_app3D(ch,:,ntr))));
                end
            end
            Erp_hilb(nclass).(band_name{iband}).power=data_hilbert_pow;
            Erp_hilb(nclass).(band_name{iband}).phase=data_hilbert_phase;
        end
    end

    %% Definisco i confronti tra le classi da fare
    subcouple = {{1,2},{1,3}};%,{2,4},{1,5}};
    for subcp = 1:length(subcouple)
        sub = subcouple{subcp};

        Erp1 = Erp(sub{1});
        Erp2 = Erp(sub{2});
        
        % Erp Hilb
        Erp1Hil = Erp_hilb(sub{1});
        Erp2Hil = Erp_hilb(sub{2});

        Classes = cell2mat(sub);
        legendLab = cell(1,length(Classes));
        colors = cell(1,length(Classes));
        saveclass = cell(1,length(Classes));
        n=1;
        if ismember(1,Classes)
            legendLab{1,n} = 'Coherent Eng';
            colors{1,n} = 'b';
            saveclass{1,n} = 'CE';
            n=n+1;
        end
        if ismember(2,Classes)
            legendLab{1,n} = 'Coherent Ita';
            colors{1,n} = 'r';
            saveclass{1,n} = 'CI';
            n=n+1;
        end
        if ismember(3,Classes)
            legendLab{1,n} = 'Incoherent Eng';
            colors{1,n} = 'g'; %'[0.9290 0.6940 0.1250]'; %'[0.3010 0.7450 0.9330]';
            saveclass{1,n} = 'IE';
            n=n+1;
        end
        if ismember(4,Classes)
            legendLab{1,n} = 'Incoherent Ita';
            colors{1,n} = 'c'; %'[0.4940 0.1840 0.5560]'; %'m'; %
            saveclass{1,n} = 'II';
            n=n+1;
        end
        if ismember(5,Classes)
            legendLab{1,n} = 'Scrumbled';
            colors{1,n} = 'm';
            saveclass{1,n} = 'SW';
            n=n+1;
        end

        save_class1 = saveclass{1};
        save_class2 = saveclass{2};
        save_class = strjoin(saveclass, '_');
        sel_classes = cell2mat(sub);

        for iband = 1:length(band_name)
            %% c POWER

            C1 = Erp1.Hb_mod.(band_name{iband});
            C2 = Erp2.Hb_mod.(band_name{iband});

            C1_3D = Erp1Hil.(band_name{iband}).power;
            C2_3D = Erp2Hil.(band_name{iband}).power;
            c1= C1_3D;
            c2= C2_3D;

            Xf = linspace(start_plot,end_plot,size(C1,2));
            time_lab = 1;

            percent = 0; % regular t-test
            alpha = 0.05;
            [~,~,~,~,p,~,~] = limo_yuend_ttest(c1,c2,percent,alpha);

            figure('Color','w','NumberTitle','off') % make blank figure
            hold on % we're going to plot several elements
            plot(Xf,C1,'Color',colors{1},'LineStyle','-','LineWidth',1)
            plot(Xf,C2,'Color',colors{2},'LineStyle','-','LineWidth',1)
            set(gca,'LineWidth',1,'FontSize',14,'XLim',[start_plot end_plot])
            % legend(legendLab{1:2})
            if time_lab == 1
                xlabel('Time in [s]','FontSize',16)
            else
                xlabel('Time in [ms]','FontSize',16)
            end
            ylabel('Power [\muV^2]','FontSize',16)
            ylim(ylim1)
            ylim_curr = ylim;
            ylim([0 ylim_curr(2)])
            offset_fraction = 0.01;
            off_scale = offset_fraction * ylim_curr(2);
            % p_sum = sum(p<=alpha);
            % p_title = 100*(sum(p_sum~=0)/length(Xf));
            t_title = strcat(sprintf('ERP Power Response in the %s', bands{iband}),...
                '\newline','      Area:',ScalpArea_name{sa}); ...
                
            title(t_title)
            box on
            hold on;
            % % We add a horizontal line showing time points at which a significant mean
            % % difference was observed.
            % v=axis; % get current axis limits
            % alpha=0.05; % set alpha level
            % % plot(Xf,(p<=alpha)*100-100+v(3)*.95,'ro','MarkerSize',5)
            % pp = any((p<=alpha),1);
            % x_zero = Xf(pp == 1);
            % y_zero = off_scale * ones(size(x_zero));  % Ordinata fissa
            % plot(x_zero, y_zero, 'ro')
            % axis(v) % restore axis limits to hide non-significant points
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            legend(legendLab{1:2},'')


            name1 = strcat('ERP_Power_', bands{iband},'_',ScalpArea_name{sa});
            % plot saving params
            save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\Final_FIGURES\Edit_Y_range\Power\NOc_power\';
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',erase(num2str(end_plot),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = name1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all

            %% c time

            C1 = Erp1.Hb_mod.(band_name{iband});
            C2 = Erp2.Hb_mod.(band_name{iband});

            C1_4D = Erp1.data4D;
            C2_4D = Erp2.data4D;

            C1_3D = squeeze(C1_4D(:,:,iband,:));
            C2_3D = squeeze(C2_4D(:,:,iband,:));

            c1= C1_3D;
            c2= C2_3D;

            Xf = linspace(start_plot,end_plot,size(C1,2));
            time_lab = 1;

            percent = 0; % regular t-test
            alpha = 0.05;
            [~,~,~,~,p,~,~] = limo_yuend_ttest(c1,c2,percent,alpha);

            figure('Color','w','NumberTitle','off') % make blank figure
            hold on % we're going to plot several elements
            plot(Xf,C1,'Color',colors{1},'LineStyle','-','LineWidth',1)
            plot(Xf,C2,'Color',colors{2},'LineStyle','-','LineWidth',1)
            set(gca,'LineWidth',1,'FontSize',14,'XLim',[start_plot end_plot])
            % legend(legendLab{1:2})
            if time_lab == 1
                xlabel('Time in [s]','FontSize',16)
            else
                xlabel('Time in [ms]','FontSize',16)
            end
            ylabel('Power [\muV^2]','FontSize',16)
            ylim(ylim1)
            ylim_curr = ylim;
            ylim([0 ylim_curr(2)])
            offset_fraction = 0.01;
            off_scale = offset_fraction * ylim_curr(2);
            % p_sum = sum(p<=alpha);
            % p_title = 100*(sum(p_sum~=0)/length(Xf));
            t_title = strcat(sprintf('ERP Power Response in the %s', bands{iband}),...
                '\newline','      Area:',ScalpArea_name{sa}); ...
                
            title(t_title)
            box on
            hold on;
            % % We add a horizontal line showing time points at which a significant mean
            % % difference was observed.
            % v=axis; % get current axis limits
            % alpha=0.05; % set alpha level
            % % plot(Xf,(p<=alpha)*100-100+v(3)*.95,'ro','MarkerSize',5)
            % pp = any((p<=alpha),1);
            % x_zero = Xf(pp == 1);
            % y_zero = off_scale * ones(size(x_zero));  % Ordinata fissa
            % plot(x_zero, y_zero, 'ro')
            % axis(v) % restore axis limits to hide non-significant points
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            legend(legendLab{1:2},'')


            name1 = strcat('ERP_Power_', bands{iband},'_',ScalpArea_name{sa});
            % plot saving params
            save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\Final_FIGURES\Edit_Y_range\Power\NOc_time\';
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',erase(num2str(end_plot),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = name1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all

            %% Topoplot
            figure
            topoplot(C1,chanloc, 'maplimits', 'absmax', 'electrodes','pts','style', 'both', 'emarkersize', 10)
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            Topoplotname1 = strcat('Topoplot_ERP_Power', bands{iband},'_',ScalpArea_name{sa},'_',save_class1);

            % plot saving params
            save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\Final_FIGURES\Edit_Y_range\Power\Topoplot';
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',erase(num2str(end_plot),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = Topoplotname1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)

            figure
            topoplot(C2,chanloc, 'maplimits', 'absmax', 'electrodes','pts','style', 'both', 'emarkersize', 10)
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            Topoplotname2 = strcat('Topoplot_ERP_Power_', bands{iband},'_',ScalpArea_name{sa},'_',save_class2);

            % plot saving params
            save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\Final_FIGURES\Edit_Y_range\Power\Topoplot\';
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',erase(num2str(end_plot),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = Topoplotname2;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)

            %% PAHSE
            %% c phase
            C1 = Erp1.Hb_ph.(band_name{iband});
            C2 = Erp2.Hb_ph.(band_name{iband});
            C1 = rad2deg(C1);
            C2 = rad2deg(C2);

            C1_3D = Erp1Hil.(band_name{iband}).phase;
            C2_3D = Erp2Hil.(band_name{iband}).phase;

            c1= rad2deg(C1_3D);
            c2= rad2deg(C2_3D);

            Xf = linspace(start_plot,end_plot,size(C1,2));
            time_lab = 1;

            percent = 0; % regular t-test
            alpha = 0.05;
            [~,~,~,~,p,~,~] = limo_yuend_ttest(c1,c2,percent,alpha);

            figure('Color','w','NumberTitle','off') % make blank figure
            hold on % we're going to plot several elements
            plot(Xf,C1,'Color',colors{1},'LineStyle','-','LineWidth',1)
            plot(Xf,C2,'Color',colors{2},'LineStyle','-','LineWidth',1)
            set(gca,'LineWidth',1,'FontSize',14,'XLim',[start_plot end_plot])
            % legend(legendLab{1:2})
            if time_lab == 1
                xlabel('Time in [s]','FontSize',16)
            else
                xlabel('Time in [ms]','FontSize',16)
            end
            ylabel('Phase [°]','FontSize',16)
            ylim(ylim1)
            % p_sum = sum(p<=alpha);
            % p_title = 100*(sum(p_sum~=0)/length(Xf));
            t_title = strcat(sprintf('ERP Phase Response in the %s', bands{iband}),...
                '\newline','      Area:',ScalpArea_name{sa}); ...
                
            title(t_title)
            box on
            hold on;
            % % We add a horizontal line showing time points at which a significant mean
            % % difference was observed.
            % v=axis; % get current axis limits
            % alpha=0.05; % set alpha level
            % plot(Xf,(p<=alpha)*100-100+v(3)*.95,'ro','MarkerSize',5)
            % axis(v) % restore axis limits to hide non-significant points
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            legend(legendLab{1:2},'')


            name1 = strcat('ERP_Phase_', bands{iband},'_',ScalpArea_name{sa});
            % plot saving params
            save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\Final_FIGURES\Edit_Y_range\Phase\NOc_phase\';
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',erase(num2str(end_plot),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = name1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all

            % c time
            C1 = Erp1.Hb_ph.(band_name{iband});
            C2 = Erp2.Hb_ph.(band_name{iband});
            
            C1 = rad2deg(C1);
            C2 = rad2deg(C2);

            C1_4D = Erp1.data4D;
            C2_4D = Erp2.data4D;

            C1_3D = squeeze(C1_4D(:,:,iband,:));
            C2_3D = squeeze(C2_4D(:,:,iband,:));

            c1= C1_3D;
            c2= C2_3D;

            Xf = linspace(start_plot,end_plot,size(C1,2));
            time_lab = 1;

            percent = 0; % regular t-test
            alpha = 0.05;
            [~,~,~,~,p,~,~] = limo_yuend_ttest(c1,c2,percent,alpha);

            figure('Color','w','NumberTitle','off') % make blank figure
            hold on % we're going to plot several elements
            plot(Xf,C1,'Color',colors{1},'LineStyle','-','LineWidth',1)
            plot(Xf,C2,'Color',colors{2},'LineStyle','-','LineWidth',1)
            set(gca,'LineWidth',1,'FontSize',14,'XLim',[start_plot end_plot])
            % legend(legendLab{1:2})
            if time_lab == 1
                xlabel('Time in [s]','FontSize',16)
            else
                xlabel('Time in [ms]','FontSize',16)
            end
            ylabel('Phase [°]','FontSize',16)
            ylim(ylim1)
            p_sum = sum(p<=alpha);
            p_title = 100*(sum(p_sum~=0)/length(Xf));
            t_title = strcat(sprintf('ERP Phase Response in the %s', bands{iband}),...
                '\newline','      Area:',ScalpArea_name{sa}); ...
                
            title(t_title)
            box on
            hold on;
            % % We add a horizontal line showing time points at which a significant mean
            % % difference was observed.
            % v=axis; % get current axis limits
            % alpha=0.05; % set alpha level
            % plot(Xf,(p<=alpha)*100-100+v(3)*.95,'ro','MarkerSize',5)
            % axis(v) % restore axis limits to hide non-significant points
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            legend(legendLab{1:2},'')


            name1 = strcat('ERP_Phase_', bands{iband},'_',ScalpArea_name{sa});
            % plot saving params
            save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\Final_FIGURES\Edit_Y_range\Phase\NOc_time\';
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',erase(num2str(end_plot),'.'));
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'\MATfiles\');

            par.savePlotEpsPdfMat.file_name = name1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all
        end
    end
    close all
end