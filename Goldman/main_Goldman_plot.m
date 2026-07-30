% ========================================================================
% MAIN PLOT - OUTPUT ERP / ERAN / DIFFERENCE WAVES
% Replica visualizzazioni dai file già salvati in output_root
% ========================================================================

% clear; close all; clc;

%% =======================================================================
% 1) PATH
% ========================================================================
output_root = 'D:\X-SONANCE\Goldman\Output';
eeglab_path = 'D:\eeglab2026.0.0\';

addpath(eeglab_path);
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; 

plot_out = fullfile(output_root, 'GROUP_PLOTS');
if ~exist(plot_out, 'dir')
    mkdir(plot_out);
end

%% =======================================================================
% 2) PARAMETRI PLOT
% ========================================================================
chan_of_interest = 'FCz';       % cambia se vuoi: Fz, FCz, Cz...
eran_window_ms   = [100 300];  % finestra classica ERAN
xlim_ms          = [-200 800]; % finestra visualizzata nei plot
ylim_uv          = [];         % es. [-8 8], lascia [] per auto
make_topoplots   = true;

%% =======================================================================
% 3) CERCA FILE EPOCH
% ========================================================================
std_files = dir(fullfile(output_root, '**', '*_epochs_standard.set'));
ex_files  = dir(fullfile(output_root, '**', '*_epochs_exemplar.set'));
fn_files  = dir(fullfile(output_root, '**', '*_epochs_function.set'));

if isempty(std_files) || isempty(ex_files) || isempty(fn_files)
    error('Non trovo tutti i file epocati standard/exemplar/function in output_root.');
end

nSubj = min([numel(std_files), numel(ex_files), numel(fn_files)]);
fprintf('Trovati %d soggetti con tripletta completa di file.\n', nSubj);

%% =======================================================================
% 4) CONTENITORI
% ========================================================================
all_std = [];
all_ex  = [];
all_fn  = [];

times_ms = [];
chanlocs = [];
chan_idx = [];

subject_names = cell(nSubj,1);
ntr_std = nan(nSubj,1);
ntr_ex  = nan(nSubj,1);
ntr_fn  = nan(nSubj,1);

% matrici time x subjects per il canale di interesse
std_ch_mat = [];
ex_ch_mat  = [];
fn_ch_mat  = [];

%% =======================================================================
% 5) LOOP SOGGETTI
% ========================================================================
for s = 1:nSubj

    EEG_std = pop_loadset(fullfile(std_files(s).folder, std_files(s).name));
    EEG_ex  = pop_loadset(fullfile(ex_files(s).folder,  ex_files(s).name));
    EEG_fn  = pop_loadset(fullfile(fn_files(s).folder,  fn_files(s).name));

    if isempty(times_ms)
        times_ms = EEG_std.times(:);  % sempre colonna
        chanlocs = EEG_std.chanlocs;
        chan_idx = find(strcmpi({EEG_std.chanlocs.labels}, chan_of_interest), 1);

        if isempty(chan_idx)
            error('Canale %s non trovato nei dati.', chan_of_interest);
        end
    end

    % ERP medi per soggetto: canali x tempi
    erp_std = mean(EEG_std.data, 3, 'omitnan');
    erp_ex  = mean(EEG_ex.data,  3, 'omitnan');
    erp_fn  = mean(EEG_fn.data,  3, 'omitnan');

    % Contenitori per grand average scalp
    all_std(:,:,s) = erp_std; %#ok<SAGROW>
    all_ex(:,:,s)  = erp_ex;  %#ok<SAGROW>
    all_fn(:,:,s)  = erp_fn;  %#ok<SAGROW>

    % Estrazione robusta del canale di interesse: vettore tempo x 1
    std_ch_mat(:,s) = erp_std(chan_idx,:).'; %#ok<SAGROW>
    ex_ch_mat(:,s)  = erp_ex(chan_idx,:).';  %#ok<SAGROW>
    fn_ch_mat(:,s)  = erp_fn(chan_idx,:).';  %#ok<SAGROW>

    subject_names{s} = regexprep(std_files(s).name, '_epochs_standard\.set$', '');

    ntr_std(s) = EEG_std.trials;
    ntr_ex(s)  = EEG_ex.trials;
    ntr_fn(s)  = EEG_fn.trials;
