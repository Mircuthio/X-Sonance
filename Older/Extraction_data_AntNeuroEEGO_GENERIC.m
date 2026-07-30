% Extraction_data_AntNeuroEEGO_GENERIC.m
% FLUSSO UNICO COERENTE CON IL TUO ESPERIMENTO
% - baseline occhi aperti iniziale
% - trial continui con marker start / sound / end
% - preprocessing e ICA sul continuo del soggetto
% - estrazione successiva delle epoche consonante / dissonante
% - nessuna ICA separata training/test

clear; close all; clc

%% ============================================================
% 1) PATH E DIPENDENZE
% ============================================================
% Cartella dei dati grezzi esportati da EEGO mylab
raw_dir = 'E:\AntNeuro_Project\Data_raw\';

% Cartella di output per i file finali
output_dir = 'E:\AntNeuro_Project\ERP_analysis\Extracted\';

% Path locale di EEGLAB
addpath(genpath('D:\eeglab2023.1\'))

if ~exist(output_dir,'dir')
    mkdir(output_dir)
end

%% ============================================================
% 2) PARAMETRI SPERIMENTALI
% ============================================================
% Inserisci qui i codici reali dei marker del tuo esperimento.
% Questi sono solo segnaposto e vanno adattati ai trigger effettivi.
marker_baseline        = 'BASELINE_EO';   % baseline occhi aperti iniziale
marker_trial_start     = 'TRIAL_START';   % inizio trial
marker_sound_con       = 'SOUND_CON';     % suono consonante
marker_sound_dis       = 'SOUND_DIS';     % suono dissonante
marker_trial_end       = 'TRIAL_END';     % fine trial

% Epoche per l'analisi ERP / time-frequency sul suono
epoch_window = [-0.2 0.8];   % 200 ms pre-stimolo, 800 ms post-stimolo

% Parametri di filtro
% Scelta coerente con il tuo dubbio precedente:
% - per non tagliare la gamma, manteniamo una banda ampia per il dato analitico
% - per ICA, useremo un dataset filtrato adatto alla decomposizione
analysis_lowcut = 1;
analysis_highcut = 90;
ica_lowcut = 1;
ica_highcut = 45;   % filtro più conservativo solo per aiutare l'ICA

% Downsampling
target_fs = 250;

%% ============================================================
% 3) RICERCA FILE
% ============================================================
files_cnt = dir(fullfile(raw_dir,'*.cnt'));
files_set = dir(fullfile(raw_dir,'*.set'));
files_mat = dir(fullfile(raw_dir,'*.mat'));
files = [files_cnt; files_set; files_mat];
names = {files(:).name};

