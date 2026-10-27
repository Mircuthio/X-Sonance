function cfgFD = step10A_config()

%% ============================================================
% CLASSES
%% ============================================================

cfgFD.class_labels = { ...
    'Consonant',...
    'Dissonant'};

cfgFD.class_codes = [7 8];

%% ============================================================
% MASTER TEMPORAL WINDOWS
%% ============================================================

cfgFD.windows = struct();

cfgFD.windows.EARLY = [0.170 0.210];
cfgFD.windows.CORE  = [0.240 0.310];
cfgFD.windows.LATE  = [0.470 0.530];

%% ============================================================
% ROI FROM ERP + TFR AUDIT
%% ============================================================

cfgFD.analysis_rois = { ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};

%% ============================================================
% ERP FEATURES
%% ============================================================

cfgFD.erp_features = { ...
    'Mean',...
    'MinPeak',...
    'MaxPeak',...
    'AUC'};

%% ============================================================
% COMPLEX ERP FEATURES
%% ============================================================

cfgFD.erp_complex_features = { ...
    'PeakToPeak',...
    'ERPIndex'};

%% ============================================================
% BAND DEFINITIONS
%% ============================================================

cfgFD.bands = struct();

cfgFD.bands.Theta     = [4 8];
cfgFD.bands.Alpha     = [8 13];
cfgFD.bands.BetaLow   = [13 20];

cfgFD.bands.BetaHigh  = [20 30];
cfgFD.bands.GammaLow  = [30 40];
cfgFD.bands.GammaHigh = [40 90];

%% ============================================================
% PRIORITY BANDS
%% ============================================================

cfgFD.analysis_bands = { ...
    'Theta',...
    'Alpha',...
    'BetaLow'};

%% ============================================================
% FEATURE SOURCES
%% ============================================================

cfgFD.useERP = true;
cfgFD.useBandPower = true;

%% ============================================================
% BASELINE
%% ============================================================

cfgFD.baseline_win = [-0.2 0];

%% ============================================================
% BANDPOWER NORMALIZATION
%% ============================================================

cfgFD.bandpower_normalization = 'db';

%% ============================================================
% SCREENING METRICS
%% ============================================================

cfgFD.compute_auc = true;
cfgFD.compute_ttest = true;
cfgFD.compute_cohensd = true;

%% ============================================================
% REDUNDANCY ANALYSIS
%% ============================================================

cfgFD.compute_correlation = true;

cfgFD.high_corr_threshold = 0.85;

%% ============================================================
% DATASET FIELDS
%% ============================================================

cfgFD.eventField = 'eventLabel';

cfgFD.subjectField = 'subj_id';

%% ============================================================
% ANALYSIS WINDOW
%% ============================================================

cfgFD.analysis_window = [-0.5 1.0];

end