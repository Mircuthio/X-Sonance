% ============================================================
% CHECK_EPOCH_FEASIBILITY
% ============================================================
inputFolder = 'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EXTRACTED_DATA';
preStim  = 0.5;
postStim = 1.5;

subjectDirs = dir(fullfile(inputFolder,'Subj*'));
subjectDirs = subjectDirs([subjectDirs.isdir]);

fprintf('\n');
fprintf('=====================================\n');
fprintf('EPOCH FEASIBILITY CHECK\n');
fprintf('=====================================\n');

globalMinBefore = inf;
globalMinAfter  = inf;

for s = 1:numel(subjectDirs)

    subjName = subjectDirs(s).name;

    file = dir(fullfile( ...
        inputFolder,...
        subjName,...
        '*data_extracted.mat'));

    tmp = load(fullfile(file(1).folder,file(1).name));

    subjectData = tmp.subjectData;

    EEG = subjectData.cleanContinuous;

    eventsTable = subjectData.eventsTable;

    validIdx = ismember(eventsTable.trigger,1:8);

    eventTimes = eventsTable.timeSec(validIdx);

    recordingDuration = ...
        EEG.pnts / EEG.srate;

    firstEvent = eventTimes(1);

    lastEvent = eventTimes(end);

    marginBefore = firstEvent;
    marginAfter  = recordingDuration - lastEvent;

    globalMinBefore = ...
        min(globalMinBefore,marginBefore);

    globalMinAfter = ...
        min(globalMinAfter,marginAfter);

    fprintf('%s\n',subjName);
    fprintf('   First Event   : %.3f s\n',firstEvent);
    fprintf('   Last Event    : %.3f s\n',lastEvent);
    fprintf('   Duration      : %.3f s\n',recordingDuration);
    fprintf('   Margin Before : %.3f s\n',marginBefore);
    fprintf('   Margin After  : %.3f s\n',marginAfter);
    fprintf('\n');

end

fprintf('=====================================\n');
fprintf('GLOBAL MIN MARGIN BEFORE = %.3f s\n',...
    globalMinBefore);

fprintf('GLOBAL MIN MARGIN AFTER  = %.3f s\n',...
    globalMinAfter);

fprintf('Required prestim  = %.3f s\n',preStim);
fprintf('Required poststim = %.3f s\n',postStim);

assert(globalMinBefore >= preStim,...
    'Prestim window exceeds available data');

assert(globalMinAfter >= postStim,...
    'Poststim window exceeds available data');

fprintf('\n');
fprintf('CHECK PASSED\n');
fprintf('No epochs will be lost.\n');
fprintf('=====================================\n');