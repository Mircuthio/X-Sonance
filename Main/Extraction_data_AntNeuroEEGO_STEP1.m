% Extraction_data_AntNeuroEEGO_STEP1.m
% FINAL VERSION - SUBJECT-LEVEL CONTINUOUS PREPROCESSING
% Raw
% ↓
% Notch
% ↓
% 1-90 Hz
% ↓
% Resample
% ↓
% Detrend
% ↓
% Reref
% ↓
% ICA dataset
% ↓
% 1-45 Hz+
% ↓
% ICA
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

%% ============================================================
% 1) PATHS AND DEPENDENCIES
% ============================================================
raw_dir    = 'E:\AntNeuro_Project\Data_raw\';
output_dir = 'E:\AntNeuro_Project\ERP_analysis\Extracted\';

addpath(genpath('D:\eeglab2023.1\'))

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% ============================================================
% 2) EXPERIMENTAL PARAMETERS
% ============================================================
% Replace these placeholders with your real trigger labels
marker_baseline_open   = 'BASELINE_EO';
marker_baseline_closed = 'BASELINE_EC';
marker_trial_start     = 'TRIAL_START';
marker_sound_con       = 'SOUND_CON';
marker_sound_dis       = 'SOUND_DIS';
marker_trial_end       = 'TRIAL_END';

% Baseline segment duration after baseline marker
baselineWindowSec = [0 2];

% Filtering
analysis_lowcut  = 1;
analysis_highcut = 90;
line_frequency = 50;

ica_lowcut  = 1;
ica_highcut = 45;

% Downsampling
target_fs = 250;

%% ============================================================
% 3) FILE SEARCH
% ============================================================
files_cnt = dir(fullfile(raw_dir, '*.cnt'));
files_set = dir(fullfile(raw_dir, '*.set'));
files_mat = dir(fullfile(raw_dir, '*.mat'));

allFiles = [files_cnt; files_set; files_mat];

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
for n = 1:numel(names)

    try

        [~, base_filename, ext] = fileparts(names{n});
        subjName = base_filename;

        fprintf('\n============================================================\n');
        fprintf('Processing subject %d/%d: %s\n', n, numel(names), names{n});
        fprintf('============================================================\n');

        %% --------------------------------------------------------
        % 4A) LOAD RAW DATA
        % --------------------------------------------------------
        switch lower(ext)
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

        %% --------------------------------------------------------
        % 4B) EVENT CHECK
        % --------------------------------------------------------
        if ~isfield(EEG,'event') || isempty(EEG.event)

            warning('No events found in %s. Skipped.', names{n});
            continue

        end
        eventTypes = {EEG.event.type};

        requiredMarkers = { ...
            marker_trial_start,...
            marker_trial_end,...
            marker_sound_con,...
            marker_sound_dis};

        missingMarkers = requiredMarkers( ...
            ~ismember(requiredMarkers,eventTypes));

        if ~isempty(missingMarkers)
            warning('Missing markers: %s', ...
                strjoin(missingMarkers,', '));
        end
        if ~isfield(EEG, 'event') || isempty(EEG.event)
            warning('No events found in %s. Skipped.', names{n});
            continue
        end

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

        EEG = pop_eegfiltnew(EEG, ...
            'locutoff', line_frequency-5, 'hicutoff', line_frequency+5, ...
            'revfilt', 1, 'plotfreqz', 0);

        %% --------------------------------------------------------
        % 4G) ANALYSIS FILTER (FINAL CONTINUOUS DATA BAND)
        % --------------------------------------------------------
        EEG = pop_eegfiltnew(EEG, ...
            'locutoff', analysis_lowcut, ...
            'hicutoff', analysis_highcut, ...
            'plotfreqz', 0);

        %% --------------------------------------------------------
        % 4H) RESAMPLE - DOWNSAMPLING
        % --------------------------------------------------------
        EEG = pop_resample(EEG, target_fs);

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
        EEG = eeg_checkset(EEG);

        %% --------------------------------------------------------
        % 4K) SAVE FULL EEG BEFORE BAD-CHANNEL REMOVAL
        % --------------------------------------------------------
        fullEEG = EEG;

        %% --------------------------------------------------------
        % 4L) REMOVE BAD CHANNELS BEFORE ICA
        % --------------------------------------------------------
        EEG_ica = EEG;

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

        %% --------------------------------------------------------
        % 4M) ICA-SUPPORT FILTER
        % --------------------------------------------------------
        EEG_ica = pop_eegfiltnew(EEG_ica, ...
            'locutoff', ica_lowcut, ...
            'hicutoff', ica_highcut, ...
            'plotfreqz', 0);

        %% --------------------------------------------------------
        % 4N) RUN ICA ON GOOD CHANNELS ONLY
        % --------------------------------------------------------
        EEG_ica = pop_runica(EEG_ica, ...
            'icatype', 'runica', ...
            'extended', 1, ...
            'interrupt', 'on');

        %% --------------------------------------------------------
        % 4O) LABEL / FLAG ARTIFACTUAL ICS
        % --------------------------------------------------------
        EEG_ica = pop_iclabel(EEG_ica, 'default');
        ICLabelResults = [];

        if isfield(EEG_ica,'etc') && ...
                isfield(EEG_ica.etc,'ic_classification')

            ICLabelResults = EEG_ica.etc.ic_classification;

        end
        EEG_ica = pop_icflag(EEG_ica,...
            [NaN NaN;   % Brain
            0.8 1;     % Muscle
            0.8 1;     % Eye
            NaN NaN;     % Heart
            0.8 1;     % Line Noise
            0.8 1;     % Channel Noise
            NaN NaN]); % Other
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
        nRemoved = numel(bad_labels);

        if nRemoved > 0.3*numel(full_labels)
            warning('More than 30%% channels removed before ICA');
        end
        cleanEEG = eeg_checkset(cleanEEG);

        %% --------------------------------------------------------
        % 4S) STORE CLEANING METADATA
        % --------------------------------------------------------
        cleanEEG.etc.bad_channels_removed_preICA = bad_labels;
        cleanEEG.etc.good_channels_for_ICA       = good_labels;
        cleanEEG.etc.subjectID                   = subjName;
        cleanEEG.etc.marker_sound_con            = marker_sound_con;
        cleanEEG.etc.marker_sound_dis            = marker_sound_dis;
        cleanEEG.etc.marker_trial_start          = marker_trial_start;
        cleanEEG.etc.marker_trial_end            = marker_trial_end;
        cleanEEG.etc.badICs = badICs;
        cleanEEG.etc.nBadICs = numel(badICs);
        cleanEEG.etc.ICLabel = ICLabelResults;
        cleanEEG.etc.nBadChannels = numel(bad_labels);

        %% --------------------------------------------------------
        % 4T) SUBJECT OUTPUT STRUCT
        % --------------------------------------------------------
        subjectData = struct();
        subjectData.subjectID = subjName;
        subjectData.cleanContinuous = cleanEEG;
        subjectData.chanlocs = cleanEEG.chanlocs;
        subjectData.chanlabels = {cleanEEG.chanlocs.labels};
        subjectData.badICs = badICs;
        subjectData.nBadICs = numel(badICs);
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
        save(fullfile(output_dir, [subjName '_data_extracted.mat']), 'subjectData', '-v7.3');

    catch ME

        fprintf('\nERROR in %s\n', names{n});
        fprintf('%s\n', ME.message);

        continue

    end

end

