% ========================================================================
% MAIN_EXTRACT_DATASET_MARCO_STEP2
% ========================================================================

clear; clc; close all

inputFolder = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EXTRACTED_DATA';

outputFolder = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA';

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

preStim  = 0.5;
postStim = 1.5;

validTriggers = 1:8;

% ---EVENT LABELS
eventLabels = containers.Map('KeyType','double',...
    'ValueType','char');

eventLabels(1) = 'ConsonantGOAL';
eventLabels(2) = 'DissonantGOAL';
eventLabels(3) = 'ControlGOAL';
eventLabels(4) = 'ConsonantNoGOAL';
eventLabels(5) = 'DissonantNoGOAL';
eventLabels(6) = 'ControlNoGOAL';
eventLabels(7) = 'Consonant';
eventLabels(8) = 'Dissonant';
% ----
subjectDirs = dir(fullfile(inputFolder,'Subj*'));
subjectDirs = subjectDirs([subjectDirs.isdir]);

for s = 1:numel(subjectDirs)

    subjName = subjectDirs(s).name;

    subjFolder = fullfile(inputFolder,subjName);

    dataFile = dir(fullfile(subjFolder,...
        '*trialALL_data_extracted.mat'));

    if isempty(dataFile)

        dataFile = dir(fullfile(subjFolder,...
            '*data_extracted.mat'));

    end

    if isempty(dataFile)

        fprintf('\nNo extracted file for %s\n',subjName);
        continue

    end

    fprintf('\n=====================================\n');
    fprintf('SUBJECT: %s\n',subjName);
    fprintf('=====================================\n');

    tmp = load(fullfile(subjFolder,dataFile(1).name));

    subjectData = tmp.subjectData;

    EEG = subjectData.cleanContinuous;

    eventsTable = subjectData.eventsTable;

    Fs = EEG.srate;

    eventCodes = eventsTable.trigger;
    eventTimes = eventsTable.timeSec;
    eventLat = round([EEG.event.latency])';
    % Use EEGLAB event latencies because current extracted files
    % were generated before latency correction was stored back into
    % eventsTable. Future datasets may directly use:
    %
    % eventLat = eventsTable.latency;
    %
    % eventLat   = eventsTable.latency; %next impl
    fprintf('Max event latency : %d\n',max(eventLat));
    fprintf('EEG length        : %d\n',EEG.pnts);

    assert(max(eventLat) < EEG.pnts,...
        'Event latencies exceed EEG length');
    keep = ismember(eventCodes,validTriggers);
    fprintf('Total events      : %d\n',numel(eventCodes));
    fprintf('Valid events 1-8  : %d\n',sum(keep));
    eventCodes = eventCodes(keep);
    eventTimes = eventTimes(keep);
    eventLat   = eventLat(keep);

    nValidEvents = numel(eventCodes);
    expectedSamples = ...
        round((preStim+postStim)*Fs)+1;

    data_trials = struct([]);

    trialCounter = 0;

    for k = 1:numel(eventCodes)

        latency = round(eventLat(k));

        startSample = ...
            round(latency - preStim*Fs);

        endSample = ...
            round(latency + postStim*Fs);

        assert(startSample >= 1,...
            'Epoch starts before recording');

        assert(endSample <= EEG.pnts,...
            'Epoch ends after recording');

        eegEpoch = EEG.data(:,startSample:endSample);

        assert(size(eegEpoch,2)==expectedSamples,...
            'Unexpected epoch length');

        trialCounter = trialCounter + 1;

        timeVec = ...
            (-preStim : 1/Fs : postStim);

        code = eventCodes(k);

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
                eventTimes(k)-eventTimes(k-1);
        else
            data_trials(trialCounter).previousISI = NaN;
        end

        if k < numel(eventCodes)
            data_trials(trialCounter).nextISI = ...
                eventTimes(k+1)-eventTimes(k);
        else
            data_trials(trialCounter).nextISI = NaN;
        end

    end

    subjectEpochData = struct();

    subjectEpochData.subjectID = subjName;

    subjectEpochData.preStim = preStim;
    subjectEpochData.postStim = postStim;

    subjectEpochData.nTrials = ...
        numel(data_trials);

    subjectEpochData.data_trials = ...
        data_trials;

    subjectEpochData.chanlocs = ...
        EEG.chanlocs;

    subjectEpochData.eventLabelMap = eventLabels;

    figure
    plot(data_trials(1).time,...
        mean(data_trials(1).eeg,1))
    xline(0,'r')

    save( ...
        fullfile(outputFolder,...
        sprintf('%s_epochData.mat',subjName)),...
        'subjectEpochData',...
        '-v7.3');

    fprintf('Trials generated : %d\n', ...
        numel(data_trials));

    assert(numel(data_trials)==nValidEvents,...
        'Mismatch between valid events and generated trials');
    fprintf('Valid events     : %d\n',nValidEvents);
    fprintf('Generated trials : %d\n',numel(data_trials));
end