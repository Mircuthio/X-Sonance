function groupTF = ...
    average_group_erp_spectrogram( ...
    TFERP_Subj,...
    roiName)

%% ============================================================
% SUBJECTS
%% ============================================================

subjectNames = ...
    fieldnames(TFERP_Subj);

nSubjectsTotal = ...
    numel(subjectNames);

if nSubjectsTotal == 0
    error('TFERP_Subj is empty');
end

%% ============================================================
% FIND FIRST VALID SUBJECT
%% ============================================================

firstValid = [];

for iSub = 1:nSubjectsTotal

    subjID = ...
        subjectNames{iSub};

    if isfield( ...
            TFERP_Subj.(subjID),...
            roiName)

        firstValid = ...
            TFERP_Subj.(subjID).(roiName);

        break

    end

end

if isempty(firstValid)
    error('ROI %s not found',roiName);
end

%% ============================================================
% CONDITIONS
%% ============================================================

allFields = ...
    fieldnames(firstValid);

condMask = ...
    false(size(allFields));

for iField = 1:numel(allFields)

    condMask(iField) = ...
        isstruct(firstValid.(allFields{iField})) && ...
        isfield(firstValid.(allFields{iField}), ...
        'power');

end

condNames = ...
    allFields(condMask);

condNames = ...
    setdiff(condNames, ...
    {'Difference'});

nConditions = ...
    numel(condNames);

%% ============================================================
% OUTPUT
%% ============================================================

groupTF = struct();

%% ============================================================
% CONDITION LOOP
%% ============================================================

for iCond = 1:nConditions

    condName = ...
        condNames{iCond};

    %% --------------------------------------------------------
    % REFERENCE POWER MATRIX
    %% --------------------------------------------------------

    firstPower = ...
        firstValid.(condName).power;

    [nFreq,nTime] = ...
        size(firstPower);

    %% --------------------------------------------------------
    % PREALLOCATION
    %% --------------------------------------------------------

    powerStack = ...
        NaN( ...
        nFreq,...
        nTime,...
        nSubjectsTotal);

    validCount = 0;

    %% --------------------------------------------------------
    % STACK SUBJECTS
    %% --------------------------------------------------------

    for iSub = 1:nSubjectsTotal

        subjID = ...
            subjectNames{iSub};

        if ~isfield( ...
                TFERP_Subj.(subjID),...
                roiName)
            continue
        end

        subjROI = ...
            TFERP_Subj.(subjID).(roiName);

        if ~isfield(subjROI,condName)
            continue
        end

        validCount = ...
            validCount + 1;

        powerStack(:,:,validCount) = ...
            subjROI.(condName).power;

    end

    %% --------------------------------------------------------
    % REMOVE UNUSED SLOTS
    %% --------------------------------------------------------

    powerStack = ...
        powerStack(:,:,1:validCount);

    %% --------------------------------------------------------
    % GROUP AVERAGE
    %% --------------------------------------------------------

    groupTF.(condName).power = ...
        mean(powerStack, ...
        3,...
        'omitnan');

    groupTF.(condName).condition = ...
        condName;

    groupTF.(condName).nSubjects = ...
        validCount;

    groupTF.freq = ...
        firstValid.(condName).freq;

    groupTF.time = ...
        firstValid.(condName).time;

end

%% ============================================================
% DIFFERENCE
%% ============================================================

if nConditions == 2

    cond1 = ...
        condNames{1};

    cond2 = ...
        condNames{2};

    groupTF.Difference.power = ...
        groupTF.(cond1).power - ...
        groupTF.(cond2).power;

    groupTF.Difference.freq = ...
        groupTF.freq;

    groupTF.Difference.time = ...
        groupTF.time;

    groupTF.Difference.label = ...
        sprintf('%s - %s', ...
        cond1,...
        cond2);

end

%% ============================================================
% METADATA
%% ============================================================

groupTF.roiName = ...
    roiName;

end