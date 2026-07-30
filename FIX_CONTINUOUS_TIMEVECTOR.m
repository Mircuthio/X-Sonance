% ========================================================================
% FIX_CONTINUOUS_TIMEVECTOR
% ========================================================================

clear; clc

rootFolder = ...
'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials';

subjectList = {'Subj2','Subj3','Subj4','Subj5'};

for s = 1:numel(subjectList)

    subjName = subjectList{s};

    fprintf('\n%s\n',subjName);

    subjFolder = fullfile(rootFolder,subjName);

    fileInfo = dir(fullfile(subjFolder,'*_trial.mat'));

    fileName = fullfile(subjFolder,fileInfo(1).name);

    tmp = load(fileName);

    y = tmp.y;

    timeOld = y(1,:);

    Fs = round(1/mean(diff(timeOld)));

    fprintf('Fs = %.1f Hz\n',Fs);

    nSamples = size(y,2);

    timeNew = (0:nSamples-1)/Fs;

    y(1,:) = timeNew;

    trialBoundaries = tmp.trialBoundaries;
    
    copyfile(fileName,...
         strrep(fileName,'.mat','_OLDTIME.mat'));

    save(fileName,...
        'y',...
        'trialBoundaries',...
        '-v7.3');

    fprintf('Fixed %s\n',fileInfo(1).name);

end