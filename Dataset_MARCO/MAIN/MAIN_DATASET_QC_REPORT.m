%% ========================================================================
% MAIN_DATASET_QC_REPORT
% ========================================================================
%
% Purpose
% -------
% Aggregate and summarize quality-control metrics generated during
% MAIN_EXTRACT_DATASET_MARCO_STEP1 across all subjects and trials.
%
% Processing steps
% ----------------
% 1. Load all *_data_extracted.mat files
% 2. Extract preprocessing QC metrics
% 3. Evaluate event integrity after preprocessing
% 4. Quantify removed channels and removed ICA components
% 5. Evaluate trigger latency preservation after resampling
% 6. Compute simple QC score for each recording
% 7. Generate summary tables and descriptive visualizations
% 8. Identify potential outliers requiring manual inspection
%
% Evaluated metrics
% -----------------
% - Recording duration
% - Number of detected events
% - Number of removed channels
% - Identity of removed channels
% - Number of removed ICA components
% - ICLabel classes of removed components
% - Event latency preservation
% - Signal variance reduction after cleaning
% - ICA rank information
%
% Output
% ------
% QC_SUMMARY.csv
%     Tabular summary of all recordings
%
% QC_SUMMARY.mat
%     MATLAB table containing all QC metrics
%
% Figures
% -------
% - Removed channel distributions
% - Removed channel topographies
% - Removed IC distributions
% - Event distributions
% - Latency-error distributions
% - ICA rank statistics
% - Global QC overview
%
% Notes
% -----
% This script does not modify EEG data.
% It only evaluates preprocessing quality and generates
% descriptive reports for dataset inspection.
%
% Recommended workflow
% --------------------
% MAIN_EXTRACT_DATASET_MARCO_STEP1
%           ↓
% MAIN_DATASET_QC_REPORT
%           ↓
% MAIN_EXTRACT_DATASET_MARCO_STEP2
%
% Author: Mirco Frosolone
% ========================================================================
clear; clc;

