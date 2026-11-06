function Dataset = ...
    apply_fbcsp_roi_selection( ...
    Dataset,...
    cfgFBCSP)
%% ============================================================
% APPLY FBCSP ROI SELECTION
%
% Selects channels belonging to the requested ROIs and
% applies the selection to:
%
%   Dataset.trials.eeg
%   Dataset.trials.eegFB
%
%% ============================================================

%% ============================================================
% CHECKS
%% ============================================================
if ~isfield(cfgFBCSP,'useROI')
    return
end

if ~cfgFBCSP.useROI
    return
end

assert(isfield(cfgFBCSP,'analysis_rois'), ...
    'analysis_rois not found');

assert(isfield(cfgFBCSP,'rois'), ...
    'ROI structure not found');

assert(isfield(cfgFBCSP,'chanlocs'), ...
    'chanlocs not found');

%% ============================================================
% CHANNEL LABELS
%% ============================================================
chanLabels = ...
    {cfgFBCSP.chanlocs.labels};

nChannels = numel(chanLabels);
nROIs = numel(cfgFBCSP.analysis_rois);

%% ============================================================
% PREALLOCATION
%% ============================================================
% Each ROI can select at most all channels.
selectedIdx = zeros(1,nROIs*nChannels);

selectedCount = 0;

%% ============================================================
% BUILD ROI CHANNEL SET
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('FBCSP ROI SELECTION\n');
fprintf('================================\n');

for iROI = 1:nROIs

    roiName = ...
        cfgFBCSP.analysis_rois{iROI};

    fprintf('ROI : %s\n',roiName);

    roiLabels = ...
        cfgFBCSP.rois.(roiName);

    roiIdx = ...
        get_roi_indices_v2( ...
        chanLabels,...
        roiLabels);

    nRoiChannels = numel(roiIdx);

    selectedIdx(selectedCount+1:selectedCount+nRoiChannels) = ...
        roiIdx(:)';

    selectedCount = ...
        selectedCount + nRoiChannels;
end

%% ============================================================
% UNIQUE CHANNELS
%% ============================================================
selectedIdx = ...
    unique(selectedIdx(1:selectedCount));

assert(~isempty(selectedIdx), ...
    'ROI selection returned zero channels');

selectedLabels = ...
    chanLabels(selectedIdx);

nSelected = numel(selectedIdx);

fprintf('\n');
fprintf('Selected channels : %d\n', ...
    nSelected);
disp(selectedLabels')

%% ============================================================
% APPLY ROI
%% ============================================================
for iTrial = 1:numel(Dataset.trials)

    if isfield(Dataset.trials(iTrial),'eeg')
        Dataset.trials(iTrial).eeg = ...
            Dataset.trials(iTrial).eeg( ...
            selectedIdx,:);
    end

    if isfield(Dataset.trials(iTrial),'eegFB')
        Dataset.trials(iTrial).eegFB = ...
            Dataset.trials(iTrial).eegFB( ...
            selectedIdx,:,:);
    end
end

%% ============================================================
% SAVE INFO
%% ============================================================
Dataset.roiSelection.Enabled = true;
Dataset.roiSelection.ROIs = ...
    cfgFBCSP.analysis_rois;
Dataset.roiSelection.ChannelIdx = ...
    selectedIdx;
Dataset.roiSelection.ChannelLabels = ...
    selectedLabels;

%% ============================================================
% CHANNEL INFORMATION
%% ============================================================
Dataset.nChannels = ...
    nSelected;
Dataset.channelNames = ...
    selectedLabels;
Dataset.chanlocs = ...
    cfgFBCSP.chanlocs(selectedIdx);

if isfield(cfgFBCSP,'srate')
    Dataset.srate = ...
        cfgFBCSP.srate;
end

fprintf('\n');
fprintf('ROI selection completed\n');
fprintf('================================\n');

end