end

%% =======================================================================
% 6) GRAND AVERAGE
% ========================================================================
GA_std = mean(all_std, 3, 'omitnan');
GA_ex  = mean(all_ex,  3, 'omitnan');
GA_fn  = mean(all_fn,  3, 'omitnan');

GA_diff_ex = GA_ex - GA_std;
GA_diff_fn = GA_fn - GA_std;

% ERP medio sul canale di interesse: time x subjects -> media sui subjects
m_std = mean(std_ch_mat, 2, 'omitnan');
m_ex  = mean(ex_ch_mat,  2, 'omitnan');
m_fn  = mean(fn_ch_mat,  2, 'omitnan');

if nSubj > 1
    se_std = std(std_ch_mat, 0, 2, 'omitnan') ./ sqrt(size(std_ch_mat,2));
    se_ex  = std(ex_ch_mat,  0, 2, 'omitnan') ./ sqrt(size(ex_ch_mat,2));
    se_fn  = std(fn_ch_mat,  0, 2, 'omitnan') ./ sqrt(size(fn_ch_mat,2));
else
    se_std = zeros(size(m_std));
    se_ex  = zeros(size(m_ex));
    se_fn  = zeros(size(m_fn));
end

diff_ex_ch = GA_diff_ex(chan_idx,:).';
diff_fn_ch = GA_diff_fn(chan_idx,:).';

%% Debug utile
fprintf('size(times_ms)   = %s\n', mat2str(size(times_ms)));
fprintf('size(std_ch_mat) = %s\n', mat2str(size(std_ch_mat)));
fprintf('size(m_std)      = %s\n', mat2str(size(m_std)));

%% =======================================================================
% 7) CSV RIASSUNTIVO TRIAL
% ========================================================================
T_summary = table(subject_names, ntr_std, ntr_ex, ntr_fn, ...
    'VariableNames', {'subject','n_standard','n_exemplar','n_function'});
writetable(T_summary, fullfile(plot_out, 'trial_counts_summary.csv'));

%% =======================================================================
% 8) ERP GRAND AVERAGE AL CANALE
% ========================================================================
f1 = figure('Color','w','Position',[100 100 1000 600]); 
hold on;

plot_with_shade(times_ms, m_std, se_std, [0.2 0.2 0.2]);
plot_with_shade(times_ms, m_ex,  se_ex,  [0.85 0.33 0.10]);
plot_with_shade(times_ms, m_fn,  se_fn,  [0 0.45 0.74]);

xline(0,'k--','LineWidth',1);
yline(0,'k:','LineWidth',1);
xline(eran_window_ms(1),'--','Color',[0.5 0.5 0.5]);
xline(eran_window_ms(2),'--','Color',[0.5 0.5 0.5]);

xlabel('Time (ms)');
ylabel('Amplitude (\muV)');
title(sprintf('Grand average ERP - %s', chan_of_interest));
legend({'Standard','Exemplar','Function'}, 'Location','best');
xlim(xlim_ms);

if ~isempty(ylim_uv)
    ylim(ylim_uv);
end

set(gca,'FontSize',12,'Box','off');
drawnow;
print(f1, fullfile(plot_out, sprintf('ERP_grand_average_%s.png', chan_of_interest)), '-dpng', '-r300');

%% =======================================================================
% 9) DIFFERENCE WAVES
% ========================================================================
f2 = figure('Color','w','Position',[100 100 1000 600]); 
hold on;

plot(times_ms, diff_ex_ch, 'LineWidth', 2, 'Color', [0.85 0.33 0.10]);
plot(times_ms, diff_fn_ch, 'LineWidth', 2, 'Color', [0 0.45 0.74]);

xline(0,'k--','LineWidth',1);
yline(0,'k:','LineWidth',1);
xline(eran_window_ms(1),'--','Color',[0.5 0.5 0.5]);
xline(eran_window_ms(2),'--','Color',[0.5 0.5 0.5]);

