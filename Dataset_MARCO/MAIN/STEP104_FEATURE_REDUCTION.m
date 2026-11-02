%% =========================================================================
% STEP104_FEATURE_REDUCTION
%
% Correlation-based feature reduction
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
    'STEP10_MASTER_DATASET',...
    'MASTER_FEATURE_DATASET.mat'));

load(fullfile( ...
    projectRoot,...
    'STEP10_FEATURE_RANKING',...
    'FeatureRanking.mat'));

X = MasterDataset.X;
Y = MasterDataset.Y;

%% =========================================================================
% PARAMETERS
%% =========================================================================

cfgFR = struct();

cfgFR.useFDR           = true;
cfgFR.fdrThreshold     = 0.05;

cfgFR.useCorrelation   = true;
cfgFR.corrThreshold    = 0.90;

%% =========================================================================
% STEP1 - FDR FILTER
%% =========================================================================

idxKeep = true(height(Ranking),1);

if cfgFR.useFDR

    idxKeep = ...
        Ranking.PValue_FDR < cfgFR.fdrThreshold;

end

RankingKeep = Ranking(idxKeep,:);

fprintf('\n');
fprintf('After FDR: %d features\n',height(RankingKeep));

%% =========================================================================
% FEATURE INDEX
%% =========================================================================

[~,idxMaster] = ...
    ismember(RankingKeep.Feature,...
             MasterDataset.FeatureNames);

Xkeep = X(:,idxMaster);

%% =========================================================================
% STEP2 - CORRELATION REDUCTION
%% =========================================================================

nFeat = size(Xkeep,2);

corrMat = ...
    abs(corr(Xkeep,...
    'rows','pairwise'));

corrMat(1:nFeat+1:end) = 0;

Selected = true(nFeat,1);

for i = 1:nFeat

    if ~Selected(i)
        continue
    end

    redundant = ...
        find(corrMat(i,:) > cfgFR.corrThreshold);

    redundant(redundant<=i) = [];

    Selected(redundant) = false;

end

%% =========================================================================
% REDUCED SET
%% =========================================================================

RankingReduced = ...
    RankingKeep(Selected,:);

[~,idxMasterReduced] = ...
    ismember(RankingReduced.Feature,...
             MasterDataset.FeatureNames);

XReduced = ...
    MasterDataset.X(:,idxMasterReduced);

%% =========================================================================
% SUMMARY
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('FEATURE REDUCTION\n');
fprintf('====================================\n');

fprintf('Original Features : %d\n', ...
    MasterDataset.nFeatures);

fprintf('After FDR         : %d\n', ...
    height(RankingKeep));

fprintf('After Correlation : %d\n', ...
    height(RankingReduced));

%% =========================================================================
% SAVE
%% =========================================================================

ReducedDataset = struct();

ReducedDataset.X = XReduced;
ReducedDataset.Y = MasterDataset.Y;

ReducedDataset.SubjectID = ...
    MasterDataset.SubjectID;

ReducedDataset.TrialID = ...
    MasterDataset.TrialID;

ReducedDataset.EventLabel = ...
    MasterDataset.EventLabel;

ReducedDataset.FeatureNames = ...
    RankingReduced.Feature;

ReducedDataset.FeatureFamily = ...
    RankingReduced.FeatureFamily;

ReducedDataset.Ranking = ...
    RankingReduced;

ReducedDataset.nTrials = ...
    size(XReduced,1);

ReducedDataset.nFeatures = ...
    size(XReduced,2);

ReducedDataset.cfgFR = ...
    cfgFR;

outdir = fullfile( ...
    projectRoot,...
    'STEP11_FEATURE_REDUCTION');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

save( ...
    fullfile(outdir,...
    'ReducedDataset.mat'),...
    'ReducedDataset',...
    '-v7.3');

writetable( ...
    RankingReduced,...
    fullfile(outdir,...
    'ReducedFeatures.csv'));

fprintf('\n');
fprintf('REDUCTION COMPLETED\n');