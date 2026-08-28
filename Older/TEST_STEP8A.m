%% =========================================================================
% TEST_STEP8A
%
% PURPOSE
% -------
% Quick validation of STEP8A ERP Spectrogram pipeline.
%
% Tests:
%
%   - ROI extraction
%   - ERP computation
%   - Spectrogram computation
%   - Group averaging
%   - Plot generation
%
%% =========================================================================

% clear
% close all
% clc
% 
% %% ============================================================
% % LOAD DATA
% %% ============================================================
% 
% step2_indir = ...
%     'D:\X-SONANCE\Dataset_MARCO\';
% 
% load(fullfile(step2_indir,'subj_list.mat'));
%% ============================================================
% TEST OUTPUT
%% ============================================================

test_outdir = ...
    fullfile( ...
    step2_indir,...
    'TEST_STEP8A');

if ~exist(test_outdir,'dir')
    mkdir(test_outdir);
end
%% ============================================================
% TEST DATASET
%% ============================================================

nSubjectsTest = 3;

subj_list = ...
    subj_list(1:min( ...
    nSubjectsTest,...
    numel(subj_list)));

fprintf('\n');
fprintf('================================\n');
fprintf('TEST DATASET\n');
fprintf('Subjects: %d\n',numel(subj_list));
fprintf('================================\n');

%% ============================================================
% CONFIG
%% ============================================================

cfgTFERP = struct();

cfgTFERP.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgTFERP.cond_field = ...
    'eventLabel';

cfgTFERP.analysis_window = ...
    [-0.5 1.0];

cfgTFERP.window_length = 32;

cfgTFERP.overlap = 16;

cfgTFERP.nfft = 64;

cfgTFERP.fmin = 1;

cfgTFERP.fmax = 90;

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

cfgTFERP.rois = ROI;

roiName = 'ERAN';

assert( ...
    isfield(cfgTFERP.rois,roiName),...
    'ROI not found');

cfgTFERP.roi_labels = ...
    cfgTFERP.rois.(roiName);

%% ============================================================
% SUBJECT LEVEL
%% ============================================================

TFERP_Subj = struct();

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT LEVEL\n');
fprintf('================================\n');

for iSub = 1:numel(subj_list)

    subjID = ...
        matlab.lang.makeValidName( ...
        char(subj_list(iSub).subj_id));

    fprintf('Subject: %s\n',subjID);

    TFERP_Subj.(subjID).(roiName) = ...
        extract_roi_erp_spectrogram( ...
        subj_list(iSub),...
        cfgTFERP);

end

%% ============================================================
% SINGLE SUBJECT CHECK
%% ============================================================

firstSubj = ...
    matlab.lang.makeValidName( ...
    char(subj_list(1).subj_id));

disp(fieldnames( ...
    TFERP_Subj.(firstSubj).(roiName)));

fprintf('\n');
fprintf('Consonant size:\n');
disp(size( ...
    TFERP_Subj.(firstSubj).(roiName) ...
    .Consonant.power));

fprintf('\n');
fprintf('Dissonant size:\n');
disp(size( ...
    TFERP_Subj.(firstSubj).(roiName) ...
    .Dissonant.power));

%% ============================================================
% GROUP LEVEL
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP LEVEL\n');
fprintf('================================\n');

TFERP_Group.(roiName) = ...
    average_group_erp_spectrogram( ...
    TFERP_Subj,...
    roiName);

%% ============================================================
% CHECK GROUP STRUCTURE
%% ============================================================

disp(fieldnames( ...
    TFERP_Group.(roiName)));

fprintf('\n');
fprintf('Group Consonant size:\n');
disp(size( ...
    TFERP_Group.(roiName) ...
    .Consonant.power));

fprintf('\n');
fprintf('Group Dissonant size:\n');
disp(size( ...
    TFERP_Group.(roiName) ...
    .Dissonant.power));

fprintf('\n');
fprintf('Group Difference size:\n');
disp(size( ...
    TFERP_Group.(roiName) ...
    .Difference.power));

%% ============================================================
% PLOT CONFIG
%% ============================================================

cfgPlot = struct();

cfgPlot.colormap = turbo;

cfgPlot.clim = 'auto';

cfgPlot.showDifference = true;

cfgPlot.save_path = '';

%% ============================================================
% GROUP PLOT
%% ============================================================

cfgPlot.save_path = ...
    fullfile( ...
    test_outdir,...
    sprintf( ...
    'GROUP_%s.png',...
    roiName));

plot_erp_spectrogram( ...
    TFERP_Group.(roiName),...
    roiName,...
    cfgPlot);
%% ============================================================
% SUBJECT PLOT
%% ============================================================

cfgPlot.save_path = ...
    fullfile( ...
    test_outdir,...
    sprintf( ...
    'SUBJECT_%s_%s.png',...
    firstSubj,...
    roiName));

plot_erp_spectrogram_subject( ...
    TFERP_Subj.(firstSubj).(roiName),...
    firstSubj,...
    roiName,...
    cfgPlot);

%% ============================================================
% DIFFERENCE PLOT
%% ============================================================

cfgPlot.save_path = ...
    fullfile( ...
    test_outdir,...
    sprintf( ...
    'DIFFERENCE_%s.png',...
    roiName));

plot_erp_spectrogram_difference( ...
    TFERP_Group.(roiName),...
    sprintf('%s Difference',roiName),...
    cfgPlot);
%% ============================================================
% NUMERIC SANITY CHECK
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('NUMERIC CHECK\n');
fprintf('================================\n');

groupData = ...
    TFERP_Group.(roiName);

fprintf('Consonant mean : %.4f\n', ...
    mean(groupData.Consonant.power(:)));

fprintf('Dissonant mean : %.4f\n', ...
    mean(groupData.Dissonant.power(:)));

fprintf('Difference mean : %.4f\n', ...
    mean(groupData.Difference.power(:)));

fprintf('Time range: %.3f -> %.3f\n', ...
    TFERP_Group.(roiName).time(1), ...
    TFERP_Group.(roiName).time(end));

fprintf('Freq range: %.3f -> %.3f\n', ...
    TFERP_Group.(roiName).freq(1), ...
    TFERP_Group.(roiName).freq(end));

fprintf('\n');
fprintf('Output folder:\n');
fprintf('%s\n',test_outdir);
fprintf('\n');
fprintf('================================\n');
fprintf('TEST COMPLETE\n');
fprintf('================================\n');