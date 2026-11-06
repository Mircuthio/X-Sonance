%% =========================================================================
% STEP11E2_NSA_GUIDED_FEATURE_DATASET
%
% BUILD NSA GUIDED FEATURE DATASET
%
% INPUT
%
%   STEP11B_NSA_MANIFOLD/NSA_Manifold.mat
%
% OUTPUT
%
%   STEP11E2_NSA_GUIDED_FEATURE_DATASET/
%       NSA_GuidedDataset.mat
%
%% =========================================================================
clear
close all
clc

%% =========================================================================
% LOAD
%% =========================================================================

projectRoot = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

load(fullfile( ...
    projectRoot,...
    'STEP11B_NSA_MANIFOLD',...
    'NSA_Manifold.mat'));

data_trials = ...
    NSA_Manifold.data_trials;

%% =========================================================================
% WINDOWS
%% =========================================================================

Windows = struct();

% PC4 : early discriminative component
Windows.PC4 = [0.08 0.25];

% PC3 : intermediate dynamics
Windows.PC3 = [0.40 0.80];

% PC2 : late dynamics
Windows.PC2 = [1.00 1.50];

%% =========================================================================
% FEATURES
%% =========================================================================

FeatureNames = { ...
    'PC4_Mean'
    'PC4_AUC'
    'PC4_MinPeak'
    'PC4_MaxPeak'
    'PC4_PeakToPeak'

    'PC3_Mean'
    'PC3_AUC'
    'PC3_PeakToPeak'

    'PC2_Mean'
    'PC2_AUC'
    'PC2_Slope'
    };

FeatureFamily = ...
    repmat({'NSA_GUIDED'}, ...
    numel(FeatureNames),1);

nFeatures = ...
    numel(FeatureNames);

nTrials = ...
    numel(data_trials);

%% =========================================================================
% FEATURE EXTRACTION
%% =========================================================================

X = nan(nTrials,nFeatures);
Y = nan(nTrials,1);
SubjectID = cell(nTrials,1);

for iTrial = 1:nTrials

    dpca = ...
        data_trials(iTrial).dpca;

    t = ...
        data_trials(iTrial).timedpca;

    featureVector = nan(1,nFeatures);

    %% -----------------------------------------------------------------
    % PC4
    %% -----------------------------------------------------------------
    idx = ...
        t >= Windows.PC4(1) & ...
        t <= Windows.PC4(2);
    
    assert(any(idx), ...
        'Finestra PC4 vuota nella trial %d',iTrial);

    tSel = t(idx);
    sig = dpca(4,idx);

    featureVector(1:5) = [ ...
        mean(sig), ...
        trapz(tSel,sig), ...
        min(sig), ...
        max(sig), ...
        range(sig)];

    %% -----------------------------------------------------------------
    % PC3
    %% -----------------------------------------------------------------
    idx = ...
        t >= Windows.PC3(1) & ...
        t <= Windows.PC3(2);

    assert(any(idx), ...
        'Finestra PC3 vuota nella trial %d',iTrial);
    tSel = t(idx);
    sig = ...
        dpca(3,idx);

    featureVector(6:8) = [ ...
        mean(sig), ...
        trapz(tSel,sig), ...
        range(sig)];

    %% -----------------------------------------------------------------
    % PC2
    %% -----------------------------------------------------------------
    idx = ...
        t >= Windows.PC2(1) & ...
        t <= Windows.PC2(2);

    assert(any(idx), ...
        'Finestra PC2 vuota nella trial %d',iTrial);
    
    tSel = t(idx);
    sig = ...
        dpca(2,idx);

    if numel(sig) > 1

        dt = tSel(end) - tSel(1);

        if dt ~= 0
            slope = ...
                (sig(end) - sig(1)) / dt;
        else
            slope = 0;
        end
    else
        slope = 0;
    end

    featureVector(9:11) = [ ...
        mean(sig), ...
        trapz(tSel,sig), ...
        slope];

    %% -----------------------------------------------------------------
    % SAVE
    %% -----------------------------------------------------------------
    X(iTrial,:) = ...
        featureVector;

    Y(iTrial) = ...
        data_trials(iTrial).trialType;

    SubjectID{iTrial} = ...
        data_trials(iTrial).subjectID;

end

%% =========================================================================
% DATASET
%% =========================================================================

NSA_GuidedDataset = struct();

NSA_GuidedDataset.X = X;

NSA_GuidedDataset.Y = Y;

NSA_GuidedDataset.SubjectID = ...
    SubjectID;

NSA_GuidedDataset.FeatureNames = ...
    FeatureNames;

NSA_GuidedDataset.FeatureFamily = ...
    FeatureFamily;

NSA_GuidedDataset.nTrials = ...
    nTrials;

NSA_GuidedDataset.nFeatures = ...
    nFeatures;

NSA_GuidedDataset.Windows = ...
    Windows;

NSA_GuidedDataset.Source = ...
    'NSA_GUIDED';

NSA_GuidedDataset.cfgNSA = ...
    NSA_Manifold.cfgNSA;

%% =========================================================================
% SUMMARY
%% =========================================================================

fprintf('\n');
fprintf('================================\n');
fprintf('NSA GUIDED FEATURE DATASET\n');
fprintf('================================\n');

fprintf('Trials      : %d\n', ...
    NSA_GuidedDataset.nTrials);

fprintf('Features    : %d\n', ...
    NSA_GuidedDataset.nFeatures);

fprintf('Consonant   : %d\n', ...
    sum(Y==1));

fprintf('Dissonant   : %d\n', ...
    sum(Y==2));

fprintf('================================\n');

disp(table( ...
    FeatureNames,...
    FeatureFamily));

%% =========================================================================
% SAVE
%% =========================================================================

outdir = fullfile( ...
    projectRoot,...
    'STEP11E2_NSA_GUIDED_FEATURE_DATASET');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

save( ...
    fullfile( ...
    outdir,...
    'NSA_GuidedDataset.mat'),...
    'NSA_GuidedDataset',...
    '-v7.3');

fprintf('\n');
fprintf('STEP11E2 COMPLETED\n');
fprintf('\n');