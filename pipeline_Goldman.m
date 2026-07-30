% ========================================================================
% PIPELINE EEG - REPLICA GOLDMAN ET AL. (2018) IN EEGLAB
% Studio: Improvisation experience predicts how musicians categorize musical structures
%
% Versione corretta sul dataset BIDS trovato:
% - events.tsv letto da BIDS
% - colonna chiave per i marker: "value"
% - trial_type ignorata per la classificazione, perché nel file è "STATUS"
% - standard  = *_S
% - exemplar  = *deviantE*
% - function  = *deviantF*
%
% NOTE:
% - Il file events.json trovato è praticamente vuoto e non è utile per il mapping.
% - Il filtro comportamentale hit/false alarm/RT è lasciato SOLO come parte opzionale,
%   perché nelle colonne che hai mostrato non c'è ancora una colonna pulita di accuracy trial-wise.
% - Il paper che avevi riportato prima parlava di epoching sul 2° accordo; qui assumiamo
%   che i marker standard/deviant presenti in "value" siano già gli onset informativi
%   da usare come ancoraggio dell'epoca.
% ========================================================================

clear; close all; clc;

%% =======================================================================
% 1) PATH
% ========================================================================
bids_root   = 'E:\DatiOpenNeuro';
output_root = 'D:\X-SONANCE\Goldman\Output';
eeglab_path = 'D:\eeglab2023.1\';

addpath(genpath(bids_root));
addpath(genpath(eeglab_path));


if ~exist(output_root,'dir')
    mkdir(output_root);
end

%% =======================================================================
% 2) PARAMETRI DI PIPELINE
% ========================================================================
target_fs          = 64;
bp_low             = 0.5;
bp_high            = 30;
epoch_window_sec   = [-0.4 1.6];
baseline_window_ms = [-100 0];
rt_min_sec         = 0.2;
amp_thresh_uv      = 250;
prob_sd_thresh     = 5;

%% =======================================================================
% 3) RICERCA FILE .SET
% ========================================================================
set_files = dir(fullfile(bids_root, '**', '*_eeg.set'));

if isempty(set_files)
    error('Nessun file *_eeg.set trovato nella cartella specificata.');
end

