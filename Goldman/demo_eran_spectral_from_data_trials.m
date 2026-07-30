function demo_eran_spectral_from_data_trials()
% DEMO_ERAN_SPECTRAL_FROM_DATA_TRIALS
% Versione generale che lavora sui data_trials reali salvati su disco.
%
% Richiede:
%   - un file per soggetto: *_data_trials.mat
%   - data_trials(i).eeg        = channels x time
%   - data_trials(i).time       = vettore tempo
%   - data_trials(i).trialType  = codice numerico condizione
%   - data_trials(i).trialName  = nome stringa condizione
%   - data_trials(1).chanloc    = EEG.chanlocs
%
% Esegue:
%   1) ERP medio per soggetto e grand average su ROI ERAN
%   2) Welch PSD in finestra post-target
%   3) CWT su segnale medio per condizione

clearvars -except ans;
clc;

%% =======================================================================
% 1) PATH E PARAMETRI
% ========================================================================
output_root = 'D:\X-SONANCE\Goldman\Output';
data_trials_root = fullfile(output_root, 'DATA_TRIALS');
plot_out = fullfile(output_root, 'ERAN_SPECTRAL_FROM_DATA_TRIALS');

if ~exist(plot_out, 'dir')
    mkdir(plot_out);
end

roi_eran_labels    = {'Fz'}; %,'F4','F8','FC2','FC4'};   
roi_control_labels = {'Cz','Pz','Oz'};          

win_eran = [90 250];
win_psd  = [0 300]; %300
band_defs  = [4 8; 8 13; 13 30; 30 90];
band_names = {'theta','alpha','beta','gamma'};

%% =======================================================================
% 2) CERCA FILE
% ========================================================================
dt_files = dir(fullfile(data_trials_root, '*_data_trials.mat'));
if isempty(dt_files)
    error('Nessun file *_data_trials.mat trovato in %s', data_trials_root);
end

nSubj = numel(dt_files);
fprintf('Trovati %d file data_trials.\n', nSubj);

%% =======================================================================
% 3) META DAL PRIMO FILE
% ========================================================================
S0 = load(fullfile(dt_files(1).folder, dt_files(1).name));
data0 = S0.data_trials;

if isempty(data0)
    error('Il primo file data_trials è vuoto.');
end

time_ms = data0(1).time(:)';
dt_ms = median(diff(time_ms));
fs = 1000 / dt_ms;

if ~isfield(data0(1), 'chanloc') || isempty(data0(1).chanloc)
    error('Nel primo file manca data_trials(1).chanloc.');
end

chan_labels = {data0(1).chanloc.labels};

roi_eran = find(ismember(lower(chan_labels), lower(roi_eran_labels)));
roi_control = find(ismember(lower(chan_labels), lower(roi_control_labels)));

if isempty(roi_eran)
    error('Nessun canale ROI ERAN trovato.');
end
if isempty(roi_control)
    warning('Nessun canale ROI controllo trovato.');
end

meta = struct();
meta.fs = fs;
meta.time_ms = time_ms;
meta.chan_labels = chan_labels;
meta.roi_eran_labels = chan_labels(roi_eran);
meta.roi_control_labels = chan_labels(roi_control);
meta.band_defs = band_defs;
meta.band_names = band_names;
meta.nSubjects = nSubj;
meta.win_eran = win_eran;
meta.win_psd = win_psd;

%% =======================================================================
% 4) CONDIZIONI
% ========================================================================
all_trial_names = {};
for s = 1:nSubj
    S = load(fullfile(dt_files(s).folder, dt_files(s).name));
    dt = S.data_trials;
    all_trial_names = [all_trial_names, {dt.trialName}]; %#ok<AGROW>
end
conds = unique(lower(string(all_trial_names)), 'stable');
nConds = numel(conds);

fprintf('Condizioni trovate: %s\n', strjoin(cellstr(conds), ', '));

%% =======================================================================
% 5) ERP ROI ERAN: soggetto e grand average
% ========================================================================
subj_erp = nan(nSubj, numel(time_ms), nConds);
subject_names = cell(nSubj,1);

