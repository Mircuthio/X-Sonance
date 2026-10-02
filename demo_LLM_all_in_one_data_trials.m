function demo_LLM_all_in_one_data_trials()
% DEMO_ALL_IN_ONE_DATA_TRIALS
% Genera data_trials fittizio, esegue ERP classico e single-trial LMM
% (versione aggiornata con SPN pre-target, ERP post-target e Rating).

clearvars -except ans;
clc;

% 1) Genera dati fittizi
[data_trials, meta] = make_dummy_data_trials_local();

% 2) ERP classico
classic_erp_example_local(data_trials);

% 3) Single-trial LMM (Modello stile Chang)
lme = single_trial_lmm_example_chang_style(data_trials);

% 4) Salva nel workspace
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
labels = {'predictable','unpredictable'};
chan_labels = {'Fz','FC1','FC2','Cz','C3','C4','Pz','P3','P4','Oz'};
nCh = numel(chan_labels);
fs = 250;
time_ms = -500:1000/fs:800; % Finestra estesa per includere la SPN pre-target
nT = numel(time_ms);
roi = [1 2 3 4];
nTrials = nSubjects * nTrialsPerCond * 2;

data_trials = repmat(struct('eeg',[],'label','','subject_id',[],'rating',[],'time_ms',[],'fs',[],'chan_labels',{{}}),1,nTrials);

k = 0;
for s = 1:nSubjects
    subj_shift = randn * 0.4;
    for c = 1:2
        for tr = 1:nTrialsPerCond
            k = k + 1;
            x = 0.8 * randn(nCh, nT);
            
            % Generazione componente SPN pre-target (-400 a 0 ms)
            spn_amp = -2.0 + subj_shift + randn*0.5;
            spn_win = time_ms >= -400 & time_ms <= 0;
            
            % Generazione ERP post-target (150 a 250 ms)
            % Relazione negativa: una SPN piu negativa induce un ERP post-target piu negativo
            erp_amp = 0.6 * spn_amp + subj_shift + randn*0.3;
            erp_lat = 200 + randn*15;
            gauss_erp = exp(-0.5 * ((time_ms - erp_lat)/28).^2);
            
            for ch = 1:nCh
                w = ismember(ch, roi) * 0.8 + 0.2;
                x(ch, spn_win) = x(ch, spn_win) + w * spn_amp;
                x(ch, :) = x(ch, :) + w * erp_amp * gauss_erp;
            end
            
            data_trials(k).eeg = x;
            data_trials(k).label = labels{c};
            data_trials(k).subject_id = s;
            data_trials(k).rating = randi([1, 7]); % Rating comportamentale fittizio 1-7
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
time_ms = data_trials(1).time_ms;
chan_labels = data_trials(1).chan_labels;
roi_labels = {'Fz','FC1','FC2','Cz'};
roi = find(ismember(chan_labels, roi_labels));
subjects = unique([data_trials.subject_id]);
conds = {'predictable','unpredictable'};

subj_erp = struct();
for c = 1:numel(conds)
    subj_erp.(conds{c}) = nan(numel(subjects), numel(time_ms));
end

for iS = 1:numel(subjects)
    s = subjects(iS);
    for c = 1:numel(conds)
        idx = find([data_trials.subject_id] == s & strcmp({data_trials.label}, conds{c}));
        if isempty(idx), continue; end
        tmp = [];
        for k = idx
            tmp = cat(3, tmp, mean(data_trials(k).eeg(roi,:), 1));
        end
        subj_erp.(conds{c})(iS,:) = mean(tmp, 3);
    end
end

figure('Color','w','Name','ERP Classico Grand Average');
plot(time_ms, mean(subj_erp.predictable, 1, 'omitnan'), 'b', 'LineWidth', 2); hold on;
plot(time_ms, mean(subj_erp.unpredictable, 1, 'omitnan'), 'r', 'LineWidth', 2);
yline(0, ':k'); xline(0, '--k');
legend('predictable','unpredictable','Location','best');
xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
title('ERP Classico - Media di Gruppo');
set(gca,'FontSize',12);
box on;
end

%% ========================================================================
function lme = single_trial_lmm_example_chang_style(data_trials)
time_ms = data_trials(1).time_ms;
chan_labels = data_trials(1).chan_labels;
roi_labels = {'Fz','FC1','FC2','Cz'};
roi = find(ismember(chan_labels, roi_labels));

