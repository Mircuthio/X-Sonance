%% =========================================================================
% STEP12A_V2_BUILD_TFRERP_DATASETS
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
    'STEP12A_V2_TFRERP_DATASETS');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CASES
%% ============================================================

Cases = struct();

%% ------------------------------------------------------------
% CD
%% ------------------------------------------------------------

Cases(1).name = 'CD';

Cases(1).class_labels = { ...
    'Consonant',...
    'Dissonant'};

Cases(1).class_codes = [7 8];

%% ------------------------------------------------------------
% CON_CONTROL
%% ------------------------------------------------------------

Cases(2).name = 'CON_CONTROL';

Cases(2).class_labels = { ...
    'Consonant',...
    'ControlGOAL'};

Cases(2).class_codes = [7 3];

%% ------------------------------------------------------------
% DIS_CONTROL
%% ------------------------------------------------------------

Cases(3).name = 'DIS_CONTROL';

Cases(3).class_labels = { ...
    'Dissonant',...
    'ControlGOAL'};

Cases(3).class_codes = [8 3];

%% ------------------------------------------------------------
% CD_CONTROL
%% ------------------------------------------------------------

Cases(4).name = 'CD_CONTROL';

Cases(4).class_labels = { ...
    'Consonant',...
    'Dissonant',...
    'ControlGOAL'};

Cases(4).class_codes = [7 8 3];

%% ============================================================
% LOOP CASES
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

    %% ========================================================
    % TFR SETTINGS
    %% ========================================================

    cfgTFRINF.freqs = ...
        4:1:60;

    cfgTFRINF.nCycles = ...
        7;

    cfgTFRINF.baseline_win = ...
        [-0.200 -0.050];

    %% ========================================================
    % BANDS
    %% ========================================================

    cfgTFRINF.bandDefs = struct();

    cfgTFRINF.bandDefs.Theta = ...
        [4 7];

    cfgTFRINF.bandDefs.Alpha = ...
        [8 12];

    cfgTFRINF.bandDefs.BetaLow = ...
        [13 20];

    cfgTFRINF.bandDefs.BetaMid = ...
        [20 30];

    cfgTFRINF.bandDefs.Gamma = ...
        [30 60];

    %% ========================================================
    % WINDOWS
    %% ========================================================

    cfgTFRINF.windowDefs = struct();

    cfgTFRINF.windowDefs.ERAN_A = ...
        [0.170 0.195];

    cfgTFRINF.windowDefs.ERAN_B = ...
        [0.195 0.220];

    cfgTFRINF.windowDefs.REB_A = ...
        [0.220 0.270];

    cfgTFRINF.windowDefs.REB_B = ...
        [0.270 0.320];

    %% ========================================================
    % ROI
    %% ========================================================

    MAIN_ROI

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
    fprintf('COMPUTING TFR ERP-GUIDED FEATURES...\n');

    nTrials = ...
        numel(TFRINF_Dataset.trials);

    for iTr = 1:nTrials

        if mod(iTr,50)==0

            fprintf( ...
                'Trial %d / %d\n',...
                iTr,...
                nTrials);

        end

        tr = ...
            TFRINF_Dataset.trials(iTr);

        [tmp,FeatureNames] = ...
            compute_tfrerp_features( ...
            tr,...
            cfgTFRINF,...
            'TFRERP');

        TFRINF_Dataset.trials(iTr).TFRERP = ...
            tmp.TFRERP;

        TFRINF_Dataset.trials(iTr).timeTFRERP = ...
            tmp.timeTFRERP;

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
        numel(TFRINF_Dataset.trials));

    fprintf('Features  : %d\n', ...
        TFRINF_Dataset.nFeatures);

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
fprintf('ALL TFR ERP-GUIDED DATASETS CREATED\n');
fprintf('================================\n');