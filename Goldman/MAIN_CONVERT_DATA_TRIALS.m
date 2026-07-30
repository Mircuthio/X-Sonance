% ========================================================================
% MAIN CONVERT - OUTPUT DATA_TRIALS
% Estrae i data_trials dai file epocati già salvati in output_root
% ========================================================================
clear; close all; clc;

%% =======================================================================
% 1) PATH
% ========================================================================
output_root = 'D:\X-SONANCE\Goldman\Output';
eeglab_path = 'D:\eeglab2023.1\';
addpath(eeglab_path);
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; 

data_trials_out = fullfile(output_root, 'DATA_TRIALS');
if ~exist(data_trials_out, 'dir')
    mkdir(data_trials_out);
end

%% =======================================================================
% 2) CERCA FILE EPOCH
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
% 3) LOOP SOGGETTI
% ========================================================================
for s = 1:nSubj

    EEG_std = pop_loadset('filename', std_files(s).name, 'filepath', std_files(s).folder);
    EEG_ex  = pop_loadset('filename', ex_files(s).name,  'filepath', ex_files(s).folder);
    EEG_fn  = pop_loadset('filename', fn_files(s).name,  'filepath', fn_files(s).folder);

    subject_name = regexprep(std_files(s).name, '_epochs_standard\.set$', '');
    fprintf('\nProcessing subject %d/%d: %s\n', s, nSubj, subject_name);

    data_trials = struct( ...
        'trialId',   {}, ...
        'eeg',       {}, ...
        'time',      {}, ...
        'events',    {}, ...
        'trialType', {}, ...
        'trialName', {}, ...
        'chanloc',   {} );

    trial_counter = 0;

    % ---------------------------------------------------------------
    % STANDARD
    % ---------------------------------------------------------------
    data_trials = append_condition_trials(data_trials, EEG_std, 1, 'standard', trial_counter);
    trial_counter = numel(data_trials);

    % ---------------------------------------------------------------
    % EXEMPLAR
    % ---------------------------------------------------------------
    data_trials = append_condition_trials(data_trials, EEG_ex, 2, 'exemplar', trial_counter);
    trial_counter = numel(data_trials);

    % ---------------------------------------------------------------
    % FUNCTION
    % ---------------------------------------------------------------
    data_trials = append_condition_trials(data_trials, EEG_fn, 3, 'function', trial_counter);

    % ---------------------------------------------------------------
    % CHANLOCS: salvali solo nel primo elemento
    % ---------------------------------------------------------------
    if ~isempty(data_trials)
        data_trials(1).chanloc = EEG_std.chanlocs;
        if numel(data_trials) > 1
            [data_trials(2:end).chanloc] = deal([]);
        end
    end

    out_file = fullfile(data_trials_out, [subject_name '_data_trials.mat']);
    save(out_file, 'data_trials', '-v7.3');

    fprintf('  Salvato: %s\n', out_file);
    fprintf('  Numero totale trial: %d\n', numel(data_trials));
end

fprintf('\nConversione completata. File salvati in:\n%s\n', data_trials_out);

%% =======================================================================
% FUNZIONE LOCALE
% ========================================================================
function data_trials = append_condition_trials(data_trials, EEG, trialTypeValue, trialNameValue, start_idx)

    nTrials = EEG.trials;
    time_vec = EEG.times(:)';  % vettore riga

    for k = 1:nTrials
        idx = start_idx + k;

        data_trials(idx).trialId    = idx;
        data_trials(idx).eeg        = EEG.data(:,:,k);   % channels x time
        data_trials(idx).time       = time_vec;
        data_trials(idx).trialType  = trialTypeValue;
        data_trials(idx).trialName  = trialNameValue;
        data_trials(idx).events     = build_events_struct(EEG, k, time_vec);
        data_trials(idx).chanloc    = [];
    end
end

function ev = build_events_struct(EEG, k, time_vec)

    ev = struct();
    ev.tstart = time_vec(1);
    ev.tstop  = time_vec(end);

    zero_idx = find(time_vec == 0, 1);
    if isempty(zero_idx)
        [~, zero_idx] = min(abs(time_vec));
    end
    ev.ttarget = time_vec(zero_idx);

    if isfield(EEG, 'epoch') && numel(EEG.epoch) >= k
        ev.epoch = EEG.epoch(k);
    else
        ev.epoch = [];
    end
end