%% ============================================================
% CHECK_SUBJECT_RMS_OUTLIERS
%% ============================================================

clear
close all
clc

load('subj_list.mat','subj_list')

nSubjects = numel(subj_list);

Results = table();

figure('Color','w','Position',[100 100 1200 600])

for iSub = 1:nSubjects

    subjID = subj_list(iSub).subj_id;

    nTrials = numel(subj_list(iSub).data_trials);

    trialRMS = nan(nTrials,1);

    for tr = 1:nTrials

        X = subj_list(iSub).data_trials(tr).eeg;

        trialRMS(tr) = rms(X(:));

    end

    nBad = sum(trialRMS > 100);

    percBad = 100*nBad/nTrials;

    Results = [Results ;

    table( ...
    string(subjID), ...
    nTrials, ...
    nBad, ...
    percBad, ...
    mean(trialRMS), ...
    median(trialRMS), ...
    max(trialRMS), ...
    'VariableNames',{ ...
    'Subject',...
    'NTrials',...
    'N_RMS_GT100',...
    'Perc_GT100',...
    'MeanRMS',...
    'MedianRMS',...
    'MaxRMS'})];

    subplot(nSubjects,1,iSub)

    stem(trialRMS,'.')

    hold on

    yline(100,'r--','LineWidth',1.5)

    ylabel('RMS')

    title(sprintf('%s | %d trials >100', ...
        subjID,nBad))

    if iSub == nSubjects
        xlabel('Trial')
    end

end

disp(Results)

fprintf('\n')
fprintf('====================================\n')
disp(Results)
fprintf('====================================\n')

writetable(Results,...
    'RMS_Outlier_Summary.csv')

for iSub = 1:nSubjects

    subjID = subj_list(iSub).subj_id;

    nTrials = numel(subj_list(iSub).data_trials);

    trialRMS = nan(nTrials,1);

    for tr = 1:nTrials

        X = subj_list(iSub).data_trials(tr).eeg;

        trialRMS(tr) = rms(X(:));

    end

    badTrials = find(trialRMS > 100);

    fprintf('\n%s\n',subjID)

    disp(badTrials')

end