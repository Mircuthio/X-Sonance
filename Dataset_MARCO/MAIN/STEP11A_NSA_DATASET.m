%% =========================================================================
% STEP11A_NSA_DATASET
%
% BUILD NSA DATASET
%
% OUTPUT
%
% NSA_Dataset
%
% Trials
% Subjects
% Chanlocs
% Timeeeg
%
%% =========================================================================
clear
close all
clc

%% =========================================================================
% LOAD
%% =========================================================================
projectRoot = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

load(fullfile( ...
    projectRoot,...
    'subj_list.mat'));

%% =========================================================================
% CONFIG
%% =========================================================================
cfgNSA = struct();
cfgNSA.class_codes = [7 8];
cfgNSA.class_labels = { ...
    'Consonant',...
    'Dissonant'};
cfgNSA.time_window = [-0.5 1.0];

%% =========================================================================
% COUNT VALID TRIALS
%% =========================================================================

nTrialsValid = 0;

for iSub = 1:numel(subj_list)

    SubjectTrials = ...
        subj_list(iSub).data_trials;

    for iTrial = 1:numel(SubjectTrials)

        if ismember( ...
                SubjectTrials(iTrial).eventCode,...
                cfgNSA.class_codes)

            nTrialsValid = ...
                nTrialsValid + 1;

        end

    end

end

%% =========================================================================
% TRIAL TEMPLATE
%% =========================================================================

TrialTemplate = struct( ...
    'eeg',        [], ...
    'timeeeg',    [], ...
    'srate',      [], ...
    'eventCode',  [], ...
    'eventLabel', '', ...
    'trialType',  [], ...
    'label',      [], ...
    'labelName',  '', ...
    'trialName',  '', ...
    'trialNameAll', '', ...
    'subjectID',  '', ...
    'trialID',    [], ...
    'train',      true, ...
    'valid',      false, ...
    'test',       false);

%% =========================================================================
% PREALLOCATION
%% =========================================================================

Trials = ...
    repmat( ...
    TrialTemplate,...
    1,...
    nTrialsValid);

iTrialGlobal = 0;
%% =========================================================================
% SUBJECT LOOP
%% =========================================================================
for iSub = 1:numel(subj_list)
    fprintf('\n');
    fprintf('================================\n');
    fprintf('SUBJECT %d/%d\n', ...
        iSub,...
        numel(subj_list));
    fprintf('================================\n');
    
    Subject = subj_list(iSub);
    SubjectTrials = ...
        Subject.data_trials;
    
    for iTrial = 1:numel(SubjectTrials)
        Trial = SubjectTrials(iTrial);
        
        if ~ismember( ...
                Trial.eventCode,...
                cfgNSA.class_codes)
            continue
        end
        
        iTrialGlobal = ...
            iTrialGlobal + 1;
        
        % -----------------------------------------------
        % RESET TO TEMPLATE STRUCTURE
        % (stessi campi di TemplateTrial, valori vuoti)
        % -----------------------------------------------
        NewTrial = TrialTemplate;
                
        %% ----------------------------------------------------
        % SIGNAL
        %% ----------------------------------------------------
        NewTrial.eeg = ...
            Trial.eeg;
        NewTrial.timeeeg = ...
            Trial.time;
        NewTrial.srate = ...
            Trial.srate;
        
        %% ----------------------------------------------------
        % EVENTS
        %% ----------------------------------------------------
        NewTrial.eventCode = ...
            Trial.eventCode;
        NewTrial.eventLabel = ...
            Trial.eventLabel;
        
        %% ----------------------------------------------------
        % CLASS LABELS
        %% ----------------------------------------------------
        switch Trial.eventCode
            case 7

                NewTrial.trialType = 1;
                NewTrial.label = 1;
                NewTrial.labelName = 'Consonant';
                NewTrial.trialName = 'Consonant';
                NewTrial.trialNameAll = 'Consonant';

            case 8

                NewTrial.trialType = 2;
                NewTrial.label = 2;
                NewTrial.labelName = 'Dissonant';
                NewTrial.trialName = 'Dissonant';
                NewTrial.trialNameAll = 'Dissonant';
        end
        
        %% ----------------------------------------------------
        % SUBJECT
        %% ----------------------------------------------------
        if isfield(Trial,'subjectID')
            NewTrial.subjectID = ...
                Trial.subjectID;
        else
            NewTrial.subjectID = ...
                sprintf('Subj%d',iSub);
        end
        
        %% ----------------------------------------------------
        % TRIAL ID
        %% ----------------------------------------------------
        if isfield(Trial,'trialID')
            NewTrial.trialID = ...
                Trial.trialID;
        else
            NewTrial.trialID = ...
                iTrialGlobal;
        end
        
        %% ----------------------------------------------------
        % COMPATIBILITY
        %% ----------------------------------------------------
        NewTrial.train = true;
        NewTrial.valid = false;
        NewTrial.test  = false;
        
        % WRITE DIRECTLY INTO PREALLOCATED SLOT
        Trials(iTrialGlobal) = ...
            NewTrial;
    end
