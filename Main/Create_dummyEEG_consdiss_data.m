%% ============================================================
%  function Create_dummyEEG_consdiss_data(cfg)
%% ============================================================
function subj_list = Create_dummyEEG_consdiss_data(cfg)
%% PARAMETRI
nSub = cfg.nSub;
condNames = cfg.condNames;
nCond = numel(condNames);
nTrialPerCond = cfg.nTrialPerCond;
tstart = cfg.tstart;
tend = cfg.tend;
chanLabels = cfg.chanLabels;
nChan = numel(chanLabels);

time = tstart:4:tend;              % ms, tempo zero-allineato
time_raw = 1:numel(time);       % placeholder realistico
nTime = numel(time);

subj_list = struct('subj_id', cell(nSub,1), 'data_trials', cell(nSub,1));

%% COSTRUZIONE SUBJECT-WISE
for iSub = 1:nSub

    subj_id = sprintf('subj_%02d', iSub);
    data_trials = struct([]);
    k = 0;

    % piccolo jitter soggetto-specifico
    subjNoiseScale = 1.5 + 0.3*randn(1);

    for iCond = 1:nCond
        condName = condNames{iCond};

        for iTr = 1:nTrialPerCond
            k = k + 1;

            % rumore di base
            eeg = subjNoiseScale * randn(nChan, nTime);

            % drift lento
            eeg = eeg + 0.2 * sin(linspace(0, 2*pi, nTime));

            % effetto ERP artificiale
            % dissonant più negativo tra 120 e 180 ms su Fz/FCz/Cz
            if strcmp(condName, 'dissonant')
                idxEff = time >= 120 & time <= 180;
                effectShape = -3 * exp(-((time(idxEff)-150).^2)/(2*20^2));
                eeg(1:3, idxEff) = eeg(1:3, idxEff) + repmat(effectShape, 3, 1);
            end

            % piccola variabilità trial-by-trial
            eeg = eeg + 0.3 * randn(size(eeg));

            % evento principale del trial
            events = struct([]);
            events(1).type = 'target';
            events(1).label = condName;
            events(1).latency_raw = find(time == 0, 1, 'first');
            events(1).latency_zero = 0;

            % opzionale: evento antecedente
            events(2).type = 'sequence_end';
            events(2).label = 'pretarget';
            events(2).latency_raw = find(time == -100, 1, 'first');
            events(2).latency_zero = -100;

            % trial struct
            data_trials(k).trialId     = k;
            data_trials(k).trialName   = condName;
            data_trials(k).trialType   = condName;
            data_trials(k).eeg         = eeg;
            data_trials(k).time        = time;
            data_trials(k).time_raw    = time_raw;
            data_trials(k).events      = events;
            data_trials(k).chanLabels  = chanLabels;
        end
    end

    subj_list(iSub).subj_id = subj_id;
    subj_list(iSub).data_trials = data_trials;

    fprintf('Subject %s with %d trial\n', subj_id, numel(data_trials));
end

%% SAVE OPZIONALE
save(sprintf('subj_list_%d.mat',nSub), 'subj_list');