trialName = 'All_trials'; % SingleTrial
rootFolder = fullfile(...
'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\',trialName,'EXTRACTED_DATA');

files = dir(fullfile(rootFolder,'Subj*','*_data_extracted.mat'));

AllQC = table();

for k = 1:numel(files)

    fprintf('\n[%d/%d] %s\n', ...
        k,numel(files),files(k).name);

    try

        S = load(fullfile( ...
            files(k).folder,...
            files(k).name));

        subjectData = S.subjectData;

        %% ------------------------------------------------------------
        % METRICS
        % ------------------------------------------------------------
        DurationMin = ...
            subjectData.cleanContinuous.pnts / ...
            subjectData.cleanContinuous.srate / 60;

        nEvents = height(subjectData.eventsTable);

        nBadChannels = subjectData.nBadChannels;
        nameBadChannels = {subjectData.badChannelsRemoved};

        nBadICs = subjectData.nBadICs;
        ICL = subjectData.ICLabel;

        badICs = subjectData.badICs;

        classes = ...
            subjectData.cleanContinuous.etc.ic_classification.ICLabel.classes;

        removedICClassesTmp = strings(numel(badICs),1);

        for kk = 1:numel(badICs)
            ic = badICs(kk);
            [~,idx] = max(ICL(ic,:));
            removedICClassesTmp(kk) = classes{idx};
        end

        removedICClasses = {removedICClassesTmp};


        LatencyError = ...
            subjectData.QC.maxEventLatencyError;

        MeanSTD_raw = ...
            subjectData.QC.meanSTD_raw;

        MeanSTD_clean = ...
            subjectData.QC.meanSTD_clean;

        ReductionSTD = ...
            100*(1 - MeanSTD_clean/MeanSTD_raw);

        %% ------------------------------------------------------------
        % SCORE
        % ------------------------------------------------------------
        score = 100;

        if nBadChannels > 5
            score = score - 5;
        end

        if nBadChannels > 10
            score = score - 10;
        end

        if nBadICs == 0
            score = score - 10;
        end

        if nBadICs > 20
            score = score - 10;
        end

        if LatencyError > 1
            score = score - 10;
        end

        if LatencyError > 2
            score = score - 20;
        end

        %% ------------------------------------------------------------
        % CLASSIFICATION
        % ------------------------------------------------------------
        if score >= 90

            QCstatus = "EXCELLENT";

        elseif score >= 75

            QCstatus = "GOOD";

        elseif score >= 50

            QCstatus = "WARNING";

        else

            QCstatus = "CHECK";

        end

        %% ------------------------------------------------------------
        % TABLE ROW
        % ------------------------------------------------------------
        T = table( ...
            string(subjectData.subjectID),...
            string(subjectData.trialID),...
            DurationMin,...
            nEvents,...
            nBadChannels,...
            nameBadChannels,...
            nBadICs,...
            removedICClasses,...
            LatencyError,...
            MeanSTD_raw,...
            MeanSTD_clean,...
            ReductionSTD,...
            score,...
            QCstatus,...
            'VariableNames',{ ...
            'Subject',...
            'Trial',...
            'DurationMin',...
            'nEvents',...
            'nBadChannels',...
            'nameBadChannels',...
            'nBadICs',...
            'removedICClasses',...
            'LatencyError',...
            'MeanSTD_raw',...
            'MeanSTD_clean',...
            'STDReductionPercent',...
            'QCScore',...
            'QCStatus'});

        AllQC = [AllQC; T];

    catch ME

        fprintf('ERROR: %s\n',files(k).name);
        fprintf('%s\n',ME.message);

    end

end

%% =======================================================================
% SORT
% =======================================================================

AllQC = sortrows(AllQC,'QCScore','descend');

disp(AllQC)

%% =======================================================================
% SAVE
% =======================================================================

writetable( ...
    AllQC,...
    fullfile(rootFolder,'QC_SUMMARY.csv'));

save( ...
    fullfile(rootFolder,'QC_SUMMARY.mat'),...
    'AllQC');

fprintf('\nQC summary saved.\n');
pause
%% FIGURE
figure
histogram(AllQC.nBadChannels)
title('Bad Channels')
% distribuzione sul numero di canali che sono stati eliminati per ogni
% trial ed ogni soggetto
allBadChannels = [AllQC.nameBadChannels{:}];
[channelNames,~,idx] = unique(allBadChannels);
counts = accumarray(idx,1);
[countsSorted,ord] = sort(counts,'descend');
channelNamesSorted = channelNames(ord);
% figure of single channel occurances
figure
bar(countsSorted)
xticks(1:numel(channelNamesSorted))
xticklabels(channelNamesSorted)
xtickangle(45)
ylabel('Occurrences')
xlabel('Channel')
title('Frequency of Removed Channels')
grid on
% Table with percentage
nFiles = height(AllQC);
TableChPerc = table(channelNamesSorted',...
      countsSorted,...
      100*(countsSorted/nFiles));

% Evaluation of STD channels
subjId = 'Subj3';
trialId = 'trial1';
load(sprintf('%s_%s_data_extracted.mat',subjId,trialId))
rawSTD = subjectData.QC.stdChanRaw;
labels = subjectData.QC.chanLabels;
T = table(labels',rawSTD);
sortrows(T,2,'descend')
% Visualization of occurrance channel topoplot
addpath(genpath('D:\eeglab2026.0.0\'))
chanlocs = readlocs('Mon_64cc.xyz');
values = zeros(length(chanlocs),1);
for k = 1:length(channelNamesSorted)
    idx = strcmp({chanlocs.labels}, ...
                      channelNamesSorted{k});
    values(idx) = countsSorted(k);
end
figure
topoplot(values,chanlocs,...
          'electrodes','labels');
colorbar
title('Bad Channel Frequency')
%% ICDs
% quante componenti IC vengono rimosse
figure
histogram(AllQC.nBadICs)
% Che tipo di componenti IC vengono rimosse
allClasses = vertcat(AllQC.removedICClasses{:});
[classNames,~,idx] = unique(allClasses);
counts = accumarray(idx,1);
[counts,ord] = sort(counts,'descend');
classNames = classNames(ord);
table(classNames,counts)
% Chi sono gli outliers?quali soggetti hanno più IC eliminate?
TabOutliers = sortrows(AllQC,'nBadICs','descend');
TabOutliersICs = TabOutliers(:,{'Subject','Trial','nBadICs'});
disp(TabOutliersICs)
% i soggetti con molte badChannels anche anche molte badICs?
subjects = unique(AllQC.Subject);
baseColors = lines(numel(subjects));
figure
hold on
for s = 1:numel(subjects)
    idxSub = strcmp(AllQC.Subject,subjects{s});
    Tsub = AllQC(idxSub,:);
    for k = 1:height(Tsub)
        tr = sscanf(Tsub.Trial{k},'trial%d');
        alpha = tr/4;   % trial1=0.25 trial4=1
        baseColor = baseColors(s,:);
        c = (1-alpha)*[1 1 1] + alpha*baseColor;
        scatter(Tsub.nBadChannels(k), ...
                Tsub.nBadICs(k), ...
                100, ...
                c, ...
                'filled');
        lbl = sprintf('%s_%s',...
            Tsub.Subject{k},...
            Tsub.Trial{k});
        num = regexp(lbl, '\d+', 'match');
        new_lbl = sprintf('Sbj_%s,Tr_%s', num{1}, num{2});
        text(Tsub.nBadChannels(k)+0.05,...
            Tsub.nBadICs(k),...
            new_lbl,...
            'FontSize',8);
    end
end
xlabel('Bad Channels')
ylabel('Bad ICs')
title('QC Overview')
grid on
hold off
% %----RANK ICA
% figure
% subplot(1,2,1)
% histogram(AllQC.rankBeforeICA)
% title('Rank before ICA')
% subplot(1,2,2)
% histogram(AllQC.rankApproxAfterClean)
% title('Channels retained for ICA')


%--EVENTS
TableEvents = AllQC(:,{'Subject','Trial',...
          'nEvents'});
disp(TableEvents)
figure
histogram(AllQC.nEvents)
% in caso di eventi mancanti verifico se la lunghezza è coerente tramite
% confronto tra soggetti. Ad es in questo caso subj5 trial2 ha 378 eventi
s1 = load('D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\EXTRACTED_DATA\Subj5\Subj5_trial2_data_extracted.mat');
s1.subjectData.eventsTable(1:10,:)
tabulate(s1.subjectData.eventsTable.type)
s2 = load('D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\EXTRACTED_DATA\Subj2\Subj2_trial2_data_extracted.mat');
s2.subjectData.eventsTable(1:10,:)
tabulate(s2.subjectData.eventsTable.type)
% calcolo z-score
zEvents = zscore(AllQC.nEvents);
TableZscore = table(AllQC.Subject,...
      AllQC.Trial,...
      AllQC.nEvents,...
      zEvents);
disp(TableZscore)
% VerificA Percentuale differenza
maxEvents = max(AllQC.nEvents);
eventLossPercent = ...
100*(maxEvents - AllQC.nEvents)/maxEvents;
TableDiff = table(AllQC.Subject,...
      AllQC.Trial,...
      AllQC.nEvents,...
      eventLossPercent);
disp(TableDiff)
%Event integrity check showed preservation of trigger categories and event
%timing across all trials. One recording (Subj5_trial2) contained fewer
%total events (378 vs ~400 in the remaining trials, z = −3.75),
%corresponding to a reduction of approximately 5.7%. However, all event
%classes were present and displayed a comparable distribution, suggesting a
%shorter recording or fewer delivered stimuli rather than event loss
%introduced by preprocessing. 


% ---MAX LATENCY ERROR
TableLatencyError = sortrows(AllQC,'LatencyError','descend');
disp(TableLatencyError)
figure
histogram(AllQC.LatencyError)
xlabel('Max Latency Error (samples)')





%% ICA PLOT COMPONENT CONTROL
subjICA = 4;
trialICA = 3;
subjICAname = sprintf('Subj%d',subjICA);
trialICAname = sprintf('Subj%d_trial%d_data_extracted.mat',subjICA,trialICA);

load(fullfile('D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\EXTRACTED_DATA',subjICAname,trialICAname));
subjectData.badICs



