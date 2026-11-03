function ResultsTSNE = ...
    plot_fbcsp_tsne_eeg( ...
    TrainTrials,...
    TestTrials,...
    Ytrain,...
    Ytest,...
    outdir,...
    prefix,...
    parTSNE)
%% ============================================================
% PLOT FBCSP TSNE ON RAW FILTERED EEG
%
% Applies tsneModel jointly to train + test trials.
%
% The signal field and corresponding time field are defined
% by parTSNE:
%
%   parTSNE.InField = 'eeg'    -> uses eeg and timeeeg
%   parTSNE.InField = 'eegFB'  -> uses eegFB and timeeegFB
%
%% ============================================================

%% ============================================================
% DEFAULT TSNE PARAMETERS
%% ============================================================
if nargin < 7
    parTSNE = struct();
end

if ~isfield(parTSNE,'InField')
    error('parTSNE.InField is required');
end

if ~isfield(parTSNE,'NumDimensions')
    parTSNE.NumDimensions = 2;
end

if ~isfield(parTSNE,'exec')
    parTSNE.exec = true;
end

if ~isfield(parTSNE,'OutField')
    parTSNE.OutField = 'TSNE';
end

if ~isfield(parTSNE,'xfld')
    parTSNE.xfld = 'time';
end

SignalField = parTSNE.InField;
TimeField = [parTSNE.xfld SignalField];
prefix = strrep(prefix, '_', ' ');
%% ============================================================
% INPUT VALIDATION
%% ============================================================
assert(~isempty(TrainTrials), ...
    'TrainTrials is empty');
assert(~isempty(TestTrials), ...
    'TestTrials is empty');

assert(isfield(TrainTrials,SignalField), ...
    'TrainTrials.%s not found',SignalField);
assert(isfield(TestTrials,SignalField), ...
    'TestTrials.%s not found',SignalField);

assert(isfield(TrainTrials,TimeField), ...
    'TrainTrials.%s not found',TimeField);
assert(isfield(TestTrials,TimeField), ...
    'TestTrials.%s not found',TimeField);

assert(numel(TrainTrials) == numel(Ytrain), ...
    'TrainTrials / Ytrain size mismatch');
assert(numel(TestTrials) == numel(Ytest), ...
    'TestTrials / Ytest size mismatch');

%% ============================================================
% SUBJECT IDS
%% ============================================================
TrainSubjects = ...
    {TrainTrials.subjectID}';
TestSubjects = ...
    {TestTrials.subjectID}';

%% ============================================================
% COMBINE TRAIN AND TEST
%% ============================================================
nTrain = numel(TrainTrials);
nTest  = numel(TestTrials);
nAll   = nTrain + nTest;

AllTrials = repmat(struct(),nAll,1);

for iTrial = 1:nTrain
    AllTrials(iTrial).subjectID = ...
        TrainTrials(iTrial).subjectID;

    AllTrials(iTrial).trialType = ...
        TrainTrials(iTrial).trialType;

    AllTrials(iTrial).(SignalField) = ...
        TrainTrials(iTrial).(SignalField);

    AllTrials(iTrial).(TimeField) = ...
        TrainTrials(iTrial).(TimeField);
end

for iTrial = 1:nTest
    idx = nTrain + iTrial;

    AllTrials(idx).subjectID = ...
        TestTrials(iTrial).subjectID;

    AllTrials(idx).trialType = ...
        TestTrials(iTrial).trialType;

    AllTrials(idx).(SignalField) = ...
        TestTrials(iTrial).(SignalField);

    AllTrials(idx).(TimeField) = ...
        TestTrials(iTrial).(TimeField);
end

Yall = [Ytrain; Ytest];

SubjectAll = [TrainSubjects; TestSubjects];

SetAll = [ ...
    repmat("Train",nTrain,1); ...
    repmat("Test", nTest, 1)];

SetAll = categorical(SetAll);

%% ============================================================
% CLASS LABELS
%% ============================================================
Yplot = strings(size(Yall));

Yplot(Yall == 1) = "Consonant";
Yplot(Yall == 2) = "Dissonant";

assert(all(Yplot ~= ""), ...
    'Some class labels were not mapped');

Yplot = categorical(Yplot);

%% ============================================================
% TSNE
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('TSNE ON %s\n',SignalField);
fprintf('================================\n');

rng(10)

[AllTrials,outTSNE] = tsneModel( ...
    AllTrials,...
    parTSNE);

%% ============================================================
% EXTRACT TSNE COORDINATES
%% ============================================================
YtsneAll = zeros(nAll,parTSNE.NumDimensions);

for iTrial = 1:nAll
    YtsneAll(iTrial,:) = ...
        AllTrials(iTrial).(parTSNE.OutField)(:)';
end

%% ============================================================
% OUTPUT DIR
%% ============================================================
tsneOutDir = ...
    fullfile(outdir,'TSNE_EEG');

if ~exist(tsneOutDir,'dir')
    mkdir(tsneOutDir);
end

%% ============================================================
% TSNE CLASS
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YtsneAll(:,1),...
    YtsneAll(:,2),...
    Yplot);

grid on
xlabel('t-SNE 1');
ylabel('t-SNE 2');
title(sprintf( ...
    '%s - t-SNE %s by Class', ...
    prefix, ...
    SignalField));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    sprintf('%s_TSNE_%s_CLASS.png', ...
    prefix,SignalField)), ...
    'Resolution',300);

close(f)

%% ============================================================
% TSNE SUBJECT
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YtsneAll(:,1),...
    YtsneAll(:,2),...
    SubjectAll);

grid on
xlabel('t-SNE 1');
ylabel('t-SNE 2');
title(sprintf( ...
    '%s - t-SNE %s by Subject', ...
    prefix, ...
    SignalField));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    sprintf('%s_TSNE_%s_SUBJECT.png', ...
    prefix,SignalField)), ...
    'Resolution',300);

close(f)

%% ============================================================
% TSNE TRAIN VS TEST
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YtsneAll(:,1),...
    YtsneAll(:,2),...
    SetAll);

grid on
xlabel('t-SNE 1');
ylabel('t-SNE 2');
title(sprintf( ...
    '%s - t-SNE %s Train vs Test', ...
    prefix, ...
    SignalField));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    sprintf('%s_TSNE_%s_TRAIN_VS_TEST.png', ...
    prefix,SignalField)), ...
    'Resolution',300);

close(f)

%% ============================================================
% SAVE RESULTS
%% ============================================================
ResultsTSNE = struct();

ResultsTSNE.Ytrain = Ytrain;
ResultsTSNE.Ytest = Ytest;

ResultsTSNE.SubjectTrain = ...
    TrainSubjects;
ResultsTSNE.SubjectTest = ...
    TestSubjects;

ResultsTSNE.TSNE = ...
    YtsneAll;
ResultsTSNE.Set = ...
    SetAll;
ResultsTSNE.Yplot = ...
    Yplot;

ResultsTSNE.SignalField = ...
    SignalField;
ResultsTSNE.TimeField = ...
    TimeField;

ResultsTSNE.TSNEModel = ...
    outTSNE;

save( ...
    fullfile( ...
    tsneOutDir,...
    sprintf('%s_TSNE_%s_RESULTS.mat', ...
    prefix,SignalField)),...
    'ResultsTSNE',...
    '-v7.3');

fprintf('TSNE ON %s COMPLETED\n',SignalField);

end