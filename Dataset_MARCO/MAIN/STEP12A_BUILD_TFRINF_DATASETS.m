%% =========================================================================
% STEP12A_BUILD_TFRINF_DATASETS
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
    'STEP12A_TFRINF_DATASETS');

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
% LOOP
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
    % GAMMA SETTINGS
    %% --------------------------------------------------------

    cfgTFRINF.freqs = ...
        30:1:60;

    cfgTFRINF.nCycles = 7;

    cfgTFRINF.baseline_win = ...
        [-0.200 -0.050];

    cfgTFRINF.gamma_freq_win = ...
        [30 60];

    cfgTFRINF.gamma_time_win = ...
        [0.100 0.250];

    %% --------------------------------------------------------
    % ROI
    %% --------------------------------------------------------

    MAIN_ROI

    cfgTFRINF.rois = ROI;

    %% --------------------------------------------------------
    % DATASET
    %% --------------------------------------------------------

    TFRINF_Dataset = ...
        build_bandpower_dataset( ...
        subj_list,...
        cfgTFRINF);

    %% --------------------------------------------------------
    % FEATURES
    %% --------------------------------------------------------

    fprintf('\n');
    fprintf('COMPUTING TFR FEATURES...\n');

    nTrials = ...
        numel(TFRINF_Dataset.trials);

    for iTr = 1:nTrials

        if mod(iTr,100)==0

            fprintf( ...
                'Trial %d / %d\n', ...
                iTr,...
                nTrials);

        end

        tr = ...
            TFRINF_Dataset.trials(iTr);

        [tmp,FeatureNames] = ...
            compute_tfr_informed_features( ...
            tr,...
            cfgTFRINF,...
            'TFRINF');

        TFRINF_Dataset.trials(iTr).TFRINF = ...
            tmp.TFRINF;

        TFRINF_Dataset.trials(iTr).timeTFRINF = ...
            tmp.timeTFRINF;

    end

    %% --------------------------------------------------------
    % METADATA
    %% --------------------------------------------------------

    TFRINF_Dataset.FeatureNames = ...
        FeatureNames;

    TFRINF_Dataset.nFeatures = ...
        numel(FeatureNames);

    %% --------------------------------------------------------
    % SAVE
    %% --------------------------------------------------------

    saveName = sprintf( ...
        'TFRINF_Dataset_%s_FULL.mat',...
        CaseCfg.name);

    save( ...
        fullfile( ...
        outdir,...
        saveName),...
        'TFRINF_Dataset',...
        'cfgTFRINF',...
        '-v7.3');

end

set(0,'DefaultFigureVisible',origState);