function Cases = build_fbcsp_cases()

iCase = 0;

%% ============================================================
% TEMPLATE
%% ============================================================
base = struct();

% ---- Identification
base.name = '';
base.group = '';
base.case_id = '';

% ---- Class selection
base.class_codes = [];
base.class_labels = {};

% ---- Time window
base.time_window = [];

% ---- Optional epoching
base.useSubEpochs = false;
base.subEpochLength = [];
base.subEpochOverlap = [];

% ---- Filter bank / CSP / MI / classifiers
base.useFilterBank = true;
base.filterBankName = 'EEGbands';
base.csp_components = 4;
base.useMI = true;
base.mi_k = 5;
base.classifiers = {'QDA','NB','KNN'};

% ---- Optional metadata
base.notes = '';

Cases = repmat(base, 0, 1);

%% ============================================================
% PART1
% CONSONANT vs DISSONANT
%% ============================================================

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_01';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'FULL_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [-0.5 1.0];
Cases(iCase).notes = 'Full epoch, Consonant vs Dissonant';


iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_02';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'ERAN_EARLY_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [0.05 0.20];
Cases(iCase).notes = 'ERAN early window, Consonant vs Dissonant';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_03';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'ERAN_LATE_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [0.15 0.30];
Cases(iCase).notes = 'ERAN late window, Consonant vs Dissonant';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_04';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'ERAN_FULL_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [0.05 0.30];
Cases(iCase).notes = 'ERAN full window, Consonant vs Dissonant';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_05';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'MMN_EARLY_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [0.10 0.20];
Cases(iCase).notes = 'MMN early window, Consonant vs Dissonant';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_06';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'MMN_LATE_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [0.20 0.30];
Cases(iCase).notes = 'MMN late window, Consonant vs Dissonant';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_07';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'N5_EARLY_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [0.30 0.40];
Cases(iCase).notes = 'N5 early window, Consonant vs Dissonant';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P1_08';
Cases(iCase).group = 'PART1';
Cases(iCase).name = 'N5_DERIVED_CD';
Cases(iCase).class_codes = [7 8];
Cases(iCase).class_labels = {'Consonant','Dissonant'};
Cases(iCase).time_window = [0.45 0.55];
Cases(iCase).notes = 'N5 derived window, Consonant vs Dissonant';

%% ============================================================
% PART2
% CONTROLGOAL vs CONSONANT vs DISSONANT
%% ============================================================

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_01';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'FULL_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [-0.5 1.0];
Cases(iCase).notes = 'Full epoch, Consonant vs Dissonant vs ControlGOAL';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_02';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'ERAN_EARLY_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [0.05 0.20];
Cases(iCase).notes = 'ERAN early window, Consonant vs Dissonant vs ControlGOAL';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_03';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'ERAN_LATE_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [0.15 0.30];
Cases(iCase).notes = 'ERAN late window, Consonant vs Dissonant vs ControlGOAL';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_04';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'ERAN_FULL_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [0.05 0.30];
Cases(iCase).notes = 'ERAN full window, Consonant vs Dissonant vs ControlGOAL';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_05';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'MMN_EARLY_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [0.10 0.20];
Cases(iCase).notes = 'MMN early window, Consonant vs Dissonant vs ControlGOAL';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_06';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'MMN_LATE_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [0.20 0.30];
Cases(iCase).notes = 'MMN late window, Consonant vs Dissonant vs ControlGOAL';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_07';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'N5_EARLY_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [0.30 0.40];
Cases(iCase).notes = 'N5 early window, Consonant vs Dissonant vs ControlGOAL';

iCase = iCase + 1;
Cases(iCase) = base;
Cases(iCase).case_id = 'P2_08';
Cases(iCase).group = 'PART2';
Cases(iCase).name = 'N5_DERIVED_CCD';
Cases(iCase).class_codes = [7 8 3];
Cases(iCase).class_labels = {'Consonant','Dissonant','ControlGOAL'};
Cases(iCase).time_window = [0.45 0.55];
Cases(iCase).notes = 'N5 derived window, Consonant vs Dissonant vs ControlGOAL';


%% ============================================================
% PART3
% ERP GUIDED FBCSP
%% ============================================================

%% ------------------------------------------------------------
% P3_01
% ERAN_B WINDOW
%% ------------------------------------------------------------

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P3_01';

Cases(iCase).group = ...
    'PART3_ERP_GUIDED';

Cases(iCase).name = ...
    'ERANB_150_350_CD';

