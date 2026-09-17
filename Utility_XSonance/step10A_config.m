function cfgFD = step10A_config()

%% ============================================================
% CLASSES
%% ============================================================

cfgFD.class_labels = { ...
    'Consonant' ...
    'Dissonant'};

cfgFD.class_codes = [1 2];

%% ============================================================
% ERP WINDOWS
%% ============================================================

cfgFD.windows = struct();

cfgFD.windows.MMN      = [0.100 0.200];

cfgFD.windows.ERAN_A   = [0.170 0.195];
cfgFD.windows.ERAN_B   = [0.195 0.220];

cfgFD.windows.REB_A    = [0.220 0.270];
cfgFD.windows.REB_B    = [0.270 0.320];

cfgFD.windows.N5       = [0.450 0.550];


%% ============================================================
% ANALYSIS ROI
%% ============================================================

cfgFD.analysis_rois = { ...
    'MMN' ...
    'ERAN_CORE' ...
    'ERAN_RIGHT' ...
    'N5_CENTRAL'};

%% ============================================================
% ERP FEATURES
%% ============================================================

cfgFD.erp_features = { ...
    'Mean' ...
    'MinPeak' ...
    'MaxPeak' ...
    'AUC'};

%% ============================================================
% ERP COMPLEX FEATURES
%% ============================================================

cfgFD.erp_complex_features = { ...
    'PeakToPeak'
    'ERPIndex'};

%% ============================================================
% BANDS
%% ============================================================

cfgFD.bands.Theta    = [4 8];
cfgFD.bands.Alpha    = [8 13];
cfgFD.bands.BetaLow  = [13 20];
cfgFD.bands.BetaHigh = [20 30];
cfgFD.bands.GammaLow = [30 45];

cfgFD.analysis_bands = { ...
    'Theta' ...
    'Alpha' ...
    'BetaLow' ...
    'BetaHigh' ...
    'GammaLow'};

%% ============================================================
% BASELINE
%% ============================================================

cfgFD.baseline_win = [-0.2 0];

cfgFD.normalization = 'db';

%% ============================================================
% SCREENING
%% ============================================================

cfgFD.compute_auc = true;
cfgFD.compute_ttest = true;
cfgFD.compute_cohensd = true;
%% ============================================================
% DATASET FIELDS
%% ============================================================

cfgFD.eventField = ...
    'eventLabel';

cfgFD.subjectField = ...
    'subj_id';

%% ============================================================
% CLASS CONFIG
%% ============================================================

cfgFD.class_labels = { ...
    'Consonant',...
    'Dissonant'};

cfgFD.class_codes = [7 8];

%% ============================================================
% BUILD DATASET WINDOW
%% ============================================================

cfgFD.analysis_window = ...
    [-0.5 1.0];

end