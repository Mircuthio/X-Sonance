% ========================================================================
% MAIN_EXTRACT_DATASET_CHANG_STEP2_EPOCHING
% ========================================================================
clear; clc; close all
debugMode = true;

%% =======================================================================
% PATHS
% ========================================================================
inputFolder = ...
    'D:\X-SONANCE\CHANG_EXPERIMENT\';

outputFolder = ...
    'D:\X-SONANCE\CHANG_EXPERIMENT\EPOCH_DATA';

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

%% =======================================================================
% MARKERS
% ========================================================================
marker_start = 10;
marker_end   = 20;

validTriggers = [101 102 103];

% Epoch window: -4 s / +2 s
preSec  = 4;
postSec = 2;

eventLabels = containers.Map( ...
    'KeyType','double', ...
    'ValueType','char');

eventLabels(101) = 'Condition101';
eventLabels(102) = 'Condition102';
eventLabels(103) = 'Condition103';

% >>> MODIFICA: griglia temporale unica obbligatoria
targetFs = 250;

preSamples  = preSec  * targetFs;   % 4 s * 250 Hz = 1000
postSamples = postSec * targetFs;   % 2 s * 250 Hz = 500
nSamples    = preSamples + postSamples;  % 1500

% Da -4.000 s a +1.996 s, 1500 punti.
timeVecFixed = (-preSamples:postSamples-1) / targetFs;

assert(numel(timeVecFixed) == nSamples, ...
    'Internal error: time vector is not 1500 points.');
% <<< FINE MODIFICA

%% =======================================================================
% LOAD SUBJECT FILES
% ========================================================================
files = dir(fullfile(inputFolder,'*_data_extracted.mat'));

if isempty(files)
    error('No extracted files found.');
end

