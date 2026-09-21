function Cases = ...
    build_erpinf_control_cases()

iCase = 0;

%% ============================================================
% CONSONANT vs DISSONANT
%% ============================================================

iCase = iCase + 1;

Cases(iCase).name = ...
    'CD';

Cases(iCase).class_labels = { ...
    'Consonant',...
    'Dissonant'};

Cases(iCase).class_codes = [7 8];

%% ============================================================
% CONSONANT vs CONTROL
%% ============================================================

iCase = iCase + 1;

Cases(iCase).name = ...
    'CON_CONTROL';

Cases(iCase).class_labels = { ...
    'Consonant',...
    'ControlGOAL'};

Cases(iCase).class_codes = [7 3];

%% ============================================================
% DISSONANT vs CONTROL
%% ============================================================

iCase = iCase + 1;

Cases(iCase).name = ...
    'DIS_CONTROL';

Cases(iCase).class_labels = { ...
    'Dissonant',...
    'ControlGOAL'};

Cases(iCase).class_codes = [8 3];

%% ============================================================
% CONSONANT vs DISSONANT vs CONTROL
%% ============================================================

iCase = iCase + 1;

Cases(iCase).name = ...
    'CD_CONTROL';

Cases(iCase).class_labels = { ...
    'Consonant',...
    'Dissonant',...
    'ControlGOAL'};

Cases(iCase).class_codes = [7 8 3];

end