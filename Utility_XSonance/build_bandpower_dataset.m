function BandPower_Dataset = ...
    build_bandpower_dataset( ...
    subj_list,...
    cfgBP)

%% ============================================================
% INITIALIZATION
%% ============================================================

dataset_trials = struct([]);
trialCounter = 0;

%% ============================================================
% SUBJECT LOOP
%% ============================================================

for iSub = 1:numel(subj_list)

    subjectID = ...
        subj_list(iSub).(cfgBP.subjectField);

    data_trials = ...
        subj_list(iSub).data_trials;

    for iTr = 1:numel(data_trials)

        trial = data_trials(iTr);

        %% ----------------------------------------------------
        % CLASS SELECTION
        %% ----------------------------------------------------

        if ~ismember( ...
                trial.eventCode,...
                cfgBP.class_codes)

            continue

        end

        %% ----------------------------------------------------
        % LABEL ENCODING
        %% ----------------------------------------------------

        idxClass = find( ...
            cfgBP.class_codes == ...
            trial.eventCode,...
            1);

        if isempty(idxClass)

            continue

        end

        label = ...
            idxClass;

        labelName = ...
            cfgBP.class_labels{idxClass};

        %% ----------------------------------------------------
        % TIME WINDOW
        %% ----------------------------------------------------

        idxTime = ...
            trial.time >= ...
            cfgBP.analysis_window(1) & ...
            trial.time <= ...
            cfgBP.analysis_window(2);

        if ~any(idxTime)

            continue

        end

        %% ----------------------------------------------------
        % STORE
        %% ----------------------------------------------------

        trialCounter = ...
            trialCounter + 1;

        dataset_trials(trialCounter).eeg = ...
            trial.eeg(:,idxTime);

        dataset_trials(trialCounter).time = ...
            trial.time(idxTime);

        dataset_trials(trialCounter).srate = ...
            trial.srate;
        dataset_trials(trialCounter).chanlocs = ...
            trial.chanlocs;

        dataset_trials(trialCounter).label = ...
            label;

        dataset_trials(trialCounter).labelName = ...
            labelName;

        dataset_trials(trialCounter).trialType = ...
            label;

        dataset_trials(trialCounter).eventCode = ...
            trial.eventCode;

        dataset_trials(trialCounter).eventLabel = ...
            trial.(cfgBP.eventField);

        dataset_trials(trialCounter).subjectID = ...
            subjectID;

        dataset_trials(trialCounter).trialID = ...
            trial.trialID;

    end

end

%% ============================================================
% EMPTY DATASET CHECK
%% ============================================================

if isempty(dataset_trials)

    error( ...
        ['No trials available after ' ...
         'class and time-window selection']);

end

%% ============================================================
% GLOBAL INFO
%% ============================================================

BandPower_Dataset = struct();

BandPower_Dataset.trials = ...
    dataset_trials;

BandPower_Dataset.nTrials = ...
    numel(dataset_trials);

BandPower_Dataset.subjectIDs = ...
    unique({dataset_trials.subjectID});

BandPower_Dataset.nSubjects = ...
    numel(BandPower_Dataset.subjectIDs);

BandPower_Dataset.classLabels = ...
    cfgBP.class_labels;

BandPower_Dataset.classCodes = ...
    cfgBP.class_codes;

BandPower_Dataset.analysisWindow = ...
    cfgBP.analysis_window;

BandPower_Dataset.srate = ...
    dataset_trials(1).srate;

%% ============================================================
% CLASS COUNTS
%% ============================================================

labels = ...
    [dataset_trials.label];

BandPower_Dataset.classCount = ...
    zeros( ...
    1,...
    numel(cfgBP.class_labels));

fprintf('\n');
fprintf('================================\n');
fprintf('BANDPOWER DATASET CREATED\n');
fprintf('================================\n');
fprintf('Trials      : %d\n', ...
    BandPower_Dataset.nTrials);

fprintf('Subjects    : %d\n', ...
    BandPower_Dataset.nSubjects);

for iClass = 1:numel(cfgBP.class_labels)

    nClass = ...
        sum(labels == iClass);

    BandPower_Dataset.classCount(iClass) = ...
        nClass;

    fprintf('%s : %d\n', ...
        cfgBP.class_labels{iClass},...
        nClass);

end

fprintf('Window : [%.3f %.3f] s\n', ...
    cfgBP.analysis_window(1),...
    cfgBP.analysis_window(2));

end