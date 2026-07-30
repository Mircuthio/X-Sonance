function OUT = create_group_erp_by_roi(subj_list, cfg)
% CREATE_GROUP_ERP_BY_ROI
%
% Builds ROI-specific ERP datasets for group-level analyses.
%
% INPUT
%   subj_list : structure containing data_trials for each subject
%   cfg       : analysis configuration structure
%
% OUTPUT
%   OUT.(roiName).(cfg.conditions{1})  -> Channels x Time x Subjects
%   OUT.(roiName).(cfg.conditions{2})  -> Channels x Time x Subjects
%
% For each subject:
%   trials are grouped by condition,
%   averaged within condition,
%   and stored in ROI-specific matrices.
%
% Intended use:
%   robust statistics
%   group ERP analyses
%   LIMO-based comparisons

assert(~isempty(subj_list), 'Empty subject list');
assert(isfield(cfg,'rois') && ~isempty(cfg.rois),'cfg.rois missing or empty');
assert(isfield(cfg,'conditions') && numel(cfg.conditions)>=2, ...
    'cfg.conditions missing or invalid');
assert(isfield(cfg,'cond_field'),'cfg.cond_field missing');
assert(isfield(cfg,'time_field'),'cfg.time_field missing');
assert(isfield(cfg,'target_time_units'),'cfg.target_time_units missing');
cond1 = cfg.conditions{1};
cond2 = cfg.conditions{2};

roiNames = fieldnames(cfg.rois);
nSubj = numel(subj_list);

OUT = struct();
OUT.subjects = {subj_list.subj_id};
for r = 1:numel(roiNames)
    roiName = roiNames{r};
    roi_ch = cfg.rois.(roiName);
    roi_ch = roi_ch(:)';

    for iSub = 1:nSubj
        subj_curr = subj_list(iSub);
        assert(isfield(subj_curr, 'data_trials') && ~isempty(subj_curr.data_trials), ...
            'Empty data_trials for subject %d', iSub);

        dt = subj_curr.data_trials;
        if iscell(dt), dt = [dt{:}]; end

        if ~isfield(dt, cfg.cond_field)
            error('Condition field "%s" not found in subject %d trials', cfg.cond_field, iSub);
        end

        cond_values = string({dt.(cfg.cond_field)});
        idx1 = find(strcmpi(cond_values, string(cond1)));
        idx2 = find(strcmpi(cond_values, string(cond2)));

        if isempty(idx1) || isempty(idx2)
            warning('Subject %d: one or both conditions missing in ROI %s', iSub, roiName);
        end

        [cube1, cube2, timeVec] = extract_condition_trials(dt, roi_ch, cfg.time_field, cfg.target_time_units, idx1, idx2);

        if ~isfield(OUT, roiName)

            OUT.(roiName) = struct();
            OUT.(roiName).roi_labels = roi_ch;
            OUT.(roiName).time = timeVec;

        end

        OUT.(roiName).roi_labels = roi_ch;
        OUT.(roiName).(cfg.conditions{1})(:,:,iSub) = mean(cube1, 3, 'omitnan');
        OUT.(roiName).(cfg.conditions{2})(:,:,iSub) = mean(cube2, 3, 'omitnan');

        OUT.(roiName).(['nTrials',cfg.conditions{1}])(iSub,1) = numel(idx1);
        OUT.(roiName).(['nTrials',cfg.conditions{2}])(iSub,1) = numel(idx2);
    end
end
end

function [cube1,cube2,timeVec] =  extract_condition_trials(dt, roi_ch, time_field, target_time_units, idx1, idx2)
[cube1,timeVec] = extract_roi_trials( ...
    dt,...
    roi_ch,...
    time_field,...
    target_time_units,...
    idx1);

[cube2,~]  = extract_roi_trials( ...
    dt,...
    roi_ch,...
    time_field,...
    target_time_units,...
    idx2);
end

function [cube,timeVec] = extract_roi_trials(dt, roi_labels, time_field, target_time_units, idx)
% Returns:
%
% cube =
%   ROI_channels x Time x Trials
cube = [];
if isempty(idx)
    return
end

nTrials = numel(idx);
firstTr = dt(idx(1));
if isfield(firstTr,'chanLabels') && ~isempty(firstTr.chanLabels)
    chan_labels = cellstr(string(firstTr.chanLabels));
elseif isfield(firstTr,'chanlabels') && ~isempty(firstTr.chanlabels)
    chan_labels = cellstr(string(firstTr.chanlabels));
elseif isfield(firstTr,'chanlocs') && ~isempty(firstTr.chanlocs)
    chan_labels = {firstTr.chanlocs.labels};
else
    error('No channel labels found');
end
roi_idx = find( ...
    ismember( ...
        lower(chan_labels), ...
        lower(roi_labels)));
if isempty(roi_idx)
    error('No channels found for requested ROI');
end

t0 = double(firstTr.(time_field)(:).');
switch lower(target_time_units)
    case 'ms'
    % Time stored in seconds -> convert to milliseconds
    t0 = t0 * 1000;
    case 's'
    otherwise
        error('cfg.target_time_units must be ''ms'' or ''s''');

end

timeVec = t0;
nCh = numel(roi_idx);
nTime = numel(t0);
cube = nan(nCh, nTime, nTrials);

for k = 1:nTrials
    tr = dt(idx(k));
    eeg = double(tr.eeg);

    if isfield(tr, 'chanLabels') && ~isempty(tr.chanLabels)
        chan_labels = cellstr(string(tr.chanLabels));
    elseif isfield(tr, 'chanlabels') && ~isempty(tr.chanlabels)
        chan_labels = cellstr(string(tr.chanlabels));
    elseif isfield(tr, 'chanlocs') && ~isempty(tr.chanlocs)
        chan_labels = {tr.chanlocs.labels};
    else
        chan_labels = {};
    end

    roi_idx = find( ...
    ismember( ...
        lower(chan_labels), ...
        lower(roi_labels)));
    if isempty(roi_idx)
        error('Channels ROI not found');
    end

    t = double(tr.(time_field)(:).');
    switch lower(target_time_units)

        case 'ms'
            % Time stored in seconds -> convert to milliseconds
            t = t * 1000;

        case 's'
            % ok

        otherwise
            error('cfg.target_time_units must be ''ms'' or ''s''');

    end

    minLen = min(size(eeg,2), numel(t));
    eeg = eeg(:,1:minLen);
    t = t(1:minLen);

    if size(eeg,2) ~= nTime
        if numel(t) == nTime
            % ok
        else
            minLen = min(size(eeg,2), nTime);
            eeg = eeg(:,1:minLen);
        end
    end

    L = min(size(eeg,2),nTime);

    cube(:,1:L,k) = eeg(roi_idx,1:L);
end
end