for s = 1:nSubj
    S = load(fullfile(dt_files(s).folder, dt_files(s).name));
    data_trials = S.data_trials;
    subject_names{s} = regexprep(dt_files(s).name, '_data_trials\.mat$', '');

    for c = 1:nConds
        idx = find(strcmpi({data_trials.trialName}, conds(c)));
        if isempty(idx)
            continue;
        end

        tmp = nan(numel(roi_eran), numel(time_ms), numel(idx));
        for k = 1:numel(idx)
            tmp(:,:,k) = data_trials(idx(k)).eeg(roi_eran,:);
        end

        roi_trial = squeeze(mean(tmp, 1, 'omitnan'));   % time x trials
        if isvector(roi_trial)
            roi_trial = roi_trial(:);
        end
        subj_erp(s,:,c) = mean(roi_trial, 2, 'omitnan');
    end
end

grand_avg = squeeze(mean(subj_erp, 1, 'omitnan'));
grand_se  = squeeze(std(subj_erp, 0, 1, 'omitnan') ./ sqrt(nSubj));

f1 = figure('Color','w','Name','ERP ROI ERAN');
for c = 1:nConds
    plot_with_shade(time_ms, grand_avg(:,c), grand_se(:,c), get_color(c)); hold on;
end
xline(0,'--k'); yline(0,':k');
xlabel('Time (ms)');
ylabel('Amplitude');
title('Grand average ERP - ROI ERAN');
legend(cellstr(conds), 'Location', 'best');
set(gca,'FontSize',12);

yl = ylim;
patch([win_eran(1) win_eran(2) win_eran(2) win_eran(1)], ...
      [yl(1) yl(1) yl(2) yl(2)], [1.00 0.92 0.92], ...
      'FaceAlpha',0.25,'EdgeColor','none');
uistack(findobj(gca,'Type','patch'),'bottom');
ylim(yl);

print(f1, fullfile(plot_out, 'ERP_ROI_ERAN.png'), '-dpng', '-r300');

%% =======================================================================
% 6) WELCH PSD
% ========================================================================
idx_win = time_ms >= win_psd(1) & time_ms <= win_psd(2);
nBands = numel(band_names);

trial_bandpower_eran = [];
trial_bandpower_control = [];
trial_cond = strings(0,1);
trial_subj = strings(0,1);

for s = 1:nSubj
    S = load(fullfile(dt_files(s).folder, dt_files(s).name));
    data_trials = S.data_trials;
    subj_name = regexprep(dt_files(s).name, '_data_trials\.mat$', '');

    for k = 1:numel(data_trials)
        xE = mean(data_trials(k).eeg(roi_eran, idx_win), 1, 'omitnan');

        if ~isempty(roi_control)
            xC = mean(data_trials(k).eeg(roi_control, idx_win), 1, 'omitnan');
        else
            xC = nan(size(xE));
        end

        segLen = min(round(fs*0.4), numel(xE));
        if segLen < 8
            segLen = numel(xE);
        end
        nover = floor(segLen * 0.5);

        [PxxE, f] = pwelch(xE, segLen, nover, [], fs);
        if all(isnan(xC))
            PxxC = nan(size(PxxE));
        else
            [PxxC, ~] = pwelch(xC, segLen, nover, [], fs);
        end

        bpE = nan(1, nBands);
        bpC = nan(1, nBands);

        for b = 1:nBands
            ib = f >= band_defs(b,1) & f < band_defs(b,2);
            bpE(b) = trapz(f(ib), PxxE(ib));
            if ~all(isnan(PxxC))
                bpC(b) = trapz(f(ib), PxxC(ib));
            end
        end

        trial_bandpower_eran = [trial_bandpower_eran; bpE]; %#ok<AGROW>
        trial_bandpower_control = [trial_bandpower_control; bpC]; %#ok<AGROW>
        trial_cond(end+1,1) = string(data_trials(k).trialName); %#ok<AGROW>
        trial_subj(end+1,1) = string(subj_name); %#ok<AGROW>
    end
end

psd_results = struct();
psd_results.bandpower_eran = trial_bandpower_eran;
psd_results.bandpower_control = trial_bandpower_control;
psd_results.band_names = band_names;
psd_results.Condition = trial_cond;
psd_results.Subject = trial_subj;
psd_results.f = f;

