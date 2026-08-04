function subj_list_spn = build_spn_subject_list( ...
    inputFolder,...
    cfgSPN)

%% ============================================================
% SETTINGS
%% ============================================================

validTriggers = cfgSPN.validTriggers;

preStim  = cfgSPN.preStim;
postStim = cfgSPN.postStim;

%% ============================================================
% EVENT LABELS
%% ============================================================

eventLabels = containers.Map( ...
    'KeyType','double',...
    'ValueType','char');

eventLabels(1) = 'ConsonantGOAL';
eventLabels(2) = 'DissonantGOAL';
eventLabels(3) = 'ControlGOAL';
eventLabels(4) = 'ConsonantNoGOAL';
eventLabels(5) = 'DissonantNoGOAL';
eventLabels(6) = 'ControlNoGOAL';
eventLabels(7) = 'Consonant';
eventLabels(8) = 'Dissonant';

%% ============================================================
% SUBJECTS
%% ============================================================

subjectDirs = dir(fullfile(inputFolder,'Subj*'));
subjectDirs = subjectDirs([subjectDirs.isdir]);

subj_list_spn = struct([]);

subjCounter = 0;

%% ============================================================
% LOOP SUBJECTS
%% ============================================================

for s = 1:numel(subjectDirs)

    subjName = subjectDirs(s).name;

    fprintf('\n');
    fprintf('========================================\n');
    fprintf('SPN SUBJECT: %s\n',subjName);
    fprintf('========================================\n');

    subjFolder = ...
        fullfile(inputFolder,subjName);

    dataFile = dir( ...
        fullfile(subjFolder,...
        '*trialALL_data_extracted.mat'));

    if isempty(dataFile)

        dataFile = dir( ...
            fullfile(subjFolder,...
            '*data_extracted.mat'));

    end

    if isempty(dataFile)

        warning('No extracted file found for %s', ...
            subjName);

        continue

    end

    %% ========================================================
    % LOAD
    %% ========================================================

    S = load( ...
        fullfile( ...
        subjFolder,...
        dataFile(1).name));

    subjectData = S.subjectData;

    EEG = subjectData.cleanContinuous;

    eventsTable = ...
        subjectData.eventsTable;

    Fs = EEG.srate;

    eventCodes = ...
        eventsTable.trigger;

    eventTimes = ...
        eventsTable.timeSec;

    eventLat = ...
        round([EEG.event.latency])';

    %% ========================================================
    % KEEP VALID TRIGGERS
    %% ========================================================

    keep = ...
        ismember( ...
        eventCodes,...
        validTriggers);

    eventCodes = ...
        eventCodes(keep);

    eventTimes = ...
        eventTimes(keep);

    eventLat = ...
        eventLat(keep);

    %% ========================================================
    % EPOCH SETTINGS
    %% ========================================================

    expectedSamples = ...
        round((preStim+postStim)*Fs)+1;

    data_trials = struct([]);

    trialCounter = 0;

    %% ========================================================
    % LOOP EVENTS
    %% ========================================================

    for k = 1:numel(eventCodes)

        latency = ...
            round(eventLat(k));

        startSample = ...
            round(latency - preStim*Fs);

        endSample = ...
            round(latency + postStim*Fs);

        %% Boundary check

        if startSample < 1
            continue
        end

        if endSample > EEG.pnts
            continue
        end

        eegEpoch = ...
            EEG.data(:,...
            startSample:endSample);

        if size(eegEpoch,2) ~= expectedSamples
            continue
        end

        %% ====================================================
        % TIME VECTOR
        %% ====================================================

        timeVec = ...
            (-preStim : 1/Fs : postStim);

        %% ====================================================
        % BASELINE CORRECTION
        %% ====================================================

        idxBL = ...
            timeVec >= cfgSPN.baseline(1) & ...
            timeVec <= cfgSPN.baseline(2);

        baseline = ...
            mean(eegEpoch(:,idxBL),2);

        eegEpoch = ...
            eegEpoch - baseline;

        %% ====================================================
        % STORE TRIAL
        %% ====================================================

        trialCounter = ...
            trialCounter + 1;

        code = ...
            eventCodes(k);

        data_trials(trialCounter).trialID = ...
            trialCounter;

        data_trials(trialCounter).subjectID = ...
            subjName;

        data_trials(trialCounter).eventCode = ...
            code;

        data_trials(trialCounter).eventLabel = ...
            eventLabels(code);

        data_trials(trialCounter).latencySample = ...
            latency;

        data_trials(trialCounter).latencySec = ...
            eventTimes(k);

        data_trials(trialCounter).eeg = ...
            eegEpoch;

        data_trials(trialCounter).time = ...
            timeVec;

        data_trials(trialCounter).srate = ...
            Fs;

        data_trials(trialCounter).chanlocs = ...
            EEG.chanlocs;

        if k > 1

            data_trials(trialCounter).previousISI = ...
                eventTimes(k) - ...
                eventTimes(k-1);

        else

            data_trials(trialCounter).previousISI = ...
                NaN;

        end

        if k < numel(eventCodes)

            data_trials(trialCounter).nextISI = ...
                eventTimes(k+1) - ...
                eventTimes(k);

        else

            data_trials(trialCounter).nextISI = ...
                NaN;

        end

    end

    %% ========================================================
    % SUBJECT STRUCT
    %% ========================================================

    subjCounter = ...
        subjCounter + 1;

    subj_list_spn(subjCounter).subj_id = ...
        subjName;

    subj_list_spn(subjCounter).data_trials = ...
        data_trials;

    fprintf('SPN Trials: %d\n', ...
        numel(data_trials));

end

%% ============================================================
% FINAL CHECK
%% ============================================================

fprintf('\n');
fprintf('========================================\n');
fprintf('SPN SUBJECTS GENERATED: %d\n', ...
    numel(subj_list_spn));
fprintf('========================================\n');