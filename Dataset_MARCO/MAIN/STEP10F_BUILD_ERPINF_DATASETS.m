%% =========================================================================
% STEP10F_BUILD_ERPINF_DATASETS
% STEP10F_BUILD_CONTROL_DATASETS
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
    'STEP10F_CONTROL_DATASETS');

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
        ERPINF_Dataset.nTrials);

    fprintf('Subjects  : %d\n', ...
        ERPINF_Dataset.nSubjects);

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
fprintf('ALL CONTROL DATASETS CREATED\n');
fprintf('================================\n');