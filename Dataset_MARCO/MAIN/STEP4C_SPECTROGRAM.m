%% =========================================================================
% STEP4C_SPECTROGRAM
% MAIN_DATASET_MARCO_TIMEFREQUENCY_STEP8A
%% =========================================================================
%
% PROJECT
% -------
% X-SONANCE EEG
%
%
% PURPOSE
% -------
% ERP Spectrogram Analysis
%
% This analysis provides a descriptive visualization of
% condition differences in the Time-Frequency domain.
%
%
% PIPELINE
%
% subj_list
%     ↓
% ROI Selection
%     ↓
% Condition Selection
%     ↓
% ROI ERP
%     ↓
% Spectrogram
%     ↓
% Subject Spectrogram
%     ↓
% Group Average
%     ↓
% Difference
%     ↓
% Plot
%
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% DEBUG (OPTIONAL)
%% ============================================================

cfgDebug = struct();

cfgDebug.enable = false;

cfgDebug.nSubjects = 3;

if cfgDebug.enable

    subj_list = ...
        subj_list(1:min( ...
        cfgDebug.nSubjects,...
        numel(subj_list)));

end

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgTFERP = struct();

%% ------------------------------------------------------------
% CONDITIONS
%% ------------------------------------------------------------

cfgTFERP.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgTFERP.cond_field = ...
    'eventLabel';

cfgTFERP.referenceCondition = ...
    cfgTFERP.conditions{1};

cfgTFERP.comparisonCondition = ...
    cfgTFERP.conditions{2};

%% ------------------------------------------------------------
% TIME WINDOW
%% ------------------------------------------------------------

cfgTFERP.analysis_window = ...
    [-0.5 1.0];

%% ------------------------------------------------------------
% SPECTROGRAM
%% ------------------------------------------------------------

cfgTFERP.window_length = 32;

cfgTFERP.overlap = 16;

cfgTFERP.nfft = 64;

cfgTFERP.fmin = 1;

cfgTFERP.fmax = 90;

%% ------------------------------------------------------------
% QC
%% ------------------------------------------------------------

cfgQC = struct();

cfgQC.enable_subject_plot = false;

cfgQC.subject_index = 1;

cfgQC.plot_all_selected_rois = true;

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

cfgTFERP.rois = ROI;

cfgTFERP.analysis_rois = { ...
    'ERAN_CORE',...
    'MMN',...
    'FrontoCentral',...
    'N5_CENTRAL'};

roiNames = ...
    reshape(cfgTFERP.analysis_rois,[],1);

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
step4_outroot = ...
    fullfile(...
    'D:\X-SONANCE\Dataset_MARCO',...
   'STEP4C_SPECTROGRAM');

if ~exist(step4_outroot,'dir')
    mkdir(step4_outroot);
end

outdir = ...
    fullfile(step4_outroot, ...
    'Consonance');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% INITIALIZATION
%% ============================================================

TFERP_Subj = struct();

TFERP_Group = struct();

%% ============================================================
% SUBJECT LEVEL
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL ERP SPECTROGRAM\n');
fprintf('================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = ...
        subj_list(iSub);

    subjID = ...
        matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    fprintf('\n');
    fprintf('[%02d/%02d] %s\n',...
        iSub,...
        numel(subj_list),...
        subjID);

    for r = 1:numel(roiNames)

        roiName = ...
            roiNames{r};

        fprintf('   %s\n',roiName);

        assert( ...
            isfield(cfgTFERP.rois,roiName),...
            'ROI %s not found',roiName);

        cfgCurr = cfgTFERP;

        cfgCurr.roi_labels = ...
            cfgTFERP.rois.(roiName);

        TFERP_Subj.(subjID).(roiName) = ...
            extract_roi_erp_spectrogram( ...
            subj_curr,...
            cfgCurr);

    end

end

%% ============================================================
% GROUP LEVEL
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL ERP SPECTROGRAM\n');
fprintf('================================\n');

for r = 1:numel(roiNames)

    roiName = ...
        roiNames{r};

    fprintf('%s\n',roiName);

    TFERP_Group.(roiName) = ...
        average_group_erp_spectrogram( ...
        TFERP_Subj,...
        roiName);

end

assert( ...
    ~isempty(fieldnames(TFERP_Group)),...
    'Empty TFERP_Group');

%% ============================================================
% PLOT CONFIGURATION
%% ============================================================

cfgPlot = struct();

cfgPlot.colormap = turbo;

cfgPlot.clim = 'auto';

cfgPlot.showDifference = true;

cfgPlot.save_path = '';

cfgPlot.save_difference_only = true;

%% ============================================================
% GROUP PLOTS
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP PLOTS\n');
fprintf('================================\n');

for r = 1:numel(roiNames)

    roiName = ...
        roiNames{r};

    cfgPlot.save_path = ...
        fullfile( ...
        outdir,...
        sprintf( ...
        'ERP_Spectrogram_%s.png', ...
        roiName));

    plot_erp_spectrogram( ...
        TFERP_Group.(roiName),...
        roiName,...
        cfgPlot);

end

%% ============================================================
% QC SUBJECT PLOTS
%% ============================================================

if cfgQC.enable_subject_plot

    subjID = ...
        matlab.lang.makeValidName( ...
        char( ...
        subj_list( ...
        cfgQC.subject_index).subj_id));

    if cfgQC.plot_all_selected_rois

        roiQC = roiNames;

    else

        roiQC = roiNames(1);

    end

    for r = 1:numel(roiQC)

        roiName = ...
            roiQC{r};

        cfgPlot.save_path = ...
            fullfile( ...
            outdir,...
            sprintf( ...
            'QC_%s_%s.png',...
            subjID,...
            roiName));

        plot_erp_spectrogram_subject( ...
            TFERP_Subj.(subjID).(roiName),...
            subjID,...
            roiName,...
            cfgPlot);

    end

end

%% ============================================================
% DIFFERENCE MAPS
%% ============================================================

if cfgPlot.save_difference_only

    for r = 1:numel(roiNames)

        roiName = ...
            roiNames{r};

        cfgPlot.save_path = ...
            fullfile( ...
            outdir,...
            sprintf( ...
            'Difference_%s.png',...
            roiName));

        plot_erp_spectrogram_difference( ...
            TFERP_Group.(roiName),...
            sprintf('%s Difference',roiName),...
            cfgPlot);

    end

end

%% ============================================================
% SAVE RESULTS
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'STEP4C_SPECTROGRAM_RESULTS.mat'),...
    'TFERP_Subj',...
    'TFERP_Group',...
    'cfgTFERP',...
    '-v7.3');

%% ============================================================
% END
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP4C SPECTROGRAM COMPLETED\n');
fprintf('================================\n');