xlabel('Time (ms)');
ylabel('Amplitude difference (\muV)');
title(sprintf('Difference waves at %s', chan_of_interest));
legend({'Exemplar - Standard','Function - Standard'}, 'Location','best');
xlim(xlim_ms);
set(gca,'FontSize',12,'Box','off');

drawnow;
print(f2, fullfile(plot_out, sprintf('Difference_waves_%s.png', chan_of_interest)), '-dpng', '-r300');

%% =======================================================================
% 10) MEDIA FINESTRA ERAN
% ========================================================================
eran_idx = times_ms >= eran_window_ms(1) & times_ms <= eran_window_ms(2);

eran_std = mean(GA_std(:, eran_idx), 2, 'omitnan');
eran_ex  = mean(GA_ex(:,  eran_idx), 2, 'omitnan');
eran_fn  = mean(GA_fn(:,  eran_idx), 2, 'omitnan');

eran_diff_ex = eran_ex - eran_std;
eran_diff_fn = eran_fn - eran_std;

T_eran = table({chanlocs.labels}', eran_std, eran_ex, eran_fn, eran_diff_ex, eran_diff_fn, ...
    'VariableNames', {'channel','standard','exemplar','function','diff_ex_std','diff_fn_std'});
writetable(T_eran, fullfile(plot_out, 'ERAN_window_channel_means.csv'));

%% =======================================================================
% 11) TOPOPLOTS
% ========================================================================
if make_topoplots
    try
        f3 = figure('Color','w','Position',[100 100 1200 700]);

        subplot(2,3,1);
        topoplot(eran_std, chanlocs, 'electrodes', 'on');
        title(sprintf('Standard\n%d-%d ms', eran_window_ms(1), eran_window_ms(2)));
        colorbar;

        subplot(2,3,2);
        topoplot(eran_ex, chanlocs, 'electrodes', 'on');
        title(sprintf('Exemplar\n%d-%d ms', eran_window_ms(1), eran_window_ms(2)));
        colorbar;

        subplot(2,3,3);
        topoplot(eran_fn, chanlocs, 'electrodes', 'on');
        title(sprintf('Function\n%d-%d ms', eran_window_ms(1), eran_window_ms(2)));
        colorbar;

        subplot(2,3,5);
        topoplot(eran_diff_ex, chanlocs, 'electrodes', 'on');
        title('Exemplar - Standard');
        colorbar;

        subplot(2,3,6);
        topoplot(eran_diff_fn, chanlocs, 'electrodes', 'on');
        title('Function - Standard');
        colorbar;

        drawnow;
        print(f3, fullfile(plot_out, 'Topoplots_ERAN_window.png'), '-dpng', '-r300');
    catch ME
        warning('Topoplot non riuscito:');
    end
end

%% =======================================================================
% 12) SALVATAGGIO MAT
% ========================================================================
save(fullfile(plot_out, 'group_erp_results.mat'), ...
    'subject_names', 'times_ms', 'chanlocs', 'chan_idx', ...
    'all_std', 'all_ex', 'all_fn', ...
    'std_ch_mat', 'ex_ch_mat', 'fn_ch_mat', ...
    'GA_std', 'GA_ex', 'GA_fn', ...
    'GA_diff_ex', 'GA_diff_fn', ...
    'm_std', 'm_ex', 'm_fn', ...
    'se_std', 'se_ex', 'se_fn', ...
    'eran_window_ms', 'eran_std', 'eran_ex', 'eran_fn', ...
    'eran_diff_ex', 'eran_diff_fn', ...
    'ntr_std', 'ntr_ex', 'ntr_fn');

fprintf('\nPlot e file salvati in:\n%s\n', plot_out);

%% =======================================================================
% FUNZIONE LOCALE
% ========================================================================
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

    fill(xx, yy, color_rgb, ...
        'FaceAlpha', 0.2, ...
        'EdgeColor', 'none');
    hold on
    plot(x, m, 'Color', color_rgb, 'LineWidth', 2);
end