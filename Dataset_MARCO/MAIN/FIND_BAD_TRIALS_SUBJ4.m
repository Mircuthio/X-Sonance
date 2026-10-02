%% ============================================================
% FIND_BAD_TRIALS_SUBJ4
%% ============================================================

clear

load('subj_list.mat','subj_list')

subj = subj_list(4);

nTrials = numel(subj.data_trials);

trialRMS   = nan(nTrials,1);
trialMAX   = nan(nTrials,1);
trialPCT50 = nan(nTrials,1);

for tr = 1:nTrials

    eeg = double(subj.data_trials(tr).eeg);

    vals = eeg(:);

    % RMS
    trialRMS(tr) = rms(vals);

    % max absolute amplitude
    trialMAX(tr) = max(abs(vals));

    % percentuale oltre ±50 µV
    trialPCT50(tr) = ...
        100 * mean(abs(vals) > 50);

end

%% ============================================================
% ROBUST THRESHOLDS
%% ============================================================

rmsThr = ...
    median(trialRMS) + ...
    5*mad(trialRMS,1);

maxThr = ...
    median(trialMAX) + ...
    5*mad(trialMAX,1);

pctThr = ...
    median(trialPCT50) + ...
    5*mad(trialPCT50,1);

%% ============================================================
% BAD TRIALS
%% ============================================================

badRMS = find(trialRMS > rmsThr);

badMAX = find(trialMAX > maxThr);

badPCT = find(trialPCT50 > pctThr);

badTrials = unique([ ...
    badRMS ; ...
    badMAX ; ...
    badPCT ]);

fprintf('\n');
fprintf('=========================\n');
fprintf('BAD TRIAL DETECTION\n');
fprintf('=========================\n');

fprintf('RMS threshold  : %.2f\n',rmsThr);
fprintf('MAX threshold  : %.2f\n',maxThr);
fprintf('PCT threshold  : %.2f\n',pctThr);

fprintf('\nBad trials:\n');

disp(badTrials')

fprintf('\nN bad trials = %d / %d\n', ...
    numel(badTrials), ...
    nTrials);

%% ============================================================
% VISUALIZATION
%% ============================================================

figure

subplot(3,1,1)
plot(trialRMS,'o-')
hold on
yline(rmsThr,'r--')
title('Trial RMS')

subplot(3,1,2)
plot(trialMAX,'o-')
hold on
yline(maxThr,'r--')
title('Trial MAX')

subplot(3,1,3)
plot(trialPCT50,'o-')
hold on
yline(pctThr,'r--')
title('% Samples > 50 uV')


trGood = 100;

eegBad  = subj_list(4).data_trials(tr).eeg;
eegGood = subj_list(4).data_trials(trGood).eeg;

figure

subplot(2,1,1)
plot(mean(eegGood,1))
title('Good Trial')

subplot(2,1,2)
plot(mean(eegBad,1))
title('Bad Trial')

figure

subplot(1,2,1)
imagesc(eegGood)

subplot(1,2,2)
imagesc(eegBad)


thr = prctile(trialRMS,99.5);

badTrials = find(trialRMS > thr);

length(badTrials)
badTrials'