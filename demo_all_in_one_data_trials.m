function demo_all_in_one_data_trials()
% DEMO_ALL_IN_ONE_DATA_TRIALS
% File unico: genera data_trials fittizio, esegue ERP classico e single-trial LMM.
% Uso:
%   demo_all_in_one_data_trials

clearvars -except ans;
clc;

% 1) genera dati fittizi
[data_trials, meta] = make_dummy_data_trials_local();

% 2) ERP classico
classic_erp_example_local(data_trials);

% 3) Single-trial LMM
% lme = single_trial_lmm_example_local(data_trials);
lme = single_trial_lmm_example_local_updated(data_trials);
% 4) salva nel workspace
assignin('base', 'data_trials_demo', data_trials);
assignin('base', 'demo_meta', meta);
assignin('base', 'lme_demo', lme);

disp('Salvate nel workspace MATLAB: data_trials_demo, demo_meta, lme_demo');
end

%% ========================================================================
function [data_trials, meta] = make_dummy_data_trials_local()
rng(1);

nSubjects = 6;
nTrialsPerCond = 20;
labels = {'standard','deviant'};
chan_labels = {'Fz','FC1','FC2','Cz','C3','C4','Pz','P3','P4','Oz'};
nCh = numel(chan_labels);
fs = 250;
time_ms = -200:1000/fs:800;
nT = numel(time_ms);
roi = [1 2 3 4];

nTrials = nSubjects * nTrialsPerCond * 2;
data_trials = repmat(struct('eeg',[],'label','','subject_id',[],'time_ms',[],'fs',[],'chan_labels',{{}}),1,nTrials);

k = 0;
for s = 1:nSubjects
    subj_shift = randn * 0.4;
    for c = 1:2
        for tr = 1:nTrialsPerCond
            k = k + 1;
            x = 0.8 * randn(nCh, nT);
            slow = 0.2 * sin(2*pi*2*(time_ms/1000));
            x = x + repmat(slow, nCh, 1);

            peakLat = 200 + randn*15;
            gauss = exp(-0.5 * ((time_ms - peakLat)/28).^2);

            if strcmp(labels{c}, 'standard')
                amp = -1.5 + subj_shift + randn*0.2;
            else
                amp = -3.5 + subj_shift + randn*0.2;
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
function classic_erp_example_local(data_trials)
assert(~isempty(data_trials), 'data_trials vuoto');

time_ms = data_trials(1).time_ms;
chan_labels = data_trials(1).chan_labels;
roi_labels = {'Fz','FC1','FC2','Cz'};
roi = find(ismember(chan_labels, roi_labels));

subjects = unique([data_trials.subject_id]);
conds = {'standard','deviant'};

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

grand_standard = mean(subj_erp.standard, 1, 'omitnan');
grand_deviant = mean(subj_erp.deviant, 1, 'omitnan');

figure('Color','w');
plot(time_ms, grand_standard, 'b', 'LineWidth', 2); hold on;
plot(time_ms, grand_deviant, 'r', 'LineWidth', 2);
yline(0, ':k');
xline(0, '--k');
legend('standard','deviant','Location','best');
xlabel('Time (ms)');
ylabel('Amplitude');
title('ERP classico - media per soggetto poi gruppo');
set(gca,'FontSize',12);

win = [150 250];
idx_win = time_ms >= win(1) & time_ms <= win(2);
A = mean(subj_erp.standard(:, idx_win), 2, 'omitnan');
B = mean(subj_erp.deviant(:, idx_win), 2, 'omitnan');
[~, p, ~, stats] = ttest(A, B);

disp('===== ERP CLASSICO: t-test soggetto per soggetto =====');
fprintf('p = %.6f, t = %.3f\n', p, stats.tstat);
end

%% ========================================================================
function lme = single_trial_lmm_example_local(data_trials)
assert(~isempty(data_trials), 'data_trials vuoto');

time_ms = data_trials(1).time_ms;
chan_labels = data_trials(1).chan_labels;
roi_labels = {'Fz','FC1','FC2','Cz'};
roi = find(ismember(chan_labels, roi_labels));
win = [150 250];
idx_win = time_ms >= win(1) & time_ms <= win(2);

nTrials = numel(data_trials);
Subject = nan(nTrials,1);
Condition = strings(nTrials,1);
AmplitudeMean = nan(nTrials,1);
AmplitudePeak = nan(nTrials,1);

for k = 1:nTrials
    x = data_trials(k).eeg(roi, idx_win);
    Subject(k) = data_trials(k).subject_id;
    Condition(k) = string(data_trials(k).label);
    AmplitudeMean(k) = mean(x, 'all');
    AmplitudePeak(k) = min(mean(x,1));
