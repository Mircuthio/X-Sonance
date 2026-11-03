%% =========================================================================
% STEP103_ERP_REDUNDANCY_ANALYSIS
% old STEP10B_ERP_REDUNDANCY_ANALYSIS
%
% Best ERP features redundancy analysis
%
% INPUT
%   FeatureRanking.mat
%   MASTER_FEATURE_DATASET.mat
%
% OUTPUT
%   ERP_Redundancy.mat
%   ERP_Redundancy.csv
%   ERP_CorrelationMatrix.mat
%
%% =========================================================================

clear
close all
clc

%% =========================================================================
% PATHS
%% =========================================================================

projectRoot = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

rankDir = fullfile( ...
    projectRoot,...
    'STEP102_FEATURE_RANKING');

datasetDir = fullfile( ...
    projectRoot,...
    'STEP101_MASTER_DATASET');

%% =========================================================================
% LOAD
%% =========================================================================

load(fullfile(rankDir,...
    'FeatureRanking.mat'));

load(fullfile(datasetDir,...
    'MASTER_FEATURE_DATASET.mat'));

X = MasterDataset.X;
FeatureNames = MasterDataset.FeatureNames;

%% =========================================================================
% CONFIG
%% =========================================================================

TOP_N = 50;

corrThreshold = 0.90;

%% =========================================================================
% SELECT TOP ERP FEATURES
%% =========================================================================

idxERP = ...
    strcmp(Ranking.FeatureFamily,'ERP');

RankingERP = Ranking(idxERP,:);

nKeep = min(TOP_N,height(RankingERP));

TopERP = RankingERP(1:nKeep,:);

fprintf('\n');
fprintf('====================================\n');
fprintf('TOP ERP FEATURES\n');
fprintf('====================================\n');

fprintf('Selected ERP features: %d\n',nKeep);

%% =========================================================================
% GET FEATURE INDICES
%% =========================================================================

FeatureIdx = zeros(nKeep,1);

for k = 1:nKeep

    idx = find(strcmp( ...
        FeatureNames,...
        TopERP.Feature{k}));

    FeatureIdx(k) = idx;

end

%% =========================================================================
% BUILD FEATURE MATRIX
%% =========================================================================

Xtop = X(:,FeatureIdx);

%% =========================================================================
% CORRELATION MATRIX
%% =========================================================================

R = corr( ...
    Xtop,...
    'Type','Spearman',...
    'Rows','pairwise');

%% =========================================================================
% FIND REDUNDANT PAIRS
%% =========================================================================

PairA = {};
PairB = {};
CorrValue = [];

for i = 1:nKeep-1

    for j = i+1:nKeep

        r = R(i,j);

        if abs(r) >= corrThreshold

            PairA{end+1,1} = ...
                TopERP.Feature{i};

            PairB{end+1,1} = ...
                TopERP.Feature{j};

            CorrValue(end+1,1) = r;

        end

    end

end

%% =========================================================================
% TABLE
%% =========================================================================

RedundantPairs = table();

RedundantPairs.Feature_A = PairA;
RedundantPairs.Feature_B = PairB;
RedundantPairs.Correlation = CorrValue;

if ~isempty(RedundantPairs)

    RedundantPairs = ...
        sortrows( ...
        RedundantPairs,...
        'Correlation',...
        'descend');

end

%% =========================================================================
% DISPLAY
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('REDUNDANT PAIRS\n');
fprintf('====================================\n');

fprintf('Threshold = %.2f\n',corrThreshold);

fprintf('Pairs found = %d\n', ...
    height(RedundantPairs));

disp( ...
    RedundantPairs( ...
    1:min(20,height(RedundantPairs)),:))

%% =========================================================================
% FEATURE FREQUENCY
%% =========================================================================

AllFeatures = [ ...
    RedundantPairs.Feature_A
    ; ...
    RedundantPairs.Feature_B];

if ~isempty(AllFeatures)

    [uFeat,~,idx] = unique(AllFeatures);

    counts = accumarray(idx,1);

    FrequencyTable = table();

    FrequencyTable.Feature = uFeat;
    FrequencyTable.Count = counts;

    FrequencyTable = ...
        sortrows( ...
        FrequencyTable,...
        'Count',...
        'descend');

else

    FrequencyTable = table();

end

%% =========================================================================
% SAVE
%% =========================================================================

outdir = fullfile( ...
    projectRoot,...
    'STEP103_REDUNDANCY');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

save( ...
    fullfile(outdir,...
    'ERP_CorrelationMatrix.mat'),...
    'R',...
    'TopERP');

save( ...
    fullfile(outdir,...
    'ERP_Redundancy.mat'),...
    'RedundantPairs',...
    'FrequencyTable');

writetable( ...
    RedundantPairs,...
    fullfile(outdir,...
    'ERP_RedundantPairs.csv'));

writetable( ...
    FrequencyTable,...
    fullfile(outdir,...
    'ERP_FeatureFrequency.csv'));

fprintf('\n');
fprintf('====================================\n');
fprintf('REDUNDANCY ANALYSIS COMPLETED\n');
fprintf('====================================\n');