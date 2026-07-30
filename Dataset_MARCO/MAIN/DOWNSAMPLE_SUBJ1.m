% ========================================================================
% DOWNSAMPLE_SUBJ1
% ========================================================================

clear
clc

inputFile = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\Subj1\NDS_trial.mat';

outputFile = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\Subj1\NDS_trial.mat';

targetFs = 250;

M = matfile(inputFile);

[nRows,nCols] = size(M,'y');

fprintf('Rows    : %d\n',nRows);
fprintf('Samples : %d\n',nCols);

time = M.y(1,:);
Fs = round(1/mean(diff(time)));
fprintf('Original Fs = %.1f Hz\n',Fs);
nChan = nRows - 2;

nOut = round(numel(time)*targetFs/Fs);
fprintf('Target Fs   = %.1f Hz\n',targetFs);
timeDS = single((0:nOut-1)/targetFs);

trigger = M.y(end,:);

triggerDS = zeros(1,nOut,'like',trigger);

evt = find(trigger~=0);

evt_ds = round((evt-1)*targetFs/Fs)+1;

evt_ds(evt_ds<1) = 1;
evt_ds(evt_ds>nOut) = nOut;
fprintf('Original events : %d\n',numel(evt));
fprintf('Unique DS events: %d\n',numel(unique(evt_ds)));

triggerDS(evt_ds) = trigger(evt);

EEGds = zeros(nChan,nOut,'single');

fprintf('Output samples: %d\n',nOut);
fprintf('Output duration: %.2f min\n', ...
    nOut/targetFs/60);

for ch = 1:nChan

    fprintf('Channel %d/%d\n',ch,nChan);

    x = single(M.y(ch+1,:));

    EEGds(ch,:) = single( ...
        resample(double(x),targetFs,Fs));

    clear x ytmp

end

y = [
    timeDS;
    EEGds;
    triggerDS
    ];


nEventsOrig = sum(diff([0 trigger~=0])==1);
nEventsDS   = sum(diff([0 triggerDS~=0])==1);

assert(nEventsOrig == nEventsDS, ...
    'Event count mismatch after trigger resampling')
fprintf('Original events   : %d\n',nEventsOrig);
fprintf('Resampled events  : %d\n',nEventsDS);

eventOnsets = find(diff([0 trigger~=0])==1);

eventCodes = trigger(eventOnsets);

tabulate(eventCodes)

save(outputFile,'y','-v7.3');

fprintf('DONE\n');