f2 = figure('Color','w','Name','Welch band power ROI ERAN');
for b = 1:nBands
    subplot(2,2,b); hold on;
    vals = cell(1, nConds);
    grp = [];
    y = [];
    for c = 1:nConds
        vc = trial_bandpower_eran(trial_cond == conds(c), b);
        vals{c} = vc;
        y = [y; vc]; %#ok<AGROW>
        grp = [grp; c*ones(size(vc))]; %#ok<AGROW>
    end
    boxplot(y, grp, 'Labels', cellstr(conds));
    title(['ERAN ROI - ' band_names{b}]);
    ylabel('Band power');
end
print(f2, fullfile(plot_out, 'Welch_bandpower_ROI_ERAN.png'), '-dpng', '-r300');

%% =======================================================================
% 7) CWT SU MEDIA PER CONDIZIONE
% ========================================================================
cwt_results = struct();
cwt_results.time_ms = time_ms;
cwt_results.band_names = band_names;
cwt_results.Condition = conds;

f3 = figure('Color','w','Name','CWT ROI ERAN');

for c = 1:nConds
    sig_all = [];
    for s = 1:nSubj
        S = load(fullfile(dt_files(s).folder, dt_files(s).name));
        data_trials = S.data_trials;
        idx = find(strcmpi({data_trials.trialName}, conds(c)));
        if isempty(idx)
            continue;
        end

        tmp = nan(numel(roi_eran), numel(time_ms), numel(idx));
        for k = 1:numel(idx)
            tmp(:,:,k) = data_trials(idx(k)).eeg(roi_eran,:);
        end
        roi_trial = squeeze(mean(tmp, 1, 'omitnan')); % time x trials
        if isvector(roi_trial)
            roi_trial = roi_trial(:);
        end
        sig_all = [sig_all; mean(roi_trial,2,'omitnan').']; %#ok<AGROW>
    end

    sig = mean(sig_all, 1, 'omitnan');
    [cfs, fr] = cwt(sig, fs, 'amor');
    pow = abs(cfs).^2;

    cwt_results(c).condition = conds(c);
    cwt_results(c).cfs = cfs;
    cwt_results(c).fr = fr;
    cwt_results(c).pow = pow;

    subplot(nConds,1,c);
    imagesc(time_ms, fr, pow);
    axis xy;
    xlabel('Time (ms)');
    ylabel('Frequency (Hz)');
    title(['CWT scalogram - ' char(conds(c)) ' (ROI ERAN)']);
    colorbar;
    ylim([1 30]); hold on;
    xline(win_eran(1),'--w','LineWidth',1.2);
    xline(win_eran(2),'--w','LineWidth',1.2);
end

print(f3, fullfile(plot_out, 'CWT_ROI_ERAN.png'), '-dpng', '-r300');

%% =======================================================================
% 8) SALVATAGGI
% ========================================================================
save(fullfile(plot_out, 'eran_spectral_results_from_data_trials.mat'), ...
    'meta', 'subject_names', 'subj_erp', 'grand_avg', 'grand_se', ...
    'psd_results', 'cwt_results', 'conds');

assignin('base', 'meta_eran_spectral', meta);
assignin('base', 'subj_erp_eran_spectral', subj_erp);
assignin('base', 'psd_eran_spectral', psd_results);
assignin('base', 'cwt_eran_spectral', cwt_results);

disp('Salvate nel workspace MATLAB: meta_eran_spectral, subj_erp_eran_spectral, psd_eran_spectral, cwt_eran_spectral');
end

%% ========================================================================
function plot_with_shade(x, m, se, color_rgb)
x  = x(:);
m  = m(:);
se = se(:);
n = min([numel(x), numel(m), numel(se)]);
x  = x(1:n);
m  = m(1:n);
se = se(1:n);
xx = [x; flipud(x)];
yy = [m-se; flipud(m+se)];
fill(xx, yy, color_rgb, 'FaceAlpha', 0.20, 'EdgeColor', 'none');
hold on;
plot(x, m, 'Color', color_rgb, 'LineWidth', 2);
end

function c = get_color(i)
cols = [ ...
    0.2  0.2  0.2;
    0.85 0.33 0.10;
    0.00 0.45 0.74;
    0.47 0.67 0.19;
    0.49 0.18 0.56;
    0.93 0.69 0.13];
c = cols(mod(i-1,size(cols,1))+1,:);
end