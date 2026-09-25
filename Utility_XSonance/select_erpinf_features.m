function DatasetOut = ...
    select_erpinf_features( ...
    DatasetIn,...
    featureGroups)

%% ============================================================
% INPUT CHECK
%% ============================================================

if nargin < 2

    error( ...
        'select_erpinf_features requires DatasetIn and featureGroups');

end

assert( ...
    isfield(DatasetIn,'FeatureNames'), ...
    'DatasetIn.FeatureNames not found');

assert( ...
    isfield(DatasetIn,'trials'), ...
    'DatasetIn.trials not found');

FeatureNames = ...
    string(DatasetIn.FeatureNames);

%% ============================================================
% VALID GROUPS
%% ============================================================

validGroups = { ...
    'ERPINDEX',...
    'ERAN_B',...
    'BETALOW'};

featureGroups = ...
    upper(string(featureGroups));

%% ============================================================
% CHECK REQUEST
%% ============================================================

for iG = 1:numel(featureGroups)

    if ~ismember( ...
            featureGroups(iG), ...
            string(validGroups))

        error( ...
            'Feature group "%s" does not exist.\nValid groups are:\n%s',...
            featureGroups(iG),...
            strjoin(validGroups,', '));

    end

end

%% ============================================================
% EXPLICIT FEATURE DEFINITIONS
%% ============================================================

FeatureMap = struct();

%% ------------------------------------------------------------
% ERPINDEX
%% ------------------------------------------------------------

FeatureMap.ERPINDEX = string({ ...
    'ERAN_CORE_ERPIndex'
    'MMN_ERPIndex'
    'ERAN_RIGHT_ERPIndex'
    'N5_CENTRAL_ERPIndex'
    });

%% ------------------------------------------------------------
% ERAN_B
%% ------------------------------------------------------------

FeatureMap.ERAN_B = string({ ...
    'ERAN_CORE_ERAN_B_Mean'
    'ERAN_CORE_ERAN_B_AUC'
    'MMN_ERAN_B_Mean'
    'MMN_ERAN_B_AUC'
    'ERAN_CORE_ERAN_B_MinPeak'
    'MMN_ERAN_B_MinPeak'
    });

%% ------------------------------------------------------------
% BETALOW
%% ------------------------------------------------------------

FeatureMap.BETALOW = string({ ...
    'N5_CENTRAL_BetaLow_REB_A'
    'N5_CENTRAL_BetaLow_REB_B'
    'MMN_BetaLow_REB_A'
    'MMN_BetaLow_REB_B'
    'N5_CENTRAL_BetaLow_ERAN_A'
    'N5_CENTRAL_BetaLow_ERAN_B'
    });

%% ============================================================
% BUILD INDEX LIST
%% ============================================================

keepIdx = [];

for iG = 1:numel(featureGroups)

    currGroup = ...
        char(featureGroups(iG));

    requestedNames = ...
        FeatureMap.(currGroup);

    idx = find( ...
        ismember( ...
        FeatureNames,...
        requestedNames));

    missingNames = ...
        setdiff( ...
        requestedNames,...
        FeatureNames);

    if ~isempty(missingNames)

        error( ...
            'Missing feature(s) for group "%s":\n%s',...
            currGroup,...
            strjoin(cellstr(missingNames),', '));

    end

    keepIdx = ...
        [keepIdx idx(:)'];

end

%% ============================================================
% FINAL CHECK
%% ============================================================

keepIdx = ...
    unique(keepIdx);

if isempty(keepIdx)

    error('No features selected');

end

%% ============================================================
% COPY DATASET
%% ============================================================

DatasetOut = ...
    DatasetIn;

%% ============================================================
% APPLY SELECTION
%% ============================================================

for iTr = 1:numel(DatasetOut.trials)

    DatasetOut.trials(iTr).ERPINF = ...
        DatasetOut.trials(iTr).ERPINF(keepIdx);

    DatasetOut.trials(iTr).timeERPINF = ...
        1:numel(keepIdx);

end

DatasetOut.FeatureNames = ...
    cellstr(FeatureNames(keepIdx));

DatasetOut.nFeatures = ...
    numel(keepIdx);

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('ERP FEATURE SELECTION\n');
fprintf('================================\n');

fprintf('Requested Groups:\n');
disp(featureGroups(:))

fprintf('\n');
fprintf('Features retained : %d\n', ...
    DatasetOut.nFeatures);

fprintf('\n');
fprintf('Selected Features:\n');
disp(DatasetOut.FeatureNames(:))

fprintf('================================\n');

end