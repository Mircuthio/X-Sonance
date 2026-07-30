% Extraction_data_AntNeuroEEGO_STEP2.m
% STEP 2 - RESTING BASELINE REMOVAL + SUBJECT-WISE EPOCHING FROM EXTRACTED FILE
%
% PIPELINE LOGIC
% - load one subject at a time from *_data_extracted.mat
% - load external event file from PsychoPy / Excel-derived MAT / CSV
% - align event markers to the extracted continuous EEG
% - extract resting-state baseline segment
% - subtract resting-state baseline from the whole continuous data
% - extract trial epochs subject by subject
% - store trial epochs and internal zero-point markers
%
% NOTE
% - This step assumes the continuous EEG was already cleaned in Step 1
% - No ICA, no rereferencing, no filtering here
% - ERP-specific baseline correction will be done later, after epoching

clear; close all; clc

%% ============================================================
% 1) PATHS AND DEPENDENCIES
% ============================================================
input_dir  = 'E:\AntNeuro_Project\ERP_analysis\Extracted\';
event_dir  = 'E:\AntNeuro_Project\ERP_analysis\Events\';
output_dir = 'E:\AntNeuro_Project\ERP_analysis\Epochs\';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% ============================================================
% 2) GENERIC MARKERS PLACEHOLDERS
% ============================================================
marker_baseline_rest_start = 'BASELINE_REST_START';
marker_baseline_rest_end   = 'BASELINE_REST_END';
marker_trial_start         = 'TRIAL_START';
marker_trial_end           = 'TRIAL_END';
marker_zero_point          = 'ZERO_POINT';
marker_sound_con           = 'SOUND_CON';
marker_sound_dis           = 'SOUND_DIS';

%% ============================================================
% 3) LOAD SUBJECT FILES
% ============================================================
files = dir(fullfile(input_dir, '*_data_extracted.mat'));
if isempty(files)
    error('No *_data_extracted.mat files found in input_dir.');
end

