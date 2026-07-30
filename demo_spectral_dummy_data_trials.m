function demo_spectral_dummy_data_trials()
% DEMO_SPECTRAL_DUMMY_DATA_TRIALS
% Demo completo con dati fittizi EEG trial-by-trial.
% Flusso:
%   1) genera data_trials dummy
%   2) mostra ERP classico
%   3) stima PSD con Welch
%   4) estrae band power (theta/alpha/beta/gamma)
%   5) esegue CWT Morlet-like e mostra mappa tempo-frequenza
%   6) salva risultati nel workspace

clearvars -except ans;
clc;

[data_trials, meta] = make_dummy_spectral_data_local();
classic_erp_spectral_local(data_trials, meta);
psd_results = welch_spectral_local(data_trials, meta);
cwt_results = cwt_spectral_local(data_trials, meta);

assignin('base', 'data_trials_spectral_demo', data_trials);
assignin('base', 'meta_spectral_demo', meta);
assignin('base', 'psd_spectral_demo', psd_results);
assignin('base', 'cwt_spectral_demo', cwt_results);
disp('Salvate nel workspace MATLAB: data_trials_spectral_demo, meta_spectral_demo, psd_spectral_demo, cwt_spectral_demo');
end

%% ========================================================================
function [data_trials, meta] = make_dummy_spectral_data_local()
rng(77);

nSubjects = 6;
nTrialsPerCond = 20;
labels = {'consonant','dissonant'};
chan_labels = {'Fz','FC1','FC2','Cz','C3','C4','Pz','P3','P4','Oz'};
roi_front = [1 2 3 4];
roi_pariet = [7 8 9];

fs = 250;
time_ms = -500:1000/fs:1000;
t = time_ms / 1000;
nT = numel(time_ms);
nCh = numel(chan_labels);

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
    subj_shift = randn * 0.20;
    for c = 1:2
        for tr = 1:nTrialsPerCond
            k = k + 1;

            x = 0.55 * randn(nCh, nT);
            x = x + 0.12 * repmat(sin(2*pi*1.2*t), nCh, 1);

            alpha_wave = sin(2*pi*10*t + rand*2*pi);
            theta_wave = sin(2*pi*6*t  + rand*2*pi);
            beta_wave  = sin(2*pi*20*t + rand*2*pi);
            gamma_wave = sin(2*pi*35*t + rand*2*pi);

            env_pre  = exp(-0.5*((time_ms + 200)/180).^2);
            env_post = exp(-0.5*((time_ms - 250)/180).^2);
            env_n5   = exp(-0.5*((time_ms - 550)/90).^2);

            if strcmp(labels{c}, 'consonant')
                a_theta = 0.55 + subj_shift;
                a_alpha = 0.45 + 0.2*rand;
                a_beta  = 0.25 + 0.1*rand;
                a_gamma = 0.40 + 0.1*rand;
                n5_amp  = -1.1 + 0.15*randn;
            else
                a_theta = 0.90 + subj_shift;
                a_alpha = 0.30 + 0.1*rand;
                a_beta  = 0.35 + 0.1*rand;
                a_gamma = 0.22 + 0.08*rand;
                n5_amp  = -2.0 + 0.18*randn;
            end

            for ch = 1:nCh
                x(ch,:) = x(ch,:) + 0.15*alpha_wave + 0.08*theta_wave;

                if ismember(ch, roi_front)
                    x(ch,:) = x(ch,:) + a_theta*(theta_wave.*env_post) ...
                                      + a_beta *(beta_wave .*env_post) ...
                                      + n5_amp * env_n5;
                end

                if ismember(ch, roi_pariet)
                    x(ch,:) = x(ch,:) + a_alpha*(alpha_wave.*env_pre) ...
                                      + a_gamma*(gamma_wave.*env_post);
                end
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
meta.roi_front_labels = chan_labels(roi_front);
meta.roi_pariet_labels = chan_labels(roi_pariet);
meta.band_defs = [4 8; 8 13; 13 30; 30 40];
meta.band_names = {'theta','alpha','beta','gamma'};
meta.nSubjects = nSubjects;
meta.nTrials = nTrials;
end