% 1. Definizione finestre temporali
win_spn = time_ms >= -400 & time_ms <= 0;   % Pre-target SPN
win_erp = time_ms >= 150 & time_ms <= 250;  % Post-target ERP

nTrials = numel(data_trials);
Subject   = nan(nTrials,1);
Condition = strings(nTrials,1);
Rating    = nan(nTrials,1);
SPN_pre   = nan(nTrials,1);
ERP_post  = nan(nTrials,1);

% 2. Estrazione feature trial-by-trial
for k = 1:nTrials
    Subject(k)   = data_trials(k).subject_id;
    Condition(k) = string(data_trials(k).label);
    Rating(k)    = data_trials(k).rating;
    
    eeg_roi = data_trials(k).eeg(roi, :);
    SPN_pre(k)  = mean(eeg_roi(:, win_spn), 'all');
    ERP_post(k) = mean(eeg_roi(:, win_erp), 'all');
end

T = table();
T.Subject   = categorical(Subject);
T.Condition = categorical(Condition);
T.Rating    = Rating;
T.SPN_pre   = SPN_pre;
T.ERP_post  = ERP_post;

% 3. Fit del Modello LMM (Stile Chang)
% ERP_post ~ SPN_pre + Condition + Rating + (1|Subject)
if exist('fitlme', 'file') == 2
    lme = fitlme(T, 'ERP_post ~ SPN_pre + Condition + Rating + (1|Subject)');
    fprintf('\n===== SINGLE-TRIAL LMM (MODELLO CHANG) =====\n');
    disp(lme);
    
    T.Fitted = fitted(lme);
    T.Residuals = residuals(lme);
else
    lme = [];
    warning('fitlme non disponibile: serve Statistics and Machine Learning Toolbox.');
    return;
end

%% =====================================================
% FIGURA 1: Scatter Plot SPN_pre vs ERP_post (Effetto Trial-Level)
% ======================================================
figure('Color','w','Name','LMM - Relazione SPN pre vs ERP post');
hold on;

subjs = categories(T.Subject);
colors = lines(numel(subjs));

% Plot dei singoli punti e rette di regressione per soggetto
for i = 1:numel(subjs)
    idx = T.Subject == subjs{i};
    scatter(T.SPN_pre(idx), T.ERP_post(idx), 25, colors(i,:), 'filled', ...
        'MarkerFaceAlpha', 0.4, 'DisplayName', ['Subj ' char(subjs{i})]);
    
    % Retta di fit per soggetto
    p = polyfit(T.SPN_pre(idx), T.ERP_post(idx), 1);
    x_val = linspace(min(T.SPN_pre(idx)), max(T.SPN_pre(idx)), 50);
    plot(x_val, polyval(p, x_val), 'Color', colors(i,:), 'LineWidth', 1.5, 'HandleVisibility', 'off');
end

% Retta di fit globale (Fixed effect)
p_global = polyfit(T.SPN_pre, T.Fitted, 1);
x_global = linspace(min(T.SPN_pre), max(T.SPN_pre), 100);
plot(x_global, polyval(p_global, x_global), 'k--', 'LineWidth', 3, 'DisplayName', 'LMM Fixed Effect');

xlabel('Pre-target SPN Amplitude (\muV)');
ylabel('Post-target ERP Amplitude (\muV)');
title('Associazione Trial-Level: SPN_{pre} vs ERP_{post}');
legend('Location', 'bestoutside');
grid on;
set(gca, 'FontSize', 12);

%% =====================================================
% FIGURA 2: Diagnostica dei Residui e Fitted Values
% ======================================================
figure('Color','w','Name','LMM - Diagnostica Modello');
subplot(1,2,1);
scatter(T.Fitted, T.Residuals, 30, 'filled', 'MarkerFaceAlpha', 0.5);
yline(0, '--r');
xlabel('Valori Predetti (Fitted)'); ylabel('Residui');
title('Residui vs Fitted Values');
grid on; set(gca,'FontSize',12);

subplot(1,2,2);
histogram(T.Residuals, 15);
xlabel('Residuo'); ylabel('Frequenza');
title('Distribuzione dei Residui');
grid on; set(gca,'FontSize',12);

assignin('base', 'LMM_table_chang', T);
end