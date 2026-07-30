function demo_eran_spectral_dummy_data_trials()
% DEMO_ERAN_SPECTRAL_DUMMY_DATA_TRIALS
% Demo completo con dati fittizi per ERAN + analisi spettrale.
% Flusso:
%   1) genera data_trials dummy
%   2) mostra ERP classico centrato su ERAN
%   3) stima PSD con Welch nella finestra precoce post-target
%   4) estrae band power
%   5) esegue CWT Morlet-like e mostra mappa tempo-frequenza
%   6) salva risultati nel workspace

clearvars -except ans;
clc;

[data_trials, meta] = make_dummy_eran_spectral_data_local();
classic_erp_eran_spectral_local(data_trials, meta);
psd_results = welch_eran_spectral_local(data_trials, meta);
cwt_results = cwt_eran_spectral_local(data_trials, meta);

assignin('base', 'data_trials_eran_spectral_demo', data_trials);
assignin('base', 'meta_eran_spectral_demo', meta);
assignin('base', 'psd_eran_spectral_demo', psd_results);
assignin('base', 'cwt_eran_spectral_demo', cwt_results);
disp('Salvate nel workspace MATLAB: data_trials_eran_spectral_demo, meta_eran_spectral_demo, psd_eran_spectral_demo, cwt_eran_spectral_demo');
end

%% ========================================================================
function [data_trials, meta] = make_dummy_eran_spectral_data_local()
rng(91);

nSubjects = 6;
nTrialsPerCond = 20;
labels = {'regular','irregular'};
chan_labels = {'F7','F3','F4','F8','FC1','FC2','FC4','Cz','Pz','Oz'};
roi_eran = [3 4 6 7];      % F4 F8 FC2 FC4, anteriore destra
roi_control = [8 9 10];    % Cz Pz Oz

fs = 250;
time_ms = -300:1000/fs:700;
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
    subj_shift = randn * 0.18;
    for c = 1:2
        for tr = 1:nTrialsPerCond
            k = k + 1;

            x = 0.50 * randn(nCh, nT);
            x = x + 0.08 * repmat(sin(2*pi*1.0*t), nCh, 1);

            theta_wave = sin(2*pi*6*t  + rand*2*pi);
            alpha_wave = sin(2*pi*10*t + rand*2*pi);
            beta_wave  = sin(2*pi*18*t + rand*2*pi);
            gamma_wave = sin(2*pi*34*t + rand*2*pi);

            env_eran = exp(-0.5*((time_ms - 190)/40).^2);
            env_post = exp(-0.5*((time_ms - 220)/90).^2);
            env_late = exp(-0.5*((time_ms - 500)/100).^2);

            if strcmp(labels{c}, 'regular')
                eran_amp = -0.8 + subj_shift + 0.10*randn;
                a_theta = 0.35 + 0.08*rand;
                a_alpha = 0.28 + 0.08*rand;
                a_beta  = 0.18 + 0.05*rand;
                a_gamma = 0.15 + 0.05*rand;
                late_amp = -0.4 + 0.10*randn;
            else
                eran_amp = -2.0 + subj_shift + 0.12*randn;
                a_theta = 0.75 + 0.10*rand;
                a_alpha = 0.22 + 0.07*rand;
                a_beta  = 0.32 + 0.06*rand;
                a_gamma = 0.24 + 0.05*rand;
                late_amp = -0.9 + 0.12*randn;
            end

            for ch = 1:nCh
                x(ch,:) = x(ch,:) + 0.08*alpha_wave;

                if ismember(ch, roi_eran)
                    x(ch,:) = x(ch,:) + eran_amp * env_eran ...
                        + a_theta*(theta_wave.*env_post) ...
                        + a_beta *(beta_wave .*env_post) ...
                        + a_gamma*(gamma_wave.*env_post) ...
                        + late_amp * env_late;
                end

                if ismember(ch, roi_control)
                    x(ch,:) = x(ch,:) + 0.12*(alpha_wave.*exp(-0.5*((time_ms+120)/160).^2));
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
meta.roi_eran_labels = chan_labels(roi_eran);
meta.roi_control_labels = chan_labels(roi_control);
meta.band_defs = [4 8; 8 13; 13 30; 30 40];
meta.band_names = {'theta','alpha','beta','gamma'};
meta.nSubjects = nSubjects;
meta.nTrials = nTrials;
meta.win_eran = [150 250];
meta.win_psd = [0 300];
end

