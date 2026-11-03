function Dataset = ...
    apply_fbcsp_roi_selection( ...
    Dataset,...
    cfgFBCSP)

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

%% ============================================================
% CHANNEL LABELS
%% ============================================================

chanLabels = ...
    {Dataset.trials(1).chanlocs.labels};

%% ============================================================
% BUILD ROI CHANNEL SET
%% ============================================================

selectedIdx = [];

fprintf('\n');
fprintf('================================\n');
fprintf('FBCSP ROI SELECTION\n');
fprintf('================================\n');

for iROI = 1:numel(cfgFBCSP.analysis_rois)

    roiName = ...
        cfgFBCSP.analysis_rois{iROI};

    fprintf('ROI : %s\n',roiName);

    roiLabels = ...
        cfgFBCSP.rois.(roiName);

    roiIdx = ...
        get_roi_indices_v2( ...
        chanLabels,...
        roiLabels);

    selectedIdx = ...
        [selectedIdx roiIdx(:)'];

end

%% ============================================================
% UNIQUE CHANNELS
%% ============================================================

selectedIdx = ...
    unique(selectedIdx);

selectedLabels = ...
    chanLabels(selectedIdx);

fprintf('\n');
fprintf('Selected channels : %d\n', ...
    numel(selectedIdx));

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

fprintf('\n');
fprintf('ROI selection completed\n');
fprintf('================================\n');

end