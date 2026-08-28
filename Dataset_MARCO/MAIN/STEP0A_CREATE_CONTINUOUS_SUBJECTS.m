% ========================================================================
% MAIN_CREATE_CONTINUOUS_SUBJECTS
% ========================================================================

clear; clc;

rootFolder = 'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS';

subjectDirs = dir(fullfile(rootFolder,'Subj*'));
subjectDirs = subjectDirs([subjectDirs.isdir]);

for s = 1:numel(subjectDirs)

    subjName = subjectDirs(s).name;

    % Subj1 già continuo
    if strcmpi(subjName,'Subj1')
        fprintf('\nSkipping %s (already continuous)\n',subjName);
        continue
    end

    subjFolder = fullfile(rootFolder,subjName);

    matFiles = dir(fullfile(subjFolder,'*_trial*.mat'));

    if isempty(matFiles)
        fprintf('\nNo trial files found in %s\n',subjName);
        continue
    end

    % ---------------------------------------------------------------
    % Ordina trial1, trial2, trial3, trial4
    % ---------------------------------------------------------------

    matFiles = dir(fullfile(subjFolder,'*_trial*.mat'));

    keep = false(numel(matFiles),1);

    for k = 1:numel(matFiles)

        keep(k) = ~isempty( ...
            regexp(matFiles(k).name,...
            'trial\d+\.mat$',...
            'once'));

    end

    matFiles = matFiles(keep);

    trialNum = zeros(numel(matFiles),1);

    for k = 1:numel(matFiles)

        tok = regexp(matFiles(k).name,...
            'trial(\d+)\.mat$',...
            'tokens','once');

        trialNum(k) = str2double(tok{1});

    end

    [~,idx] = sort(trialNum);
    matFiles = matFiles(idx);

    fprintf('\n=====================================\n');
    fprintf('SUBJECT: %s\n',subjName);
    fprintf('FOUND %d TRIALS\n',numel(matFiles));
    fprintf('=====================================\n');
    
    % ---------------------------------------------------------------
    % PASS 1 - COUNT SAMPLES
    % ---------------------------------------------------------------

    totalSamples = 0;

    for f = 1:numel(matFiles)

        tmp = load(fullfile(subjFolder,matFiles(f).name));

        y = tmp.y;

        totalSamples = totalSamples + size(y,2);

        if f == 1

            Fs = round(1/mean(diff(y(1,:))));
            nChannels = size(y,1)-2;

            recordingName = regexp( ...
                matFiles(f).name,...
                '(.*)_trial\d+',...
                'tokens');

            recordingName = recordingName{1}{1};

        end

    end

    fprintf('Total samples: %d\n',totalSamples);
    fprintf('Channels: %d\n',nChannels);
    fprintf('Fs: %.1f Hz\n',Fs);

    % ---------------------------------------------------------------
    % PREALLOCATION
    % ---------------------------------------------------------------

    timeAll    = zeros(1,totalSamples);
    dataAll    = zeros(nChannels,totalSamples,'single');
    triggerAll = zeros(1,totalSamples);

    trialBoundaries = struct();

    currentIdx = 1;
    timeOffset = 0;

    % ---------------------------------------------------------------
    % PASS 2 - CONCATENATION
    % ---------------------------------------------------------------

    for f = 1:numel(matFiles)

        currentFile = fullfile( ...
            subjFolder,...
            matFiles(f).name);

        tmp = load(currentFile);

        y = tmp.y;

        time    = y(1,:);
        data    = y(2:end-1,:);
        trigger = y(end,:);

        nS = size(y,2);

        idxStart = currentIdx;
        idxEnd   = currentIdx + nS - 1;


        dataAll(:,idxStart:idxEnd)    = single(data);
        triggerAll(idxStart:idxEnd)   = trigger;

        eventsTrial = find(diff([0 trigger~=0])==1);

        trialBoundaries(f).trialID = sprintf('trial%d',f);
        trialBoundaries(f).fileName = matFiles(f).name;
        trialBoundaries(f).startSample = idxStart;
        trialBoundaries(f).endSample = idxEnd;
        trialBoundaries(f).durationSec = nS/Fs;
        trialBoundaries(f).nEvents = numel(eventsTrial);

        fprintf('Added %s\n',matFiles(f).name);

        currentIdx = idxEnd + 1;

    end
    % ---------------------------------------------------------------
    % BUILD TIME VECTOR
    % ---------------------------------------------------------------

    timeAll = double((0:totalSamples-1)/Fs);
    
    % ---------------------------------------------------------------
    % BUILD Y
    % ---------------------------------------------------------------

    y = [
        timeAll;
        dataAll;
        triggerAll
        ];

    % ---------------------------------------------------------------
    % SAVE
    % ---------------------------------------------------------------

    outputFile = fullfile( ...
        subjFolder,...
        sprintf('%s_trial.mat',recordingName));

    save( ...
        outputFile,...
        'y',...
        'trialBoundaries',...
        '-v7.3');

    fprintf('\nSaved:\n%s\n',outputFile);

end

fprintf('\nDONE\n');