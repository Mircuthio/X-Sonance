% ========================================================================
% MAIN_EXTRACT_DATASET_MARCO_STEP1
% ========================================================================
%
% Purpose
% -------
% Automated EEG preprocessing pipeline for all subjects and trials
% contained in the DATA_SUBJECTS directory.
%
% Processing steps
% ----------------
% 1. Load continuous EEG recording
% 2. Extract trigger events
% 3. Line-noise notch filtering
% 4. Downsampling to target sampling rate
% 5. Detrending and centering
% 6. Average re-referencing
% 7. Creation of analysis and ICA datasets
% 8. Automatic bad-channel detection (clean_rawdata)
% 9. ICA decomposition
% 10. ICLabel classification
% 11. Automatic artifact IC rejection
% 12. Channel interpolation
% 13. Quality-control metrics generation
% 14. Saving cleaned dataset and metadata
%
% Output
% ------
% DEBUG_PLOTS/
%     QC figures and diagnostic outputs
%
% EXTRACTED_DATA/
%     subjectData structures ready for downstream analyses
%
% Notes
% -----
% Files not matching the pattern *_trialN.mat
% are automatically skipped (e.g. relax recordings).
%
% Author: Marco
% ========================================================================
clear; close all; clc
origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

par.savePlotEpsPdfMat.save_png = true;
par.savePlotEpsPdfMat.save_pdf = false;
par.savePlotEpsPdfMat.save_fig = false;

debugMode = true;

