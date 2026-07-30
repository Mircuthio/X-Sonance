%% SANITY_TEST_STEP3_MARCO
subjName = 'Subj2_epochData.mat';
load(fullfile('D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA\',subjName))
data_trials = subjectEpochData.data_trials;
unique({data_trials.eventLabel})
size(data_trials(1).eeg)
% data_trials(1).time
idx = strcmp({data_trials.eventLabel},...
             'ConsonantGOAL');

trials = cat(3,data_trials(idx).eeg);

erp = mean(trials,3);

plot(data_trials(1).time,...
     mean(erp,1));


unique({data_trials.eventLabel})
tabulate({data_trials.eventLabel}')