%% =======================================================================
% 4) LOOP SOGGETTI
% ========================================================================
for s = 1:15 %16:numel(set_files)

    fprintf('\n====================================================\n');
    fprintf('Soggetto %d / %d\n', s, numel(set_files));
    fprintf('File: %s\n', set_files(s).name);
    fprintf('====================================================\n');

    %% -------------------------------------------------------------------
    % 4A) IDENTIFICAZIONE FILE ASSOCIATI
    % --------------------------------------------------------------------
    set_path = fullfile(set_files(s).folder, set_files(s).name);
    [~, set_base, ~] = fileparts(set_files(s).name);
    base_prefix = regexprep(set_base, '_eeg$', '');

    events_tsv      = fullfile(set_files(s).folder, [base_prefix '_events.tsv']);
    channels_tsv    = fullfile(set_files(s).folder, [base_prefix '_channels.tsv']);
    electrodes_tsv  = fullfile(set_files(s).folder, [base_prefix '_electrodes.tsv']); %#ok<NASGU>
    eeg_json        = fullfile(set_files(s).folder, [base_prefix '_eeg.json']); %#ok<NASGU>
    events_json     = fullfile(set_files(s).folder, [base_prefix '_events.json']); %#ok<NASGU>

    subj_out = fullfile(output_root, base_prefix);
    if ~exist(subj_out,'dir')
        mkdir(subj_out);
    end

    %% -------------------------------------------------------------------
    % 4B) CARICAMENTO EEG
    % --------------------------------------------------------------------
    EEG = pop_loadset(set_path);
    EEG.setname = [base_prefix '_raw_loaded'];

    orig_srate = EEG.srate;
    orig_nbchan = EEG.nbchan;

    fprintf('Campionamento originale: %.2f Hz\n', orig_srate);
    fprintf('Canali originali: %d\n', orig_nbchan);

    EEG_orig_for_interp = EEG;

    %% -------------------------------------------------------------------
    % 4C) LETTURA EVENTS.TSV
    % --------------------------------------------------------------------
    if ~exist(events_tsv, 'file')
        warning('Events TSV non trovato per %s. Soggetto saltato.', base_prefix);
        continue;
    end

    T_events = readtable(events_tsv, 'FileType', 'text', 'Delimiter', '\t');
    var_names = T_events.Properties.VariableNames;

    disp('Colonne disponibili in events.tsv:');
    disp(var_names');

    required_cols = {'onset','value'};
    if ~all(ismember(required_cols, var_names))
        warning('Mancano colonne richieste in events.tsv per %s. Soggetto saltato.', base_prefix);
        continue;
    end

    %% -------------------------------------------------------------------
    % 4D) NORMALIZZAZIONE COLONNE DI TESTO
    % --------------------------------------------------------------------
    T_events.value = string(T_events.value);

    if ismember('trial_type', var_names)
        T_events.trial_type = string(T_events.trial_type);
    end

    if ismember('response_time', var_names)
        tmp_rt = string(T_events.response_time);
        tmp_rt(tmp_rt == "n/a" | tmp_rt == "") = missing;
        T_events.response_time_num = double(tmp_rt);
    else
        T_events.response_time_num = nan(height(T_events),1);
    end

    %% -------------------------------------------------------------------
    % 4E) EVENTI DI INTERESSE DAL CAMPO "value"
    % --------------------------------------------------------------------
    event_vals = strtrim(T_events.value);

    is_boundary  = strcmpi(event_vals, "boundary");
    is_statusnum = strcmpi(event_vals, "16128");
    is_one       = strcmpi(event_vals, "one");
    is_two       = strcmpi(event_vals, "two");

    is_standard = endsWith(event_vals, "_S") | contains(event_vals, "_Sincorrect");
    is_exemplar = contains(event_vals, "deviantE");
    is_function = contains(event_vals, "deviantF");

    is_feedback = contains(event_vals, "Correct - ") | contains(event_vals, "Incorrect - ");

    % Eventi usati per ERP principale
    is_epoch_event = is_standard | is_exemplar | is_function;

    T_epoch = T_events(is_epoch_event, :);
    epoch_vals = strtrim(T_epoch.value);

    cond_label = strings(height(T_epoch),1);
    cond_label(is_standard(is_epoch_event)) = "std_chord2";
    cond_label(is_exemplar(is_epoch_event)) = "ex_chord2";
    cond_label(is_function(is_epoch_event)) = "fn_chord2";

    fprintf('Conteggi eventi usati per epoching:\n');
    fprintf('  standard : %d\n', sum(cond_label == "std_chord2"));
    fprintf('  exemplar : %d\n', sum(cond_label == "ex_chord2"));
    fprintf('  function : %d\n', sum(cond_label == "fn_chord2"));
    fprintf('Eventi ignorati nel main epoching:\n');
    fprintf('  one       : %d\n', sum(is_one));
    fprintf('  two       : %d\n', sum(is_two));
    fprintf('  feedback  : %d\n', sum(is_feedback));
    fprintf('  boundary  : %d\n', sum(is_boundary));
    fprintf('  16128     : %d\n', sum(is_statusnum));

    %% -------------------------------------------------------------------
    % 4F) CHANNELS.TSV -> BAD CHANNELS
    % --------------------------------------------------------------------
    bad_from_tsv = {};

    if exist(channels_tsv, 'file')
        T_channels = readtable(channels_tsv, 'FileType', 'text', 'Delimiter', '\t');

        if all(ismember({'name','status'}, T_channels.Properties.VariableNames))
            bad_idx = strcmpi(string(T_channels.status), 'bad');
            bad_from_tsv = cellstr(string(T_channels.name(bad_idx)));
        end
    end

    if ~isempty(bad_from_tsv)
        fprintf('Bad channels da channels.tsv: %s\n', strjoin(bad_from_tsv, ', '));
        try
            EEG = pop_select(EEG, 'nochannel', bad_from_tsv);
        catch
            warning('Impossibile rimuovere alcuni canali marcati bad nel TSV.');
        end
    end

    %% -------------------------------------------------------------------
    % 4G) DOWNSAMPLE
    % --------------------------------------------------------------------
    EEG = pop_resample(EEG, target_fs);

    %% -------------------------------------------------------------------
    % 4H) FILTRO BAND-PASS
    % --------------------------------------------------------------------
    EEG = pop_eegfiltnew(EEG, 'locutoff', bp_low, 'hicutoff', bp_high, 'plotfreqz', 0);

    %% -------------------------------------------------------------------
    % 4I) AVERAGE REFERENCE
    % --------------------------------------------------------------------
    EEG = pop_reref(EEG, []);

    %% -------------------------------------------------------------------
    % 4J) RICREAZIONE EVENTI EEGLAB A PARTIRE DA T_epoch
    % --------------------------------------------------------------------
    EEG.event = struct('type', {}, 'latency', {}, 'duration', {}, 'urevent', {});

    for iEv = 1:height(T_epoch)
        ev_latency = T_epoch.onset(iEv) * EEG.srate + 1;
        EEG.event(end+1).type = char(cond_label(iEv));
        EEG.event(end).latency = ev_latency;
        EEG.event(end).duration = 0;
        EEG.event(end).urevent = iEv;
    end

    EEG = eeg_checkset(EEG, 'eventconsistency');

    %% -------------------------------------------------------------------
    % 4K) ICA PER ARTEFATTI
    % --------------------------------------------------------------------
    EEG_ica = EEG;

    EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');

    try
        EEG_ica = pop_iclabel(EEG_ica, 'default');
        EEG_ica = pop_icflag(EEG_ica, [NaN NaN; 0.9 1; 0.9 1; NaN NaN; NaN NaN; NaN NaN; NaN NaN]);
    catch
        warning('ICLabel non disponibile. Procedi con eventuale ispezione manuale.');
    end

    EEG.icaweights  = EEG_ica.icaweights;
    EEG.icasphere   = EEG_ica.icasphere;
    EEG.icawinv     = EEG_ica.icawinv;
    EEG.icachansind = EEG_ica.icachansind;

    if isfield(EEG_ica, 'etc') && isfield(EEG_ica.etc, 'ic_classification')
        EEG.etc.ic_classification = EEG_ica.etc.ic_classification;
    end

    if isfield(EEG_ica, 'reject') && isfield(EEG_ica.reject, 'gcompreject')
        EEG.reject.gcompreject = EEG_ica.reject.gcompreject;
    else
        EEG.reject.gcompreject = false(1, size(EEG.icaweights,1));
    end

    EEG = eeg_checkset(EEG);

    comps_to_remove = find(EEG.reject.gcompreject);
    fprintf('Componenti ICA rimosse: %d\n', numel(comps_to_remove));

    if ~isempty(comps_to_remove)
        EEG = pop_subcomp(EEG, comps_to_remove, 0);
    end

    %% -------------------------------------------------------------------
    % 4L) INTERPOLAZIONE CANALI BAD
    % --------------------------------------------------------------------
    if ~isempty(bad_from_tsv)
        try
            EEG = pop_interp(EEG, EEG_orig_for_interp.chanlocs, 'spherical');
        catch
            warning('Interpolazione canali non riuscita.');
        end
    end

    % %% -------------------------------------------------------------------
    % % 4M) SALVATAGGIO CONTINUO PREPROCESSATO
    % % --------------------------------------------------------------------
    EEG.setname = [base_prefix '_continuous_preprocessed'];
    pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', subj_out);

    %% -------------------------------------------------------------------
    % 4N) EPOCHING
    % --------------------------------------------------------------------
    EEG_std = pop_epoch(EEG, {'std_chord2'}, epoch_window_sec, 'epochinfo', 'yes');
    EEG_ex  = pop_epoch(EEG, {'ex_chord2'},  epoch_window_sec, 'epochinfo', 'yes');
    EEG_fn  = pop_epoch(EEG, {'fn_chord2'},  epoch_window_sec, 'epochinfo', 'yes');

    EEG_std = pop_rmbase(EEG_std, baseline_window_ms);
    EEG_ex  = pop_rmbase(EEG_ex,  baseline_window_ms);
    EEG_fn  = pop_rmbase(EEG_fn,  baseline_window_ms);

    %% -------------------------------------------------------------------
    % 4O) FILTRO COMPORTAMENTALE OPZIONALE
    % --------------------------------------------------------------------
    % Non abbiamo ancora una colonna trial-wise pulita di hit/false alarm.
    % Quindi lasciamo i trial così come sono per l'ERP principale.
    %
    % Se in seguito ricostruiamo una tabella trial-by-trial con risposta corretta,
    % qui si può riattivare il filtro.
    keep_std = true(EEG_std.trials,1);
    keep_ex  = true(EEG_ex.trials,1);
    keep_fn  = true(EEG_fn.trials,1);

    EEG_std = pop_select(EEG_std, 'trial', find(keep_std));
    EEG_ex  = pop_select(EEG_ex,  'trial', find(keep_ex));
    EEG_fn  = pop_select(EEG_fn,  'trial', find(keep_fn));

    fprintf('Dopo filtro comportamentale (attualmente neutro) -> standard: %d | exemplar: %d | function: %d\n', ...
        EEG_std.trials, EEG_ex.trials, EEG_fn.trials);

    %% -------------------------------------------------------------------
    % 4P) REJECT EPOCHE: AMPIEZZA
    % --------------------------------------------------------------------
    EEG_std = pop_eegthresh(EEG_std, 1, 1:EEG_std.nbchan, -amp_thresh_uv, amp_thresh_uv, ...
                            EEG_std.xmin, EEG_std.xmax, 0, 1);
    EEG_ex  = pop_eegthresh(EEG_ex,  1, 1:EEG_ex.nbchan,  -amp_thresh_uv, amp_thresh_uv, ...
                            EEG_ex.xmin,  EEG_ex.xmax,  0, 1);
    EEG_fn  = pop_eegthresh(EEG_fn,  1, 1:EEG_fn.nbchan,  -amp_thresh_uv, amp_thresh_uv, ...
                            EEG_fn.xmin,  EEG_fn.xmax,  0, 1);

    %% -------------------------------------------------------------------
    % 4Q) REJECT EPOCHE: PROBABILITÀ
    % --------------------------------------------------------------------
    EEG_std = pop_jointprob(EEG_std, 1, 1:EEG_std.nbchan, prob_sd_thresh, prob_sd_thresh, 0, 1, 0, [], 0);
    EEG_ex  = pop_jointprob(EEG_ex,  1, 1:EEG_ex.nbchan,  prob_sd_thresh, prob_sd_thresh, 0, 1, 0, [], 0);
    EEG_fn  = pop_jointprob(EEG_fn,  1, 1:EEG_fn.nbchan,  prob_sd_thresh, prob_sd_thresh, 0, 1, 0, [], 0);

    fprintf('Dopo reject EEG -> standard: %d | exemplar: %d | function: %d\n', ...
        EEG_std.trials, EEG_ex.trials, EEG_fn.trials);

    %% -------------------------------------------------------------------
    % 4R) ERP MEDI
    % --------------------------------------------------------------------
    ERP = struct();
    ERP.standard = mean(EEG_std.data, 3);
    ERP.exemplar = mean(EEG_ex.data, 3);
    ERP.function = mean(EEG_fn.data, 3);
    ERP.times_ms = EEG_std.times;
    ERP.chanlocs = EEG_std.chanlocs;

    %% -------------------------------------------------------------------
    % 4S) INDICI COMPORTAMENTALI BASE
    % --------------------------------------------------------------------
    behavior = struct();
    behavior.median_rt_ex = NaN;
    behavior.median_rt_fn = NaN;
    behavior.acc_ex = NaN;
    behavior.acc_fn = NaN;
    behavior.IES_ex = NaN;
    behavior.IES_fn = NaN;
    behavior.logIES = NaN;

    % Placeholder: da completare solo quando ricostruiamo i trial con risposta.
    if ismember('response_time_num', T_events.Properties.VariableNames)
        ex_rt_raw = T_events.response_time_num(contains(T_events.value, "Correct - Exemplar!"));
        fn_rt_raw = T_events.response_time_num(contains(T_events.value, "Correct - Function!"));

        ex_rt_raw = ex_rt_raw(~isnan(ex_rt_raw) & ex_rt_raw >= rt_min_sec);
        fn_rt_raw = fn_rt_raw(~isnan(fn_rt_raw) & fn_rt_raw >= rt_min_sec);

        if ~isempty(ex_rt_raw)
            behavior.median_rt_ex = median(ex_rt_raw);
        end
        if ~isempty(fn_rt_raw)
            behavior.median_rt_fn = median(fn_rt_raw);
        end
    end

    %% -------------------------------------------------------------------
    % 4T) SALVATAGGIO OUTPUT
    % --------------------------------------------------------------------
    EEG_std.setname = [base_prefix '_epochs_standard'];
    EEG_ex.setname  = [base_prefix '_epochs_exemplar'];
    EEG_fn.setname  = [base_prefix '_epochs_function'];

    pop_saveset(EEG_std, 'filename', [EEG_std.setname '.set'], 'filepath', subj_out);
    pop_saveset(EEG_ex,  'filename', [EEG_ex.setname  '.set'], 'filepath', subj_out);
    pop_saveset(EEG_fn,  'filename', [EEG_fn.setname  '.set'], 'filepath', subj_out);

    save(fullfile(subj_out, [base_prefix '_ERP_behavior.mat']), ...
         'ERP', 'behavior', 'T_events', 'T_epoch', 'cond_label');

    %% -------------------------------------------------------------------
    % 4U) REPORT TESTUALE SOGGETTO
    % --------------------------------------------------------------------
    fid = fopen(fullfile(subj_out, [base_prefix '_report.txt']), 'w');

    fprintf(fid, 'Subject: %s\n', base_prefix);
    fprintf(fid, 'Original srate: %.2f Hz\n', orig_srate);
    fprintf(fid, 'Target srate: %d Hz\n', target_fs);
    fprintf(fid, 'Original channels: %d\n', orig_nbchan);
    fprintf(fid, 'Band-pass: %.2f - %.2f Hz\n', bp_low, bp_high);
    fprintf(fid, 'Epoch window: %.1f to %.1f s\n', epoch_window_sec(1), epoch_window_sec(2));
    fprintf(fid, 'Baseline: %d to %d ms\n', baseline_window_ms(1), baseline_window_ms(2));
    fprintf(fid, 'Events used for epoching - standard: %d\n', sum(cond_label == "std_chord2"));
    fprintf(fid, 'Events used for epoching - exemplar: %d\n', sum(cond_label == "ex_chord2"));
    fprintf(fid, 'Events used for epoching - function: %d\n', sum(cond_label == "fn_chord2"));
    fprintf(fid, 'Trials finali - standard: %d\n', EEG_std.trials);
    fprintf(fid, 'Trials finali - exemplar: %d\n', EEG_ex.trials);
    fprintf(fid, 'Trials finali - function: %d\n', EEG_fn.trials);
    fprintf(fid, 'ICA components removed: %d\n', numel(comps_to_remove));
    fprintf(fid, 'Median RT exemplar: %.6f\n', behavior.median_rt_ex);
    fprintf(fid, 'Median RT function: %.6f\n', behavior.median_rt_fn);

    fclose(fid);

    clear EEG EEG_ica EEG_std EEG_ex EEG_fn ERP behavior T_events T_epoch cond_label ...
          bad_from_tsv event_vals is_boundary is_statusnum is_one is_two ...
          is_standard is_exemplar is_function is_feedback is_epoch_event epoch_vals ...
          comps_to_remove orig_srate orig_nbchan
end