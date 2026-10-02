function demo_LMM_ROI_all_in_one_data_trials()
% DEMO_ALL_IN_ONE_DATA_TRIALS (Versione Completa Stile Chang)
% Replica la pipeline di Chang:
% 1) ROI separate per SPN (posteriore destra) e ERAN/ERP (anteriore)
% 2) Trial-level LMM: ERP ~ SPN + Condition + Rating + (1|Subject)
% 3) LMM per condizione su SPN: SPN ~ Condition + (1|Subject)
% 4) Sensibilità Bayesiana / Resampling dei coefficienti LMM
% 5) Visualizzazione completa ERP, Scatter e Boxplot per condizione

clearvars -except ans;
clc;

% 1) Genera dati fittizi
[data_trials, meta] = make_dummy_data_trials_local();

% 2) Analisi Completa Stile Chang
lme_models = run_chang_pipeline(data_trials, meta);

% 3) Salva nel workspace
assignin('base', 'data_trials_demo', data_trials);
assignin('base', 'demo_meta', meta);
assignin('base', 'lme_models', lme_models);
disp('Variabili salvate nel workspace MATLAB: data_trials_demo, demo_meta, lme_models');
end

%% ========================================================================
function [data_trials, meta] = make_dummy_data_trials_local()
rng(42);
nSubjects = 5; % Replicando N = 5 di Chang
nTrialsPerCond = 30;
labels = {'predictable','unpredictable'};
chan_labels = {'Fz','FC1','FC2','Cz','C3','C4','Pz','P3','P4','Oz'};
nCh = numel(chan_labels);
fs = 250;
time_ms = -500:1000/fs:800;
nT = numel(time_ms);

% Indici ROI
roi_ant_labels = {'Fz','FC1','FC2','Cz'};
roi_post_labels = {'P4','Pz','Oz'}; % ROI Posteriore Destra / Centro-Posteriore per SPN

roi_ant  = find(ismember(chan_labels, roi_ant_labels));
roi_post = find(ismember(chan_labels, roi_post_labels));

nTrials = nSubjects * nTrialsPerCond * 2;
data_trials = repmat(struct('eeg',[],'label','','subject_id',[],'rating',[],'time_ms',[],'fs',[],'chan_labels',{{}}),1,nTrials);

k = 0;
for s = 1:nSubjects
    subj_shift = randn * 0.4;
    for c = 1:2
        for tr = 1:nTrialsPerCond
            k = k + 1;
            x = 0.8 * randn(nCh, nT);
            
            % Trend descrittivo per SPN: più negativa in 'predictable'
            if strcmp(labels{c}, 'predictable')
                spn_base = -2.8 + subj_shift;
            else
                spn_base = -1.8 + subj_shift;
            end
            spn_amp = spn_base + randn*0.6;
            spn_win = time_ms >= -400 & time_ms <= 0;
            
            % Relazione trial-level: SPN più negativa -> ERP post-target più negativo
            erp_amp = 0.55 * spn_amp + subj_shift + randn*0.4;
            erp_lat = 200 + randn*15;
            gauss_erp = exp(-0.5 * ((time_ms - erp_lat)/28).^2);
            
            % Applicazione su ROI Posteriore (SPN) e Anteriore (ERP/ERAN)
            for ch = 1:nCh
                if ismember(ch, roi_post)
                    x(ch, spn_win) = x(ch, spn_win) + spn_amp;
                end
                if ismember(ch, roi_ant)
                    x(ch, :) = x(ch, :) + erp_amp * gauss_erp;
                end
            end
            
            data_trials(k).eeg = x;
            data_trials(k).label = labels{c};
            data_trials(k).subject_id = s;
            data_trials(k).rating = randi([1, 7]);
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
meta.roi_ant_labels = roi_ant_labels;
meta.roi_post_labels = roi_post_labels;
meta.roi_ant = roi_ant;
meta.roi_post = roi_post;
meta.nSubjects = nSubjects;
meta.nTrials = nTrials;
end

%% ========================================================================
function lme_struct = run_chang_pipeline(data_trials, meta)
time_ms = meta.time_ms;

win_spn = time_ms >= -400 & time_ms <= 0;   % Pre-target SPN
win_erp = time_ms >= 150 & time_ms <= 250;  % Post-target ERP