%% ========================================================================
function classic_erp_spectral_local(data_trials, meta)
time_ms = meta.time_ms;
roi = find(ismember(meta.chan_labels, meta.roi_front_labels));
subjects = unique([data_trials.subject_id]);
conds = {'consonant','dissonant'};

subj_erp = struct();
for c = 1:numel(conds)
    subj_erp.(conds{c}) = nan(numel(subjects), numel(time_ms));
end

for iS = 1:numel(subjects)
    s = subjects(iS);
    for c = 1:numel(conds)
        idx = find([data_trials.subject_id] == s & strcmp({data_trials.label}, conds{c}));
        tmp = [];
        for k = idx
            tmp = cat(3, tmp, mean(data_trials(k).eeg(roi,:), 1));
        end
        subj_erp.(conds{c})(iS,:) = mean(tmp, 3);
    end
end

m1 = mean(subj_erp.consonant,1,'omitnan');
m2 = mean(subj_erp.dissonant,1,'omitnan');

figure('Color','w','Name','ERP spettro-demo');
plot(time_ms, m1, 'b', 'LineWidth', 2); hold on;
plot(time_ms, m2, 'r', 'LineWidth', 2);
xline(0,'--k'); yline(0,':k');
legend('consonant','dissonant','Location','best');
xlabel('Time (ms)');
ylabel('Amplitude');
title('ERP classico fronto-centrale');
set(gca,'FontSize',12);

yl = ylim;
patch([450 650 650 450],[yl(1) yl(1) yl(2) yl(2)],[0.92 0.95 1.00], ...
    'FaceAlpha',0.25,'EdgeColor','none');
uistack(findobj(gca,'Type','patch'),'bottom');
ylim(yl);
end

%% ========================================================================
function psd_results = welch_spectral_local(data_trials, meta)
fs = meta.fs;
time_ms = meta.time_ms;
idx_win = time_ms >= 0 & time_ms <= 800;
roi_front = find(ismember(meta.chan_labels, meta.roi_front_labels));
roi_pariet = find(ismember(meta.chan_labels, meta.roi_pariet_labels));
conds = {'consonant','dissonant'};

nTrials = numel(data_trials);
bandpower_front = nan(nTrials, numel(meta.band_names));
bandpower_pariet = nan(nTrials, numel(meta.band_names));
Condition = strings(nTrials,1);
Subject = nan(nTrials,1);

for k = 1:nTrials
    xF = mean(data_trials(k).eeg(roi_front, idx_win), 1);
    xP = mean(data_trials(k).eeg(roi_pariet, idx_win), 1);

    [PxxF, f] = pwelch(xF, round(fs*0.5), round(fs*0.25), [], fs);
    [PxxP, ~] = pwelch(xP, round(fs*0.5), round(fs*0.25), [], fs);

    for b = 1:numel(meta.band_names)
        fr = meta.band_defs(b,:);
        ib = f >= fr(1) & f < fr(2);
        bandpower_front(k,b) = trapz(f(ib), PxxF(ib));
        bandpower_pariet(k,b) = trapz(f(ib), PxxP(ib));
    end

    Condition(k) = string(data_trials(k).label);
    Subject(k) = data_trials(k).subject_id;
end

psd_results = struct();
psd_results.bandpower_front = bandpower_front;
psd_results.bandpower_pariet = bandpower_pariet;
psd_results.band_names = meta.band_names;
psd_results.Condition = Condition;
psd_results.Subject = Subject;
psd_results.f = f;

figure('Color','w','Name','Welch band power');
for b = 1:numel(meta.band_names)
    subplot(2,2,b);
    vals1 = bandpower_front(Condition == "consonant", b);
    vals2 = bandpower_front(Condition == "dissonant", b);
    boxplot([vals1; vals2], [ones(size(vals1)); 2*ones(size(vals2))], ...
        'Labels', {'consonant','dissonant'});
    title(['Front ROI - ' meta.band_names{b}]);
    ylabel('Band power');
