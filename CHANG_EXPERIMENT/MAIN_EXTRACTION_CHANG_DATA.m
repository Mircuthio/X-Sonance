% MAIN_EXTRACTION_CHANG_DATA.m
% revision of Extraction_data_AntNeuroEEGO_STEP1_bis.m
% FINAL VERSION - SUBJECT-LEVEL CONTINUOUS PREPROCESSING
% Raw
% ↓
% Notch
% ↓
% Resample
% ↓
% Detrend
% ↓
% Average Reference
% ↓
%
%       EEG
%
%      /   \
%     /     \
%
% fullEEG   EEG_ica
%
% 1-90 Hz   1-45 Hz
%
%     │        │
%     │        └─ clean_rawdata
%     │        └─ ICA
%     │        └─ ICLabel
%     │
%     └──────── Transfer ICA weights
%               ↓
%            Remove ICs
%               ↓
%          Interpolate
%               ↓
%        cleanEEG 1-90 Hz
% PIPELINE LOGIC
% - load one subject at a time
% - keep continuous EEG as the main preprocessing object
% - remove non-EEG channels
% - filter / resample / detrend / rereference
% - remove bad channels before ICA
% - run ICA on good channels only
% - remove bad ICs
% - interpolate removed bad channels back
% - save:
%       1) clean continuous EEG
%       2) baseline segments
%       3) datatrials struct with full trial segments and internal events
%
% NOTE
% - No direct consonant/dissonant epoching here
% - Event-locked epoching will be done in a later analysis step

clear; close all; clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

debugMode = true;
%% ============================================================
% 1) PATHS AND DEPENDENCIES
% ============================================================
raw_dir    = 'D:\X-SONANCE\CHANG_EXPERIMENT\';
output_dir = 'D:\X-SONANCE\CHANG_EXPERIMENT\';

