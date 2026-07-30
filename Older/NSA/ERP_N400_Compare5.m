% ERP_N400_Compare5.m
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

starting_time = 0;
ending_time = 2.5;

start_plot  = 0;
end_plot    = 0.35;

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
par.FilterBankCompute.f_max  = 30; % Max frequency range in Hz 20 30 o 40 oppure delta e Tetha
par.FilterBankCompute.fsample    = fsample;

if strcmp(par.FilterBankCompute.FilterBank,'EEGbands')
    ylim1 = [-0.3 0.3];
else
    ylim1 = [-5.5 5];
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
    %% Definisco i confronti tra le classi da fare
    subcouple = {{1,2,3,4,5}};
    for subcp = 1:length(subcouple)
        sub = subcouple{subcp};
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

        save_class1 = saveclass{1};
        save_class2 = saveclass{2};
        save_class = strjoin(saveclass, '_');
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


            C1 = mean(C1_chan);
            C2 = mean(C2_chan);
            C3 = mean(C3_chan);
            C4 = mean(C4_chan);
            C5 = mean(C5_chan);

            Xf = linspace(start_plot,end_plot,size(C1,2)); % in s
            time_lab = 1;
            % Xf = linspace(0,2500,size(C1,2)); % in ms
            % time_lab = 0;
            c1= C1_3D;
            c2= C2_3D;
            c3= C3_3D;
            c4= C4_3D;
            c5= C5_3D;

            c1_mean = mean(c1);
            c2_mean = mean(c2);
            c3_mean = mean(c3);
            c4_mean = mean(c4);
            c5_mean = mean(c5);


            ShadeColors = {
                [0 0 0.5];   % CE
                [0.5 0 0];   % CI
                [0 0.5 0];   % IE
                [0 0.5 0.5]; % II
                [0.5 0 0.5]; % SW
                };
            OutlineColors = {
                [0.6 0.6 1]; % CE
                [1 0.6 0.6]; % CI
                [0.6 1 0.6]; % IE
                [0.6 1 1];   % II
                [1 0.6 1];   % SW
                };
            percent = 0; % regular t-test
            alpha = 0.05;
            [~,~,~,~,p12,~,~] = limo_yuend_ttest(c1,c2,percent,alpha);
            [~,~,~,~,p13,~,~] = limo_yuend_ttest(c1,c3,percent,alpha);
            [~,~,~,~,p14,~,~] = limo_yuend_ttest(c1,c4,percent,alpha);
            [~,~,~,~,p15,~,~] = limo_yuend_ttest(c1,c5,percent,alpha);
            [~,~,~,~,p23,~,~] = limo_yuend_ttest(c2,c3,percent,alpha);
            [~,~,~,~,p24,~,~] = limo_yuend_ttest(c2,c4,percent,alpha);
            [~,~,~,~,p25,~,~] = limo_yuend_ttest(c2,c5,percent,alpha);
            [~,~,~,~,p34,~,~] = limo_yuend_ttest(c3,c4,percent,alpha);
            [~,~,~,~,p35,~,~] = limo_yuend_ttest(c3,c5,percent,alpha);

            figure('Color','w','NumberTitle','off') % make blank figure
            hold on % we're going to plot several elements
            plot(Xf,C1,'Color',colors{1},'LineStyle','-','LineWidth',1)
            plot(Xf,C2,'Color',colors{2},'LineStyle','-','LineWidth',1)
            plot(Xf,C3,'Color',colors{3},'LineStyle','-','LineWidth',1)
            plot(Xf,C4,'Color',colors{4},'LineStyle','-','LineWidth',1)
            plot(Xf,C5,'Color',colors{5},'LineStyle','-','LineWidth',1)
            set(gca,'LineWidth',1,'FontSize',14,'XLim',[start_plot end_plot])
            % legend(legendLab{1:2})
            if time_lab == 1
                xlabel('Time in [s]','FontSize',16)
            else
                xlabel('Time in [ms]','FontSize',16)
            end
            ylabel('Amplitude in \muV','FontSize',16)
            ylim(ylim1)

             % add shaded area
            percent=0;
            alpha=0.05; % to get a 95% confidence interval
            nullvalue=0;
            [~,~,trimci_c1,~,~,~] = limo_trimci(c1_mean, percent, alpha, nullvalue);
            [~,~,trimci_c2,~,~,~] = limo_trimci(c2_mean, percent, alpha, nullvalue);
            [~,~,trimci_c3,~,~,~] = limo_trimci(c3_mean, percent, alpha, nullvalue);
            [~,~,trimci_c4,~,~,~] = limo_trimci(c4_mean, percent, alpha, nullvalue);
            [~,~,trimci_c5,~,~,~] = limo_trimci(c5_mean, percent, alpha, nullvalue);

            % plot confidence intervals
            x = Xf; % time vector
            yc1 = squeeze(trimci_c1(:,:,1)); % CI lower bound
            zc1 =squeeze(trimci_c1(:,:,2)); % CI upper bound
            colorc1 = ShadeColors{1}; % set colour
            tc=.1; % set transparency [0, 1]
            x=x(:)';yc1=yc1(:)';zc1=zc1(:)';
            X=[x,fliplr(x)]; % create continuous x value array for plotting
            Yc1=[yc1,fliplr(zc1)]; % create y values for out and then back
            hfc1=fill(X,Yc1,colorc1); % plot filled area
            set(hfc1,'FaceAlpha',tc,'EdgeColor',OutlineColors{1},'LineWidth', 0.1);

            yc2=squeeze(trimci_c2(:,:,1));
            zc2=squeeze(trimci_c2(:,:,2));
            colorc2=ShadeColors{2};
            yc2=yc2(:)';
            zc2=zc2(:)';
            Yc2=[yc2,fliplr(zc2)];%create y values for out and then back
            hfc2=fill(X,Yc2,colorc2);%plot filled area
            set(hfc2,'FaceAlpha',tc,'EdgeColor',OutlineColors{2},'LineWidth', 0.1);

            yc3=squeeze(trimci_c3(:,:,1));
            zc3=squeeze(trimci_c3(:,:,2));
            colorc3=ShadeColors{3};
            yc3=yc3(:)';
            zc3=zc3(:)';
            Yc3=[yc3,fliplr(zc3)];%create y values for out and then back
            hfc3=fill(X,Yc3,colorc3);%plot filled area
            set(hfc3,'FaceAlpha',tc,'EdgeColor',OutlineColors{3},'LineWidth', 0.1)

            yc4=squeeze(trimci_c4(:,:,1));
            zc4=squeeze(trimci_c4(:,:,2));
            colorc4=ShadeColors{4};
            yc4=yc4(:)';
            zc4=zc4(:)';
            Yc4=[yc4,fliplr(zc4)];%create y values for out and then back
            hfc4=fill(X,Yc4,colorc4);%plot filled area
            set(hfc4,'FaceAlpha',tc,'EdgeColor',OutlineColors{3},'LineWidth', 0.1)
            
            yc5=squeeze(trimci_c5(:,:,1));
            zc5=squeeze(trimci_c5(:,:,2));
            colorc5=ShadeColors{5};
            yc5=yc5(:)';
            zc5=zc5(:)';
            Yc5=[yc5,fliplr(zc5)];%create y values for out and then back
            hfc5=fill(X,Yc5,colorc5);%plot filled area
            set(hfc5,'FaceAlpha',tc,'EdgeColor',OutlineColors{3},'LineWidth', 0.1)

            p_sum12 = sum(p12<=alpha);
            p_title12 = 100*(sum(p_sum12~=0)/length(Xf));
            p_sum13 = sum(p13<=alpha);
            p_title13 = 100*(sum(p_sum13~=0)/length(Xf));
            p_sum14 = sum(p14<=alpha);
            p_title14 = 100*(sum(p_sum14~=0)/length(Xf));
            p_sum15 = sum(p15<=alpha);
            p_title15 = 100*(sum(p_sum15~=0)/length(Xf));
            p_sum23 = sum(p23<=alpha);
            p_title23 = 100*(sum(p_sum23~=0)/length(Xf));
            p_sum24 = sum(p24<=alpha);
            p_title24 = 100*(sum(p_sum24~=0)/length(Xf));
            p_sum25 = sum(p25<=alpha);
            p_title25 = 100*(sum(p_sum25~=0)/length(Xf));
            p_sum34 = sum(p34<=alpha);
            p_title34 = 100*(sum(p_sum34~=0)/length(Xf));
            p_sum35 = sum(p35<=alpha);
            p_title35 = 100*(sum(p_sum35~=0)/length(Xf));

            % t_title = strcat(sprintf('ERP Response in the %s', bands{iband}),...
            %     '\newline','                      significance:',...
            %     '\newline', 'CE vs CI (Purple):', sprintf(' %.1f', p_title12),'%',...
            %     '\newline', 'CE vs IE (Green):', sprintf(' %.1f', p_title13),'%',...
            %     '\newline', 'CI vs IE (Orange):', sprintf(' %.1f', p_title23),'%');
            % title(t_title)
            box on
            hold on;
            % We add a horizontal line showing time points at which a significant mean
            % difference was observed.
            v=axis; % get current axis limits
            alpha=0.05; % set alpha level

            p12_any = any((p12<=alpha) == 1, 1);
            p13_any = any((p13<=alpha) == 1, 1);
            p14_any = any((p14<=alpha) == 1, 1);
            p15_any = any((p15<=alpha) == 1, 1);
            p23_any = any((p23<=alpha) == 1, 1);
            p24_any = any((p24<=alpha) == 1, 1);
            p25_any = any((p25<=alpha) == 1, 1);
            p34_any = any((p34<=alpha) == 1, 1);
            p35_any = any((p35<=alpha) == 1, 1);
            plot(Xf,p12_any*100-99.1+v(3)*.95,'o','MarkerSize',3, 'Color', [0    0.4470    0.7410]); % Blu (default MATLAB)
            plot(Xf,p13_any*100-99.2+v(3)*.95,'o','MarkerSize',3, 'Color', [0.8500    0.3250    0.0980]); % Rosso Arancio (default MATLAB)
            plot(Xf,p14_any*100-99.3+v(3)*.95,'o','MarkerSize',3, 'Color', [0.9290    0.6940    0.1250]); % Giallo (default MATLAB)
            plot(Xf,p15_any*100-99.4+v(3)*.95,'o','MarkerSize',3, 'Color', [0.4940    0.1840    0.5560]); % Viola (default MATLAB)
            plot(Xf,p23_any*100-99.5+v(3)*.95,'o','MarkerSize',3, 'Color', [0.4660    0.6740    0.1880]); % Verde (default MATLAB)
            plot(Xf,p24_any*100-99.6+v(3)*.95,'o','MarkerSize',3, 'Color', [0.3010    0.7450    0.9330]); % Azzurro Chiaro (default MATLAB)
            plot(Xf,p25_any*100-99.7+v(3)*.95,'o','MarkerSize',3, 'Color', [0.6350    0.0780    0.1840]); % Rosso Scuro (default MATLAB)
            plot(Xf,p34_any*100-99.8+v(3)*.95,'o','MarkerSize',3, 'Color', [0.1 0.1 0.1]); % Grigio Scuro (quasi nero)
            plot(Xf,p35_any*100-99.9+v(3)*.95,'o','MarkerSize',3, 'Color', [0 0.8 0.8]); % Ciano brillante


            % axis(v) % restore axis limits to hide non-significant points
            set(gcf,'PaperPositionMode','auto')
            set(gcf, 'WindowState', 'maximized');
            legend(legendLab{1:5},'')


            name1 = strcat('ERP_in_', bands{iband});
            % plot saving params
            save_dir1 ='D:\main_scriptNSA\Older_and_Proof\Sound_pipeline\11_06\ERP_analysis\N400Plot\BaselineRemoved\NEW_FIGURE\Confronto_a_5\';
            save_dir = strcat(save_dir1,ScalpSaveName{sa},'\',save_class,'\',num2str(end_plot),'\');
            par.savePlotEpsPdfMat.dir_png = strcat(save_dir,'\PNGs');
            par.savePlotEpsPdfMat.dir_pdf = strcat(save_dir,'PDFs\');
            par.savePlotEpsPdfMat.dir_mat = strcat(save_dir,'MATfiles\');

            par.savePlotEpsPdfMat.file_name = name1;
            savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
        end
        close all
    end
end