%% ========================================================================
function classic_erp_eran_spectral_local(data_trials, meta)
time_ms = meta.time_ms;
roi = find(ismember(meta.chan_labels, meta.roi_eran_labels));
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
        tmp = [];
        for k = idx
            tmp = cat(3, tmp, mean(data_trials(k).eeg(roi,:), 1));
        end
        subj_erp.(conds{c})(iS,:) = mean(tmp, 3);
    end
end

m1 = mean(subj_erp.regular,1,'omitnan');
m2 = mean(subj_erp.irregular,1,'omitnan');

figure('Color','w','Name','ERP ERAN demo');
plot(time_ms, m1, 'b', 'LineWidth', 2); hold on;
plot(time_ms, m2, 'r', 'LineWidth', 2);
xline(0,'--k'); yline(0,':k');
legend('regular','irregular','Location','best');
xlabel('Time (ms)');
ylabel('Amplitude');
title('ERP classico ROI anteriore destra (ERAN)');
set(gca,'FontSize',12);

yl = ylim;
patch([meta.win_eran(1) meta.win_eran(2) meta.win_eran(2) meta.win_eran(1)], ...
    [yl(1) yl(1) yl(2) yl(2)], [1.00 0.92 0.92], ...
    'FaceAlpha',0.25,'EdgeColor','none');
uistack(findobj(gca,'Type','patch'),'bottom');
ylim(yl);
end

%% ========================================================================
function psd_results = welch_eran_spectral_local(data_trials, meta)
fs = meta.fs;
time_ms = meta.time_ms;
idx_win = time_ms >= meta.win_psd(1) & time_ms <= meta.win_psd(2);
roi_eran = find(ismember(meta.chan_labels, meta.roi_eran_labels));
roi_control = find(ismember(meta.chan_labels, meta.roi_control_labels));
conds = {'regular','irregular'};

nTrials = numel(data_trials);
bandpower_eran = nan(nTrials, numel(meta.band_names));
bandpower_control = nan(nTrials, numel(meta.band_names));
Condition = strings(nTrials,1);
Subject = nan(nTrials,1);

for k = 1:nTrials
    xE = mean(data_trials(k).eeg(roi_eran, idx_win), 1);
    xC = mean(data_trials(k).eeg(roi_control, idx_win), 1);

    segLen = min(round(fs*0.4), numel(xE));
    if segLen < 8
        segLen = numel(xE);
    end
    nover = floor(segLen * 0.5);

    [PxxE, f] = pwelch(xE, segLen, nover, [], fs);
    [PxxC, ~] = pwelch(xC, segLen, nover, [], fs);

    for b = 1:numel(meta.band_names)
        fr = meta.band_defs(b,:);
        ib = f >= fr(1) & f < fr(2);
        bandpower_eran(k,b) = trapz(f(ib), PxxE(ib));
        bandpower_control(k,b) = trapz(f(ib), PxxC(ib));
    end

    Condition(k) = string(data_trials(k).label);
    Subject(k) = data_trials(k).subject_id;
end

psd_results = struct();
psd_results.bandpower_eran = bandpower_eran;
psd_results.bandpower_control = bandpower_control;
psd_results.band_names = meta.band_names;
psd_results.Condition = Condition;
psd_results.Subject = Subject;
psd_results.f = f;