%% ============================================================
% 4) LOOP SOGGETTO PER SOGGETTO
% ============================================================
for n = 1:numel(names)
    [~, base_filename, ext] = fileparts(names{n});
    fprintf('\nProcessing file %d/%d: %s\n', n, numel(names), names{n});

    %% --------------------------------------------------------
    % 4A) CARICAMENTO DEL DATO GREZZO
    % --------------------------------------------------------
    switch lower(ext)
        case '.cnt'
            EEG = pop_loadcnt(fullfile(raw_dir, names{n}));
        case '.set'
            EEG = pop_loadset('filename', names{n}, 'filepath', raw_dir);
        case '.mat'
            tmp = load(fullfile(raw_dir, names{n}));
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

    %% --------------------------------------------------------
    % 4B1) CONTROLLO EVENTI
    % --------------------------------------------------------
    % Qui i marker devono già essere presenti nel file importato.
    % Baseline, inizio trial, suono e fine trial vengono usati per
    % separare il flusso sperimentale solo dopo il preprocessing.
    if ~isfield(EEG,'event') || isempty(EEG.event)
        warning('Nessun evento trovato in %s. Saltato.', names{n});
        continue
    end
    %% --------------------------------------------------------
    % 4B2) CANALE EYE-BLINK / EOG
    % --------------------------------------------------------
    eye_blink_labels = {'EYE_BLINK','VEOG','EOG','Blink','LHEOG','RHEOG'};
    if isfield(EEG,'chanlocs') && ~isempty(EEG.chanlocs)
        existing_labels = {EEG.chanlocs.labels};
        blink_channel = intersect(eye_blink_labels, existing_labels, 'stable');
        if ~isempty(blink_channel)
            fprintf('Canale eye-blink trovato: %s\n', blink_channel{1});
            idx_blink = find(strcmpi(existing_labels, blink_channel{1}), 1);
            EEG.etc.eye_blink_channel = blink_channel{1};
            EEG.etc.eye_blink_index = idx_blink;
        else
            warning('Nessun canale eye-blink trovato nel file %s.', names{n});
        end
    end
    %% --------------------------------------------------------
    % 4C) RIMOZIONE CANALI NON EEG
    % --------------------------------------------------------
    % Elimina canali ausiliari che non vuoi portare nel preprocessing.
    % Adatta la lista ai nomi reali del tuo montaggio.
    removable_channels = {'LHEOG','RHEOG','VEOGup','VEOGdown','HEOG','VEOG','audio','AUDIO','TRIG'};
    if isfield(EEG,'chanlocs') && ~isempty(EEG.chanlocs)
        existing_labels = {EEG.chanlocs.labels};
        channels_to_remove = removable_channels(ismember(removable_channels, existing_labels));
        if ~isempty(channels_to_remove)
            EEG = pop_select(EEG, 'rmchannel', channels_to_remove);
        end
    end

    %% --------------------------------------------------------
    % 4D) STANDARDIZZAZIONE CANALE DI RIFERIMENTO
    % --------------------------------------------------------
    % Se il tuo export usa RM come etichetta, lo rinominiamo a M2.
    chan_labels = {EEG.chanlocs.labels};
    if any(strcmpi(chan_labels, 'RM'))
        idx_rm = find(strcmpi(chan_labels, 'RM'), 1);
        EEG.chanlocs(idx_rm).labels = 'M2';
    end
    %% --------------------------------------------------------
    % 4E0) NOTCH FILTER LINE NOISE
    % --------------------------------------------------------
    % Utile se hai rumore di rete a 50 Hz.
    % Lo inseriamo prima del filtro di analisi.
    EEG = pop_eegfiltnew(EEG, 'locutoff', 45, 'hicutoff', 55, ...
        'revfilt', 1, 'plotfreqz', 0);
    %% --------------------------------------------------------
    % 4E) FILTRO DEL DATO GREZZO PER L'ANALISI FINALE
    % --------------------------------------------------------
    % Questo è il dataset che vuoi conservare per l'analisi finale.
    % Manteniamo il contenuto fino a 90 Hz perché hai detto che vuoi
    % poter analizzare anche gamma oltre 45 Hz.
    EEG = pop_eegfiltnew(EEG, 'locutoff', analysis_lowcut, 'hicutoff', analysis_highcut, 'plotfreqz', 0);

    %% --------------------------------------------------------
    % 4F) RESAMPLE
    % --------------------------------------------------------
    % Riduce il peso computazionale e mantiene ampia copertura spettrale.
    EEG = pop_resample(EEG, target_fs);
    %% --------------------------------------------------------
    % 4F1) DETRENDING / CENTERING
    % --------------------------------------------------------
    % Rimuove offset e drift lenti canale per canale sul continuo.
    % Utile prima dell'ICA per rendere il segnale più stabile.
    EEG.data = double(EEG.data);
    for ch = 1:size(EEG.data,1)
        EEG.data(ch,:) = detrend(EEG.data(ch,:), 'linear');
        EEG.data(ch,:) = EEG.data(ch,:) - mean(EEG.data(ch,:));
    end
    EEG = eeg_checkset(EEG);
    %% --------------------------------------------------------
    % 4G) REREFERENCE
    % --------------------------------------------------------
    % Qui uso average reference come scelta semplice e coerente.
    % Se vuoi un riferimento diverso, lo cambi qui.
    EEG = pop_reref(EEG, []);

    %% --------------------------------------------------------
    % 4H) SALVATAGGIO DI UNA COPIA DEL DATO EEG COMPLETO
    % --------------------------------------------------------
    % Dopo filtri, resample, detrending e rereference, salviamo una copia
    % del dataset EEG completo (senza canali ausiliari non EEG).
    fullEEG = EEG;

    %% --------------------------------------------------------
    % 4I) IDENTIFICAZIONE E RIMOZIONE BAD CHANNELS ASR
    % --------------------------------------------------------
    % Qui puoi sostituire questa parte con criterio manuale o automatico.
    % Esempio: uso clean_rawdata solo per identificare/rimuovere canali scadenti.
    EEG_ica = EEG;

    EEG_ica = pop_clean_rawdata(EEG_ica, ...
        'FlatlineCriterion', 5, ...
        'ChannelCriterion', 0.8, ...
        'LineNoiseCriterion', 4, ...
        'Highpass', 'off', ...
        'BurstCriterion', 'off', ...
        'WindowCriterion', 'off', ...
        'BurstRejection', 'off', ...
        'Distance', 'Euclidian');

    % Salviamo quali canali sono rimasti dopo la rimozione
    good_labels = {EEG_ica.chanlocs.labels};
    full_labels = {fullEEG.chanlocs.labels};
    bad_mask = ~ismember(full_labels, good_labels);
    bad_labels = full_labels(bad_mask);

    fprintf('Bad channels rimossi prima della ICA: %s\n', strjoin(bad_labels, ', '));

    %% --------------------------------------------------------
    % 4J) DATASET DI SUPPORTO PER ICA
    % --------------------------------------------------------
    % Applichiamo il filtro più conservativo solo al dataset usato per ICA.
    EEG_ica = pop_eegfiltnew(EEG_ica, ...
        'locutoff', ica_lowcut, 'hicutoff', ica_highcut, 'plotfreqz', 0);

    %% --------------------------------------------------------
    % 4K) ICA SUL CONTINUO CON I SOLI CANALI BUONI
    % --------------------------------------------------------
    EEG_ica = pop_runica(EEG_ica, 'icatype', 'runica', 'extended', 1, 'interrupt', 'on');

    %% --------------------------------------------------------
    % 4L) IDENTIFICAZIONE COMPONENTI ARTEFATTUALI
    % --------------------------------------------------------
    EEG_ica = pop_iclabel(EEG_ica, 'default');
    EEG_ica = pop_icflag(EEG_ica, [NaN NaN; 0.9 1; 0.9 1; 0.9 1; 0.9 1; 0.9 1; NaN NaN]);

    %% --------------------------------------------------------
    % 4M) PREPARAZIONE DEL DATO ORIGINALE SUGLI STESSI CANALI DELLA ICA
    % --------------------------------------------------------
    % Per applicare i pesi ICA, il dataset deve avere gli stessi canali usati
    % nella decomposizione.
    originalEEG = pop_select(fullEEG, 'channel', good_labels);

    originalEEG.icaweights  = EEG_ica.icaweights;
    originalEEG.icasphere   = EEG_ica.icasphere;
    originalEEG.icawinv     = EEG_ica.icawinv;
    originalEEG.icachansind = EEG_ica.icachansind;
    originalEEG.etc.ic_classification = EEG_ica.etc.ic_classification;
    originalEEG.reject.gcompreject = EEG_ica.reject.gcompreject;

    originalEEG = eeg_checkset(originalEEG);
    originalEEG = eeg_checkset(originalEEG, 'ica');

    %% --------------------------------------------------------
    % 4N) RIMOZIONE COMPONENTI ARTEFATTUALI
    % --------------------------------------------------------
    if isfield(originalEEG.reject, 'gcompreject') && ~isempty(originalEEG.reject.gcompreject)
        originalEEG = pop_subcomp(originalEEG, find(originalEEG.reject.gcompreject), 0);
    end

    %% --------------------------------------------------------
    % 4O) INTERPOLAZIONE DEI BAD CHANNELS
    % --------------------------------------------------------
    % Dopo la rimozione dei bad ICs, riportiamo il montaggio completo.
    cleanEEG = pop_interp(originalEEG, fullEEG.chanlocs, 'spherical');

    %% --------------------------------------------------------
    % 4P) METADATI SUI BAD CHANNELS
    % --------------------------------------------------------
    cleanEEG.etc.bad_channels_removed_preICA = bad_labels;
    cleanEEG.etc.good_channels_for_ICA = good_labels;

    %% --------------------------------------------------------
    % 4R) SAVE CLEAN CONTINUOUS DATA
    % --------------------------------------------------------
    subjectData = struct();
    subjectData.subjectID = subjName;
    subjectData.cleanContinuous = cleanEEG;

    %% --------------------------------------------------------
    % 4S) EXTRACT BASELINE SEGMENTS
    % --------------------------------------------------------
    % Assumes baseline events are already present in EEG.event
    % Example event labels: 'baseline_open', 'baseline_closed'
    baselineLabels = {'baseline_open', 'baseline_closed'};
    baselineWindowSec = [0 2];   % example: take 2 s after baseline marker

    baselineSegments = struct();
    baselineCount = 0;

    for ev = 1:numel(cleanEEG.event)
        if ismember(string(cleanEEG.event(ev).type), string(baselineLabels))
            latency = round(cleanEEG.event(ev).latency);
            s1 = latency + round(baselineWindowSec(1) * cleanEEG.srate);
            s2 = latency + round(baselineWindowSec(2) * cleanEEG.srate) - 1;

            if s1 >= 1 && s2 <= size(cleanEEG.data, 2)
                baselineCount = baselineCount + 1;
                baselineSegments(baselineCount).label = char(string(cleanEEG.event(ev).type));
                baselineSegments(baselineCount).eventIndex = ev;
                baselineSegments(baselineCount).latency = latency;
                baselineSegments(baselineCount).srate = cleanEEG.srate;
                baselineSegments(baselineCount).time = (0:(s2-s1)) / cleanEEG.srate;
                baselineSegments(baselineCount).eeg = cleanEEG.data(:, s1:s2);
                baselineSegments(baselineCount).chanlocs = cleanEEG.chanlocs;
            end
        end
    end

    subjectData.baselineSegments = baselineSegments;

    %% --------------------------------------------------------
    % 4T) EXTRACT FULL TRIALS FROM CONTINUOUS EEG
    % --------------------------------------------------------
    % Assumes trial structure is delimited by trial start / trial end events
    trialStartLabel = 'trial_start';
    trialEndLabel   = 'trial_end';

    allTypes = string({cleanEEG.event.type});
    startIdx = find(allTypes == trialStartLabel);
    endIdx   = find(allTypes == trialEndLabel);

    datatrials = struct([]);
    trialCount = 0;

    for i = 1:numel(startIdx)
        sEv = startIdx(i);
        sLat = round(cleanEEG.event(sEv).latency);

        % find first end event after this start
        eCandidates = endIdx(endIdx > sEv);
        if isempty(eCandidates)
            continue;
        end
        eEv = eCandidates(1);
        eLat = round(cleanEEG.event(eEv).latency);

        if eLat <= sLat
            continue;
        end

        trialCount = trialCount + 1;
        sampleIdx = sLat:eLat;
        timeVec = (sampleIdx - sLat) / cleanEEG.srate;

        % collect internal events within this trial
        inTrial = find([cleanEEG.event.latency] >= sLat & [cleanEEG.event.latency] <= eLat);

        trialEvents = struct([]);
        for k = 1:numel(inTrial)
            evIdx = inTrial(k);
            trialEvents(k).type = cleanEEG.event(evIdx).type;
            trialEvents(k).latency_samples = round(cleanEEG.event(evIdx).latency - sLat + 1);
            trialEvents(k).latency_sec = (cleanEEG.event(evIdx).latency - sLat) / cleanEEG.srate;
            if isfield(cleanEEG.event, 'duration')
                trialEvents(k).duration = cleanEEG.event(evIdx).duration;
            end
        end

        datatrials(trialCount).trialId = trialCount;
        datatrials(trialCount).subjectID = subjName;
        datatrials(trialCount).eeg = cleanEEG.data(:, sampleIdx);
        datatrials(trialCount).time = timeVec;
        datatrials(trialCount).events = trialEvents;
        datatrials(trialCount).trialStartSample = sLat;
        datatrials(trialCount).trialEndSample = eLat;
        datatrials(trialCount).srate = cleanEEG.srate;
        datatrials(trialCount).chanlocs = cleanEEG.chanlocs;
        datatrials(trialCount).trialType = NaN;
        datatrials(trialCount).trialName = '';
    end

    subjectData.datatrials = datatrials;

    %% --------------------------------------------------------
    % 4U) OPTIONAL: SAVE CLEAN SUBJECT OUTPUT
    % --------------------------------------------------------
    save(fullfile(outDir, [subjName '_subjectData_clean.mat']), 'subjectData', '-v7.3');
end