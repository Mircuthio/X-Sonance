function Cases = build_bandpower_cases()

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

base.analysis_window = [];

base.analysis_rois = { ...
    'ERAN',...
    'MMN',...
    'N5'};

base.analysis_bands = { ...
    'Delta',...
    'Theta',...
    'Alpha',...
    'BetaLow',...
    'BetaHigh',...
    'GammaLow',...
    'GammaHigh'};

base.feature_mode = 'summary';

base.feature_windows = struct();
base.feature_windows.ERAN = [0.17 0.22];
base.feature_windows.MMN  = [0.10 0.25];
base.feature_windows.N5   = [0.45 0.55];

base.name = '';

Cases = repmat(base,0,1);

%% ============================================================
% FULL SUMMARY
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'FULL_CD_SUMMARY';

Cases(iCase).analysis_window = ...
    [-0.5 1.0];

Cases(iCase).feature_mode = ...
    'summary';

%% ============================================================
% FULL WINDOW
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'FULL_CD_WINDOW';

Cases(iCase).analysis_window = ...
    [-0.5 1.0];

Cases(iCase).feature_mode = ...
    'window';

%% ============================================================
% FULL TIMECOURSE
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'FULL_CD_TIMECOURSE';

Cases(iCase).analysis_window = ...
    [-0.5 1.0];

Cases(iCase).feature_mode = ...
    'timecourse';

%% ============================================================
% ERAN SUMMARY
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'ERAN_SUMMARY';

Cases(iCase).analysis_window = ...
    [0.17 0.22];

Cases(iCase).feature_mode = ...
    'summary';

%% ============================================================
% MMN SUMMARY
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'MMN_SUMMARY';

Cases(iCase).analysis_window = ...
    [0.10 0.25];

Cases(iCase).feature_mode = ...
    'summary';

%% ============================================================
% N5 SUMMARY
%% ============================================================

iCase = iCase + 1;

Cases(iCase) = base;

Cases(iCase).name = ...
    'N5_SUMMARY';

Cases(iCase).analysis_window = ...
    [0.45 0.55];

Cases(iCase).feature_mode = ...
    'summary';

end