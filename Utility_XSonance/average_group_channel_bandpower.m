function GroupChanBP = average_group_channel_bandpower( ...
    BandPower_Channel,...
    bandName)

% ============================================================
% AVERAGE_GROUP_CHANNEL_BANDPOWER
%
% Creates group-level channel-wise band power maps.
%
% Input
%
%   BandPower_Channel
%
% Output
%
%   GroupChanBP
%
%       .time
%       .chanlocs
%
%       .Consonant.power
%       .Dissonant.power
%       .Difference.power
%
% Dimensions:
%
%   Channels x Time
%
% ============================================================

%% -----------------------------------------------------------
% Subject list
%% -----------------------------------------------------------

subjNames = fieldnames(BandPower_Channel);

nSubj = numel(subjNames);

if nSubj == 0

    error('BandPower_Channel is empty');

end

%% -----------------------------------------------------------
% First valid subject
%% -----------------------------------------------------------

firstValid = [];

for iSub = 1:nSubj

    subjID = subjNames{iSub};

    if isfield( ...
            BandPower_Channel.(subjID), ...
            bandName)

        firstValid = iSub;
        break

    end

end

if isempty(firstValid)

    error( ...
        'Band %s not found', ...
        bandName);

end

BP0 = ...
    BandPower_Channel.(subjNames{firstValid}) ...
    .(bandName);

%% -----------------------------------------------------------
% Basic information
%% -----------------------------------------------------------

time = BP0.time;

chanlocs = BP0.chanlocs;

[nChan,nTime] = ...
    size(BP0.Consonant.power);

%% -----------------------------------------------------------
% Allocate
%% -----------------------------------------------------------

ConMat = ...
    nan(nChan,nTime,nSubj);

DisMat = ...
    nan(nChan,nTime,nSubj);

DiffMat = ...
    nan(nChan,nTime,nSubj);

%% -----------------------------------------------------------
% Subject loop
%% -----------------------------------------------------------

for iSub = 1:nSubj

    subjID = subjNames{iSub};

    if ~isfield( ...
            BandPower_Channel.(subjID), ...
            bandName)

        continue

    end

    BP = ...
        BandPower_Channel.(subjID) ...
        .(bandName);

    if isfield(BP,'Consonant')

        ConMat(:,:,iSub) = ...
            BP.Consonant.power;

    end

    if isfield(BP,'Dissonant')

        DisMat(:,:,iSub) = ...
            BP.Dissonant.power;

    end

    if isfield(BP,'Difference')

        DiffMat(:,:,iSub) = ...
            BP.Difference.power;

    end

end

%% -----------------------------------------------------------
% Group average
%% -----------------------------------------------------------

GroupChanBP = struct();

GroupChanBP.time = time;

GroupChanBP.chanlocs = chanlocs;

GroupChanBP.nSubjects = nSubj;

%% -----------------------------------------------------------
% Consonant
%% -----------------------------------------------------------

GroupChanBP.Consonant.power = ...
    mean(ConMat,3,'omitnan');

GroupChanBP.Consonant.sem = ...
    std(ConMat,0,3,'omitnan') ./ ...
    sqrt(nSubj);

GroupChanBP.Consonant.subject_values = ...
    ConMat;

%% -----------------------------------------------------------
% Dissonant
%% -----------------------------------------------------------

GroupChanBP.Dissonant.power = ...
    mean(DisMat,3,'omitnan');

GroupChanBP.Dissonant.sem = ...
    std(DisMat,0,3,'omitnan') ./ ...
    sqrt(nSubj);

GroupChanBP.Dissonant.subject_values = ...
    DisMat;

%% -----------------------------------------------------------
% Difference
%% -----------------------------------------------------------

GroupChanBP.Difference.power = ...
    mean(DiffMat,3,'omitnan');

GroupChanBP.Difference.sem = ...
    std(DiffMat,0,3,'omitnan') ./ ...
    sqrt(nSubj);

GroupChanBP.Difference.subject_values = ...
    DiffMat;

end