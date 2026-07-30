% ========================================================================
% MAIN PLOT - ERP DA DATA_TRIALS
% 3 soggetti in subplot + grand average generale
% Funziona sia con singolo canale sia con ROI
% ========================================================================
% clear; close all; clc;

%% =======================================================================
% 1) PATH
% ========================================================================
output_root = 'D:\X-SONANCE\Goldman\Output';
data_trials_root = fullfile(output_root, 'DATA_TRIALS');
plot_out = fullfile(output_root, 'GROUP_PLOTS_FROM_DATA_TRIALS');

if ~exist(plot_out, 'dir')
    mkdir(plot_out);
end

%% =======================================================================
% 2) PARAMETRI
% ========================================================================
MAIN_ROI
chan_of_interest = {'Fz','FCz','Cz'};            % {'Fz'} oppure {'Fz','FCz','Cz'}
xlim_ms          = [-200 800];
ylim_uv          = [];                  % es. [-8 8], 

cond_codes = [1 2 3];
cond_names = {'standard', 'exemplar', 'function'};
cond_colors = [ ...
    0.2  0.2  0.2; ...
    0.85 0.33 0.10; ...
    0.00 0.45 0.74];

%% =======================================================================
% 3) LABEL ROI/CHANNEL
% ========================================================================
if ischar(chan_of_interest) || isstring(chan_of_interest)
    chan_of_interest = cellstr(chan_of_interest);
end

roi_label = strjoin(chan_of_interest, ' ');

%% =======================================================================
% 4) CERCA FILE DATA_TRIALS
% ========================================================================
dt_files = dir(fullfile(data_trials_root, '*_data_trials.mat'));
if isempty(dt_files)
    error('Nessun file *_data_trials.mat trovato in %s', data_trials_root);
end

nSubj = numel(dt_files);
fprintf('Trovati %d file data_trials.\n', nSubj);

subject_names = cell(nSubj,1);
subject_erps  = cell(nSubj,1);
times_ms      = [];
chan_idx      = [];
chan_labels   = {};

%% =======================================================================
% 5) LOOP SOGGETTI: ERP per soggetto e condizione
% ========================================================================
for s = 1:nSubj

    S = load(fullfile(dt_files(s).folder, dt_files(s).name));
    if ~isfield(S, 'data_trials')
        error('Nel file %s non trovo la variabi le data_trials.', dt_files(s).name);
    end

    data_trials = S.data_trials;

    if isempty(data_trials)
        warning('data_trials vuoto nel file %s. Salto.', dt_files(s).name);
        continue;
    end

    subject_names{s} = regexprep(dt_files(s).name, '_data_trials\.mat$', '');

    if isempty(times_ms)
        times_ms = data_trials(1).time(:);

        if isfield(data_trials(1), 'chanloc') && ~isempty(data_trials(1).chanloc)
            chan_labels = {data_trials(1).chanloc.labels};
        else
            error(['Nel data_trials(1) non trovo il campo chanloc oppure è vuoto. ' ...
                   'Serve data_trials(1).chanloc = EEG.chanlocs']);
        end

        chan_idx = find(ismember(lower(chan_labels), lower(chan_of_interest)));

        if isempty(chan_idx)
            error('Nessuno dei canali richiesti è stato trovato in data_trials(1).chanloc.');
        end

        fprintf('Canali selezionati: %s\n', strjoin(chan_labels(chan_idx), ', '));
    end

    erp_mat = nan(numel(times_ms), numel(cond_codes));

    for c = 1:numel(cond_codes)
        cond_idx = find([data_trials.trialType] == cond_codes(c));

        if isempty(cond_idx)
            warning('Soggetto %s: nessun trial per condizione %s.', subject_names{s}, cond_names{c});
            continue;
        end

        nTrialsCond = numel(cond_idx);
        tmp = nan(numel(times_ms), nTrialsCond);

        for k = 1:nTrialsCond
            tr = data_trials(cond_idx(k)).eeg;   % channels x time

            if numel(chan_idx) == 1
                tmp(:,k) = tr(chan_idx,:).';
            else
                tmp(:,k) = mean(tr(chan_idx,:), 1, 'omitnan').';
            end
        end

        erp_mat(:,c) = mean(tmp, 2, 'omitnan');
    end

    subject_erps{s} = erp_mat;
end

%% =======================================================================
% 6) GRAND AVERAGE
% ========================================================================
valid_subj = find(~cellfun(@isempty, subject_erps));
nValid = numel(valid_subj);

if nValid == 0
    error('Nessun soggetto valido trovato.');
end

grand_mat = nan(numel(times_ms), numel(cond_codes), nValid);
for i = 1:nValid
    grand_mat(:,:,i) = subject_erps{valid_subj(i)};
end

grand_avg = mean(grand_mat, 3, 'omitnan');

if nValid > 1
    grand_se = std(grand_mat, 0, 3, 'omitnan') ./ sqrt(nValid);
else
    grand_se = zeros(size(grand_avg));
end

%% =======================================================================
% 7) PLOT: soggetti in subplot
% ========================================================================
nRows = nValid + 1;
f1 = figure('Color','w','Position',[100 100 1200 250*nRows]);

for i = 1:nValid
    s = valid_subj(i);
    subplot(nRows,1,i); hold on;

    erp_mat = subject_erps{s};

    for c = 1:numel(cond_codes)
        plot(times_ms, erp_mat(:,c), 'LineWidth', 2, 'Color', cond_colors(c,:));
    end

    xline(0,'k--','LineWidth',1);
    yline(0,'k:','LineWidth',1);
    xlim(xlim_ms);

    if ~isempty(ylim_uv)
        ylim(ylim_uv);
    end

    ylabel('\muV');
    title(sprintf('Subject: %s - %s', subject_names{s}, roi_label));
    set(gca,'FontSize',11,'Box','off');

    if i == 1
        legend(cond_names, 'Location', 'best');
    end
end

%% =======================================================================
% 9) FIGURA SOLO GRAND AVERAGE
% ========================================================================
f2 = figure('Color','w','Position',[200 200 1000 500]); hold on;

for c = 1:numel(cond_codes)
    plot_with_shade(times_ms, grand_avg(:,c), grand_se(:,c), cond_colors(c,:));
end

xline(0,'k--','LineWidth',1);
yline(0,'k:','LineWidth',1);
xlim(xlim_ms);

if ~isempty(ylim_uv)
    ylim(ylim_uv);
end

xlabel('Time (ms)');
ylabel('\muV');
title(sprintf('Grand average (%d subjects) - %s', nValid, roi_label));
set(gca,'FontSize',11,'Box','off');
legend(cond_names, 'Location', 'best');

drawnow;
print(f2, fullfile(plot_out, sprintf('Grand_average_only_%s.png', roi_label)), '-dpng', '-r300');

%% =======================================================================
% 10) SALVATAGGI
% ========================================================================
save(fullfile(plot_out, sprintf('ERP_subjects_and_grand_average_%s.mat', roi_label)), ...
    'subject_names', 'valid_subj', 'times_ms', 'chan_of_interest', 'chan_idx', ...
    'cond_codes', 'cond_names', 'subject_erps', ...
    'grand_mat', 'grand_avg', 'grand_se');

fprintf('\nPlot e MAT salvati in:\n%s\n', plot_out);