Cases(iCase).class_codes = ...
    [7 8];

Cases(iCase).class_labels = ...
    {'Consonant','Dissonant'};

Cases(iCase).time_window = ...
    [0.15 0.35];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = ...
    4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = ...
    8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP. ERAN_B focused window 150-350 ms';

%% ------------------------------------------------------------
% P3_02
% ERAN + N5 WINDOW
%% ------------------------------------------------------------

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P3_02';

Cases(iCase).group = ...
    'PART3_ERP_GUIDED';

Cases(iCase).name = ...
    'ERANB_150_500_CD';

Cases(iCase).class_codes = ...
    [7 8];

Cases(iCase).class_labels = ...
    {'Consonant','Dissonant'};

Cases(iCase).time_window = ...
    [0.15 0.50];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = ...
    4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = ...
    8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP. Extended ERAN/N5 window 150-500 ms';

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P4_01';

Cases(iCase).group = ...
    'PART4_ERP_GUIDED_150_350';

Cases(iCase).name = ...
    'ERANB_150_350_CON_CONTROL';

Cases(iCase).class_codes = ...
    [7 3];

Cases(iCase).class_labels = ...
    {'Consonant','ControlGOAL'};

Cases(iCase).time_window = ...
    [0.15 0.35];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = 4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = 8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP 150-350 ms. Consonant vs ControlGOAL';

% P4_02
iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P4_02';

Cases(iCase).group = ...
    'PART4_ERP_GUIDED_150_350';

Cases(iCase).name = ...
    'ERANB_150_350_DIS_CONTROL';

Cases(iCase).class_codes = ...
    [8 3];

Cases(iCase).class_labels = ...
    {'Dissonant','ControlGOAL'};

Cases(iCase).time_window = ...
    [0.15 0.35];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = 4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = 8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP 150-350 ms. Dissonant vs ControlGOAL';

% P4_03
iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P4_03';

Cases(iCase).group = ...
    'PART4_ERP_GUIDED_150_350';

Cases(iCase).name = ...
    'ERANB_150_350_CD_CONTROL';

Cases(iCase).class_codes = ...
    [7 8 3];

Cases(iCase).class_labels = ...
    {'Consonant','Dissonant','ControlGOAL'};

Cases(iCase).time_window = ...
    [0.15 0.35];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = 4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = 8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP 150-350 ms. Consonant vs Dissonant vs ControlGOAL';


% P5_01
iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P5_01';

Cases(iCase).group = ...
    'PART5_ERP_GUIDED_150_500';

Cases(iCase).name = ...
    'ERANB_150_500_CON_CONTROL';

Cases(iCase).class_codes = ...
    [7 3];

Cases(iCase).class_labels = ...
    {'Consonant','ControlGOAL'};

Cases(iCase).time_window = ...
    [0.15 0.50];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = 4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = 8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP 150-500 ms. Consonant vs ControlGOAL';

% P5_02
iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P5_02';

Cases(iCase).group = ...
    'PART5_ERP_GUIDED_150_500';

Cases(iCase).name = ...
    'ERANB_150_500_DIS_CONTROL';

Cases(iCase).class_codes = ...
    [8 3];

Cases(iCase).class_labels = ...
    {'Dissonant','ControlGOAL'};

Cases(iCase).time_window = ...
    [0.15 0.50];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = 4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = 8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP 150-500 ms. Dissonant vs ControlGOAL';


%P5_03
iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).case_id = 'P5_03';

Cases(iCase).group = ...
    'PART5_ERP_GUIDED_150_500';

Cases(iCase).name = ...
    'ERANB_150_500_CD_CONTROL';

Cases(iCase).class_codes = ...
    [7 8 3];

Cases(iCase).class_labels = ...
    {'Consonant','Dissonant','ControlGOAL'};

Cases(iCase).time_window = ...
    [0.15 0.50];

Cases(iCase).useSubEpochs = true;

Cases(iCase).subEpochLength = ...
    0.075;

Cases(iCase).subEpochOverlap = ...
    50;

Cases(iCase).useFilterBank = true;

Cases(iCase).filterBankName = ...
    'ERP_GUIDED';

Cases(iCase).csp_components = 4;

Cases(iCase).useMI = true;

Cases(iCase).mi_k = 8;

Cases(iCase).classifiers = ...
    {'QDA'};

Cases(iCase).notes = ...
    'ERP-guided FBCSP 150-500 ms. Consonant vs Dissonant vs ControlGOAL';
end