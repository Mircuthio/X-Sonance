function Subsets = ...
    create_feature_subsets( ...
    MasterDataset)

%% ============================================================
% INITIALIZATION
%% ============================================================

Subsets = struct();

X = MasterDataset.X;
Y = MasterDataset.Y;

FeatureNames = MasterDataset.FeatureNames;
FeatureFamily = MasterDataset.FeatureFamily;

%% ============================================================
% ERP ONLY
%% ============================================================

idxERP = MasterDataset.FeatureIndex.ERP;

Subsets.ERP_ONLY.X = X(:,idxERP);
Subsets.ERP_ONLY.Y = Y;
Subsets.ERP_ONLY.FeatureNames = ...
    FeatureNames(idxERP);

%% ============================================================
% BANDPOWER ONLY
%% ============================================================

idxBP = MasterDataset.FeatureIndex.BandPower;

Subsets.BANDPOWER_ONLY.X = X(:,idxBP);
Subsets.BANDPOWER_ONLY.Y = Y;
Subsets.BANDPOWER_ONLY.FeatureNames = ...
    FeatureNames(idxBP);

%% ============================================================
% ERP + BANDPOWER
%% ============================================================

idxERPBP = idxERP | idxBP;

Subsets.ERP_BANDPOWER.X = X(:,idxERPBP);
Subsets.ERP_BANDPOWER.Y = Y;
Subsets.ERP_BANDPOWER.FeatureNames = ...
    FeatureNames(idxERPBP);

%% ============================================================
% FULL
%% ============================================================

Subsets.FULL.X = X;
Subsets.FULL.Y = Y;
Subsets.FULL.FeatureNames = FeatureNames;

%% ============================================================
% METADATA
%% ============================================================

Subsets.SubjectID = ...
    MasterDataset.SubjectID;

Subsets.TrialID = ...
    MasterDataset.TrialID;

Subsets.EventLabel = ...
    MasterDataset.EventLabel;

Subsets.cfg = MasterDataset.cfg;

end
