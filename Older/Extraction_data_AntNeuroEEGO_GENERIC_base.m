% Extraction_data_AntNeuroEEGO_GENERIC_base.m
% MAIN GENERICO per export Ant Neuro / EEGO mylab
% Questo script e' volutamente generale: nei punti critici sono indicati
% i campi da controllare, completare o sostituire in base al tuo dataset.

clear; close all; clc

%% =========================
% 1) PATH E DIPENDENZE
% ==========================
% DA INSERIRE: cartella dei dati grezzi esportati da EEGO mylab
raw_dir = 'E:\AntNeuro_Project\Data_raw\';

% DA INSERIRE: cartella di output per i file finali .mat
output_dir = 'E:\AntNeuro_Project\ERP_analysis\Extracted\';

% DA INSERIRE: path locale di EEGLAB
addpath(genpath('D:\eeglab2023.1\'))

if ~exist(output_dir,'dir')
    mkdir(output_dir)
end

%% =========================
% 2) RICERCA FILE
% ==========================
% PUNTO CRITICO:
% Verificare il formato reale esportato da EEGO mylab.
% I piu' probabili candidati sono .cnt, .set, .mat.
% Se il tuo export reale e' diverso, aggiungi qui l'estensione corretta.
files_cnt = dir(fullfile(raw_dir,'*.cnt'));
files_set = dir(fullfile(raw_dir,'*.set'));
files_mat = dir(fullfile(raw_dir,'*.mat'));
files = [files_cnt; files_set; files_mat];

names = {files(:).name};

%% =========================
% 3) LOOP SOGGETTI / FILE
% ==========================
for n = 1:numel(names)
    [~, base_filename, ext] = fileparts(names{n});
    fprintf('\nProcessing file %d/%d: %s\n', n, numel(names), names{n});
    
    %% -------------------------
    % 3A) LOAD DATA
    % --------------------------
    % PUNTO CRITICO:
    % Devi usare il loader giusto in base al formato reale in uscita da EEGO mylab.
    % Se i tuoi file non sono compatibili con questi loader, va sostituito questo blocco.
    switch lower(ext)
        case '.cnt'
            EEG = pop_loadcnt(fullfile(raw_dir, names{n}));
            
        case '.set'
            EEG = pop_loadset('filename', names{n}, 'filepath', raw_dir);
            
        case '.mat'
            tmp = load(fullfile(raw_dir, names{n}));
            % PUNTO CRITICO:
            % Qui si assume che il .mat contenga una variabile EEG compatibile con EEGLAB.
            % Se il tuo .mat ha un'altra struttura, va mappato manualmente.
            if isfield(tmp,'EEG')
                EEG = tmp.EEG;
            else
                warning('Il file %s non contiene una variabile EEG compatibile. Saltato.', names{n});
                continue
            end
            
        otherwise
            warning('Formato non supportato: %s', names{n});
            continue
    end
    
    %% -------------------------
    % 3B) CONTROLLO EVENTI / MARKER
    % --------------------------
    % PUNTO CRITICO:
    % Qui devi controllare come sono codificati i trigger nel tuo export:
    % - stringhe? es. 'S221'
    % - numeri? es. 221
    % - descrizioni testuali?
    % Verifica con: {EEG.event.type}
    
    %% -------------------------
    % 3C) RIMOZIONE CANALI NON EEG
    % --------------------------
    % PUNTO CRITICO:
    % Questa lista e' SOLO un esempio. Devi adattarla ai nomi reali del tuo montaggio.
    removable_channels = {'LHEOG','RHEOG','VEOGup','VEOGdown','HEOG','VEOG','audio','AUDIO','TRIG'};
    
    if isfield(EEG,'chanlocs') && ~isempty(EEG.chanlocs)
        existing_labels = {EEG.chanlocs.labels};
        channels_to_remove = removable_channels(ismember(removable_channels, existing_labels));
        if ~isempty(channels_to_remove)
            EEG = pop_select(EEG, 'rmchannel', channels_to_remove);
        end
    end
    
    %% -------------------------
    % 3D) FILTRO
    % --------------------------
    % PUNTO CRITICO:
    % Qui devi decidere il filtro in base al tuo obiettivo.
    % Esempio ERP classico: 0.1 - 30/40 Hz. 1-45/90 per Consonance/Dissonance
    % Se fai ICA, a volte conviene creare un dataset dedicato con high-pass piu' alto.
    EEG = pop_eegfiltnew(EEG, 'locutoff', 0.1, 'hicutoff', 40, 'plotfreqz', 0);
    
    %% -------------------------
    % 3E) RESAMPLE
    % --------------------------
    % PUNTO CRITICO:
    % 250 Hz e' spesso sufficiente per ERP, ma controlla il tuo protocollo.
    EEG = pop_resample(EEG, 250); 
    
    %% -------------------------
    % 3F) RINOMINA / STANDARDIZZA CANALI
    % --------------------------
    % PUNTO CRITICO:
    % Qui puoi uniformare etichette come RM -> M2 oppure altri alias.
    if any(contains({EEG.chanlocs.labels}, 'RM'))
        idx_rm = find(contains({EEG.chanlocs.labels}, 'RM'), 1, 'first');
        EEG.chanlocs(idx_rm).labels = 'M2';
    end
    
    %% -------------------------
    % 3G) MONTAGGIO / CHANNEL LOCATIONS
    % --------------------------
    % PUNTO CRITICO:
    % Se il file esportato da EEGO mylab non contiene chanlocs corretti,
    % qui devi caricare il file di locazioni giusto.
    % Esempio:
    % EEG = pop_chanedit(EEG, 'lookup', '...standard-10-5-cap385.elp');
    
    %% -------------------------
    % 3H) RIFERIMENTO
    % --------------------------
    % PUNTO CRITICO:
    % Devi decidere il riferimento coerente col tuo studio:
    % - mastoidi medie
    % - average reference
    % - altro
    % Se manca M1/M2, vanno gestiti qui.
    chan_labels = {EEG.chanlocs.labels};
    
    if ~ismember('M1', chan_labels)
        % ESEMPIO: aggiunta canale reference virtuale
        % DA CONTROLLARE: coordinate e coerenza con il tuo montaggio
        EEG = pop_chanedit(EEG, 'append', EEG.nbchan, ...
            'changefield', {EEG.nbchan+1 'labels' 'M1'}, ...
            'lookup', 'D:\eeglab2023.1\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp');
    end
    
    % ESEMPIO di re-reference: da adattare
    try
        EEG = pop_reref(EEG, [], 'refloc', struct('labels', {'M1'}, 'type', {'EEG'}));
    catch
        warning('Re-reference con refloc non riuscito per %s', names{n});
    end
    
    chan_labels = {EEG.chanlocs.labels};
    idx_m1 = find(strcmpi(chan_labels, 'M1'));
    idx_m2 = find(strcmpi(chan_labels, 'M2'));
    if ~isempty(idx_m1) && ~isempty(idx_m2)
        EEG = pop_reref(EEG, [idx_m1 idx_m2]);
    end
    
    originalEEG = EEG;
    
    %% -------------------------
    % 3I) CLEANING / ASR
    % --------------------------
    % PUNTO CRITICO:
    % Parametri da adattare in base a rumore, durata e qualita' dati.
    EEG = pop_clean_rawdata(EEG, ...
        'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.8, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', 'off', ...
        'BurstCriterion', 20, ...
        'WindowCriterion', 'off', ...
        'BurstRejection', 'off', ...
        'Distance', 'Euclidian');
    
    %% -------------------------
    % 3L) INTERPOLAZIONE
    % --------------------------
    EEG = pop_interp(EEG, originalEEG.chanlocs, 'spherical');
    
    %% -------------------------
    % 3M) DATASET DI TRAINING PER ICA
    % --------------------------
    % PUNTO CRITICO:
    % Questo e' un punto fortemente dipendente dai tuoi marker reali.
    % Qui sotto e' solo un esempio con due trigger fittizi.
    % Devi sostituire con i marker del tuo esperimento.
    trigger_cond1 = 'S221';   % DA SOSTITUIRE
    trigger_cond2 = 'S222';   % DA SOSTITUIRE
    
    if any(strcmp({EEG.event.type}, trigger_cond1))
        training_cond1 = pop_rmdat(EEG, {trigger_cond1}, [-5 654], 0);
    else
        training_cond1 = EEG;
    end
    
    if any(strcmp({EEG.event.type}, trigger_cond2))
        training_cond2 = pop_rmdat(EEG, {trigger_cond2}, [-5 671], 0);
    else
        training_cond2 = EEG;
    end
    
    %% -------------------------
    % 3N) ICA
    % --------------------------
    % PUNTO CRITICO:
    % Verifica se vuoi una ICA unica o separate per condizioni/blocchi.
    trainCOND1_ica = pop_runica(training_cond1, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');
    trainCOND2_ica = pop_runica(training_cond2, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');
    
    %% -------------------------
    % 3O) ICLABEL E FLAGGING
    % --------------------------
    % PUNTO CRITICO:
    % Le soglie 0.9 sono conservative ma vanno validate sul tuo dataset.
    EEG_dataCOND1 = pop_iclabel(trainCOND1_ica, 'default');
    EEG_dataCOND2 = pop_iclabel(trainCOND2_ica, 'default');
    
    EEG_dataCOND1 = pop_icflag(EEG_dataCOND1, [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;NaN NaN]);
    EEG_dataCOND2 = pop_icflag(EEG_dataCOND2, [NaN NaN;0.9 1;0.9 1;0.9 1;0.9 1;0.9 1;NaN NaN]);
    
    EEG_dataCOND1 = pop_subcomp(EEG_dataCOND1, [], 0);
    EEG_dataCOND2 = pop_subcomp(EEG_dataCOND2, [], 0);
    
    fs = EEG_dataCOND1.srate;
    
    %% -------------------------
    % 3P) ORGANIZZAZIONE DATI FINALI
    % --------------------------
    % PUNTO CRITICO:
    % Qui puoi cambiare la struttura finale in base alle tue analisi future.
    % Ad esempio: trial-by-trial, condizioni musicali, congruente/incongruente, ecc.
    data = struct();
    
    data(1).eeg = EEG_dataCOND1.data;
    data(2).eeg = EEG_dataCOND2.data;
    
    data(1).trialinfo = 1;
    data(2).trialinfo = 2;
    
    data(1).fs = fs;
    data(2).fs = fs;
    
    time_cond1 = size(EEG_dataCOND1.data,2) / fs;
    time_cond2 = size(EEG_dataCOND2.data,2) / fs;
    
    data(1).time = linspace(0, time_cond1, size(EEG_dataCOND1.data,2));
    data(2).time = linspace(0, time_cond2, size(EEG_dataCOND2.data,2));
    
    % DA SOSTITUIRE con i nomi reali delle classi
    data(1).class_indices = 'COND1';
    data(2).class_indices = 'COND2';
    
    for nTrial = 1:2
        data(nTrial).Tab_duration = NaN;
        data(nTrial).Tab_final = NaN;
    end
    
    %% -------------------------
    % 3Q) SAVE
    % --------------------------
    out_name = [base_filename '_dictionary.mat'];
    save(fullfile(output_dir, out_name), 'data')
    
    clear EEG originalEEG tmp training_cond1 training_cond2 trainCOND1_ica trainCOND2_ica EEG_dataCOND1 EEG_dataCOND2 data
end