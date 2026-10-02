%% =========================================================================
% STEP10H_BUILD_ERPINF_SUBEPOCH_DATASETS
% STEP10H_BUILD_CONTROL_DATASETS_SUBEPOCH
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
    'STEP10H_CONTROL_DATASETS_SUBEPOCH');

if ~exist(outdir,'dir')

    mkdir(outdir);

end

%% ============================================================
% CASES
%% ============================================================

Cases = struct();

%% ------------------------------------------------------------
% CASE 1
%% ------------------------------------------------------------

Cases(1).name = ...
    'CD';

Cases(1).class_labels = { ...
    'Consonant',...
    'Dissonant'};

Cases(1).class_codes = ...
    [7 8];

%% ------------------------------------------------------------
% CASE 2
%% ------------------------------------------------------------

Cases(2).name = ...
    'CON_CONTROL';

Cases(2).class_labels = { ...
    'Consonant',...
    'ControlGOAL'};

Cases(2).class_codes = ...
    [7 3];

%% ------------------------------------------------------------
% CASE 3
%% ------------------------------------------------------------

Cases(3).name = ...
    'DIS_CONTROL';

Cases(3).class_labels = { ...
    'Dissonant',...
    'ControlGOAL'};

Cases(3).class_codes = ...
    [8 3];

%% ------------------------------------------------------------
% CASE 4
%% ------------------------------------------------------------

Cases(4).name = ...
    'CD_CONTROL';

Cases(4).class_labels = { ...
    'Consonant',...
    'Dissonant',...
    'ControlGOAL'};

Cases(4).class_codes = ...
    [7 8 3];

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

    %% ========================================================
    % CONFIG
    %% ========================================================

    cfgINF = struct();

    cfgINF.class_labels = ...
        CaseCfg.class_labels;

    cfgINF.class_codes = ...
        CaseCfg.class_codes;

    cfgINF.analysis_window = ...
        [-0.5 1.0];

    cfgINF.eventField = ...
        'eventLabel';

    cfgINF.subjectField = ...
        'subj_id';

    %% --------------------------------------------------------
    % SUBEPOCHS
    %% --------------------------------------------------------

    cfgINF.useSubEpochs = true;

    cfgINF.subEpochLength = ...
        0.075;

    cfgINF.subEpochOverlap = ...
        50;

    %% --------------------------------------------------------
    % ROI
    %% --------------------------------------------------------

    MAIN_ROI

    cfgINF.rois = ROI;

    %% ========================================================
    % BUILD DATASET
    %% ========================================================

    ERPINF_Dataset = ...
        build_bandpower_dataset( ...
        subj_list,...
        cfgINF);
    %% ========================================================
    % COMPATIBILITY WITH epochCompute
    %% ========================================================

    for iTr = 1:numel(ERPINF_Dataset.trials)

        ERPINF_Dataset.trials(iTr).timeeeg = ...
            ERPINF_Dataset.trials(iTr).time;

    end
    %% ========================================================
    % SUBEPOCHING
    %% ========================================================

    if cfgINF.useSubEpochs

        parEpoch = ...
            epochComputeParams();

        parEpoch.InField = ...
            'eeg';

        parEpoch.OutField = ...
            'eeg';

        parEpoch.fample = ...
            ERPINF_Dataset.srate;

        parEpoch.t_epoch = ...
            cfgINF.subEpochLength;

        parEpoch.overlap_percent = ...
            cfgINF.subEpochOverlap;

        [ERPINF_Dataset.trials,~] = ...
            epochCompute( ...
            ERPINF_Dataset.trials,...
            parEpoch);

        parMulti = struct();

        parMulti.Infield = ...
            'eeg';

        ERPINF_Dataset.trials = ...
            multiEEG( ...
            ERPINF_Dataset.trials,...
            parMulti);

        fprintf('\n');
        fprintf('================================\n');
        fprintf('SUBEPOCHING\n');
        fprintf('================================\n');

        fprintf('Length  : %.3f s\n', ...
            cfgINF.subEpochLength);

        fprintf('Overlap : %.1f %%\n', ...
            cfgINF.subEpochOverlap);

        fprintf('Trials after subepoching : %d\n', ...
            numel(ERPINF_Dataset.trials));

    end

    %% ========================================================
    % FEATURE EXTRACTION
    %% ========================================================

    fprintf('\n');
    fprintf('COMPUTING FEATURES...\n');

    nTrials = ...
        numel(ERPINF_Dataset.trials);

    for iTr = 1:nTrials

        if mod(iTr,100)==0

            fprintf( ...
                'Trial %d / %d\n',...
                iTr,...
                nTrials);

        end

        tr = ...
            ERPINF_Dataset.trials(iTr);

        [tmp,FeatureNames] = ...
            compute_erp_informed_features( ...
            tr,...
            cfgINF,...
            'ERPINF');

        ERPINF_Dataset.trials(iTr).ERPINF = ...
            tmp.ERPINF;

        ERPINF_Dataset.trials(iTr).timeERPINF = ...
            tmp.timeERPINF;

    end

    %% ========================================================
    % METADATA
    %% ========================================================

    ERPINF_Dataset.FeatureNames = ...
        FeatureNames;

    ERPINF_Dataset.nFeatures = ...
        numel(FeatureNames);

    %% ========================================================
    % SUMMARY
    %% ========================================================

    fprintf('\n');
    fprintf('Trials    : %d\n', ...
        numel(ERPINF_Dataset.trials));

    fprintf('Features  : %d\n', ...
        ERPINF_Dataset.nFeatures);

    %% ========================================================
    % SAVE
    %% ========================================================

    saveName = sprintf( ...
        'ERPINF_Dataset_%s_FULL.mat',...
        CaseCfg.name);

    save( ...
        fullfile( ...
        outdir,...
        saveName),...
        'ERPINF_Dataset',...
        'cfgINF',...
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
fprintf('ALL SUBEPOCH DATASETS CREATED\n');
fprintf('================================\n');