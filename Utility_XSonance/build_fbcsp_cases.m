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

end