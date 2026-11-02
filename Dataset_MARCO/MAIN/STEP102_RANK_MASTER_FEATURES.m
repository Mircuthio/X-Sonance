%% =========================================================================
% STEP10_RANK_MASTER_FEATURES
%
% Ranking univariato delle feature
% Consonanza vs Dissonanza
%
% Input:
%   MASTER_FEATURE_DATASET.mat
%
% Output:
%   FeatureRanking.csv
%   FeatureRanking.mat
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

X = MasterDataset.X;
Y = MasterDataset.Y;

fprintf('\n');
fprintf('Class balance\n');
tabulate(Y)

FeatureNames = ...
    MasterDataset.FeatureNames;

%% =========================================================================
% CHECK
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('MASTER DATASET\n');
fprintf('====================================\n');

fprintf('Trials   : %d\n',size(X,1));
fprintf('Features : %d\n',size(X,2));

%% =========================================================================
% PREALLOC
%% =========================================================================

nFeatures = size(X,2);

AUC_raw     = nan(nFeatures,1);
AUC_abs     = nan(nFeatures,1);
CohenD      = nan(nFeatures,1);
CohenD_signed = nan(nFeatures,1);
PValue      = nan(nFeatures,1);
Direction   = nan(nFeatures,1);
%% =========================================================================
% FEATURE LOOP
%% =========================================================================

for iFeat = 1:nFeatures

    scores = X(:,iFeat);

    idxOK = ...
        isfinite(scores);

    scores = scores(idxOK);
    labels = Y(idxOK);

    g1 = scores(labels==1);
    g2 = scores(labels==2);
    
    if isempty(g1) || isempty(g2)
        continue
    end
    %% --------------------------------------------------------
    % AUC
    %% --------------------------------------------------------

    try
        [~,~,~,aucRaw] = perfcurve(labels,scores,2);
    catch ME
        warning('AUC failed for feature %d: %s',iFeat,ME.message);
        aucRaw = NaN;
    end

    %% --------------------------------------------------------
    % Cohen D
    %% --------------------------------------------------------
    m1 = mean(g1);
    m2 = mean(g2);
    Direction(iFeat) = m2 - m1;

    sd1 = std(g1);
    sd2 = std(g2);
    spooled = sqrt((sd1.^2 + sd2.^2)/2);

    if spooled < eps
        dSigned = 0;
    else
        dSigned = (m2 - m1) / spooled;
    end

    %% --------------------------------------------------------
    % RankSum
    %% --------------------------------------------------------
    try
        p = ranksum(g1,g2);
    catch ME
        warning('ranksum failed for feature %d: %s',iFeat,ME.message);
        p = NaN;
    end

    %% --------------------------------------------------------
    % SAVE
    %% --------------------------------------------------------

    AUC_raw(iFeat) = aucRaw;
    AUC_abs(iFeat) = max(aucRaw,1-aucRaw);
    CohenD_signed(iFeat) = dSigned;
    CohenD(iFeat)        = abs(dSigned);
    PValue(iFeat) = p;

end
validFeat = isfinite(AUC_abs) & isfinite(CohenD) & isfinite(PValue);

fprintf('\n');
fprintf('Valid features   : %d / %d\n',sum(validFeat),nFeatures);
fprintf('Invalid features : %d\n',sum(~validFeat));

pFDR = nan(nFeatures,1);

[~,~,~,adj_p] = fdr_bh(PValue(validFeat));

pFDR(validFeat) = adj_p;

fprintf('FDR q < 0.05     : %d\n', sum(pFDR < 0.05));
%% =========================================================================
% RANKING
%% =========================================================================
% Higher AUC/d = better; lower p = better.
RankAUC_abs = tiedrank(AUC_abs);
RankD       = tiedrank(CohenD);
RankP       = tiedrank(-PValue);

% Normalize ranks to [0,1], so the three metrics contribute comparably.
RankAUC_abs_norm = RankAUC_abs / max(RankAUC_abs);
RankD_norm       = RankD       / max(RankD);
RankP_norm       = RankP       / max(RankP);

CombinedRank = ...
    RankAUC_abs_norm + ...
    RankD_norm + ...
    RankP_norm;

RankAUC_abs(~validFeat) = NaN;
RankD(~validFeat)       = NaN;
RankP(~validFeat)       = NaN;
CombinedRank(~validFeat) = NaN;

%% =========================================================================
% TABLE
%% =========================================================================
DominantClass = strings(nFeatures,1);
DominantClass(Direction > 0) = "Dissonance";
DominantClass(Direction < 0) = "Consonance";
DominantClass(~isfinite(Direction)) = "Undefined";

Ranking = table();
Ranking.Feature          = FeatureNames(:);
Ranking.FeatureFamily    = MasterDataset.FeatureFamily(:);
Ranking.AUC_raw          = AUC_raw;
Ranking.AUC_abs          = AUC_abs;
Ranking.CohenD_signed    = CohenD_signed;
Ranking.CohenD           = CohenD;
Ranking.PValue           = PValue;
Ranking.PValue_FDR       = pFDR;
Ranking.Direction        = Direction;
Ranking.DominantClass    = DominantClass;
Ranking.RankAUC_abs      = RankAUC_abs;
Ranking.RankD            = RankD;
Ranking.RankP            = RankP;
Ranking.RankAUC_abs_norm = RankAUC_abs_norm;
Ranking.RankD_norm       = RankD_norm;
Ranking.RankP_norm       = RankP_norm;
Ranking.CombinedRank     = CombinedRank;
Ranking.ValidFeature     = validFeat;

Ranking = sortrows(Ranking,'CombinedRank','descend','MissingPlacement','last');

%% =========================================================================
% DISPLAY
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('TOP 30 FEATURES\n');
fprintf('====================================\n');

disp(Ranking(1:min(30,height(Ranking)),:))

%% =========================================================================
% SAVE
%% =========================================================================

outdir = fullfile( ...
    projectRoot,...
    'STEP10_FEATURE_RANKING');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

save( ...
    fullfile(outdir,...
    'FeatureRanking.mat'),...
    'Ranking',...
    '-v7.3');

writetable( ...
    Ranking,...
    fullfile(outdir,...
    'FeatureRanking.csv'));

fprintf('\n');
fprintf('====================================\n');
fprintf('FEATURE RANKING COMPLETED\n');
fprintf('====================================\n');