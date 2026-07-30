function GroupBP = average_group_bandpower( ...
    BandPower_Subj,...
    roiName,...
    bandName)

% ============================================================
% AVERAGE_GROUP_BANDPOWER
%
% Aggregates subject-level band-power waveforms into a
% group-level representation.
%
% ============================================================

subjNames = fieldnames(BandPower_Subj);

nSubj = numel(subjNames);

if nSubj == 0

    error('BandPower_Subj is empty');

end

% ------------------------------------------------------------
% Find first valid subject
% ------------------------------------------------------------

firstValid = [];

for i = 1:nSubj

    subjID = subjNames{i};

    if isfield(BandPower_Subj.(subjID),roiName) && ...
       isfield(BandPower_Subj.(subjID).(roiName),bandName)

        firstValid = i;
        break

    end

end

if isempty(firstValid)

    error('No valid ROI/Band found');

end

bp0 = ...
BandPower_Subj.(subjNames{firstValid}) ...
              .(roiName) ...
              .(bandName);

time = bp0.time;

nTime = numel(time);

% ------------------------------------------------------------
% Initialize matrices
% ------------------------------------------------------------

ConMat = nan(nSubj,nTime);

DisMat = nan(nSubj,nTime);

DiffMat = nan(nSubj,nTime);

% ------------------------------------------------------------
% Subject loop
% ------------------------------------------------------------

for i = 1:nSubj

    subjID = subjNames{i};

    if ~isfield(BandPower_Subj.(subjID),roiName)
        continue
    end

    if ~isfield(BandPower_Subj.(subjID).(roiName),bandName)
        continue
    end

    BP = ...
        BandPower_Subj.(subjID) ...
                      .(roiName) ...
                      .(bandName);

    if isfield(BP,'Consonant')

        ConMat(i,:) = ...
            BP.Consonant.power;

    end

    if isfield(BP,'Dissonant')

        DisMat(i,:) = ...
            BP.Dissonant.power;

    end

    if isfield(BP,'Difference')

        DiffMat(i,:) = ...
            BP.Difference.power;

    end

end

% ------------------------------------------------------------
% Group averages
% ------------------------------------------------------------

GroupBP = struct();

GroupBP.time = time;

GroupBP.nSubjects = nSubj;

% ------------------------------------------------------------
% Consonant
% ------------------------------------------------------------

GroupBP.Consonant.power = ...
    mean(ConMat,1,'omitnan');

GroupBP.Consonant.sem = ...
    std(ConMat,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(ConMat(:,1))));

GroupBP.Consonant.subject_values = ...
    ConMat;

% ------------------------------------------------------------
% Dissonant
% ------------------------------------------------------------

GroupBP.Dissonant.power = ...
    mean(DisMat,1,'omitnan');

GroupBP.Dissonant.sem = ...
    std(DisMat,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(DisMat(:,1))));

GroupBP.Dissonant.subject_values = ...
    DisMat;

% ------------------------------------------------------------
% Difference
% ------------------------------------------------------------

GroupBP.Difference.power = ...
    mean(DiffMat,1,'omitnan');

GroupBP.Difference.sem = ...
    std(DiffMat,0,1,'omitnan') ./ ...
    sqrt(sum(~isnan(DiffMat(:,1))));

GroupBP.Difference.subject_values = ...
    DiffMat;

end