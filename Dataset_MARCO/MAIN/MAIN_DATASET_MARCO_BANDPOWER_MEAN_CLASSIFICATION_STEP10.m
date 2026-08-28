%% =========================================================================
% MAIN_DATASET_MARCO_BANDPOWER_MEAN_CLASSIFICATION_STEP10
%
% PROJECT
% -------
% X-SONANCE EEG
%
%
% PURPOSE
% -------
% BandPower Mean Classification
%
%
% PIPELINE
%
% subj_list
%     ↓
% ROI Selection
%
%     ↓
% Band Selection
%
%     ↓
% BandPower Extraction
%
%     ↓
% Mean BandPower Features
%
%         ROI × Band
%
%     ↓
% Dataset Building
%
%         X
%         y
%         subjects
%
%     ↓
% Classification
%
%         LOSO
%
%     ↓
% Metrics
%
%     ↓
% Plots
%
%     ↓
% Save
%
%% =========================================================================

clear
close all
clc

origState = ...
    get(0,'DefaultFigureVisible');

set(0,'DefaultFigureVisible','off');

disable_eeglab();
%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\';

load( ...
    fullfile( ...
    step2_indir,...
    'subj_list.mat'));

%% ============================================================
% DEBUG
%% ============================================================

cfgDebug = struct();

cfgDebug.enable = false;

cfgDebug.nSubjects = 5;

if cfgDebug.enable

    subj_list = ...
        subj_list( ...
        1:min( ...
        cfgDebug.nSubjects,...
        numel(subj_list)));

end

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgBP = struct();

%% ------------------------------------------------------------
% CONDITIONS
%% ------------------------------------------------------------

cfgBP.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgBP.cond_field = ...
    'eventLabel';

%% ------------------------------------------------------------
% ANALYSIS WINDOW
%% ------------------------------------------------------------

cfgBP.analysis_window = ...
    [-0.5 1.0];

%% ------------------------------------------------------------
% POWER MODE
%% ------------------------------------------------------------

cfgBP.power_mode = ...
    'log';

% 'absolute'
% 'log'
% 'zscore'

%% ------------------------------------------------------------
% FREQUENCY BANDS
%% ------------------------------------------------------------

cfgBP.bands.delta = [1 4];

cfgBP.bands.theta = [4 8];

cfgBP.bands.alpha = [8 13];

cfgBP.bands.beta  = [13 30];

cfgBP.bands.gamma = [30 80];

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

cfgBP.rois = ROI;

cfgBP.analysis_rois = { ...
    'ERAN',...
    'MMN',...
    'N5'};

roiNames = ...
    reshape( ...
    cfgBP.analysis_rois,...
    [],1);

%% ============================================================
% CLASSIFIER CONFIG
%% ============================================================

cfgClassifier = struct();

cfgClassifier.validation = ...
    'LOSO';

cfgClassifier.name = ...
    'SVM';

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================

outdir = ...
    fullfile( ...
    step2_indir,...
    'BANDPOWER_MEAN_CLASSIFICATION_STEP10');

if ~exist(outdir,'dir')

    mkdir(outdir);

end

%% ============================================================
% INITIALIZATION
%% ============================================================

BPFeatures_Subj = struct();

%% ============================================================
% FEATURE EXTRACTION
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('FEATURE EXTRACTION\n');
fprintf('================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = ...
        subj_list(iSub);

    subjID = ...
        matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    fprintf('[%02d/%02d] %s\n',...
        iSub,...
        numel(subj_list),...
        subjID);

    BPFeatures_Subj.(subjID) = ...
        extract_bandpower_mean_features( ...
        subj_curr,...
        cfgBP);

end

%% ============================================================
% DATASET BUILDING
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('DATASET BUILDING\n');
fprintf('================================\n');

BPDataset = ...
    build_bandpower_dataset( ...
    BPFeatures_Subj);

%% ============================================================
% DATASET CHECK
%% ============================================================

fprintf('\n');
fprintf('Trials      : %d\n', ...
    size(BPDataset.X,1));

fprintf('Features    : %d\n', ...
    size(BPDataset.X,2));

fprintf('Classes     : %d\n', ...
    numel(unique(BPDataset.y)));

fprintf('Subjects    : %d\n', ...
    numel(unique(BPDataset.subjects)));

%% ============================================================
% CLASSIFICATION
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('CLASSIFICATION\n');
fprintf('================================\n');

BPClassification = ...
    run_classifier_loso( ...
    BPDataset.X,...
    BPDataset.y,...
    BPDataset.subjects,...
    cfgClassifier);

%% ============================================================
% RESULTS
%% ============================================================

fprintf('\n');

fprintf('Accuracy          : %.2f %%\n',...
    100 * ...
    BPClassification.accuracy);

fprintf('Balanced Accuracy : %.2f %%\n',...
    100 * ...
    BPClassification.balanced_accuracy);

%% ============================================================
% PLOTS
%% ============================================================

cfgPlot = struct();

cfgPlot.save_path = ...
    fullfile( ...
    outdir,...
    'Confusion_Matrix.png');

plot_classification_results( ...
    BPClassification,...
    cfgPlot);

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'BANDPOWER_MEAN_CLASSIFICATION_STEP10.mat'),...
    'BPFeatures_Subj',...
    'BPDataset',...
    'BPClassification',...
    'cfgBP',...
    'cfgClassifier',...
    '-v7.3');

%% ============================================================
% END
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP10A COMPLETED\n');
fprintf('================================\n');