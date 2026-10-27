function MasterDataset = ...
    build_master_feature_dataset( ...
    subj_list,...
    cfgFD)

%% ---------------------------------------------------------------------
% PASSO 1: CONTEGGIO TRIAL VALIDI E NUMERO FEATURE
%% ---------------------------------------------------------------------
nTrialsValid = 0;
nFeatures = [];
FeatureNames = {};
FeatureFamily = {};

for iSub = 1:numel(subj_list)
    data_trials = subj_list(iSub).data_trials;
    
    for iTr = 1:numel(data_trials)
        tr = data_trials(iTr);
        
        if ~ismember(tr.eventCode,cfgFD.class_codes)
            continue
        end
        
        nTrialsValid = nTrialsValid + 1;
        
        % Determina feature names e numero feature dalla prima trial valida
        if isempty(FeatureNames)
            featERP = extract_erp_features_v2(tr,cfgFD);
            featBP  = extract_bandpower_features_v2(tr,cfgFD);
            FeatureNames = [featERP.Names featBP.Names];
            FeatureFamily = [ ...
                repmat({'ERP'},1,numel(featERP.Names)) ...
                repmat({'BandPower'},1,numel(featBP.Names))];
            nFeatures = numel(FeatureNames);
        end
    end
end

if nTrialsValid == 0
    error('Nessuna trial valida trovata con i class_codes specificati.');
end

%% ---------------------------------------------------------------------
% PASSO 2: PREALLOCAZIONE
%% ---------------------------------------------------------------------
X = nan(nTrialsValid,nFeatures);
Y = nan(nTrialsValid,1);
SubjectID = cell(nTrialsValid,1);
TrialID = cell(nTrialsValid,1);
EventLabel = cell(nTrialsValid,1);

rowIdx = 0;

%% ---------------------------------------------------------------------
% PASSO 3: ESTRAZIONE FEATURES
%% ---------------------------------------------------------------------
for iSub = 1:numel(subj_list)
    subjID = subj_list(iSub).subj_id;
    data_trials = subj_list(iSub).data_trials;
    
    for iTr = 1:numel(data_trials)
        tr = data_trials(iTr);
        
        if ~ismember(tr.eventCode,cfgFD.class_codes)
            continue
        end
        
        idxClass = find(cfgFD.class_codes == tr.eventCode,1);
        
        featERP = extract_erp_features_v2(tr,cfgFD);
        featBP  = extract_bandpower_features_v2(tr,cfgFD);
        
        feat = [featERP.Values featBP.Values];
        
        if numel(feat) ~= nFeatures
            error(['Il numero di feature cambia tra le trial. ' ...
                   'Atteso: %d, trovato: %d.'], ...
                   nFeatures,numel(feat));
        end
        
        rowIdx = rowIdx + 1;
        
        X(rowIdx,:) = feat;
        Y(rowIdx,1) = idxClass;
        SubjectID{rowIdx,1} = subjID;
        TrialID{rowIdx,1} = tr.trialID;
        EventLabel{rowIdx,1} = tr.eventLabel;
    end
end

%% ---------------------------------------------------------------------
% OUTPUT
%% ---------------------------------------------------------------------
MasterDataset = struct();
MasterDataset.X = X;
MasterDataset.Y = Y;
MasterDataset.SubjectID = SubjectID;
MasterDataset.TrialID = TrialID;
MasterDataset.EventLabel = EventLabel;
MasterDataset.FeatureNames = FeatureNames;
MasterDataset.FeatureFamily = FeatureFamily;
MasterDataset.nTrials = rowIdx;
MasterDataset.nFeatures = nFeatures;
MasterDataset.cfg = cfgFD;
MasterDataset.FeatureIndex.ERP = ...
    strcmp(FeatureFamily,'ERP');
MasterDataset.FeatureIndex.BandPower = ...
    strcmp(FeatureFamily,'BandPower');
end