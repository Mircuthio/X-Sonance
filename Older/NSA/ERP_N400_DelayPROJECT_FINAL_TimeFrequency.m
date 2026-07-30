% ERP_N400_DelayPROJECT_FINAL.m
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

ROI=0;
dir_path = 'D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\NEW_FIGURE\SPECTROGRAM\0.1_90\NoROI\';


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
% par.FilterBankCompute.f_min      = 1;
% par.FilterBankCompute.f_max      = 90;
% par.FilterBankCompute.FilterBank = 'EEGbands';
par.FilterBankCompute.FilterBank = 'One';
par.FilterBankCompute.f_min  = 0.1; % min frequency range in Hz
par.FilterBankCompute.f_max  = 90; %30; % Max frequency range in Hz 20 30 o 40 oppure delta e Tetha
par.FilterBankCompute.fsample    = fsample;

if strcmp(par.FilterBankCompute.FilterBank,'EEGbands')
    ylim1 = [-0.3 0.3];
else
    ylim1 = [-4 4];
end
% par.exec.funname ={'FilterBankCompute'};

% [EEG_FilterPreStim, par.execinfo]=run_trials(EEG_trialsPreStim,par);
% [EEG_Filter, par.execinfo]=run_trials(EEG_trials,par);
EEG_Filter = EEG_trials;
EEG_FilterPreStim = EEG_trialsPreStim;
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
    if ROI==1
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

    sub = {1,2,3,4,5};
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

    cmatrxix = {[-80 20];'auto'};
    cmatlab = {'-80','Auto'};

    window_length = 32;
    overlap = round(0.5 * window_length);
    nfft = 64; %512;
    fs= 250;

    pad_ms = 200;
    pad_samples = round(fs * pad_ms/1000);
    for climC = 1:2
        %% No subplot
        for i=1:length(Erp)
            signal = [Erp(i).OneBand, zeros(pad_samples,1)'];   % <-- padding

            figure
            [S, F, T] = spectrogram(signal, hamming(window_length), overlap, nfft, fs);

            imagesc(T * 1000, F, 20*log10(abs(S)));
            axis xy;
            clim(cmatrxix{climC});
            colormap(jet);
            colorbar;
            xlabel('Time [ms]');
            ylabel('Frequency [Hz]');
            yticks(0:10:90)
            ylim([0 90]);
            xlim([50 800]);
            title(strcat(saveclass{i},' Spectrogram'));

            set(gcf, 'WindowState', 'maximized');

            name_path = strcat(dir_path,'TimeFreq');

            par.savePlotEpsPdfMat.dir_png = strcat(name_path,'\PNGs\');
            par.savePlotEpsPdfMat.dir_pdf = strcat(name_path,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(name_path,'\MATfiles\');

            name_fig = strcat('Spect_',saveclass{i},cmatlab{climC});
            par.savePlotEpsPdfMat.file_name = name_fig;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all
        end
        %% No subplot with meshgrid
        for i=1:length(Erp)
            signal = [Erp(i).OneBand, zeros(pad_samples,1)'];   % <-- padding

            [S, F, T] = spectrogram(signal, hamming(window_length), overlap, nfft, fs);
            freq_idx = (F >= 0.1 & F <= 90); % (F >= 1 & F <= 90);
            S_dB = 10*log10(abs(S(freq_idx, :))); % Power
            %S_dB = 20*log10(abs(S(freq_idx, :))); % Amplitude
        
            min_finite = min(S_dB(~isinf(S_dB)));
            S_dB(isinf(S_dB)) = min_finite;
            % Interpolation
            [X, Y] = meshgrid(T, F(freq_idx));
            [Xq, Yq] = meshgrid(linspace(min(T), max(T), 300), linspace(0.1, 90, 300));
            S_interp = interp2(X, Y, S_dB, Xq, Yq, 'spline');
            
            figure
            imagesc(Xq(1,:)*1000, Yq(:,1), S_interp);
            axis xy;
            clim(cmatrxix{climC});
            colormap(jet);
            colorbar;
            xlabel('Time [ms]');
            ylabel('Frequency [Hz]');
            yticks(0:10:90)
            ylim([0 90]);
            x_limit = xlim;
            xlim([x_limit(1) 800]);
            title(strcat(legendLab{i},' Spectrogram'));
            set(gcf, 'WindowState', 'maximized');

            name_path = strcat(dir_path,'TimeFreq');

            par.savePlotEpsPdfMat.dir_png = strcat(name_path,'\PNGs\');
            par.savePlotEpsPdfMat.dir_pdf = strcat(name_path,'\PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(name_path,'\MATfiles\');

            name_fig = strcat('Spect_Mesh',saveclass{i},cmatlab{climC});
            par.savePlotEpsPdfMat.file_name = name_fig;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
            close all
        end

        %% supblot
        figure;
        num_plots = length(Erp);
        rows = ceil(sqrt(num_plots));
        cols = ceil(num_plots / rows);
        for i=1:length(Erp)
            signal = [Erp(i).OneBand, zeros(pad_samples,1)'];   % <-- padding

            [S, F, T] = spectrogram(signal, hamming(window_length), overlap, nfft, fs);
            
            subplot(rows, cols, i);
            imagesc(T * 1000, F, 20*log10(abs(S)));
            axis xy;
            clim(cmatrxix{climC});
            colormap(jet);
            colorbar;
            xlabel('Time [ms]');
            ylabel('Frequency [Hz]');
            ylim([0 90]);
            xlim([50 800]);
            title(strcat(legendLab{i},' Spectrogram'));
        end
        set(gcf, 'WindowState', 'maximized');

        name_path = strcat(dir_path,'TimeFreq');

        par.savePlotEpsPdfMat.dir_png = strcat(name_path,'\PNGs\');
        par.savePlotEpsPdfMat.dir_pdf = strcat(name_path,'\PDFs\');
        par.savePlotEpsPdfMat.dir_mat = strcat(name_path,'\MATfiles\');

        name_fig = strcat('Subp_Spect_',saveclass{i},cmatlab{climC});
        par.savePlotEpsPdfMat.file_name = name_fig;
        savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
        close all
        %% supblot con meshgrid
        figure;
        num_plots = length(Erp);
        rows = ceil(sqrt(num_plots));
        cols = ceil(num_plots / rows);
        for i=1:length(Erp)
            signal = [Erp(i).OneBand, zeros(pad_samples,1)'];   % <-- padding

            [S, F, T] = spectrogram(signal, hamming(window_length), overlap, nfft, fs);
            freq_idx = (F >= 0.1 & F <= 90); % (F >= 1 & F <= 90);
            S_dB = 10*log10(abs(S(freq_idx, :))); % Power
            %S_dB = 20*log10(abs(S(freq_idx, :))); % Amplitude

            min_finite = min(S_dB(~isinf(S_dB)));
            S_dB(isinf(S_dB)) = min_finite;

            % Interpolazione
            [X, Y] = meshgrid(T, F(freq_idx));
            [Xq, Yq] = meshgrid(linspace(min(T), max(T), 300), linspace(1, 90, 300));
            S_interp = interp2(X, Y, S_dB, Xq, Yq, 'spline');

            subplot(rows, cols, i);
            imagesc(Xq(1,:)*1000, Yq(:,1), S_interp);
            axis xy;
            clim(cmatrxix{climC});
            colormap(jet);
            colorbar;
            xlabel('Time [ms]');
            ylabel('Frequency [Hz]');
            yticks(0:10:90)
            ylim([0 90]);
            x_limit = xlim;
            xlim([x_limit(1) 800]);
            title(strcat(legendLab{i},' Spectrogram'));
        end
        set(gcf, 'WindowState', 'maximized');

        name_path = strcat(dir_path,'TimeFreq');

        par.savePlotEpsPdfMat.dir_png = strcat(name_path,'\PNGs\');
        par.savePlotEpsPdfMat.dir_pdf = strcat(name_path,'\PDFs\');
        par.savePlotEpsPdfMat.dir_mat = strcat(name_path,'\MATfiles\');

        name_fig = strcat('Subp_Spect_Mesh',saveclass{i},cmatlab{climC});
        par.savePlotEpsPdfMat.file_name = name_fig;
        savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
        close all
    end
end
