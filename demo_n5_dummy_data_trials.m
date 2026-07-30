function demo_n5_dummy_data_trials()
% DEMO_N5_DUMMY_DATA_TRIALS
% File unico: genera data_trials fittizio, esegue ERP classico e single-trial LMM.
% Uso:
%   demo_n5_dummy_data_trials

clearvars -except ans;
clc;

[data_trials, meta] = make_dummy_n5_data_local();
classic_erp_n5_local(data_trials);
lme = single_trial_lmm_n5_local(data_trials);

assignin('base', 'data_trials_n5_demo', data_trials);
assignin('base', 'demo_n5_meta', meta);
assignin('base', 'lme_n5_demo', lme);
disp('Salvate nel workspace MATLAB: data_trials_n5_demo, demo_n5_meta, lme_n5_demo');
end

%% ========================================================================
function [data_trials, meta] = make_dummy_n5_data_local()
rng(41);
nSubjects = 6;
nTrialsPerCond = 20;
labels = {'regular','irregular'};
chan_labels = {'Fz','FC1','FC2','Cz','C3','C4','Pz','P3','P4','Oz'};
nCh = numel(chan_labels);
fs = 250;
time_ms = -200:1000/fs:900;
nT = numel(time_ms);
roi = [1 2 3 4];
nTrials = nSubjects * nTrialsPerCond * 2;

data_trials = repmat(struct( ...
    'eeg',[], ...
    'label','', ...
    'subject_id',[], ...
    'time_ms',[], ...
    'fs',[], ...
    'chan_labels',{{}}), 1, nTrials);

k = 0;
for s = 1:nSubjects
    subj_shift = randn * 0.25;
    for c = 1:2
        for tr = 1:nTrialsPerCond
            k = k + 1;

            x = 0.7 * randn(nCh, nT);
            slow = 0.15 * sin(2*pi*1.5*(time_ms/1000));
            x = x + repmat(slow, nCh, 1);

            peakLat = 500 + randn*25;
            gauss = exp(-0.5 * ((time_ms - peakLat)/55).^2);

            if strcmp(labels{c}, 'regular')
                amp = -1.0 + subj_shift + randn*0.15;
            else
                amp = -2.4 + subj_shift + randn*0.15;
            end

            for ch = 1:nCh
                w = 0.2;
                if ismember(ch, roi)
                    w = 1.0;
                end
                x(ch,:) = x(ch,:) + w * amp * gauss;
            end

            data_trials(k).eeg = x;
            data_trials(k).label = labels{c};
            data_trials(k).subject_id = s;
            data_trials(k).time_ms = time_ms;
            data_trials(k).fs = fs;
            data_trials(k).chan_labels = chan_labels;
        end
    end
end

meta = struct();
meta.fs = fs;
meta.time_ms = time_ms;
meta.chan_labels = chan_labels;
meta.roi_labels = chan_labels(roi);
meta.nSubjects = nSubjects;
meta.nTrials = nTrials;
end

%% ========================================================================
function classic_erp_n5_local(data_trials)
assert(~isempty(data_trials), 'data_trials vuoto');

time_ms = data_trials(1).time_ms;
chan_labels = data_trials(1).chan_labels;
roi_labels = {'Fz','FC1','FC2','Cz'};
roi = find(ismember(chan_labels, roi_labels));
subjects = unique([data_trials.subject_id]);
conds = {'regular','irregular'};

subj_erp = struct();
for c = 1:numel(conds)
    subj_erp.(conds{c}) = nan(numel(subjects), numel(time_ms));
end

for iS = 1:numel(subjects)
    s = subjects(iS);
    for c = 1:numel(conds)
        idx = find([data_trials.subject_id] == s & strcmp({data_trials.label}, conds{c}));
        if isempty(idx)
            continue;
        end
        tmp = [];
        for k = idx
            tmp = cat(3, tmp, mean(data_trials(k).eeg(roi,:), 1));
        end
        subj_erp.(conds{c})(iS,:) = mean(tmp, 3);
    end
end

grand_regular = mean(subj_erp.regular, 1, 'omitnan');
grand_irregular = mean(subj_erp.irregular, 1, 'omitnan');

figure('Color','w');
plot(time_ms, grand_regular, 'b', 'LineWidth', 2); hold on;
plot(time_ms, grand_irregular, 'r', 'LineWidth', 2);
yline(0, ':k');
xline(0, '--k');
legend('regular','irregular','Location','best');
xlabel('Time (ms)');
ylabel('Amplitude');
title('N5 classico - media per soggetto poi gruppo');
set(gca,'FontSize',12);

yl = ylim;
patch([400 600 600 400], [yl(1) yl(1) yl(2) yl(2)], [0.92 0.95 1.00], ...
    'FaceAlpha',0.25, 'EdgeColor','none');
uistack(findobj(gca,'Type','patch'),'bottom');
ylim(yl);

win = [400 600];
idx_win = time_ms >= win(1) & time_ms <= win(2);
A = mean(subj_erp.regular(:, idx_win), 2, 'omitnan');
B = mean(subj_erp.irregular(:, idx_win), 2, 'omitnan');
[~, p, ~, stats] = ttest(A, B);

disp('===== N5 CLASSICO: t-test soggetto per soggetto =====');
fprintf('p = %.6f, t = %.3f\n', p, stats.tstat);
end

%% ========================================================================
function lme = single_trial_lmm_n5_local(data_trials)
time_ms = data_trials(1).time_ms;
chan_labels = data_trials(1).chan_labels;
roi = find(ismember(chan_labels, {'Fz','FC1','FC2','Cz'}));
idx_win = time_ms >= 400 & time_ms <= 600;

nTrials = numel(data_trials);
Subject = nan(nTrials,1);
Condition = strings(nTrials,1);
AmplitudeMean = nan(nTrials,1);
AmplitudePeak = nan(nTrials,1);
AreaUnderCurve = nan(nTrials,1);

for k = 1:nTrials
    x = data_trials(k).eeg(roi, idx_win);
    x_mean = mean(x, 1);

    Subject(k) = data_trials(k).subject_id;
    Condition(k) = string(data_trials(k).label);
    AmplitudeMean(k) = mean(x, 'all');
    AmplitudePeak(k) = min(x_mean);
    AreaUnderCurve(k) = trapz(time_ms(idx_win), x_mean);
end

T = table(categorical(Subject), categorical(Condition), ...
    AmplitudeMean, AmplitudePeak, AreaUnderCurve, ...
    'VariableNames', {'Subject','Condition','AmplitudeMean','AmplitudePeak','AreaUnderCurve'});

if exist('fitlme','file') == 2
    lme = fitlme(T, 'AmplitudeMean ~ Condition + (1|Subject)');
    disp(lme);
else
    lme = [];
    disp('fitlme non disponibile: restituisco lme = []');
end

figure('Color','w');
subplot(1,3,1);
boxplot(T.AmplitudeMean, T.Condition);
title('N5 mean amplitude');
ylabel('AmplitudeMean');

subplot(1,3,2);
boxplot(T.AmplitudePeak, T.Condition);
title('N5 peak amplitude');
ylabel('AmplitudePeak');

subplot(1,3,3);
boxplot(T.AreaUnderCurve, T.Condition);
title('N5 area');
ylabel('AreaUnderCurve');
end