end

T = table();
T.Subject = categorical(Subject);
T.Condition = categorical(Condition);
T.AmplitudeMean = AmplitudeMean;
T.AmplitudePeak = AmplitudePeak;

if exist('fitlme', 'file') == 2
    lme = fitlme(T, 'AmplitudeMean ~ Condition + (1|Subject)');
    disp('===== SINGLE-TRIAL LMM SU data_trials =====');
    disp(lme);
else
    lme = [];
    warning('fitlme non disponibile: serve Statistics and Machine Learning Toolbox.');

    Xstd = T.AmplitudeMean(T.Condition == 'standard');
    Xdev = T.AmplitudeMean(T.Condition == 'deviant');
    [~, p, ~, stats] = ttest2(Xstd, Xdev);
    fprintf('Fallback t-test trial-level: p = %.6f, t = %.3f\n', p, stats.tstat);
end

figure('Color','w');
subplot(1,2,1);
boxplot(T.AmplitudeMean, T.Condition);
ylabel('AmplitudeMean');
title('Single-trial mean amplitude');
set(gca,'FontSize',12);

subplot(1,2,2);
boxplot(T.AmplitudePeak, T.Condition);
ylabel('AmplitudePeak');
title('Single-trial peak amplitude');
set(gca,'FontSize',12);
end

function lme = single_trial_lmm_example_local_updated(data_trials)
% SINGLE_TRIAL_LMM_EXAMPLE_LOCAL_UPDATED
% Estrae feature trial-by-trial da una ROI EEG, stima un LMM e produce:
% 1) boxplot delle feature per condizione
% 2) scatter con jitter e medie di condizione
% 3) fitted values vs condition
% 4) random intercept per soggetto
% 5) residui del modello
% 6) output tabellari descrittivi del modello
%
% Richiede fitlme per la parte LMM.

assert(~isempty(data_trials), 'data_trials vuoto');

time_ms = data_trials(1).time_ms;
chan_labels = data_trials(1).chan_labels;
roi_labels = {'Fz','FC1','FC2','Cz'};
roi = find(ismember(chan_labels, roi_labels));
assert(~isempty(roi), 'ROI non trovata nei canali.');

win = [150 250];
idx_win = time_ms >= win(1) & time_ms <= win(2);
assert(any(idx_win), 'Finestra temporale non valida.');

nTrials = numel(data_trials);
Subject = nan(nTrials,1);
Condition = strings(nTrials,1);
AmplitudeMean = nan(nTrials,1);
AmplitudePeak = nan(nTrials,1);

for k = 1:nTrials
    x = data_trials(k).eeg(roi, idx_win);
    Subject(k) = data_trials(k).subject_id;
    Condition(k) = string(data_trials(k).label);
    AmplitudeMean(k) = mean(x, 'all');
    AmplitudePeak(k) = min(mean(x,1));
end

T = table();
T.Subject = categorical(Subject);
T.Condition = categorical(Condition);
T.AmplitudeMean = AmplitudeMean;
T.AmplitudePeak = AmplitudePeak;

fprintf('\n===== DESCRITTIVE STATISTICS =====\n');
G = groupsummary(T, 'Condition', {'mean','std','median'}, {'AmplitudeMean','AmplitudePeak'});
disp(G);

if exist('fitlme', 'file') == 2
    lme = fitlme(T, 'AmplitudeMean ~ Condition + (1|Subject)');
    fprintf('\n===== SINGLE-TRIAL LMM SU data_trials =====\n');
    disp(lme);

    fprintf('\n===== MODEL FIT STATISTICS =====\n');
    fprintf('AIC = %.4f\n', lme.ModelCriterion.AIC);
    fprintf('BIC = %.4f\n', lme.ModelCriterion.BIC);
    fprintf('LogLikelihood = %.4f\n', lme.LogLikelihood);
    fprintf('\n===== MODEL FIT STATISTICS =====\n');
    fprintf('AIC = %.4f\n', lme.ModelCriterion.AIC);
    fprintf('BIC = %.4f\n', lme.ModelCriterion.BIC);
    fprintf('LogLikelihood = %.4f\n', lme.LogLikelihood);
    dev = -2*lme.LogLikelihood;
    fprintf('Deviance (manuale) = %.4f\n', dev);
    fprintf('\n===== FIXED EFFECTS =====\n');
    disp(lme.Coefficients);

    fprintf('\n===== RANDOM EFFECTS =====\n');
    re = randomEffects(lme);
    disp(re);

    T.Fitted = fitted(lme);
    T.Residuals = residuals(lme);