end

figure('Color','w','Name','Welch PSD medio');
for c = 1:numel(conds)
    idx = find(strcmp({data_trials.label}, conds{c}));
    allpsd = [];
    for k = idx
        xF = mean(data_trials(k).eeg(roi_front, idx_win), 1);
        [PxxF, f] = pwelch(xF, round(fs*0.5), round(fs*0.25), [], fs);
        allpsd = [allpsd, PxxF]; %#ok<AGROW>
    end
    plot(f, mean(allpsd,2), 'LineWidth', 2); hold on;
end
xlim([1 45]);
legend(conds,'Location','best');
xlabel('Frequency (Hz)');
ylabel('PSD');
title('PSD media ROI frontale (Welch)');
set(gca,'FontSize',12);
end

%% ========================================================================
function cwt_results = cwt_spectral_local(data_trials, meta)
fs = meta.fs;
time_ms = meta.time_ms;
roi_front = find(ismember(meta.chan_labels, meta.roi_front_labels));
conds = {'consonant','dissonant'};

idx1 = find(strcmp({data_trials.label}, conds{1}), 1, 'first');
idx2 = find(strcmp({data_trials.label}, conds{2}), 1, 'first');

sig1 = mean(data_trials(idx1).eeg(roi_front,:), 1);
sig2 = mean(data_trials(idx2).eeg(roi_front,:), 1);

[cfs1, fr1] = cwt(sig1, fs, 'amor');
[cfs2, fr2] = cwt(sig2, fs, 'amor');

pow1 = abs(cfs1).^2;
pow2 = abs(cfs2).^2;

cwt_results = struct();
cwt_results.cfs1 = cfs1;
cwt_results.cfs2 = cfs2;
cwt_results.fr1 = fr1;
cwt_results.fr2 = fr2;
cwt_results.time_ms = time_ms;
cwt_results.cond1 = conds{1};
cwt_results.cond2 = conds{2};

figure('Color','w','Name','CWT consonant vs dissonant');
subplot(2,1,1);
imagesc(time_ms, fr1, pow1);
axis xy;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title(['CWT scalogram - ' conds{1} ' (amor/Morlet-like)']);
colorbar;
ylim([1 45]);

subplot(2,1,2);
imagesc(time_ms, fr2, pow2);
axis xy;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title(['CWT scalogram - ' conds{2} ' (amor/Morlet-like)']);
colorbar;
ylim([1 45]);

nTrials = numel(data_trials);
band_time = nan(nTrials, numel(meta.band_names));
Condition = strings(nTrials,1);

idx_post = time_ms >= 0 & time_ms <= 800;
for k = 1:nTrials
    sig = mean(data_trials(k).eeg(roi_front,:), 1);
    [cfs, fr] = cwt(sig, fs, 'amor');
    pow = abs(cfs).^2;
    for b = 1:numel(meta.band_names)
        frng = meta.band_defs(b,:);
        ib = fr >= frng(1) & fr < frng(2);
        band_time(k,b) = mean(pow(ib, idx_post), 'all');
    end
    Condition(k) = string(data_trials(k).label);
end

figure('Color','w','Name','CWT band power medio');
for b = 1:numel(meta.band_names)
    subplot(2,2,b);
    vals1 = band_time(Condition == "consonant", b);
    vals2 = band_time(Condition == "dissonant", b);
    boxplot([vals1; vals2], [ones(size(vals1)); 2*ones(size(vals2))], ...
        'Labels', {'consonant','dissonant'});
    title(['CWT ROI front - ' meta.band_names{b}]);
    ylabel('Mean TF power');
end

cwt_results.band_time = band_time;
cwt_results.Condition = Condition;
cwt_results.band_names = meta.band_names;
end