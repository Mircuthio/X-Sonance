function FBCSP_Dataset = build_fbcsp_dataset( ...
    subj_list,...
    cfgFBCSP)

dataset_trials = struct([]);

trialCounter = 0;

for iSub = 1:numel(subj_list)

    subjectID = ...
        subj_list(iSub).(cfgFBCSP.subjectField);

    data_trials = ...
        subj_list(iSub).data_trials;

    for iTr = 1:numel(data_trials)

        trial = data_trials(iTr);

        %% ----------------------------------------------------
        % CLASS SELECTION
        %% ----------------------------------------------------

        if ~ismember( ...
                trial.eventCode,...
                cfgFBCSP.class_codes)

            continue

        end

        %% ----------------------------------------------------
        % LABEL ENCODING
        %% ----------------------------------------------------

        eventName = trial.(cfgFBCSP.eventField);

        label = find(strcmp(cfgFBCSP.class_labels, eventName), 1);

        if isempty(label)
            continue
        end

        labelName = cfgFBCSP.class_labels{label};

        %% ----------------------------------------------------
        % TIME WINDOW
        %% ----------------------------------------------------

        idxTime = ...
            trial.time >= cfgFBCSP.time_window(1) & ...
            trial.time <= cfgFBCSP.time_window(2);

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

        dataset_trials(trialCounter).label = ...
            label;

        dataset_trials(trialCounter).labelName = ...
            labelName;

        dataset_trials(trialCounter).eventCode = ...
            trial.eventCode;

        dataset_trials(trialCounter).eventLabel = ...
            trial.(cfgFBCSP.eventField);

        dataset_trials(trialCounter).subjectID = ...
            subjectID;

        dataset_trials(trialCounter).trialID = ...
            trial.trialID;

    end

end

%% ============================================================
% GLOBAL INFO
%% ============================================================

FBCSP_Dataset = struct();

FBCSP_Dataset.trials = ...
    dataset_trials;

FBCSP_Dataset.nTrials = ...
    numel(dataset_trials);

FBCSP_Dataset.subjectIDs = ...
    unique({dataset_trials.subjectID});

FBCSP_Dataset.nSubjects = ...
    numel(FBCSP_Dataset.subjectIDs);

FBCSP_Dataset.classLabels = ...
    cfgFBCSP.class_labels;

FBCSP_Dataset.timeWindow = ...
    cfgFBCSP.time_window;

FBCSP_Dataset.srate = ...
    dataset_trials(1).srate;
%% ============================================================
% CLASS COUNTS
%% ============================================================

% CLASS COUNTS
labels = [dataset_trials.label];
nClasses = numel(cfgFBCSP.class_codes);

for iClass = 1:nClasses
    fieldName = sprintf('nClass%d', iClass);
    FBCSP_Dataset.(fieldName) = sum(labels == iClass);
end

for iClass = 1:nClasses
    fieldName = sprintf('nClass%d', iClass);
    fprintf('%s   : %d\n', cfgFBCSP.class_labels{iClass}, FBCSP_Dataset.(fieldName));
end

fprintf('\n');
fprintf('Dataset created\n');
fprintf('Trials      : %d\n', ...
    FBCSP_Dataset.nTrials);

fprintf('Subjects    : %d\n', ...
    FBCSP_Dataset.nSubjects);

fprintf('Consonant   : %d\n', ...
    FBCSP_Dataset.nClass1);

fprintf('Dissonant   : %d\n', ...
    FBCSP_Dataset.nClass2);

end