nTrials = numel(data_trials);
Subject   = nan(nTrials,1);
Condition = strings(nTrials,1);
Rating    = nan(nTrials,1);
SPN_post_roi = nan(nTrials,1);
ERP_ant_roi  = nan(nTrials,1);

% 1. Estrazione Feature con ROI Separate
for k = 1:nTrials
    Subject(k)   = data_trials(k).subject_id;
    Condition(k) = string(data_trials(k).label);
    Rating(k)    = data_trials(k).rating;
    
    eeg_data = data_trials(k).eeg;
    
    % SPN estratta da ROI Posteriore
    SPN_post_roi(k) = mean(eeg_data(meta.roi_post, win_spn), 'all');
    
    % ERP / ERAN estratta da ROI Anteriore
    ERP_ant_roi(k)  = mean(eeg_data(meta.roi_ant, win_erp), 'all');
end

T = table();
T.Subject     = categorical(Subject);
T.Condition   = categorical(Condition);
T.Rating      = Rating;
T.SPN_post_roi = SPN_post_roi;
T.ERP_ant_roi  = ERP_ant_roi;

lme_struct = struct();

if exist('fitlme', 'file') == 2
    % ---------------------------------------------------------------------
    % MODELLO 1: Associazione Trial-Level (ERP_post ~ SPN_pre + Condition + Rating)
    % ---------------------------------------------------------------------
    lme_main = fitlme(T, 'ERP_ant_roi ~ SPN_post_roi + Condition + Rating + (1|Subject)');
    fprintf('\n=======================================================\n');
    fprintf('MODELLO 1 (CHANG MAIN): Trial-level SPN_pre -> ERP_post\n');
    fprintf('=======================================================\n');
    disp(lme_main);
    
    % ---------------------------------------------------------------------
    % MODELLO 2: Effetto della Condizione sulla sola SPN (ROI Posteriore)
    % ---------------------------------------------------------------------
    lme_spn = fitlme(T, 'SPN_post_roi ~ Condition + (1|Subject)');
    fprintf('\n=======================================================\n');
    fprintf('MODELLO 2 (CHANG CONDITION ON SPN): SPN_pre ~ Condition\n');
    fprintf('=======================================================\n');
    disp(lme_spn);
    
    % ---------------------------------------------------------------------
% ---------------------------------------------------------------------
    % 3. ANALISI DI SENSIBILITÀ BAYESIANA (Posterior Sampling dai Coefficienti)
    % ---------------------------------------------------------------------
    fprintf('\n--- Sensibilità Bayesiana (Posterior/Bootstrap Approximation) ---\n');
    nSim = 1000;
    
    % Estrazione del coefficiente della SPN (effetto fisso) e della sua varianza
    idx_spn = strcmp(lme_main.CoefficientNames, 'SPN_post_roi');
    beta_spn = lme_main.Coefficients.Estimate(idx_spn);
    var_spn  = lme_main.CoefficientCovariance(idx_spn, idx_spn);
    
    % Campionamento dalla distribuzione Posterior approssimata: N(beta, Sigma)
    spn_coef_dist = beta_spn + sqrt(var_spn) * randn(nSim, 1);
    
    ci_lower = quantile(spn_coef_dist, 0.025);
    ci_upper = quantile(spn_coef_dist, 0.975);
    fprintf('Coeff. SPN medio simulato: %.4f [95%% Credible Interval: %.4f, %.4f]\n', ...
        mean(spn_coef_dist), ci_lower, ci_upper);
else
    warning('fitlme non disponibile in MATLAB.');
    return;
end

%% =======================================================
% FIGURA 1: Waveforms ERP per ROI Anteriore e ROI Posteriore
% ========================================================
figure('Color','w','Name','ERP Grand Averages per ROI');
time_ms = meta.time_ms;
subjs = unique([data_trials.subject_id]);
conds = {'predictable','unpredictable'};

% Calcolo medie di gruppo per le due ROI
ant_pred = nan(numel(subjs), numel(time_ms));
ant_unpr = nan(numel(subjs), numel(time_ms));
post_pred = nan(numel(subjs), numel(time_ms));
post_unpr = nan(numel(subjs), numel(time_ms));