% addpath(genpath('D:\eeglab2023.1\'))
addpath(genpath('D:\eeglab2026.0.0\'))

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% ============================================================
% 2) EXPERIMENTAL PARAMETERS
% ============================================================
% Replace these placeholders with your real trigger labels
% marker_baseline_open   = 'BASELINE_EO';
% marker_baseline_closed = 'BASELINE_EC';
% marker_trial_start     = 'TRIAL_START';
% marker_sound_con       = 'SOUND_CON';
% marker_sound_dis       = 'SOUND_DIS';
% marker_trial_end       = 'TRIAL_END';
% CHANG markers

marker_trial_start = '10';

marker_cond_101 = '101';
marker_cond_102 = '102';
marker_cond_103 = '103';

marker_trial_end = '20';


% Filtering
analysis_lowcut  = 1;
analysis_highcut = 90;
line_frequency = 50;
step_frequency = 2;

ica_lowcut  = 1;
ica_highcut = 45;

% Downsampling
target_fs = 250;

%% ============================================================
% 3) FILE SEARCH
% ============================================================
files_xdf = dir(fullfile(raw_dir,'*.xdf'));
files_cnt = dir(fullfile(raw_dir,'*.cnt'));
files_set = dir(fullfile(raw_dir,'*.set'));
% files_mat = dir(fullfile(raw_dir,'*.mat'));

allFiles = [files_xdf; files_cnt; files_set];

[~,baseNames] = cellfun(@fileparts,{allFiles.name},'UniformOutput',false);

if numel(unique(baseNames)) ~= numel(baseNames)
    warning('Duplicate subject filenames detected.');
end

names = {allFiles.name};

if isempty(names)
    error('No supported EEG files found in raw_dir.');
end

%% ============================================================
% 4) SUBJECT LOOP
% ============================================================
for n = 4 %1:numel(names)

    try
        [~, base_filename, ext] = fileparts(names{n});
        tok = regexp(base_filename,...
            'sub-(S\d+)',...
            'tokens','once');
        if ~isempty(tok)
            subjName = tok{1};
        else
            subjName = base_filename;
        end
        QC = struct();
        fprintf('\n============================================================\n');
        fprintf('Processing subject %d/%d: %s\n', n, numel(names), names{n});
        fprintf('============================================================\n');
        %% --------------------------------------------------------
        % 4A) LOAD RAW DATA
        % --------------------------------------------------------
        switch lower(ext)
            case '.xdf'
                EEG = load_xdf_to_eeglab( ...
                    fullfile(raw_dir,names{n}));
            case '.cnt'
                EEG = pop_loadcnt(fullfile(raw_dir, names{n}));
            case '.set'
                EEG = pop_loadset('filename', names{n}, 'filepath', raw_dir);
            case '.mat'
                tmp = load(fullfile(raw_dir, names{n}));
                if isfield(tmp, 'EEG')
                    EEG = tmp.EEG;
                else
                    warning('File %s does not contain a valid EEG variable. Skipped.', names{n});
                    continue
                end
            otherwise
                warning('Unsupported file format: %s', names{n});
                continue
        end

        EEG = eeg_checkset(EEG);
        % --------------------------------------------------------
        % REMOVE AUXILIARY XDF CHANNELS
        % Ch65 = flat channel
        % Ch66 = trigger/auxiliary channel
        % --------------------------------------------------------

        if EEG.nbchan == 66

            EEG = pop_select(EEG,'channel',1:64);

            fprintf('Removed auxiliary channels 65-66\n');

            load('Chang_AntNeuro_chanlocs_template.mat',...
                'chanlocsTemplate');

            assert(length(chanlocsTemplate)==64,...
                'Channel template does not contain 64 channels');

            EEG.chanlocs = chanlocsTemplate;

            EEG = eeg_checkset(EEG);

            fprintf('Assigned ANT Neuro channel template\n');

        end
        %% --------------------------------------------------------
        % 4B) EVENT CHECK
        % --------------------------------------------------------
        if ~isfield(EEG,'event') || isempty(EEG.event)
            warning('No events found in %s. Skipped.', names{n});
            continue
        end
        eventTypes = {EEG.event.type};
        eventCodes = cellfun(@str2double,{EEG.event.type});
        fprintf('\n=== PROTOCOL CHECK ===\n');

        fprintf('10  : %d\n',sum(eventCodes==10));
        fprintf('101 : %d\n',sum(eventCodes==101));
        fprintf('102 : %d\n',sum(eventCodes==102));
        fprintf('103 : %d\n',sum(eventCodes==103));
        fprintf('20  : %d\n',sum(eventCodes==20));

        if mod(length(eventCodes),3) ~= 0
            error('Marker count is not a multiple of 3');
        end
        firstStartEvent = find(eventCodes==10,1,'first');

        preStartDurationSec = ...
            (EEG.event(firstStartEvent).latency - 1) ...
            / EEG.srate;

        fprintf('Pre-start segment: %.2f sec\n',...
            preStartDurationSec);
        for k = 1:3:length(eventCodes)

            assert(eventCodes(k)==10,...
                'Expected START marker')

            assert(ismember(eventCodes(k+1),...
                [101 102 103]),...
                'Expected condition marker')

            assert(eventCodes(k+2)==20,...
                'Expected END marker')

        end

        fprintf('Trial structure verified.\n');

        requiredMarkers = {
            marker_trial_start,...
            marker_cond_101,...
            marker_cond_102,...
            marker_cond_103,...
            marker_trial_end};

        missingMarkers = requiredMarkers( ...
            ~ismember(requiredMarkers,eventTypes));

        if ~isempty(missingMarkers)
            warning('Missing markers: %s', ...
                strjoin(missingMarkers,', '));
        end
        QC.nChannelsBeforeCleaning = EEG.nbchan;
        QC.nEventsBeforeCleaning   = numel(EEG.event);
        %% --------------------------------------------------------
        % 4C) DETECT EOG / EYE-BLINK CHANNEL IF PRESENT
        % --------------------------------------------------------
        eye_blink_labels = {'EYE_BLINK','VEOG','EOG','Blink','LHEOG','RHEOG'};

        if isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
            existing_labels = {EEG.chanlocs.labels};
            blink_channel = intersect(eye_blink_labels, existing_labels, 'stable');

            if ~isempty(blink_channel)
                idx_blink = find(strcmpi(existing_labels, blink_channel{1}), 1);
                EEG.etc.eye_blink_channel = blink_channel{1};
                EEG.etc.eye_blink_index   = idx_blink;
                fprintf('Eye-blink channel found: %s\n', blink_channel{1});
            else
                warning('No eye-blink channel found in %s.', names{n});
            end
        end

        %% --------------------------------------------------------
        % 4D) REMOVE NON-EEG CHANNELS
        % --------------------------------------------------------
        removable_channels = {'LHEOG','RHEOG','VEOGup','VEOGdown','HEOG','VEOG','audio','AUDIO','TRIG'};

        if isfield(EEG, 'chanlocs') && ~isempty(EEG.chanlocs)
            existing_labels = {EEG.chanlocs.labels};
            channels_to_remove = existing_labels(ismember(lower(existing_labels), lower(removable_channels)));

            if ~isempty(channels_to_remove)
                EEG = pop_select(EEG, 'rmchannel', channels_to_remove);
                EEG = eeg_checkset(EEG);
            end
        end

        %% --------------------------------------------------------
        % 4E) STANDARDIZE REFERENCE CHANNEL LABEL IF NEEDED
        % --------------------------------------------------------
        if ~isfield(EEG,'chanlocs') || isempty(EEG.chanlocs)
            warning('Missing channel locations.');
            continue
        end
        chan_labels = {EEG.chanlocs.labels};
        if any(strcmpi(chan_labels, 'RM'))
            idx_rm = find(strcmpi(chan_labels, 'RM'), 1);
            EEG.chanlocs(idx_rm).labels = 'M2';
        end

        %% --------------------------------------------------------
        % 4F) NOTCH FILTER FOR LINE NOISE
        % --------------------------------------------------------
        %% NOTCH ANALYSIS
        EEG_notch = pop_eegfiltnew(EEG, ...
            'locutoff', line_frequency-step_frequency, ...
            'hicutoff', line_frequency+step_frequency, ...
            'revfilt', 1, ...
            'plotfreqz', 0);

        if debugMode
            pop_spectopo(EEG,1,[0 EEG.xmax*1000], ...
                'EEG','freqrange',[1 100]);
            sgtitle('RAW - Spectrum before notch');
            EEG_notch = pop_eegfiltnew(EEG, ...
                'locutoff', line_frequency-step_frequency, 'hicutoff', line_frequency+step_frequency, ...
                'revfilt', 1, 'plotfreqz', 0);

            pop_spectopo(EEG_notch,1,[0 EEG_notch.xmax*1000], ...
                'EEG','freqrange',[1 100]);
            sgtitle('NOTCH - Spectrum after notch');
        end
        % noch application
        EEG = EEG_notch;

        % %% --------------------------------------------------------
        % % 4G) ANALYSIS FILTER (FINAL CONTINUOUS DATA BAND)
        % % --------------------------------------------------------
        % EEG = pop_eegfiltnew(EEG, ...
        %     'locutoff', analysis_lowcut, ...
        %     'hicutoff', analysis_highcut, ...
        %     'plotfreqz', 0);

        %% Topoplot pre Resample-Detrend-AvgRemov
        stdChanRaw = std(double(EEG.data),[],2);
        fprintf('\n=== DATA RANGE CHECK ===\n');

        fprintf('Min data : %g\n', min(EEG.data(:)));
        fprintf('Max data : %g\n', max(EEG.data(:)));

        [maxAbs, idx] = max(abs(EEG.data(:)));

        [ch, samp] = ind2sub(size(EEG.data), idx);

        fprintf('Max abs value : %g\n', maxAbs);
        fprintf('Channel       : %d (%s)\n', ...
            ch, ...
            EEG.chanlocs(ch).labels);

        fprintf('Sample        : %d\n', samp);
        [maxSTD,maxCh] = max(stdChanRaw);

        fprintf('\n=== MAX STD CHANNEL ===\n');
        fprintf('Index : %d\n',maxCh);
        fprintf('Label : %s\n',EEG.chanlocs(maxCh).labels);
        fprintf('STD   : %g\n',maxSTD);
        
        if debugMode

            figure
            topoplot(stdChanRaw,EEG.chanlocs);
            colorbar
            title('RAW STD Topoplot')

            figure

            subplot(1,2,1)
            plot(stdChanRaw,'o-')
            xlabel('Channel')
            ylabel('STD')
            title('RAW STD per channel')

            subplot(1,2,2)
            topoplot(stdChanRaw,EEG.chanlocs)
            colorbar
            title('RAW STD Topoplot')

        end
        %% --------------------------------------------------------
        % 4H) RESAMPLE - DOWNSAMPLING
        % --------------------------------------------------------
        nEventsBefore = numel(EEG.event);
        EEG = pop_resample(EEG, target_fs);
        eventTypes = unique({EEG.event.type});
        disp(eventTypes)
        QC.uniqueEventTypes = eventTypes;
        QC.nEventTypes = numel(eventTypes);
        assert(numel(EEG.event) == nEventsBefore, ...
            'Event count changed after resampling');
        EEG = eeg_checkset(EEG,'eventconsistency');
        fprintf('Resampled to %.1f Hz\n',EEG.srate);
        fprintf('Events after resample: %d\n',numel(EEG.event));
        %% --------------------------------------------------------
        % 4I) DETREND / CENTER
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
        EEG = eeg_checkset(EEG,'eventconsistency');
        EEG_preICA = EEG;
        %% Topoplot post Resample-Detrend-AvgRemov
        stdChanPreICA = std(double(EEG.data),[],2);
        if debugMode
            figure
            topoplot(stdChanPreICA,EEG.chanlocs);
            title('PRE ICA STD Topoplot')
            colorbar
            % Controllo quantitativo canali post
            figure
            subplot(1,2,1)
            plot(stdChanPreICA,'o-')
            title('PRE ICA STD per channel')
            xlabel('Channel')
            subplot(1,2,2)
            topoplot(stdChanPreICA,EEG.chanlocs);
            title('PRE ICA STD Topoplot')
            colorbar
        end
        % evaluate bad channels
        zSTD = zscore(stdChanPreICA);
        badSTD = find(abs(zSTD)>3);
        fprintf('Potential outlier channels:\n')
        disp({EEG.chanlocs(badSTD).labels})

        QC.subjectID = subjName;
        QC.nChannelsOriginal = QC.nChannelsBeforeCleaning;
        QC.chanLabelsOriginal = {EEG.chanlocs.labels};
        QC.nEventsOriginal = nEventsBefore;
        QC.stdChanRaw = stdChanRaw;
        QC.stdChanPreICA = stdChanPreICA;
        QC.zSTD = zSTD;
        QC.badSTD = badSTD;
        QC.badSTD_labels = {EEG.chanlocs(badSTD).labels};

        %% --------------------------------------------------------
        % 4K) CREATE ANALYSIS AND ICA DATASETS
        % --------------------------------------------------------

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
        % Rank check
        rankData = rank(double(EEG_ica.data'));

        fprintf('\n');
        fprintf('Data rank: %d\n',rankData);
        fprintf('Channels : %d\n',EEG_ica.nbchan);
        fprintf('\n');
        fprintf('Duration: %.2f min\n', ...
            EEG_ica.pnts/EEG_ica.srate/60);

        fprintf('Samples: %d\n',EEG_ica.pnts);
        % se trovo da 0-3 dataset pulito 4-8 accettabile 10-15 controlliamo
        % quali canali sono stati rimossi, >20% problema
        %% --------------------------------------------------------
        % 4L) REMOVE BAD CHANNELS BEFORE ICA
        % --------------------------------------------------------
        EEG_ica = pop_clean_rawdata(EEG_ica, ...
            'FlatlineCriterion', 5, ...
            'ChannelCriterion', 0.8, ...
            'LineNoiseCriterion', 4, ...
            'Highpass', 'off', ...
            'BurstCriterion', 'off', ...
            'WindowCriterion', 'off', ...
            'BurstRejection', 'off', ...
            'Distance', 'Euclidian'); %'Euclidean'

        EEG_ica = eeg_checkset(EEG_ica);

        if any(strcmpi({EEG_ica.chanlocs.labels},'EOG'))
            fprintf('EOG retained for ICA\n');
        else
            warning('EOG removed by clean_rawdata');
        end
        good_labels = {EEG_ica.chanlocs.labels};
        full_labels = {fullEEG.chanlocs.labels};
        fprintf('%d/%d channels retained for ICA\n',...
            numel(good_labels),...
            numel(full_labels));
        bad_mask    = ~ismember(full_labels, good_labels);
        bad_labels  = full_labels(bad_mask);

        if isempty(bad_labels)
            fprintf('No bad channels removed before ICA.\n');
        else
            fprintf('Bad channels removed before ICA: %s\n', strjoin(bad_labels, ', '));
        end

        % CHECK clean
        fprintf('Removed %.1f %% of channels\n', ...
            100*numel(bad_labels)/numel(full_labels));
        % Plot check
        stdICA = std(double(EEG_ica.data),[],2);

        figure
        subplot(1,2,1)
        plot(stdICA,'o-')
        title('POST clean_rawdata STD')
        xlabel('Channel')
        subplot(1,2,2)
        topoplot(stdICA,EEG_ica.chanlocs)
        title('POST clean_rawdata Topoplot')
        colorbar
        % info utili valutazione di quali canali ha rimosso e di dove si
        % trovano inoltre verifica del topoplot prima e dopo e della
        % distribuzione
        %% --------------------------------------------------------
        % 4N) RUN ICA ON GOOD CHANNELS ONLY
        % --------------------------------------------------------
        fprintf('\n');
        fprintf('Running ICA...\n');
        fprintf('Channels : %d\n',EEG_ica.nbchan);
        fprintf('Samples  : %d\n',EEG_ica.pnts);
        fprintf('Duration : %.1f min\n',...
            EEG_ica.pnts/EEG_ica.srate/60);
        rankAfterClean = rank(double(EEG_ica.data'));

        EEG_ica = pop_runica(EEG_ica, ...
            'icatype','runica', ...
            'extended',1, ...
            'pca',rankAfterClean, ...
            'interrupt','on');

        EEG_ica = eeg_checkset(EEG_ica);
        fprintf('\n=== POST ICA ===\n');
        fprintf('Channels : %d\n',EEG_ica.nbchan);
        fprintf('Samples  : %d\n',EEG_ica.pnts);

        disp(size(EEG_ica.data))

        rankAfterClean = rank(double(EEG_ica.data'));

        fprintf('Rank after clean_rawdata : %d\n', ...
            rankAfterClean);
        fprintf('\n');
        fprintf('ICA computed.\n');

        disp(size(EEG_ica.icaweights))
        disp(size(EEG_ica.icawinv))
        %% --------------------------------------------------------
        % 4O) ICLABEL
        % --------------------------------------------------------
        EEG_ica = pop_iclabel(EEG_ica, 'default');
        ICLabelResults = [];

        if isfield(EEG_ica,'etc') && ...
                isfield(EEG_ica.etc,'ic_classification')
            ICLabelResults = ...
                EEG_ica.etc.ic_classification.ICLabel.classifications;
        end

        %%CHECK
        if debugMode
            pop_selectcomps(EEG_ica,1:min(35,size(EEG_ica.icawinv,2)));
        end
        % Controllo quantitativo canali
        stdChanPostICA = std(double(EEG_ica.data),[],2);
        figure
        subplot(1,2,1)
        plot(stdChanPostICA,'o-')
        title('POST ICA STD')
        xlabel('Channel')
        subplot(1,2,2)
        topoplot(stdChanPostICA,EEG_ica.chanlocs)
        title('POST ICA Topoplot')
        colorbar
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
        badICsFinal = badICs;
        classes = ...
            EEG_ica.etc.ic_classification.ICLabel.classes;
        removedClasses = strings(numel(badICs),1);
        for k=1:numel(badICs)
            ic = badICs(k);
            [~,idx] = max(ICLabelResults(ic,:));
            removedClasses(k) = classes{idx};
        end
        QC.removedICClasses = removedClasses;
        [~,maxClass] = max( ...
            EEG_ica.etc.ic_classification.ICLabel.classifications,...
            [],2);
        disp(tabulate(maxClass))
        QC.ICLabelMaxClass = maxClass;
        QC.ICLabelTable = tabulate(maxClass);
        ICLabelResults = ...
            EEG_ica.etc.ic_classification.ICLabel.classifications;

        for k=1:numel(badICs)
            ic = badICs(k);
            [p,idx] = max(ICLabelResults(ic,:));
            fprintf('IC %d -> %s (%.1f%%)\n',...
                ic,...
                classes{idx},...
                100*p);
        end

        %% --------------------------------------------------------
        % 4P) TRANSFER ICA WEIGHTS TO MATCHED DATASET
        % --------------------------------------------------------
        originalEEG = pop_select(fullEEG, ...
            'channel', good_labels);

        assert(isequal({originalEEG.chanlocs.labels},...
            {EEG_ica.chanlocs.labels}),...
            'Channel order mismatch before ICA transfer');
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
        originalEEG = eeg_checkset(originalEEG, 'ica');

        %% --------------------------------------------------------
        % 4Q) REMOVE ARTIFACTUAL ICS
        % --------------------------------------------------------
        badICs = [];

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
        % 4R) INTERPOLATE REMOVED BAD CHANNELS BACK
        % --------------------------------------------------------
        cleanEEG = pop_interp(originalEEG, fullEEG.chanlocs, 'spherical');
        cleanEEG_withEOG = cleanEEG;
        if any(strcmpi({cleanEEG.chanlocs.labels},'EOG'))
            cleanEEG = pop_select( ...
                cleanEEG, ...
                'nochannel',{'EOG'});
            % cleanEEG_final = pop_select( ...
            %     cleanEEG,...
            %     'nochannel',{'EOG','M1','M2'});
            fprintf('EOG channel removed from final EEG dataset\n');
        end
        nRemoved = numel(bad_labels);

        if nRemoved > 0.3*numel(full_labels)
            warning('More than 30%% channels removed before ICA');
        end
        cleanEEG = eeg_checkset(cleanEEG);
        cleanEventCodes = ...
            cellfun(@str2double,{cleanEEG.event.type});

        firstStartClean = ...
            find(cleanEventCodes==10,1,'first');

        preStartEndSample = ...
            round(cleanEEG.event(firstStartClean).latency)-1;

        preStartData = ...
            cleanEEG.data(:,1:preStartEndSample);
        % check
        stdChanClean = std(double(cleanEEG.data),[],2);
        figure
        subplot(1,2,1)
        plot(stdChanClean,'o-')
        title('FINAL CLEAN EEG STD')
        xlabel('Channel')
        subplot(1,2,2)
        topoplot(stdChanClean,cleanEEG.chanlocs)
        title('FINAL CLEAN EEG Topoplot')
        colorbar
        fprintf('Events final: %d\n',numel(cleanEEG.event));
        assert(numel(cleanEEG.event)==nEventsBefore)

        eventsTable = table();

        eventsTable.type = ...
            string({cleanEEG.event.type})';

        eventsTable.latency = ...
            [cleanEEG.event.latency]';

        eventsTable.timeSec = ...
            ([cleanEEG.event.latency]'-1)/cleanEEG.srate;
        %% --------------------------------------------------------
        % 4S) STORE CLEANING METADATA
        % --------------------------------------------------------
        QC.nBadChannels = numel(bad_labels);
        QC.badChannels = bad_labels;
        QC.nBadICs = numel(badICsFinal);
        QC.badICs = badICsFinal;
        QC.percentBadChannels = 100*numel(bad_labels)/numel(full_labels);
        QC.stdChanClean = stdChanClean;
        QC.meanSTD_raw = mean(stdChanRaw);
        QC.meanSTD_preICA = mean(stdChanPreICA);
        QC.meanSTD_clean = mean(stdChanClean);
        QC.medianSTD_raw = median(stdChanRaw);
        QC.medianSTD_preICA = median(stdChanPreICA);
        QC.medianSTD_clean = median(stdChanClean);
        QC.rankBeforeICA = rankData;
        QC.rankApproxAfterClean = EEG_ica.nbchan;
        QC.stdTable = table(string({EEG.chanlocs.labels})',stdChanRaw,...
            'VariableNames',{'Channel','STD'});
        QC.finalChannels = cleanEEG.nbchan;
        QC.durationMin = cleanEEG.pnts/cleanEEG.srate/60;
        QC.finalFs = cleanEEG.srate;
        QC.goodChannelsForICA = good_labels;
        QC.nChannelsForICA = numel(good_labels);
        QC.nTrig10  = sum(eventCodes==10);

        QC.nTrig101 = sum(eventCodes==101);
        QC.nTrig102 = sum(eventCodes==102);
        QC.nTrig103 = sum(eventCodes==103);

        QC.nTrig20  = sum(eventCodes==20);

        QC.nTrials = sum(eventCodes==10);

        QC.preStartDurationSec = preStartDurationSec;
        QC.hasEOG = any(strcmpi({cleanEEG_withEOG.chanlocs.labels},'EOG'));
        QC.EOGindex = find(strcmpi({cleanEEG_withEOG.chanlocs.labels},'EOG'));

        cleanEEG.etc.bad_channels_removed_preICA = bad_labels;
        cleanEEG.etc.good_channels_for_ICA       = good_labels;
        cleanEEG.etc.subjectID                   = subjName;
        cleanEEG.etc.marker_trial_start = 10;

        cleanEEG.etc.marker_cond_101 = 101;
        cleanEEG.etc.marker_cond_102 = 102;
        cleanEEG.etc.marker_cond_103 = 103;

        cleanEEG.etc.marker_trial_end = 20;
        cleanEEG.etc.badICs = badICsFinal;
        cleanEEG.etc.nBadICs = numel(badICsFinal);
        cleanEEG.etc.ICLabel = ICLabelResults;
        cleanEEG.etc.nBadChannels = numel(bad_labels);
        % TRIAL INFO

        startEvents = find(cleanEventCodes==10);
        endEvents   = find(cleanEventCodes==20);

        trialInfo = struct();

        trialInfo.startEvents = find(cleanEventCodes==10);

        trialInfo.conditionEvents = ...
            find(ismember(cleanEventCodes,[101 102 103]));

        trialInfo.endEvents = ...
            find(cleanEventCodes==20);

        trialInfo.nTrials = ...
            length(trialInfo.startEvents);

        trialInfo.n101 = sum(cleanEventCodes==101);
        trialInfo.n102 = sum(cleanEventCodes==102);
        trialInfo.n103 = sum(cleanEventCodes==103);

        trialInfo.preStartDurationSec = ...
            preStartDurationSec;
        iti = ...
            [cleanEEG.event(startEvents(2:end)).latency]' - ...
            [cleanEEG.event(endEvents(1:end-1)).latency]';

        iti = iti ./ cleanEEG.srate;

        trialInfo.meanITI = mean(iti);
        trialInfo.minITI  = min(iti);
        trialInfo.maxITI  = max(iti);

        trialInfo.ITI = iti;
        %% --------------------------------------------------------
        % 4T) SUBJECT OUTPUT STRUCT
        % --------------------------------------------------------
        subjectData = struct();
        subjectData.subjectID = subjName;
        subjectData.cleanContinuous = cleanEEG;
        subjectData.cleanContinuous_withEOG = cleanEEG_withEOG;
        subjectData.chanlocs = cleanEEG.chanlocs;
        subjectData.chanlabels = {cleanEEG.chanlocs.labels};
        subjectData.badICs = badICsFinal;
        subjectData.nBadICs = numel(badICsFinal);
        subjectData.ICLabel = ICLabelResults;
        subjectData.badChannelsRemoved = bad_labels;
        subjectData.nBadChannels = numel(bad_labels);
        subjectData.goodChannelsForICA = good_labels;
        if isfield(cleanEEG, 'event') && ~isempty(cleanEEG.event)
            subjectData.events = cleanEEG.event;
        else
            subjectData.events = [];
        end
        subjectData.preprocessingInfo.analysisBand = ...
            [analysis_lowcut analysis_highcut];
        subjectData.preprocessingInfo.icaBand = ...
            [ica_lowcut ica_highcut];
        subjectData.preprocessingInfo.lineFrequency = ...
            line_frequency;
        subjectData.preprocessingInfo.targetFs = ...
            target_fs;
        subjectData.QC = QC;
        subjectData.eventsTable = eventsTable;

        subjectData.trialInfo = trialInfo;

        subjectData.preStartSegment.data = ...
            preStartData;

        subjectData.preStartSegment.durationSec = ...
            preStartDurationSec;

        subjectData.preStartSegment.endSample = ...
            preStartEndSample;

        subjectData.preStartSegment.description = ...
            'EEG segment before first trial-start marker (10). Not a controlled baseline.';
        subjectData.protocol.marker_start = 10;

        subjectData.protocol.marker_101 = 101;
        subjectData.protocol.marker_102 = 102;
        subjectData.protocol.marker_103 = 103;

        subjectData.protocol.marker_end = 20;

        subjectData.protocol.nTrials = 360;

        save(fullfile(output_dir, [subjName '_data_extracted.mat']), 'subjectData', '-v7.3');

    catch ME

        fprintf('\nERROR in %s\n', names{n});
        fprintf('%s\n', ME.message);

        continue

    end

end