else
    lme = [];
    warning('fitlme non disponibile: serve Statistics and Machine Learning Toolbox.');
    Xstd = T.AmplitudeMean(T.Condition == 'standard');
    Xdev = T.AmplitudeMean(T.Condition == 'deviant');
    [~, p, ~, stats] = ttest2(Xstd, Xdev);
    fprintf('Fallback t-test trial-level: p = %.6f, t = %.3f\n', p, stats.tstat);
    T.Fitted = nan(height(T),1);
    T.Residuals = nan(height(T),1);
end

%% =====================================================
% FIGURA 1: boxplot delle feature
% ======================================================
figure('Color','w','Name','LMM plots - feature distributions');
subplot(1,2,1);
boxplot(T.AmplitudeMean, T.Condition);
ylabel('AmplitudeMean');
title('Single-trial mean amplitude');
set(gca,'FontSize',12);

subplot(1,2,2);
boxplot(T.AmplitudePeak, T.Condition);
ylabel('AmplitudePeak');
title('Single-trial peak amplitude');
set(gca,'FontSize',12);

%% =====================================================
% FIGURA 2: scatter con jitter + media per condizione
% ======================================================
figure('Color','w','Name','LMM plots - jitter and means');
conds = categories(T.Condition);
colors = lines(numel(conds));
hold on;
for i = 1:numel(conds)
    idx = T.Condition == conds{i};
    xj = i + 0.08*randn(sum(idx),1);
    scatter(xj, T.AmplitudeMean(idx), 30, 'MarkerFaceColor', colors(i,:), ...
        'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.3);
    m = mean(T.AmplitudeMean(idx), 'omitnan');
    plot([i-0.2 i+0.2], [m m], 'Color', colors(i,:), 'LineWidth', 3);
end
xlim([0.5 numel(conds)+0.5]);
set(gca, 'XTick', 1:numel(conds), 'XTickLabel', conds, 'FontSize', 12);
ylabel('AmplitudeMean');
title('Trial-level values with condition means');
box on;

%% =====================================================
% FIGURA 3: fitted values per condizione
% ======================================================
if exist('fitlme', 'file') == 2
    figure('Color','w','Name','LMM plots - fitted values');
    hold on;
    for i = 1:numel(conds)
        idx = T.Condition == conds{i};
        xj = i + 0.06*randn(sum(idx),1);
        scatter(xj, T.Fitted(idx), 28, 'MarkerFaceColor', colors(i,:), ...
            'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.45);
        mf = mean(T.Fitted(idx), 'omitnan');
        plot([i-0.2 i+0.2], [mf mf], 'Color', colors(i,:), 'LineWidth', 3);
    end
    xlim([0.5 numel(conds)+0.5]);
    set(gca, 'XTick', 1:numel(conds), 'XTickLabel', conds, 'FontSize', 12);
    ylabel('Fitted values');
    title('LMM fitted values by condition');
    box on;
end

%% =====================================================
% FIGURA 4: random intercept per soggetto
% ======================================================
if exist('fitlme', 'file') == 2
    [~, ~, reStats] = randomEffects(lme);
    disp(reStats);

    idxSubj = strcmp(reStats.Name, '(Intercept)');
    reSubj = reStats(idxSubj, :);
    figure('Color','w','Name','LMM plots - random effects');
    bar(categorical(reSubj.Level), reSubj.Estimate);
    ylabel('Random intercept');
    xlabel('Subject');
    title('Subject-specific random intercepts');
    set(gca,'FontSize',12);
    yline(0, ':k');
end

%% =====================================================
% FIGURA 5: residui del modello
% ======================================================
if exist('fitlme', 'file') == 2
    figure('Color','w','Name','LMM plots - residual diagnostics');
    subplot(1,2,1);
    scatter(T.Fitted, T.Residuals, 30, 'filled', 'MarkerFaceAlpha', 0.5);
    xlabel('Fitted');
    ylabel('Residuals');
    title('Residuals vs fitted');
    yline(0, ':k');
    set(gca,'FontSize',12);

    subplot(1,2,2);
    histogram(T.Residuals, 20);
    xlabel('Residuals');
    ylabel('Count');
    title('Residual distribution');
    set(gca,'FontSize',12);
end

%% =====================================================
% OUTPUT EXPORT (optional)
% ======================================================
assignin('base', 'LMM_table', T);
if exist('fitlme', 'file') == 2
    assignin('base', 'LMM_fixedEffects', lme.Coefficients);
    assignin('base', 'LMM_randomEffects', randomEffects(lme));
end

fprintf('\nVariabili salvate nel workspace: LMM_table');
if exist('fitlme', 'file') == 2
    fprintf(', LMM_fixedEffects, LMM_randomEffects');
end
fprintf('\n');
end