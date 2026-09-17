function Cases = ...
    build_erp_informed_cases()

%% ============================================================
% TEMPLATE
%% ============================================================

base = struct();

base.group = ...
    'ERP_INFORMED';

base.class_labels = { ...
    'Consonant',...
    'Dissonant'};

base.class_codes = [7 8];

base.analysis_window = ...
    [-0.5 1.0];

%% ============================================================
% CASE 1
%% ============================================================

Cases = base;

Cases.name = ...
    'CD_LOSO';

end