for iS = 1:numel(subjs)
    s = subjs(iS);
    idx_p = find([data_trials.subject_id] == s & strcmp({data_trials.label}, 'predictable'));
    idx_u = find([data_trials.subject_id] == s & strcmp({data_trials.label}, 'unpredictable'));
    
    tmp_ap = []; tmp_au = []; tmp_pp = []; tmp_pu = [];
    for k = idx_p
        tmp_ap = cat(3, tmp_ap, mean(data_trials(k).eeg(meta.roi_ant,:),1));
        tmp_pp = cat(3, tmp_pp, mean(data_trials(k).eeg(meta.roi_post,:),1));
    end
    for k = idx_u
        tmp_au = cat(3, tmp_au, mean(data_trials(k).eeg(meta.roi_ant,:),1));
        tmp_pu = cat(3, tmp_pu, mean(data_trials(k).eeg(meta.roi_post,:),1));
    end
    ant_pred(iS,:) = mean(tmp_ap, 3); ant_unpr(iS,:) = mean(tmp_au, 3);
    post_pred(iS,:) = mean(tmp_pp, 3); post_unpr(iS,:) = mean(tmp_pu, 3);
end

subplot(1,2,1);
plot(time_ms, mean(ant_pred,1), 'b', 'LineWidth', 2); hold on;
plot(time_ms, mean(ant_unpr,1), 'r', 'LineWidth', 2);
yline(0, ':k'); xline(0, '--k');
xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
title('ROI Anteriore (ERAN / Target ERP)');
legend('predictable','unpredictable','Location','best'); grid on; set(gca,'FontSize',11);

subplot(1,2,2);
plot(time_ms, mean(post_pred,1), 'b', 'LineWidth', 2); hold on;
plot(time_ms, mean(post_unpr,1), 'r', 'LineWidth', 2);
yline(0, ':k'); xline(0, '--k');
xlabel('Time (ms)'); ylabel('Amplitude (\muV)');
title('ROI Posteriore Destra (SPN)');
legend('predictable','unpredictable','Location','best'); grid on; set(gca,'FontSize',11);

%% =======================================================
% FIGURA 2: Scatter Plot SPN (Posteriore) vs ERP (Anteriore)
% ========================================================
figure('Color','w','Name','LMM - Association SPN vs ERP');
hold on;
colors = lines(numel(subjs));
T.Fitted = fitted(lme_main);

for i = 1:numel(subjs)
    idx = T.Subject == categorical(subjs(i));
    scatter(T.SPN_post_roi(idx), T.ERP_ant_roi(idx), 25, colors(i,:), 'filled', ...
        'MarkerFaceAlpha', 0.4, 'DisplayName', ['Subj ' num2str(subjs(i))]);
    p = polyfit(T.SPN_post_roi(idx), T.ERP_ant_roi(idx), 1);
    x_val = linspace(min(T.SPN_post_roi(idx)), max(T.SPN_post_roi(idx)), 50);
    plot(x_val, polyval(p, x_val), 'Color', colors(i,:), 'LineWidth', 1.2, 'HandleVisibility', 'off');
end

p_global = polyfit(T.SPN_post_roi, T.Fitted, 1);
x_global = linspace(min(T.SPN_post_roi), max(T.SPN_post_roi), 100);
plot(x_global, polyval(p_global, x_global), 'k--', 'LineWidth', 3, 'DisplayName', 'LMM Fixed Effect');

xlabel('Pre-target SPN Amplitude (\muV) [ROI Posteriore]');
ylabel('Post-target ERP Amplitude (\muV) [ROI Anteriore]');
title('Trial-Level Association (SPN_{pre} \rightarrow ERP_{post})');
legend('Location', 'bestoutside'); grid on; set(gca, 'FontSize', 12);

%% =======================================================
% FIGURA 3: Effetto di Condizione su SPN (Boxplot)
% ========================================================
figure('Color','w','Name','SPN Condition Effect');
subplot(1,2,1);
boxplot(T.SPN_post_roi, T.Condition);
ylabel('SPN Amplitude (\muV)');
title('SPN Amplitude by Condition (N=5)');
grid on; set(gca, 'FontSize', 12);

subplot(1,2,2);
histogram(spn_coef_dist, 20, 'FaceColor', [0.2 0.6 0.8]);
xline(0, '--r', 'LineWidth', 2);
xlabel('Beta Coefficient Estimate'); ylabel('Frequency');
title('Bayesian Posterior Sensitivity (SPN Coeff)');
grid on; set(gca, 'FontSize', 12);

end