%% ============================================================
% 4) SUBJECT LOOP
% ============================================================
for n = 1:numel(files)
    subj_file = files(n).name;
    [~, subjName, ~] = fileparts(subj_file);

    fprintf('\n============================================================\n');
    fprintf('Processing subject %d/%d: %s\n', n, numel(files), subj_file);
    fprintf('============================================================\n');

    %% --------------------------------------------------------
    % 4A) LOAD EXTRACTED EEG FILE
    % --------------------------------------------------------
    S = load(fullfile(input_dir, subj_file));
    if ~isfield(S, 'subjectData')
        warning('No subjectData found in %s. Skipped.', subj_file);
        continue
    end

    subjectData = S.subjectData;
    cleanEEG = subjectData.cleanContinuous;

    if ~isfield(subjectData, 'chanlocs') || isempty(subjectData.chanlocs)
        warning('No chanlocs found in %s. Skipped.', subj_file);
        continue
    end
    if ~isfield(cleanEEG, 'data') || isempty(cleanEEG.data)
        warning('No EEG data found in %s. Skipped.', subj_file);
        continue
    end

    %% --------------------------------------------------------
    % 4B) LOAD EXTERNAL EVENT FILE
    % --------------------------------------------------------
    event_file_mat = fullfile(event_dir, [subjName '_events.mat']);
    event_file_csv = fullfile(event_dir, [subjName '_events.csv']);

    eventsTable = [];
    if exist(event_file_mat, 'file')
        E = load(event_file_mat);
        if isfield(E, 'eventsTable')
            eventsTable = E.eventsTable;
        elseif isfield(E, 'events')
            eventsTable = E.events;
        end
    elseif exist(event_file_csv, 'file')
        eventsTable = readtable(event_file_csv);
    else
        warning('No event file found for %s. Skipped.', subjName);
        continue
    end

    if isempty(eventsTable)
        warning('Empty event table for %s. Skipped.', subjName);
        continue
    end

    %% --------------------------------------------------------
    % 4C) ALIGN EVENTS TO EEG EVENTS
    % --------------------------------------------------------
    if istable(eventsTable)
        eventTypes = string(eventsTable.type);
        eventLat   = double(eventsTable.latency);
        if ismember('duration', string(eventsTable.Properties.VariableNames))
            eventDur = double(eventsTable.duration);
        else
            eventDur = nan(height(eventsTable), 1);
        end
    else
        eventTypes = string({eventsTable.type});
        eventLat   = double([eventsTable.latency])';
        if isfield(eventsTable, 'duration')
            eventDur = double([eventsTable.duration])';
        else
            eventDur = nan(numel(eventsTable), 1);
        end
    end

    %% --------------------------------------------------------
    % 4D) EXTRACT RESTING-STATE BASELINE AND SUBTRACT IT
    % --------------------------------------------------------
    baselineStarts = find(eventTypes == string(marker_baseline_rest_start));
    baselineEnds   = find(eventTypes == string(marker_baseline_rest_end));

    if isempty(baselineStarts) || isempty(baselineEnds)
        warning('No resting baseline markers found for %s. Skipped.', subjName);
        continue
    end

    sIdx = baselineStarts(1);
    sLat = round(eventLat(sIdx));

    eCandidates = baselineEnds(baselineEnds > sIdx);
    if isempty(eCandidates)
        warning('No valid resting baseline end found for %s. Skipped.', subjName);
        continue
    end

    eIdx = eCandidates(1);
    eLat = round(eventLat(eIdx));

    if eLat <= sLat
        warning('Invalid resting baseline interval for %s. Skipped.', subjName);
        continue
    end

    sampleIdx = sLat:eLat;

    restingBaselineSegment = struct();
    restingBaselineSegment.baselineId = 1;
    restingBaselineSegment.label = 'resting_state';
    restingBaselineSegment.startEventIndex = sIdx;
    restingBaselineSegment.endEventIndex = eIdx;
    restingBaselineSegment.startSample = sLat;
    restingBaselineSegment.endSample = eLat;
    restingBaselineSegment.time = (sampleIdx - sLat) / cleanEEG.srate;
    restingBaselineSegment.eeg = cleanEEG.data(:, sampleIdx);
    restingBaselineSegment.chanlocs = cleanEEG.chanlocs;
    restingBaselineSegment.srate = cleanEEG.srate;

    baselineChannelMean = mean(restingBaselineSegment.eeg, 2, 'omitnan');

    cleanEEG_baselineCorrected = cleanEEG;
    cleanEEG_baselineCorrected.data = double(cleanEEG.data) - baselineChannelMean;

    %% --------------------------------------------------------
    % 4E) EXTRACT TRIALS WITH RAW TIME AND ZERO-ALIGNED TIME
    % --------------------------------------------------------
    trialStarts = find(eventTypes == string(marker_trial_start));
    trialEnds   = find(eventTypes == string(marker_trial_end));
    zeroPoints  = find(eventTypes == string(marker_zero_point));

    data_trials = struct([]);
    trialCount = 0;

    for i = 1:numel(trialStarts)
        sIdx = trialStarts(i);
        sLat = round(eventLat(sIdx));

        eCandidates = trialEnds(trialEnds > sIdx);
        if isempty(eCandidates)
            continue
        end
        eIdx = eCandidates(1);
        eLat = round(eventLat(eIdx));

        if eLat <= sLat
            continue
        end

        zCandidates = zeroPoints(zeroPoints > sIdx & zeroPoints < eLat);
        if isempty(zCandidates)
            continue
        end
        zIdx = zCandidates(1);
        zLat = round(eventLat(zIdx));

        trialCount = trialCount + 1;
        sampleIdx = sLat:eLat;

        timeRawVec = (sampleIdx - 1) / cleanEEG.srate;
        timeVec = (sampleIdx - zLat) / cleanEEG.srate;

        inTrial = find(eventLat >= sLat & eventLat <= eLat);
        trialEvents = struct([]);

        for k = 1:numel(inTrial)
            evIdx = inTrial(k);
            trialEvents(k).type = char(eventTypes(evIdx));
            trialEvents(k).latency_samples = round(eventLat(evIdx) - sLat + 1);
            trialEvents(k).latency_sec_raw = (eventLat(evIdx) - sLat) / cleanEEG.srate;
            trialEvents(k).latency_sec_zero = (eventLat(evIdx) - zLat) / cleanEEG.srate;
            trialEvents(k).isZeroPoint = strcmpi(eventTypes(evIdx), marker_zero_point);
            trialEvents(k).isCon = strcmpi(eventTypes(evIdx), marker_sound_con);
            trialEvents(k).isDis = strcmpi(eventTypes(evIdx), marker_sound_dis);
            if ~isnan(eventDur(evIdx))
                trialEvents(k).duration = eventDur(evIdx);
            end
        end

        data_trials(trialCount).trialId = trialCount;
        data_trials(trialCount).subjectID = subjName;
        data_trials(trialCount).eeg = cleanEEG_baselineCorrected.data(:, sampleIdx);
        data_trials(trialCount).time_raw = timeRawVec;
        data_trials(trialCount).time = timeVec;
        data_trials(trialCount).events = trialEvents;
        data_trials(trialCount).trialStartSample = sLat;
        data_trials(trialCount).trialEndSample = eLat;
        data_trials(trialCount).zeroPointSample = zLat;
        data_trials(trialCount).zeroPointTimeRaw = (zLat - 1) / cleanEEG.srate;
        data_trials(trialCount).srate = cleanEEG.srate;
        data_trials(trialCount).chanlocs = cleanEEG.chanlocs;
        data_trials(trialCount).trialType = 0;
        data_trials(trialCount).trialName = 'unlabeled';

        hasCon = any(strcmp(eventTypes(inTrial), string(marker_sound_con)));
        hasDis = any(strcmp(eventTypes(inTrial), string(marker_sound_dis)));

        if hasCon && ~hasDis
            data_trials(trialCount).trialType = 1;
            data_trials(trialCount).trialName = 'consonant';
        elseif hasDis && ~hasCon
            data_trials(trialCount).trialType = 2;
            data_trials(trialCount).trialName = 'dissonant';
        elseif hasCon && hasDis
            data_trials(trialCount).trialType = 99;
            data_trials(trialCount).trialName = 'mixed_or_ambiguous';
        end
    end

    %% --------------------------------------------------------
    % 4F) SAVE OUTPUT
    % --------------------------------------------------------
    subjectEpochData = struct();
    subjectEpochData.subjectID = subjName;
    subjectEpochData.restingBaselineSegment = restingBaselineSegment;
    subjectEpochData.baselineChannelMean = baselineChannelMean;
    subjectEpochData.cleanContinuousBaselineCorrected = cleanEEG_baselineCorrected;
    subjectEpochData.data_trials = data_trials;
    subjectEpochData.chanlocs = cleanEEG.chanlocs;
    subjectEpochData.chanlabels = {cleanEEG.chanlocs.labels};

    save(fullfile(output_dir, [subjName '_epochData.mat']), 'subjectEpochData', '-v7.3');
    fprintf('Saved epoch output: %s\n', fullfile(output_dir, [subjName '_epochData.mat']));
end