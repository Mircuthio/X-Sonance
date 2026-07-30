function group_tfr = average_group_tfr(TFR_Subj,roiName)

% ============================================================
% AVERAGE_GROUP_TFR
%
% Average subject-level TFRs into group-level TFR
%
% ============================================================

group_tfr = [];

subjectNames = fieldnames(TFR_Subj);

nSubjects = numel(subjectNames);

if nSubjects == 0
    warning('No subjects found');
    return
end

validSubjects = 0;

for s = 1:nSubjects

    subjID = subjectNames{s};

    if ~isfield(TFR_Subj.(subjID),roiName)
        continue
    end

    roiData = TFR_Subj.(subjID).(roiName);

    if ~isfield(roiData,'Consonant')
        continue
    end

    if ~isfield(roiData,'Dissonant')
        continue
    end

    validSubjects = validSubjects + 1;

end

if validSubjects == 0

    warning('No valid subjects');

    return

end
for s = 1:nSubjects

    subjID = subjectNames{s};

    if isfield(TFR_Subj.(subjID),roiName)

        roiData = TFR_Subj.(subjID).(roiName);

        if isfield(roiData,'Consonant') && ...
           isfield(roiData,'Dissonant')

            break

        end

    end

end
[nFreq,nTime] = ...
    size(roiData.Consonant.power);

conStack = zeros( ...
    nFreq,...
    nTime,...
    validSubjects,...
    'single');

disStack = zeros( ...
    nFreq,...
    nTime,...
    validSubjects,...
    'single');
idx = 0;

for s = 1:nSubjects

    subjID = subjectNames{s};

    if ~isfield(TFR_Subj.(subjID),roiName)
        continue
    end

    roiData = TFR_Subj.(subjID).(roiName);

    if ~isfield(roiData,'Consonant')
        continue
    end

    if ~isfield(roiData,'Dissonant')
        continue
    end

    idx = idx + 1;

    conStack(:,:,idx) = ...
        roiData.Consonant.power;

    disStack(:,:,idx) = ...
        roiData.Dissonant.power;

end
fprintf('Group ROI %s: %d subjects\n', ...
    roiName,...
    validSubjects);

group_tfr.freq = roiData.freq;
group_tfr.time = roiData.time;

group_tfr.Consonant.power = ...
    mean(conStack,3);

group_tfr.Dissonant.power = ...
    mean(disStack,3);

group_tfr.Difference.power = ...
    group_tfr.Consonant.power - ...
    group_tfr.Dissonant.power;

group_tfr.nSubjects = validSubjects;

% group_tfr.Consonant.allSubjects = conStack;
% group_tfr.Dissonant.allSubjects = disStack;