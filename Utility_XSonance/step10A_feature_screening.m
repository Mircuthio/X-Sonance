function Results = ...
    step10A_feature_screening( ...
    FeatureDataset,...
    cfgFD)

X = FeatureDataset.X;

Y = FeatureDataset.Y;

nFeatures = ...
    size(X,2);

Results = struct();

Results.Feature = ...
    FeatureDataset.FeatureNames(:);

Results.AUC = ...
    nan(nFeatures,1);

Results.CohenD = ...
    nan(nFeatures,1);

Results.pValue = ...
    nan(nFeatures,1);

for iF = 1:nFeatures

    feat = X(:,iF);

    idx1 = Y == 1;
    idx2 = Y == 2;

    g1 = feat(idx1);
    g2 = feat(idx2);

    %% TTEST

    [~,p] = ...
        ttest2(g1,g2);

    Results.pValue(iF) = p;

    %% COHEN D

    pooledStd = ...
        sqrt( ...
        (var(g1)+var(g2))/2);

    Results.CohenD(iF) = ...
        (mean(g2)-mean(g1)) ...
        / pooledStd;

    %% AUC

    try

        labels = ...
            double(idx2);

        [~,~,~,auc] = ...
            perfcurve( ...
            labels,...
            feat,...
            1);

        Results.AUC(iF) = auc;

    catch

        Results.AUC(iF) = NaN;

    end

end

end