%% =========================================================================
% STEP11E_NSA_FEATURE_DATASET
%
% BUILD FEATURE DATASET FROM NSA MANIFOLD
%
% INPUT
%
%   STEP11B_NSA_MANIFOLD/NSA_Manifold.mat
%
% OUTPUT
%
%   NSA_FeatureDataset.mat
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
% COMPONENTS
%% =========================================================================

nComponents = ...
    size(data_trials(1).dpca,1);

nTrials = ...
    numel(data_trials);

%% =========================================================================
% FEATURE NAMES
%% =========================================================================

FeatureTypes = { ...
    'Mean'
    'Std'
    'RMS'
    'MinPeak'
    'MaxPeak'
    'PeakToPeak'
    'AUC'};

nFeatures = nComponents * numel(FeatureTypes);

FeatureNames = cell(nFeatures,1);
FeatureFamily = cell(nFeatures,1);

iFeature = 0;

for iComp = 1:nComponents
    for iFeat = 1:numel(FeatureTypes)
        iFeature = iFeature + 1;

        FeatureNames{iFeature,1} = ...
            sprintf('PC%d_%s', ...
            iComp, ...
            FeatureTypes{iFeat});

        FeatureFamily{iFeature,1} = ...
            'NSA';
    end
end


%% =========================================================================
% FEATURE EXTRACTION
%% =========================================================================
nFeaturesPerComponent = 7;
nFeatures = nComponents * nFeaturesPerComponent;

X = nan(nTrials,nFeatures);
Y = nan(nTrials,1);
SubjectID = cell(nTrials,1);

for iTrial = 1:nTrials

    dpca = ...
        data_trials(iTrial).dpca;

    featureVector = nan(1,nFeatures);
    iFeature = 0;

    for iComp = 1:nComponents

        signal = ...
            dpca(iComp,:);

        MeanVal = ...
            mean(signal);
        StdVal = ...
            std(signal);
        RMSVal = ...
            rms(signal);
        MinPeak = ...
            min(signal);
        MaxPeak = ...
            max(signal);
        PeakToPeak = ...
            MaxPeak - MinPeak;
        AUC = ...
            trapz(signal);

        featureVector(iFeature+1:iFeature+nFeaturesPerComponent) = ...
            [ ...
            MeanVal, ...
            StdVal, ...
            RMSVal, ...
            MinPeak, ...
            MaxPeak, ...
            PeakToPeak, ...
            AUC];

        iFeature = iFeature + nFeaturesPerComponent;

    end

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

NSA_FeatureDataset = struct();

NSA_FeatureDataset.X = ...
    X;

NSA_FeatureDataset.Y = ...
    Y;

NSA_FeatureDataset.SubjectID = ...
    SubjectID;

NSA_FeatureDataset.FeatureNames = ...
    FeatureNames;

NSA_FeatureDataset.FeatureFamily = ...
    FeatureFamily;

NSA_FeatureDataset.nTrials = ...
    nTrials;

NSA_FeatureDataset.nFeatures = ...
    nFeatures;

NSA_FeatureDataset.cfgNSA = ...
    NSA_Manifold.cfgNSA;

%% =========================================================================
% SUMMARY
%% =========================================================================

fprintf('\n');

fprintf('================================\n');
fprintf('NSA FEATURE DATASET\n');
fprintf('================================\n');

fprintf('Trials      : %d\n', ...
    nTrials);

fprintf('Components  : %d\n', ...
    nComponents);

fprintf('Features    : %d\n', ...
    nFeatures);

fprintf('Consonant   : %d\n', ...
    sum(Y==1));

fprintf('Dissonant   : %d\n', ...
    sum(Y==2));

fprintf('================================\n');

%% =========================================================================
% SAVE
%% =========================================================================

outdir = fullfile( ...
    projectRoot,...
    'STEP11E_NSA_FEATURE_DATASET');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

save( ...
    fullfile( ...
    outdir,...
    'NSA_FeatureDataset.mat'),...
    'NSA_FeatureDataset',...
    '-v7.3');

fprintf('\n');
fprintf('STEP11E COMPLETED\n');
fprintf('\n');