%% =======================================================================
% SUBJECT LOOP
% ========================================================================
for s = 1:numel(files)

    subjFile = files(s).name;

    fprintf('\n=====================================\n');
    fprintf('SUBJECT: %s\n',subjFile);
    fprintf('=====================================\n');

    tmp = load(fullfile(inputFolder,subjFile));

    if ~isfield(tmp,'subjectData')
        warning('subjectData missing.');
        continue
    end

    subjectData = tmp.subjectData;

    EEG = subjectData.cleanContinuous;

    Fs = EEG.srate;

    % >>> MODIFICA: non continuare se il continuo NON e' veramente a 250 Hz
    assert(abs(Fs - targetFs) < 1e-6, ...
        ['Subject %s has EEG.srate = %.12f Hz, but %.0f Hz is required. ' ...
         'Resample the continuous data before epoch extraction.'], ...
        subjectData.subjectID, Fs, targetFs);

    fprintf('Sampling rate: %.12f Hz\n', Fs);
    fprintf('Fixed epoch: %d samples (%d pre + %d post)\n', ...
        nSamples, preSamples, postSamples);
    % <<< FINE MODIFICA

    %% ===================================================================
    % EVENTS
    % ====================================================================
    eventCodes = ...
        cellfun(@str2double,{EEG.event.type});

    eventLat = ...
        round([EEG.event.latency])';

    eventTimes = ...
        (eventLat-1) ./ Fs;

    fprintf('Events found : %d\n',numel(eventCodes));

    startIdx = find(eventCodes == marker_start);

    data_trials = struct([]);

    trialCounter = 0;

    %% ===================================================================
    % TRIAL EXTRACTION
    % ====================================================================
    for k = 1:numel(startIdx)

        sIdx = startIdx(k);

        if sIdx + 2 > numel(eventCodes)
            continue
        end

        codeStart  = eventCodes(sIdx);
        codeTarget = eventCodes(sIdx+1);
        codeEnd    = eventCodes(sIdx+2);

        if codeStart ~= marker_start
            continue
        end

        if ~ismember(codeTarget, validTriggers)
            continue
        end

        if codeEnd ~= marker_end
            continue
        end

        trialStartSample  = round(eventLat(sIdx));
        targetSample      = round(eventLat(sIdx+1));
        trialEndSample    = round(eventLat(sIdx+2));

        % Mantieni il controllo sul pattern 10-X-20
        if trialEndSample <= trialStartSample
            continue
        end

        % >>> MODIFICA: epoch con 1500 campioni fissi
        % 1000 campioni pre-target: -4.000 ... -0.004 s
        % 500 campioni dal target:   0.000 ... +1.996 s
        startSample = targetSample - preSamples;
        endSample   = targetSample + postSamples - 1;
        % <<< FINE MODIFICA

        % Evita trial che escono dal segnale
        if startSample < 1 || endSample > size(EEG.data,2)
            warning(['Skipped epoch in %s: target=%d, start=%d, ' ...
                     'end=%d, EEG length=%d.'], ...
                    subjectData.subjectID, ...
                    targetSample, ...
                    startSample, ...
                    endSample, ...
                    size(EEG.data,2));
            continue
        end

        eegEpoch = EEG.data(:, startSample:endSample);

        % >>> MODIFICA: verifica stretta di 1500 punti
        assert(size(eegEpoch,2) == nSamples, ...
            ['Unexpected epoch length in %s: got %d samples, ' ...
             'expected exactly %d.'], ...
            subjectData.subjectID, ...
            size(eegEpoch,2), ...
            nSamples);

        timeVec = timeVecFixed;
        % <<< FINE MODIFICA

        trialCounter = trialCounter + 1;

        %% ---------------------------------------------------------------
        % ORIGINAL FIELDS (KEEP)
        % ---------------------------------------------------------------
        data_trials(trialCounter).trialID = ...
            trialCounter;

        data_trials(trialCounter).subjectID = ...
            subjectData.subjectID;

        data_trials(trialCounter).eventCode = ...
            codeTarget;

        data_trials(trialCounter).eventLabel = ...
            eventLabels(codeTarget);

        data_trials(trialCounter).latencySample = ...
            targetSample;

        data_trials(trialCounter).latencySec = ...
            eventTimes(sIdx+1);

        data_trials(trialCounter).eeg = ...
            eegEpoch;

        data_trials(trialCounter).time = ...
            timeVec;

        % >>> MODIFICA: salva esplicitamente 250 Hz
        data_trials(trialCounter).srate = ...
            targetFs;
        % <<< FINE MODIFICA

        data_trials(trialCounter).chanlocs = ...
            EEG.chanlocs;

        if k > 1

            prevTarget = ...
                round(eventLat(startIdx(k-1)+1));

            data_trials(trialCounter).previousISI = ...
                (targetSample-prevTarget) / targetFs;

        else

            data_trials(trialCounter).previousISI = NaN;

        end

        if k < numel(startIdx)

            nextTarget = ...
                round(eventLat(startIdx(k+1)+1));

            data_trials(trialCounter).nextISI = ...
                (nextTarget-targetSample) / targetFs;

        else

            data_trials(trialCounter).nextISI = NaN;

        end

        %% ---------------------------------------------------------------
        % CHANG SPECIFIC FIELDS
        % ---------------------------------------------------------------
        data_trials(trialCounter).trialStartCode = ...
            codeStart;

        data_trials(trialCounter).trialEndCode = ...
            codeEnd;

        data_trials(trialCounter).conditionCode = ...
            codeTarget;

        data_trials(trialCounter).conditionLabel = ...
            eventLabels(codeTarget);

        data_trials(trialCounter).trialMarkerStartSample = ...
            trialStartSample;

        data_trials(trialCounter).targetSample = ...
            targetSample;

        data_trials(trialCounter).trialMarkerEndSample = ...
            trialEndSample;

        % >>> MODIFICA: denominatore coerente con la griglia comune
        data_trials(trialCounter).trialDurationSec = ...
            (trialEndSample-trialStartSample) / targetFs;
        % <<< FINE MODIFICA

        data_trials(trialCounter).epochStartSample = ...
            startSample;

        data_trials(trialCounter).epochEndSample = ...
            endSample;

        % >>> MODIFICA: denominatore coerente con la griglia comune
        data_trials(trialCounter).preTargetDurationSec = ...
            (targetSample-trialStartSample) / targetFs;

        data_trials(trialCounter).postTargetDurationSec = ...
            (trialEndSample-targetSample) / targetFs;
        % <<< FINE MODIFICA

        data_trials(trialCounter).eventSequence = ...
            [codeStart codeTarget codeEnd];

    end

    %% ===================================================================
    % OUTPUT STRUCT
    % ====================================================================
    subjectEpochData = struct();

    subjectEpochData.subjectID = ...
        subjectData.subjectID;

    subjectEpochData.nTrials = ...
        numel(data_trials);

    subjectEpochData.data_trials = ...
        data_trials;

    subjectEpochData.chanlocs = ...
        EEG.chanlocs;

    subjectEpochData.chanlabels = ...
        {EEG.chanlocs.labels};

    subjectEpochData.eventLabelMap = ...
        eventLabels;

    subjectEpochData.protocol.startMarker = ...
        marker_start;

    subjectEpochData.protocol.targetMarkers = ...
        validTriggers;

    subjectEpochData.protocol.endMarker = ...
        marker_end;

    % >>> MODIFICA: salva la definizione esplicita dell'epoch
    subjectEpochData.protocol.srate = targetFs;
    subjectEpochData.protocol.preSec = preSec;
    subjectEpochData.protocol.postSec = postSec;
    subjectEpochData.protocol.preSamples = preSamples;
    subjectEpochData.protocol.postSamples = postSamples;
    subjectEpochData.protocol.epochSamples = nSamples;
    % <<< FINE MODIFICA

    subjectEpochData.n101 = ...
        sum([data_trials.conditionCode] == 101);

    subjectEpochData.n102 = ...
        sum([data_trials.conditionCode] == 102);

    subjectEpochData.n103 = ...
        sum([data_trials.conditionCode] == 103);

    %% ===================================================================
    % QUICK CHECK
    % ====================================================================
    if debugMode && ~isempty(data_trials)

        figure

        plot( ...
            data_trials(1).time, ...
            mean(data_trials(1).eeg,1));

        xline(0,'r');

        title(sprintf('Trial 1 - Mean EEG - %s', ...
            subjectData.subjectID));

        xlabel('Time (s)');

        ylabel('Amplitude');

    end

    assert(numel(data_trials) <= sum(eventCodes == marker_start));

    fprintf('START markers : %d\n', sum(eventCodes == marker_start));
    fprintf('Extracted     : %d\n', numel(data_trials));

    %% ===================================================================
    % SAVE
    % ====================================================================
    epochLengths = ...
        arrayfun(@(x) size(x.eeg,2), data_trials);

    timeLengths = ...
        arrayfun(@(x) numel(x.time), data_trials);

    fprintf('Epoch lengths: ');
    disp(unique(epochLengths));

    fprintf('Time lengths : ');
    disp(unique(timeLengths));

    % >>> MODIFICA: verifica obbligatoria, non dipendente da Fs
    assert(all(epochLengths == nSamples), ...
        'Not all EEG epochs have exactly 1500 samples.');

    assert(all(timeLengths == nSamples), ...
        'Not all time vectors have exactly 1500 samples.');

    assert(all([data_trials.srate] == targetFs), ...
        'Not all trials are labelled as 250 Hz.');
    % <<< FINE MODIFICA

    save( ...
        fullfile( ...
            outputFolder, ...
            sprintf('%s_epochData.mat', subjectData.subjectID)), ...
        'subjectEpochData', ...
        '-v7.3');

    fprintf('Trials generated : %d\n', ...
        numel(data_trials));

    fprintf('Expected trials  : %d\n', ...
        sum(eventCodes == marker_start));

end