function demo_mmn_dummy_data_trials()
clearvars -except ans;
clc;
[data_trials, meta] = make_dummy_mmn_data_local();
classic_erp_mmn_local(data_trials);
lme = single_trial_lmm_mmn_local(data_trials);
assignin('base', 'data_trials_mmn_demo', data_trials);
assignin('base', 'meta_mmn_demo', meta);
assignin('base', 'lme_mmn_demo', lme);
disp('Salvate nel workspace MATLAB: data_trials_mmn_demo, meta_mmn_demo, lme_mmn_demo');
end

function [data_trials, meta] = make_dummy_mmn_data_local()
rng(21);
nSubjects = 6; nTrialsPerCond = 20; labels = {'standard','deviant'};
chan_labels = {'Fz','FC1','FC2','Cz','C3','C4','Pz','P3','P4','Oz'};
nCh = numel(chan_labels); fs = 250; time_ms = -200:1000/fs:500; nT = numel(time_ms);
roi = find(ismember(chan_labels, {'Fz','FC1','FC2','Cz'}));
nTrials = nSubjects * nTrialsPerCond * 2;
data_trials = repmat(struct('eeg',[],'label','','subject_id',[],'time_ms',[],'fs',[],'chan_labels',{{}}),1,nTrials);
k = 0;
for s = 1:nSubjects
    subj_shift = randn * 0.3;
    for c = 1:2
        for tr = 1:nTrialsPerCond
            k = k + 1;
            x = 0.8 * randn(nCh, nT);
            peakLat = 170 + randn*12;
            gauss = exp(-0.5 * ((time_ms - peakLat)/26).^2);
            if strcmp(labels{c}, 'standard')
                amp = -1.2 + subj_shift + randn*0.15;
            else
                amp = -2.8 + subj_shift + randn*0.15;
            end
            for ch = 1:nCh
                w = 0.2; if ismember(ch, roi), w = 1.0; end
                x(ch,:) = x(ch,:) + w * amp * gauss;
            end
            data_trials(k).eeg = x; data_trials(k).label = labels{c}; data_trials(k).subject_id = s;
            data_trials(k).time_ms = time_ms; data_trials(k).fs = fs; data_trials(k).chan_labels = chan_labels;
        end
    end
end
meta = struct('fs',fs,'time_ms',time_ms,'chan_labels',{chan_labels},'roi_labels',{chan_labels(roi)},'nSubjects',nSubjects,'nTrials',nTrials,'component','MMN');
end

function classic_erp_mmn_local(data_trials)
time_ms = data_trials(1).time_ms; chan_labels = data_trials(1).chan_labels;
roi = find(ismember(chan_labels, {'Fz','FC1','FC2','Cz'})); subjects = unique([data_trials.subject_id]); conds = {'standard','deviant'};
subj_erp = struct(); for c = 1:numel(conds), subj_erp.(conds{c}) = nan(numel(subjects), numel(time_ms)); end
for iS = 1:numel(subjects)
    s = subjects(iS);
    for c = 1:numel(conds)
        idx = find([data_trials.subject_id] == s & strcmp({data_trials.label}, conds{c})); tmp = [];
        for k = idx, tmp = cat(3, tmp, mean(data_trials(k).eeg(roi,:), 1)); end
        subj_erp.(conds{c})(iS,:) = mean(tmp, 3);
    end
end
figure('Color','w');
plot(time_ms, mean(subj_erp.standard,1,'omitnan'),'b','LineWidth',2); hold on;
plot(time_ms, mean(subj_erp.deviant,1,'omitnan'),'r','LineWidth',2);
yline(0,':k'); xline(0,'--k'); legend('standard','deviant','Location','best'); xlabel('Time (ms)'); ylabel('Amplitude'); title('MMN ERP classico'); set(gca,'FontSize',12);
end

function lme = single_trial_lmm_mmn_local(data_trials)
time_ms = data_trials(1).time_ms; chan_labels = data_trials(1).chan_labels;
roi = find(ismember(chan_labels, {'Fz','FC1','FC2','Cz'})); idx_win = time_ms >= 100 & time_ms <= 250;
nTrials = numel(data_trials); Subject = nan(nTrials,1); Condition = strings(nTrials,1); AmplitudeMean = nan(nTrials,1); AmplitudePeak = nan(nTrials,1);
for k=1:nTrials
    x = data_trials(k).eeg(roi, idx_win);
    Subject(k) = data_trials(k).subject_id; Condition(k) = string(data_trials(k).label);
    AmplitudeMean(k) = mean(x,'all'); AmplitudePeak(k) = min(mean(x,1));
end
T = table(categorical(Subject), categorical(Condition), AmplitudeMean, AmplitudePeak, 'VariableNames', {'Subject','Condition','AmplitudeMean','AmplitudePeak'});
if exist('fitlme','file')==2, lme = fitlme(T, 'AmplitudeMean ~ Condition + (1|Subject)'); disp(lme); else, lme = []; end
figure('Color','w'); subplot(1,2,1); boxplot(T.AmplitudeMean, T.Condition); title('MMN mean amplitude'); ylabel('AmplitudeMean'); subplot(1,2,2); boxplot(T.AmplitudePeak, T.Condition); title('MMN peak amplitude'); ylabel('AmplitudePeak');
end