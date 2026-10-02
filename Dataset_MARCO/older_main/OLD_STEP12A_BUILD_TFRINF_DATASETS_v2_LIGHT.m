%% =========================================================================
% STEP12A_BUILD_TFRINF_DATASETS_v2_LIGHT
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

Cases(2).name = 'CON_CONTROL';
Cases(2).class_labels = ...
    {'Consonant','ControlGOAL'};
Cases(2).class_codes = [7 3];

Cases(3).name = 'DIS_CONTROL';
Cases(3).class_labels = ...
    {'Dissonant','ControlGOAL'};
Cases(3).class_codes = [8 3];

Cases(4).name = 'CD_CONTROL';
Cases(4).class_labels = ...
    {'Consonant','Dissonant','ControlGOAL'};
Cases(4).class_codes = [7 8 3];

%% ============================================================
% LOOP
%% ============================================================

for iCase = 1:numel(Cases)

    CaseCfg = Cases(iCase);

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CASE : %s\n',CaseCfg.name);
    fprintf('================================\n');

    %% --------------------------------------------------------
    % CONFIG
    %% --------------------------------------------------------

    cfgTFR = struct();

    cfgTFR.class_labels = ...
        CaseCfg.class_labels;

    cfgTFR.class_codes = ...
        CaseCfg.class_codes;

    cfgTFR.analysis_window = ...
        [-0.5 1.0];

    cfgTFR.eventField = ...
        'eventLabel';

    cfgTFR.subjectField = ...
        'subj_id';

    %% --------------------------------------------------------
    % TFR SETTINGS
    %% --------------------------------------------------------

    cfgTFR.freqs = ...
        30:1:60;

    cfgTFR.nCycles = ...
        7;

    cfgTFR.baseline_win = ...
        [-0.200 -0.050];

    cfgTFR.gamma_freq_win = ...
        [30 60];

    cfgTFR.gamma_time_win = ...
        [0.100 0.250];

    %% --------------------------------------------------------
    % ROI
    %% --------------------------------------------------------

    MAIN_ROI

    cfgTFR.rois = ROI;

    %% ========================================================
    % DATASET
    %% ========================================================

    TFRINF_Dataset = ...
        build_bandpower_dataset( ...
        subj_list,...
        cfgTFR);

    %% ========================================================
    % FEATURE EXTRACTION
    %% ========================================================

    fprintf('\n');
    fprintf('COMPUTING TFR FEATURES...\n');

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
            compute_tfr_informed_features( ...
            tr,...
            cfgTFR,...
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
    % SUMMARY
    %% ========================================================

    fprintf('\n');
    fprintf('Trials    : %d\n', ...
        TFRINF_Dataset.nTrials);

    fprintf('Subjects  : %d\n', ...
        TFRINF_Dataset.nSubjects);

    fprintf('Features  : %d\n', ...
        TFRINF_Dataset.nFeatures);

    disp(TFRINF_Dataset.FeatureNames(:))

    %% ========================================================
    % SAVE
    %% ========================================================

    saveName = sprintf( ...
        'TFRINF_Dataset_%s_FULL.mat',...
        CaseCfg.name);

    save( ...
        fullfile( ...
        outdir,...
        saveName),...
        'TFRINF_Dataset',...
        'cfgTFR',...
        '-v7.3');

    fprintf('Saved : %s\n',saveName);

end

%% ============================================================
% END
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('ALL TFR DATASETS CREATED\n');
fprintf('================================\n');