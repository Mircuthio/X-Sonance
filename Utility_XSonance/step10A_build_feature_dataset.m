function FeatureDataset = ...
    step10A_build_feature_dataset( ...
    BandPower_Dataset,...
    cfgFD)

fprintf('\nBuilding trial dataset...\n');

Trials = ...
    BandPower_Dataset.trials;

nTrials = ...
    numel(Trials);
%% ============================================================
% FEATURE COUNT
%% ============================================================

nROI = ...
    numel(cfgFD.analysis_rois);

nWin = ...
    numel(fieldnames(cfgFD.windows));

nERPFeat = ...
    numel(cfgFD.erp_features);

nComplex = ...
    numel(cfgFD.erp_complex_features);

nBands = ...
    numel(cfgFD.analysis_bands);

nFeatures = ...
    nROI*nWin*nERPFeat + ...
    nROI*nComplex + ...
    nROI*nWin*nBands;

%% ============================================================
% PREALLOCATION
%% ============================================================

X = nan(nTrials,nFeatures);

FeatureNames = ...
    cell(1,nFeatures);

Y = nan(nTrials,1);

SubjectID = ...
    cell(nTrials,1);

%% ============================================================
% FEATURE EXTRACTION
%% ============================================================

for iTr = 1:nTrials

    tr = Trials(iTr);

    if mod(iTr,100)==0
        fprintf( ...
            'Trial %d/%d\n',...
            iTr,nTrials);
    end

    [featVec,featNames] = ...
        step10A_extract_trial_features( ...
        tr,...
        cfgFD);

    X(iTr,:) = featVec;

    if iTr == 1
        FeatureNames = featNames;
    end

    Y(iTr) = tr.trialType;

    SubjectID{iTr} = ...
        tr.subjectID;

end

%% ============================================================
% OUTPUT
%% ============================================================

FeatureDataset = struct();

FeatureDataset.X = X;
FeatureDataset.Y = Y;

FeatureDataset.FeatureNames = ...
    FeatureNames;

FeatureDataset.SubjectID = ...
    SubjectID;

end