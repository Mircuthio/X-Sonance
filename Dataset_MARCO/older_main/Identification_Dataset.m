clear
clc

tmp = load('EDP_trial1.mat');

whos('-file','EDP_trial1.mat')

fieldnames(tmp)
data = tmp.y;
time = data(1,:);
trigger = data(end,:);
eeg = data(2:end-1,:);

% plot(trigger)

unique(trigger)

dt = mean(diff(time));

Fs = 1/dt;
fprintf('Fs = %.3f Hz\n',1/mean(diff(time)));

idx = find(trigger~=0);

figure
plot(idx,trigger(idx),'.')

idx = find(trigger~=0);

eventTriggers = trigger(idx);

tabulate(eventTriggers)
eventSamples = find(trigger~=0);

diffSamples = diff(eventSamples);

[min(diffSamples) mean(diffSamples) max(diffSamples)]

eventOnsets = find(diff([0 trigger~=0])==1);
eventCodes = trigger(eventOnsets);

tabulate(eventCodes)


for k = 60:64
    disp(EEG.chanlocs(k).labels)
end
figure

for k = 60:64

    subplot(5,1,k-59)

    plot(EEG.data(k,1:50000))

    title(EEG.chanlocs(k).labels)

end
% inspect pre Notch
figure
pop_spectopo(EEG,1,[0 EEG.xmax*1000], ...
    'EEG','freqrange',[1 100]);

EEG_notch = pop_eegfiltnew(EEG, ...
    'locutoff', line_frequency-step_frequency, 'hicutoff', line_frequency+step_frequency, ...
    'revfilt', 1, 'plotfreqz', 0);

pop_spectopo(EEG_notch,1,[0 EEG_notch.xmax*1000], ...
    'EEG','freqrange',[1 100]);
stdChan = std(double(EEG.data),[],2);

figure
topoplot(stdChan,EEG.chanlocs);
colorbar
figure
topoplot(std(double(EEG.data),[],2),EEG.chanlocs);
for k = 60:64
    fprintf('%d  %s\n',k,EEG.chanlocs(k).labels);
end

% topoplot prima e dopo
% pre-post nocth non è fondamentale
% Resample
% ↓
% Detrend
% ↓
% Mean removal
% ↓
% Average reference
% 
stdChan = std(double(EEG.data),[],2);

figure
topoplot(stdChan,EEG.chanlocs);
colorbar