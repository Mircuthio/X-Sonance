%% =========================================================================
% STEP12A_v4A_BUILD_TFRINF_GRID_DATASETS
%
% Time-Frequency Grid Features
%
% ROI:
%   ERAN_CORE
%   ERAN_RIGHT
%   MMN
%   N5_CENTRAL
%
% FEATURES:
%
%   Frequency bins × Time bins
%
%   6 frequency bins
%   6 time bins
%
%   36 features ROI
%
%   144 features total
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
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';

load( ...
    fullfile( ...
    step2_indir,...
    'subj_list.mat'));

%% ============================================================
% OUTPUT
%% ============================================================

outdir = ...
    fullfile( ...
    step2_indir,...
    'STEP12A_v4A_TFRINF_GRID');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CASES
%% ============================================================

Cases = struct();

Cases(1).name = 'CD';

Cases(1).class_labels = ...
    {'Consonant','Dissonant'};

Cases(1).class_codes = [7 8];

%% ============================================================
% LOOP DATASETS
%% ============================================================

for iCase = 1:numel(Cases)

    CaseCfg = Cases(iCase);

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CASE : %s\n', ...
        CaseCfg.name);
    fprintf('================================\n');

    %% --------------------------------------------------------
    % CONFIG
    %% --------------------------------------------------------

    cfgTFRINF = struct();

    cfgTFRINF.class_labels = ...
        CaseCfg.class_labels;

    cfgTFRINF.class_codes = ...
        CaseCfg.class_codes;

    cfgTFRINF.analysis_window = ...
        [-0.5 1.0];

    cfgTFRINF.eventField = ...
        'eventLabel';

    cfgTFRINF.subjectField = ...
        'subj_id';

    %% --------------------------------------------------------
    % MORLET
    %% --------------------------------------------------------

    cfgTFRINF.freqs = ...
        30:1:60;

    cfgTFRINF.nCycles = 7;

    cfgTFRINF.baseline_win = ...
        [-0.200 -0.050];

    %% --------------------------------------------------------
    % GRID
    %% --------------------------------------------------------

    cfgTFRINF.freq_bin_edges = ...
        [30 35 40 45 50 55 60];

    cfgTFRINF.time_bin_edges = ...
        [ ...
        0.150 ...
        0.183 ...
        0.216 ...
        0.250 ...
        0.283 ...
        0.316 ...
        0.350];

    %% --------------------------------------------------------
    % ROI
    %% --------------------------------------------------------

    MAIN_ROI

    cfgTFRINF.analysis_rois = { ...
        'ERAN_CORE',...
        'ERAN_RIGHT',...
        'MMN',...
        'N5_CENTRAL'};

    cfgTFRINF.rois = ROI;

    %% ========================================================
    % BUILD DATASET
    %% ========================================================

    TFRINF_Dataset = ...
        build_bandpower_dataset( ...
        subj_list,...
        cfgTFRINF);

    %% ========================================================
    % FEATURE EXTRACTION
    %% ========================================================

    fprintf('\n');
    fprintf('================================\n');
    fprintf('COMPUTE GRID FEATURES\n');
    fprintf('================================\n');

    nTrials = ...
        numel(TFRINF_Dataset.trials);

    for iTr = 1:nTrials

        if mod(iTr,100)==0

            fprintf( ...
                'Trial %d / %d\n',...
                iTr,...
                nTrials);

        end

        tr = ...
            TFRINF_Dataset.trials(iTr);

        [tmp,FeatureNames] = ...
            compute_tfr_grid_features( ...
            tr,...
            cfgTFRINF,...
            'TFRINF');

        TFRINF_Dataset.trials(iTr).TFRINF = ...
            tmp.TFRINF;

        TFRINF_Dataset.trials(iTr).timeTFRINF = ...
            tmp.timeTFRINF;

    end

    %% ========================================================
    % METADATA
    %% ========================================================

    TFRINF_Dataset.FeatureNames = ...
        FeatureNames;

    TFRINF_Dataset.nFeatures = ...
        numel(FeatureNames);

    %% ========================================================
    % CHECK
    %% ========================================================

    fprintf('\n');
    fprintf('================================\n');
    fprintf('DATASET SUMMARY\n');
    fprintf('================================\n');

    fprintf('Trials    : %d\n', ...
        TFRINF_Dataset.nTrials);

    fprintf('Subjects  : %d\n', ...
        TFRINF_Dataset.nSubjects);

    fprintf('Features  : %d\n', ...
        TFRINF_Dataset.nFeatures);

    disp( ...
        TFRINF_Dataset.FeatureNames( ...
        1:min(20,...
        numel(TFRINF_Dataset.FeatureNames))));

    %% ========================================================
    % SAVE
    %% ========================================================

    saveName = sprintf( ...
        'TFRINF_GRID_%s.mat',...
        CaseCfg.name);

    save( ...
        fullfile( ...
        outdir,...
        saveName),...
        'TFRINF_Dataset',...
        'cfgTFRINF',...
        '-v7.3');

    fprintf('\n');
    fprintf('Saved : %s\n', ...
        saveName);

end

%% ============================================================
% END
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP12A_v4A COMPLETE\n');
fprintf('================================\n');