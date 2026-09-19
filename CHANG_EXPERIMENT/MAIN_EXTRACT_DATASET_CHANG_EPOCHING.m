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

% Epoch window: -4s +2s
preSec  = 4;
postSec = 2;

eventLabels = containers.Map( ...
    'KeyType','double', ...
    'ValueType','char');

eventLabels(101) = 'Condition101';
eventLabels(102) = 'Condition102';
eventLabels(103) = 'Condition103';

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

    %% ===================================================================
    % EVENTS
    % ====================================================================

    eventCodes = ...
        cellfun(@str2double,{EEG.event.type});

    eventLat = ...
        round([EEG.event.latency])';

    eventTimes = ...
        (eventLat-1)./Fs;

    fprintf('Events found : %d\n',numel(eventCodes));

    startIdx = find(eventCodes==marker_start);

    data_trials = struct([]);

    trialCounter = 0;

    %% ===================================================================
    % TRIAL EXTRACTION
    % ====================================================================

    for k = 1:numel(startIdx)

        sIdx = startIdx(k);

        if sIdx+2 > numel(eventCodes)
            continue
        end

        codeStart  = eventCodes(sIdx);
        codeTarget = eventCodes(sIdx+1);
        codeEnd    = eventCodes(sIdx+2);


        if codeStart ~= marker_start
            continue
        end

        if ~ismember(codeTarget,validTriggers)
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

        % Epoch fissa: -4s / +2s rispetto al target
        startSample = targetSample - round(preSec*Fs);
        endSample   = targetSample + round(postSec*Fs) - 1;

        % Evita trial che escono dal segnale
        if startSample < 1 || endSample > size(EEG.data,2)
            continue
        end

        eegEpoch = EEG.data(:,startSample:endSample);

        expectedLength = ...
            round((preSec + postSec)*Fs);

        assert(size(eegEpoch,2)==expectedLength,...
            'Unexpected epoch length');

        timeVec = (-round(preSec*Fs):round(postSec*Fs)-1)/Fs;

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

        data_trials(trialCounter).srate = ...
            Fs;

        data_trials(trialCounter).chanlocs = ...
            EEG.chanlocs;

        if k > 1
            prevTarget = ...
                round(eventLat(startIdx(k-1)+1));

            data_trials(trialCounter).previousISI = ...
                (targetSample-prevTarget)/Fs;
        else
            data_trials(trialCounter).previousISI = NaN;
        end

        if k < numel(startIdx)

            nextTarget = ...
                round(eventLat(startIdx(k+1)+1));

            data_trials(trialCounter).nextISI = ...
                (nextTarget-targetSample)/Fs;

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

        data_trials(trialCounter).trialDurationSec = ...
            (trialEndSample-trialStartSample)/Fs;

        data_trials(trialCounter).epochStartSample = ...
            startSample;

        data_trials(trialCounter).epochEndSample = ...
            endSample;

        data_trials(trialCounter).preTargetDurationSec = ...
            (targetSample-trialStartSample)/Fs;

        data_trials(trialCounter).postTargetDurationSec = ...
            (trialEndSample-targetSample)/Fs;

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

    subjectEpochData.n101 = ...
        sum([data_trials.conditionCode]==101);

    subjectEpochData.n102 = ...
        sum([data_trials.conditionCode]==102);

    subjectEpochData.n103 = ...
        sum([data_trials.conditionCode]==103);
    %% ===================================================================
    % QUICK CHECK
    % ====================================================================

    if debugMode && ~isempty(data_trials)

        figure

        plot( ...
            data_trials(1).time,...
            mean(data_trials(1).eeg,1));

        xline(0,'r');

        title('Trial 1 - Mean EEG');
        xlabel('Time (s)');
        ylabel('Amplitude');

    end
    % assert(numel(data_trials)==sum(eventCodes==10),...
    %     'Mismatch between START markers and extracted trials');
    assert(numel(data_trials) <= sum(eventCodes==10));
    fprintf('START markers : %d\n',sum(eventCodes==10));
    fprintf('Extracted     : %d\n',numel(data_trials));
    %% ===================================================================
    % SAVE
    % ====================================================================
    epochLengths = arrayfun(@(x) size(x.eeg,2), data_trials);

    fprintf('Epoch lengths: ');
    disp(unique(epochLengths));

    assert(all(epochLengths == expectedLength), ...
        'Unexpected epoch lengths detected');
    save( ...
        fullfile(outputFolder,...
        sprintf('%s_epochData.mat',...
        subjectData.subjectID)), ...
        'subjectEpochData', ...
        '-v7.3');

    fprintf('Trials generated : %d\n', ...
        numel(data_trials));

    fprintf('Expected trials  : %d\n', ...
        sum(eventCodes==10));

end