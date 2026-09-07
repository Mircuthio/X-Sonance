function Cases = build_fbcsp_cases()

iCase = 0;

%% ============================================================
% TEMPLATE
%% ============================================================

base = struct();

base.group = 'PART1';

base.class_labels = { ...
    'Consonant',...
    'Dissonant'};

base.class_codes = [7 8];

base.labelMap = struct();

base.labelMap.ControlGOAL = 1;
base.labelMap.Consonant = 2;
base.labelMap.Dissonant = 3;


base.useSubEpochs = false;
base.subEpochLength = [];
base.subEpochOverlap = [];

base.useFilterBank = true;
base.filterBankName = 'EEGbands';

base.csp_components = 4;

base.useMI = true;
base.mi_k = 5;

base.classifiers = {'QDA','NB','KNN'};

base.name = '';
base.time_window = [];

Cases = repmat(base,0,1);

%% ============================================================
% FULL
%% ============================================================


iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'FULL_CD';

Cases(iCase).time_window = ...
    [-0.5 1.0];

%% ============================================================
% ERAN EARLY
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'ERAN_EARLY_CD';

Cases(iCase).time_window = ...
    [0.08 0.15];

%% ============================================================
% ERAN DERIVED
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'ERAN_DERIVED_CD';

Cases(iCase).time_window = ...
    [0.17 0.22];

%% ============================================================
% MMN EARLY
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'MMN_EARLY_CD';

Cases(iCase).time_window = ...
    [0.10 0.20];

%% ============================================================
% MMN LATE
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'MMN_LATE_CD';

Cases(iCase).time_window = ...
    [0.20 0.30];

%% ============================================================
% N5 EARLY
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'N5_EARLY_CD';

Cases(iCase).time_window = ...
    [0.30 0.40];

%% ============================================================
% N5 DERIVED
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'N5_DERIVED_CD';

Cases(iCase).time_window = ...
    [0.45 0.55];
%% ============================================================
% PART2
% CONTROLGOAL vs CONSONANT vs DISSONANT
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).group = ...
    'PART2';

Cases(iCase).name = ...
    'FULL_CCD';

Cases(iCase).class_labels = { ...
    'ControlGOAL',...
    'Consonant',...
    'Dissonant'};

Cases(iCase).class_codes = ...
    [3 7 8];

Cases(iCase).labelMap = struct();

Cases(iCase).labelMap.ControlGOAL = 1;
Cases(iCase).labelMap.Consonant = 2;
Cases(iCase).labelMap.Dissonant = 3;

Cases(iCase).time_window = ...
    [-0.5 1.0];
end