addpath(genpath('D:\eeglab2026.0.0\'))

% PARAMETERS
line_frequency = 50;
step_frequency = 2;
target_fs = 250;

rootFolder = 'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials';

subjectDirs = dir(fullfile(rootFolder,'Subj*'));
subjectDirs = subjectDirs([subjectDirs.isdir]);
for s = 1:numel(subjectDirs)
    subjName = subjectDirs(s).name;

    subjFolder = fullfile( ...
        rootFolder,...
        subjName);

    matFiles = dir(fullfile(subjFolder,'*_trial*.mat'));

    for f = 1:numel(matFiles)
        try
            currentFile = fullfile( ...
                subjFolder,...
                matFiles(f).name);
            [~,fileBase,~] = fileparts(matFiles(f).name);
            if endsWith(fileBase,'_trial')
                tokens = regexp(fileBase,'(.*)_trial$','tokens');
                if isempty(tokens)
                    error('Could not parse file name: %s',fileBase);
                end
                recordingName = tokens{1}{1};
                trialnumber   = 'trialALL';
            else
                tokens = regexp( ...
                    fileBase,...
                    '(.*)_(trial\d+)',...
                    'tokens');
                if isempty(tokens)
                    fprintf('Skipping %s\n',matFiles(f).name);
                    continue
                end
                tokens = tokens{1};

                recordingName = tokens{1};
                trialnumber   = tokens{2};

            end

            currentFile = fullfile( ...
                subjFolder,...
                matFiles(f).name);

            tmp = load(currentFile);
            fprintf('\n');
            fprintf('=====================================\n');
            fprintf('SUBJECT : %s\n',subjName);
            fprintf('FILE    : %s\n',matFiles(f).name);
            fprintf('TRIAL   : %s\n',trialnumber);
            fprintf('[%d/%d] Subject %s\n',s,numel(subjectDirs),subjName);
            fprintf('[%d/%d] File %s\n',f,numel(matFiles),matFiles(f).name);
            fprintf('\n');
            fprintf('=====================================\n');

            if debugMode
                debugFolder = fullfile( ...
                    rootFolder,...
                    'DEBUG_PLOTS',...
                    subjName,...
                    trialnumber);
                if ~exist(debugFolder,'dir')
                    mkdir(debugFolder);
                end
            end
            QC = struct();
            y = tmp.y;

            time    = y(1,:);
            EEGraw  = y(2:end-1,:);
            trigger = y(end,:);

            dt = mean(diff(time));
            Fs = round(1/dt);

            if abs(Fs - 4800) > 1 && abs(Fs - target_fs) > 1
                warning('Unexpected sampling rate: %.2f Hz', Fs)
            end

            fprintf('Sampling rate = %.2f Hz\n',Fs);

            eventOnsets = find(diff([0 trigger~=0])==1);
            eventCodes  = trigger(eventOnsets);

            eventsTable = table;
            eventsTable.trigger = eventCodes(:);
            eventsTable.latency = eventOnsets(:);
            eventsTable.timeSecRaw = time(eventOnsets)';
            eventsTable.timeSec = (eventOnsets(:)-1)/Fs;
            eventsTable.block = repmat(string(trialnumber),height(eventsTable),1);
            fprintf('Events found: %d\n',numel(eventOnsets));
            disp(tabulate(eventCodes))
            EEG = eeg_emptyset;

            EEG.data   = EEGraw;
            EEG.nbchan = size(EEGraw,1);
            EEG.pnts   = size(EEGraw,2);
            EEG.trials = 1;
            EEG.srate  = Fs;
            EEG.xmin   = 0;
            EEG.xmax = (EEG.pnts - 1) / EEG.srate;
            for k = 1:numel(eventOnsets)

                EEG.event(k).type    = num2str(eventCodes(k));
                EEG.event(k).latency = eventOnsets(k);
                EEG.event(k).urevent = k;
            end
            EEG = eeg_checkset(EEG,'eventconsistency');

            chanlocs = readlocs('Mon_64cc.xyz');

            EEG.chanlocs = chanlocs;
            assert(length(EEG.chanlocs) == EEG.nbchan,...
                'Mismatch between EEG channels and xyz channels');
            EEG.setname = sprintf('%s_%s_raw',subjName,trialnumber);
            EEG.subject = subjName;

            EEG = eeg_checkset(EEG);
            fprintf('\n');
            fprintf('Duration raw: %.2f min\n', ...
                EEG.pnts/EEG.srate/60);
            fprintf('\n');
            dt_all = diff(time);
            
            
            QC.dt_mean   = mean(dt_all);
            QC.dt_std    = std(dt_all);
            QC.dt_maxdev = max(abs(dt_all-QC.dt_mean));
            eventsTable.type = string(eventCodes(:));
            QC.uniqueTriggers = unique(eventCodes);

            %% Topoplot pre Resample-Detrend-AvgRemov
            stdChanRaw = std(single(EEG.data),0,2);
            if debugMode
                fig = figure;
                subplot(1,2,1)
                plot(stdChanRaw,'o-')
                subplot(1,2,2)
                topoplot(stdChanRaw,EEG.chanlocs)
                colorbar
                set(gcf,'PaperPositionMode','auto')
                set(gcf, 'WindowState', 'maximized');                
                par.savePlotEpsPdfMat.dir_png = debugFolder;
                par.savePlotEpsPdfMat.file_name = sprintf('%s_%s_01_STD_RAW.png',subjName,trialnumber);
                savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
                    
                close(fig)
            end
            %% --------------------------------------------------------
            % NOTCH FILTER FOR LINE NOISE
            % --------------------------------------------------------

            EEG = pop_eegfiltnew(EEG, ...
                'locutoff', line_frequency-step_frequency, 'hicutoff', line_frequency+step_frequency, ...
                'revfilt', 1, 'plotfreqz', 0);


            %% --------------------------------------------------------
            % 4H) RESAMPLE - DOWNSAMPLING
            % --------------------------------------------------------

            EEG = pop_resample(EEG, target_fs);
            eventTypes = unique({EEG.event.type});
            disp(eventTypes)
            assert(numel(EEG.event) == numel(eventOnsets), ...
                'Event count changed after resampling');
            EEG = eeg_checkset(EEG,'eventconsistency');
            fprintf('Resampled to %.1f Hz\n',EEG.srate);
            fprintf('Events after resample: %d\n',numel(EEG.event));
            lat_old = eventOnsets(:);
            lat_new = [EEG.event.latency]';

            lat_exp = lat_old*(target_fs/Fs);
            
            QC.FsOriginal = Fs;
            QC.FsFinal = EEG.srate;
            QC.eventLatencyError = lat_new-lat_exp;
            QC.maxEventLatencyError = max(abs(QC.eventLatencyError));
            %% --------------------------------------------------------
            % DETREND / CENTER
            % --------------------------------------------------------

            EEG.data = double(EEG.data);
            for ch = 1:size(EEG.data,1)
                EEG.data(ch,:) = detrend(EEG.data(ch,:), 'linear');
                EEG.data(ch,:) = EEG.data(ch,:) - mean(EEG.data(ch,:));
            end
            EEG = eeg_checkset(EEG);

            %% --------------------------------------------------------
            % 4J) REREFERENCE
            % --------------------------------------------------------

            EEG = pop_reref(EEG, []);
            EEG = eeg_checkset(EEG);
            EEG_preICA = EEG;
            %% Topoplot post Resample-Detrend-AvgRemov
            stdChanPreICA = std(single(EEG.data),0,2);
            if debugMode
                fig = figure;
                subplot(1,2,1)
                plot(stdChanPreICA,'o-')
                subplot(1,2,2)
                topoplot(stdChanPreICA,EEG.chanlocs)
                colorbar
                set(gcf,'PaperPositionMode','auto')
                set(gcf, 'WindowState', 'maximized');
                par.savePlotEpsPdfMat.dir_png = debugFolder;
                par.savePlotEpsPdfMat.file_name = sprintf('%s_%s_02_STD_PREICA.png',subjName,trialnumber);
                savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)                  
                close(fig)
            end
            zSTD = zscore(stdChanPreICA);
            badSTD = find(abs(zSTD)>3);
            fprintf('Potential outlier channels:\n')
            disp({EEG.chanlocs(badSTD).labels})


            QC.subjectID = subjName;
            QC.nChannels = EEG.nbchan;
            QC.chanLabels = {EEG.chanlocs.labels};
            QC.FsOriginal = Fs;
            QC.FsFinal = EEG.srate;
            QC.nEvents = numel(EEG.event);
            QC.stdChanRaw = stdChanRaw;
            QC.stdChanPreICA = stdChanPreICA;
            QC.zSTD = zSTD;
            QC.badSTD = badSTD;
            QC.badSTD_labels = {EEG.chanlocs(badSTD).labels};
            QC.triggerDistribution = tabulate(eventCodes);
            QC.nTrig1 = sum(eventCodes==1);
            QC.nTrig5 = sum(eventCodes==5);
            QC.nTrig7 = sum(eventCodes==7);
            QC.nTrig8 = sum(eventCodes==8);


            fprintf('\n');
            fprintf('---------------------------------\n');
            fprintf('SUBJECT: %s\n',subjName);
            fprintf('Channels: %d\n',EEG.nbchan);
            fprintf('Sampling rate: %.1f Hz\n',EEG.srate);
            fprintf('Events: %d\n',numel(EEG.event));
            fprintf('Potential outliers: %d\n',numel(badSTD));
            fprintf('\nUnique triggers:\n');
            disp(unique(eventCodes))
            fprintf('Max latency error after resample: %.3f samples\n', ...
                QC.maxEventLatencyError);
            fprintf('---------------------------------\n');

            %% --------------------------------------------------------
            % CREATE ANALYSIS AND ICA DATASETS
            % --------------------------------------------------------

            analysis_lowcut  = 1;
            analysis_highcut = 90;

            ica_lowcut  = 1;
            ica_highcut = 45;

            fullEEG = pop_eegfiltnew(EEG,...
                'locutoff',analysis_lowcut,...
                'hicutoff',analysis_highcut,...
                'plotfreqz',0);

            EEG_ica = pop_eegfiltnew(EEG,...
                'locutoff',ica_lowcut,...
                'hicutoff',ica_highcut,...
                'plotfreqz',0);

            fullEEG = eeg_checkset(fullEEG);
            EEG_ica = eeg_checkset(EEG_ica);
            %% Rank check
            fprintf('CHECKPOINT A\n');
            rankData = EEG_ica.nbchan;

            fprintf('\n');
            fprintf('Data rank: %d\n',rankData);
            fprintf('Channels : %d\n',EEG_ica.nbchan);
            fprintf('\n');
            fprintf('Duration: %.2f min\n', ...
                EEG_ica.pnts/EEG_ica.srate/60);

            fprintf('Samples: %d\n',EEG_ica.pnts);
            %% --------------------------------------------------------
            % REMOVE BAD CHANNELS BEFORE ICA
            % --------------------------------------------------------
            fprintf('CHECKPOINT B\n');
            EEG_ica = pop_clean_rawdata(EEG_ica,...
                'FlatlineCriterion',5,...
                'ChannelCriterion',0.8,...
                'LineNoiseCriterion',4,...
                'Highpass','off',...
                'BurstCriterion','off',...
                'WindowCriterion','off',...
                'BurstRejection','off',...
                'Distance','Euclidian');

            EEG_ica = eeg_checkset(EEG_ica);
            good_labels = {EEG_ica.chanlocs.labels};
            full_labels = {fullEEG.chanlocs.labels};

            bad_mask = ~ismember(full_labels,good_labels);
            bad_labels = full_labels(bad_mask);

            fprintf('\n');
            fprintf('%d/%d channels retained for ICA\n',...
                numel(good_labels),...
                numel(full_labels));
            if isempty(bad_labels)
                fprintf('No bad channels removed.\n');
            else
                fprintf('Removed channels:\n');
                disp(bad_labels')
            end

            % CHECK clean
            fprintf('Removed %.1f %% of channels\n', ...
                100*numel(bad_labels)/numel(full_labels));
            % Plot check
            stdICA = std(single(EEG_ica.data),0,2);
            if debugMode
                fig = figure;
                subplot(1,2,1)
                plot(stdICA,'o-')
                subplot(1,2,2)
                topoplot(stdICA,EEG_ica.chanlocs)
                colorbar
                set(gcf,'PaperPositionMode','auto')
                set(gcf, 'WindowState', 'maximized');
                par.savePlotEpsPdfMat.dir_png = debugFolder;
                par.savePlotEpsPdfMat.file_name = sprintf('%s_%s_03_STD_CLEANRAWDATA.png',subjName,trialnumber);
                savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
                close(fig)
            end
            rankDataICA = size(EEG_ica.data,1);

            fprintf('Rank after clean_rawdata: %d\n', ...
                rankDataICA);

            fprintf('Channels after cleaning: %d\n', ...
                EEG_ica.nbchan);
            %% --------------------------------------------------------
            % RUN ICA
            % --------------------------------------------------------
            fprintf('\n');
            fprintf('Running ICA...\n');
            fprintf('Channels : %d\n',EEG_ica.nbchan);
            fprintf('Samples  : %d\n',EEG_ica.pnts);
            fprintf('Duration : %.1f min\n',...
                EEG_ica.pnts/EEG_ica.srate/60);
            fprintf('CHECKPOINT C\n');
            EEG_ica = pop_runica(EEG_ica,...
                'icatype','runica',...
                'extended',1,...
                'interrupt','on');

            EEG_ica = eeg_checkset(EEG_ica);

            fprintf('\n');
            fprintf('ICA computed.\n');

            disp(size(EEG_ica.icaweights))
            disp(size(EEG_ica.icawinv))

            %% --------------------------------------------------------
            % ICLABEL
            % --------------------------------------------------------
            fprintf('CHECKPOINT D\n');
            EEG_ica = pop_iclabel(EEG_ica,'default');

            %%CHECK
            stdChanPostICA = std(single(EEG_ica.data),0,2);
            if debugMode
                pop_selectcomps(EEG_ica,...
                    1:min(35,size(EEG_ica.icawinv,2)));
                drawnow
                fig = gcf;
                set(gcf,'PaperPositionMode','auto')
                set(gcf, 'WindowState', 'maximized');
                par.savePlotEpsPdfMat.dir_png = debugFolder;
                par.savePlotEpsPdfMat.file_name = sprintf('%s_%s_04_ICA_COMPONENTS.png',subjName,trialnumber);
                savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)                    
                close(fig)
                % Controllo quantitativo canali
                fig = figure;
                subplot(1,2,1)
                plot(stdChanPostICA,'o-')
                subplot(1,2,2)
                topoplot(stdChanPostICA,EEG_ica.chanlocs)
                colorbar
                set(gcf,'PaperPositionMode','auto')
                set(gcf, 'WindowState', 'maximized');
                par.savePlotEpsPdfMat.dir_png = debugFolder;
                par.savePlotEpsPdfMat.file_name = sprintf('%s_%s_05_STD_PSTICA.png',subjName,trialnumber);
                savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)
                close(fig)
            end
            %% --------------------------------------------------------
            % FLAG ARTIFACTUAL ICS
            % --------------------------------------------------------

            EEG_ica = pop_icflag(EEG_ica,...
                [NaN NaN;   % Brain
                0.8 1;     % Muscle
                0.8 1;     % Eye
                NaN NaN;     % Heart
                0.8 1;     % Line Noise
                0.8 1;     % Channel Noise
                NaN NaN]); % Other

            badICs = find(EEG_ica.reject.gcompreject);
            fprintf('Bad ICs: %d\n',numel(badICs));
            disp(badICs)
            [~,maxClass] = max( ...
                EEG_ica.etc.ic_classification.ICLabel.classifications,...
                [],2);
            disp(tabulate(maxClass))
            ICLabelResults = ...
                EEG_ica.etc.ic_classification.ICLabel.classifications;
            classes = ...
                EEG_ica.etc.ic_classification.ICLabel.classes;
            for k=1:numel(badICs)
                ic = badICs(k);
                [p,idx] = max(ICLabelResults(ic,:));
                fprintf('IC %d -> %s (%.1f%%)\n',...
                    ic,...
                    classes{idx},...
                    100*p);
            end
            % il numero di componenti classificate come eye o muscle peggio Brain deve
            % essere coerente. ad es su 20 minuti di registrazione continua 7
            % componenti oculari sono ancora credibili così come in un task statico 2
            % muscolari. Brain >90% eliminata può essere strano

            %% --------------------------------------------------------
            % TRANSFER ICA WEIGHTS
            % --------------------------------------------------------
            originalEEG = pop_select(fullEEG,...
                'channel',good_labels);

            assert(isequal({originalEEG.chanlocs.labels},...
                {EEG_ica.chanlocs.labels}),...
                'Channel mismatch');

            originalEEG.icaweights  = EEG_ica.icaweights;
            originalEEG.icasphere   = EEG_ica.icasphere;
            originalEEG.icawinv     = EEG_ica.icawinv;
            originalEEG.icachansind = EEG_ica.icachansind;

            if isfield(EEG_ica, 'etc') && isfield(EEG_ica.etc, 'ic_classification')
                originalEEG.etc.ic_classification = EEG_ica.etc.ic_classification;
            end

            if isfield(EEG_ica, 'reject') && isfield(EEG_ica.reject, 'gcompreject')
                originalEEG.reject.gcompreject = EEG_ica.reject.gcompreject;
            end

            originalEEG = eeg_checkset(originalEEG);
            originalEEG = eeg_checkset(originalEEG,'ica');

            %% --------------------------------------------------------
            % REMOVE ARTIFACTUAL ICS
            % --------------------------------------------------------
            badICsFinal = badICs;

            if isfield(originalEEG,'reject') && ...
                    isfield(originalEEG.reject,'gcompreject') && ...
                    ~isempty(originalEEG.reject.gcompreject)

                badICs = find(originalEEG.reject.gcompreject);
                fprintf('%d ICs flagged for removal\n',...
                    numel(badICs));
                if ~isempty(badICs)
                    originalEEG = pop_subcomp(originalEEG,badICs,0);
                end
            end
            %% --------------------------------------------------------
            % INTERPOLATE REMOVED BAD CHANNELS BACK
            % --------------------------------------------------------
            cleanEEG = pop_interp(originalEEG, fullEEG.chanlocs, 'spherical');
            nRemoved = numel(bad_labels);

            if nRemoved > 0.3*numel(full_labels)
                warning('More than 30%% channels removed before ICA');
            end
            cleanEEG = eeg_checkset(cleanEEG);

            fprintf('Events final: %d\n',numel(cleanEEG.event));
            assert(numel(cleanEEG.event)==numel(eventOnsets))

            % check
            stdChanClean = std(single(cleanEEG.data),0,2);
            if debugMode
                fig = figure;
                subplot(1,2,1)
                plot(stdChanClean,'o-')
                subplot(1,2,2)
                topoplot(stdChanClean,cleanEEG.chanlocs)
                colorbar
                set(gcf,'PaperPositionMode','auto')
                set(gcf, 'WindowState', 'maximized');
                par.savePlotEpsPdfMat.dir_png = debugFolder;
                par.savePlotEpsPdfMat.file_name = sprintf('%s_%s_06_STD_FINAL.png',subjName,trialnumber);
                savePlotEpsPdfMat(gcf,par.savePlotEpsPdfMat)                   
                close(fig)
            end

            %% --------------------------------------------------------
            % STORE CLEANING METADATA
            % --------------------------------------------------------
            QC.nBadChannels = numel(bad_labels);
            QC.badChannels = bad_labels;
            QC.nBadICs = numel(badICsFinal);
            QC.badICs = badICsFinal;
            QC.stdChanClean = stdChanClean;
            QC.meanSTD_raw = mean(stdChanRaw);
            QC.meanSTD_preICA = mean(stdChanPreICA);
            QC.meanSTD_clean = mean(stdChanClean);
            QC.medianSTD_raw = median(stdChanRaw);
            QC.medianSTD_preICA = median(stdChanPreICA);
            QC.medianSTD_clean = median(stdChanClean);

            %% ----
            % SAVING
            % -----
            save( ...
                fullfile(debugFolder,...
                sprintf('%s_%s_QC.mat',subjName,trialnumber)),...
                'QC');
            eventsTable.latency = [cleanEEG.event.latency]';
            eventsTable.timeSec = ...
                ([cleanEEG.event.latency]'-1)/cleanEEG.srate;
            writetable( ...
                eventsTable,...
                fullfile(debugFolder,...
                sprintf('%s_%s_events.csv',subjName,trialnumber)));

            subjectData = struct();
            subjectData.subjectID = subjName;
            subjectData.trialID = trialnumber;
            subjectData.recordingName = recordingName;
            subjectData.originalFile = matFiles(f).name;
            subjectData.cleanContinuous = cleanEEG;
            subjectData.eventsTable = eventsTable;
            subjectData.chanlocs = cleanEEG.chanlocs;
            subjectData.chanlabels = {cleanEEG.chanlocs.labels};
            subjectData.badChannelsRemoved = bad_labels;
            subjectData.nBadChannels = numel(bad_labels);
            subjectData.badICs = badICsFinal;
            subjectData.nBadICs = numel(badICsFinal);
            subjectData.ICLabel = ICLabelResults;
            subjectData.QC = QC;
            subjectData.preprocessingInfo.analysisBand = [analysis_lowcut analysis_highcut];
            subjectData.preprocessingInfo.icaBand = [ica_lowcut ica_highcut];
            subjectData.preprocessingInfo.lineFrequency = line_frequency;
            subjectData.preprocessingInfo.targetFs = target_fs;
            subjectData.events = cleanEEG.event;
            subjectData.goodChannelsForICA = good_labels;
            subjectData.preprocessingInfo.rankBeforeICA = rankData;
            subjectData.preprocessingInfo.rankAfterClean = rankDataICA;
            subjectData.preprocessingInfo.originalFs = Fs;
            subjectData.preprocessingInfo.finalFs    = target_fs;
            subjectData.preprocessingInfo.nChannelsOriginal =  numel(chanlocs);
            subjectData.preprocessingInfo.nChannelsFinal = cleanEEG.nbchan;

            save( ...
                fullfile(debugFolder,...
                sprintf('%s_%s_summary.mat',...
                subjName,trialnumber)),...
                'subjectData',...
                '-v7.3');

            outputFolder = fullfile(rootFolder, 'EXTRACTED_DATA', subjName);

            if ~exist(outputFolder,'dir')
                mkdir(outputFolder);
            end

            save( ...
                fullfile(outputFolder,...
                sprintf('%s_%s_data_extracted.mat',...
                subjName,trialnumber)),...
                'subjectData',...
                '-v7.3');
            clear EEG
            clear EEG_preICA
            clear EEG_ica
            clear fullEEG
            clear cleanEEG
            clear originalEEG
            clear tmp
            clear y
            clear EEGraw
            clear trigger
        catch ME
            fprintf('\n');
            fprintf('=====================================\n');
            fprintf('ERROR PROCESSING FILE\n');
            fprintf('%s\n',currentFile);
            fprintf('%s\n',getReport(ME,'extended'));
            fprintf('=====================================\n');
            if debugMode
                close all
            end
            continue
        end
    end
end
set(0,'DefaultFigureVisible',origState);