end

%% =========================================================================
% CHECK TRIAL COUNT
%% =========================================================================
assert(iTrialGlobal == nTrialsValid, ...
    'Trial count mismatch: expected %d, got %d', ...
    nTrialsValid,...
    iTrialGlobal);

%% =========================================================================
% DATASET
%% =========================================================================
NSA_Dataset = struct();
NSA_Dataset.trials = ...
    Trials;
NSA_Dataset.nTrials = ...
    numel(Trials);
NSA_Dataset.nSubjects = ...
    numel(unique( ...
    {Trials.subjectID}));
NSA_Dataset.class_codes = ...
    cfgNSA.class_codes;
NSA_Dataset.class_labels = ...
    cfgNSA.class_labels;
%% =========================================================================
% OUT DIR
%% =========================================================================
outdir = fullfile( ...
    projectRoot,...
    'STEP11A_NSA_DATASET');

if ~exist(outdir,'dir')
    mkdir(outdir);
end
%% =========================================================================
% CHANNEL INFORMATION
%% =========================================================================
NSA_Dataset.nChannels = ...
    size(Trials(1).eeg,1);

if isfield( ...
        subj_list(1).data_trials(1),...
        'chanlocs')
    NSA_Dataset.chanlocs = ...
        subj_list(1).data_trials(1).chanlocs;
    NSA_Dataset.channelNames = ...
        {NSA_Dataset.chanlocs.labels};
else
    NSA_Dataset.chanlocs = [];
    NSA_Dataset.channelNames = [];
end

NSA_Dataset.srate = ...
    Trials(1).srate;
NSA_Dataset.timeeeg = ...
    Trials(1).timeeeg;
NSA_Dataset.cfgNSA = ...
    cfgNSA;
NSA_Dataset.nConsonant = ...
    sum([Trials.trialType]==1);

NSA_Dataset.nDissonant = ...
    sum([Trials.trialType]==2);

NSA_Dataset.subjectIDs = ...
    unique({Trials.subjectID});

NSA_Dataset.nSamples = ...
    size(Trials(1).eeg,2);
%% =========================================================================
% PER-SUBJECT DATASETS
%% =========================================================================
subjectDir = fullfile( ...
    outdir,...
    'Subjects');

if ~exist(subjectDir,'dir')
    mkdir(subjectDir);
end

for iSubSave = 1:numel(NSA_Dataset.subjectIDs)
    subID = NSA_Dataset.subjectIDs{iSubSave};

    % Seleziona le trial di questo soggetto
    idx = find(strcmp({Trials.subjectID}, subID));
    SubjectTrials = Trials(idx);

    % Costruisce il dataset per soggetto
    Subject_Dataset = struct();
    Subject_Dataset.subjectID = subID;
    Subject_Dataset.trials = SubjectTrials;
    Subject_Dataset.nTrials = numel(SubjectTrials);
    Subject_Dataset.nConsonant = sum([SubjectTrials.trialType]==1);
    Subject_Dataset.nDissonant = sum([SubjectTrials.trialType]==2);
    Subject_Dataset.class_codes = cfgNSA.class_codes;
    Subject_Dataset.class_labels = cfgNSA.class_labels;
    Subject_Dataset.nChannels = NSA_Dataset.nChannels;
    Subject_Dataset.srate = NSA_Dataset.srate;
    Subject_Dataset.timeeeg = NSA_Dataset.timeeeg;
    Subject_Dataset.chanlocs = NSA_Dataset.chanlocs;
    Subject_Dataset.channelNames = NSA_Dataset.channelNames;
    Subject_Dataset.cfgNSA = cfgNSA;

    % Nome file sicuro (rimuove spazi/caratteri problematici)
    safeID = regexprep(subID, '[^\w]', '_');

    save( ...
        fullfile(subjectDir, ...
        sprintf('%s_NSA_Dataset.mat', safeID)), ...
        'Subject_Dataset', ...
        '-v7.3');

    fprintf('Saved subject dataset: %s (%d trials)\n', ...
        subID, ...
        Subject_Dataset.nTrials);
end
%% =========================================================================
% SUMMARY
%% =========================================================================
fprintf('\n');
fprintf('================================\n');
fprintf('NSA DATASET\n');
fprintf('================================\n');
fprintf('Trials    : %d\n', ...
    NSA_Dataset.nTrials);
fprintf('Subjects  : %d\n', ...
    NSA_Dataset.nSubjects);
fprintf('Channels  : %d\n', ...
    NSA_Dataset.nChannels);
fprintf('Consonant : %d\n', ...
    sum([Trials.trialType]==1));
fprintf('Dissonant : %d\n', ...
    sum([Trials.trialType]==2));
fprintf('================================\n');

%% =========================================================================
% SAVE
%% =========================================================================
save( ...
    fullfile( ...
    outdir,...
    'NSA_Dataset.mat'),...
    'NSA_Dataset',...
    '-v7.3');

fprintf('\n');
fprintf('STEP11A COMPLETED\n');
fprintf('\n');