figure('Color','w','Name','Welch ERAN band power');
for b = 1:numel(meta.band_names)
    subplot(2,2,b);
    vals1 = bandpower_eran(Condition == "regular", b);
    vals2 = bandpower_eran(Condition == "irregular", b);
    boxplot([vals1; vals2], [ones(size(vals1)); 2*ones(size(vals2))], ...
        'Labels', {'regular','irregular'});
    title(['ERAN ROI - ' meta.band_names{b}]);
    ylabel('Band power');
end

figure('Color','w','Name','Welch PSD media ERAN');
for c = 1:numel(conds)
    idx = find(strcmp({data_trials.label}, conds{c}));
    allpsd = [];
    for k = idx
        xE = mean(data_trials(k).eeg(roi_eran, idx_win), 1);
        segLen = min(round(fs*0.4), numel(xE));
        if segLen < 8
            segLen = numel(xE);
        end
        nover = floor(segLen * 0.5);

        [PxxE, f] = pwelch(xE, segLen, nover, [], fs);        allpsd = [allpsd, PxxE]; %#ok<AGROW>
    end
    plot(f, mean(allpsd,2), 'LineWidth', 2); hold on;
end
xlim([1 45]);
legend(conds,'Location','best');
xlabel('Frequency (Hz)');
ylabel('PSD');
title('PSD media ROI ERAN (Welch, 0-300 ms)');
set(gca,'FontSize',12);
end

%% ========================================================================
function cwt_results = cwt_eran_spectral_local(data_trials, meta)
fs = meta.fs;
time_ms = meta.time_ms;
roi_eran = find(ismember(meta.chan_labels, meta.roi_eran_labels));
conds = {'regular','irregular'};

idx1 = find(strcmp({data_trials.label}, conds{1}), 1, 'first');
idx2 = find(strcmp({data_trials.label}, conds{2}), 1, 'first');

sig1 = mean(data_trials(idx1).eeg(roi_eran,:), 1);
sig2 = mean(data_trials(idx2).eeg(roi_eran,:), 1);

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

figure('Color','w','Name','CWT ERAN regular vs irregular');
subplot(2,1,1);
imagesc(time_ms, fr1, pow1);
axis xy;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title(['CWT scalogram - ' conds{1} ' (ROI ERAN)']);
colorbar;
ylim([1 45]); hold on;
xline(meta.win_eran(1),'--w','LineWidth',1.2);
xline(meta.win_eran(2),'--w','LineWidth',1.2);

subplot(2,1,2);
imagesc(time_ms, fr2, pow2);
axis xy;
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
title(['CWT scalogram - ' conds{2} ' (ROI ERAN)']);
colorbar;
ylim([1 45]); hold on;
xline(meta.win_eran(1),'--w','LineWidth',1.2);
xline(meta.win_eran(2),'--w','LineWidth',1.2);

nTrials = numel(data_trials);
band_time = nan(nTrials, numel(meta.band_names));
Condition = strings(nTrials,1);
idx_post = time_ms >= meta.win_psd(1) & time_ms <= meta.win_psd(2);

for k = 1:nTrials
    sig = mean(data_trials(k).eeg(roi_eran,:), 1);
    [cfs, fr] = cwt(sig, fs, 'amor');
    pow = abs(cfs).^2;
    for b = 1:numel(meta.band_names)
        frng = meta.band_defs(b,:);
        ib = fr >= frng(1) & fr < frng(2);
        band_time(k,b) = mean(pow(ib, idx_post), 'all');
    end
    Condition(k) = string(data_trials(k).label);
end

figure('Color','w','Name','CWT ERAN band power');
for b = 1:numel(meta.band_names)
    subplot(2,2,b);
    vals1 = band_time(Condition == "regular", b);
    vals2 = band_time(Condition == "irregular", b);
    boxplot([vals1; vals2], [ones(size(vals1)); 2*ones(size(vals2))], ...
        'Labels', {'regular','irregular'});
    title(['CWT ERAN ROI - ' meta.band_names{b}]);
    ylabel('Mean TF power');
end

cwt_results.band_time = band_time;
cwt_results.Condition = Condition;
cwt_results.band_names = meta.band_names;
end