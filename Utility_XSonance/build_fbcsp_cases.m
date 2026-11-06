function Cases = build_fbcsp_cases()

iCase = 0;

%% ============================================================
% TEMPLATE
%% ============================================================

base = struct();

base.case_id         = '';
base.group           = '';
base.name            = '';

base.class_codes     = [];
base.class_labels    = {};

base.time_window     = [];

base.useROI          = false;
base.analysis_rois   = {};

base.useSubEpochs    = false;
base.subEpochLength  = [];
base.subEpochOverlap = [];

base.useFilterBank   = true;
base.filterBankName  = 'EEGbands';

base.csp_components  = 4;

base.useMI           = true;
base.mi_k            = 8;

base.classifiers     = {'QDA','KNN','NB'};

base.doTSNE          = false;

base.notes           = '';

Cases = repmat(base,0,1);

%% ============================================================
% PART20
% BENCHMARK CD
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P20_01';
Cases(iCase).group='PART20_BENCHMARK';
Cases(iCase).name='FULL_CD';
Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};
Cases(iCase).time_window=[-0.5 1.0];


iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P20_02';
Cases(iCase).group='PART20_BENCHMARK';
Cases(iCase).name='ERP_GUIDED_CD';
Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};
Cases(iCase).time_window=[0.17 0.53];


iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P20_03';
Cases(iCase).group='PART20_BENCHMARK';
Cases(iCase).name='ERP_GUIDED_CD_CSP8';
Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).csp_components=8;

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P20_04';
Cases(iCase).group='PART20_BENCHMARK';
Cases(iCase).name='ERP_GUIDED_CD_CSP8_MI16';
Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).csp_components=8;
Cases(iCase).mi_k=16;

%% ============================================================
% PART21
% ROI FUNCTIONAL
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;

Cases(iCase).case_id='P21_01';
Cases(iCase).group='PART21_ROI_FUNCTIONAL';
Cases(iCase).name='FUNCTIONAL_ERP_GUIDED_CD';

Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};

Cases(iCase).time_window=[0.17 0.53];

Cases(iCase).useROI=true;

Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT'};

Cases(iCase).doTSNE=true;

%% ============================================================
% PART22
% ROI ANATOMICAL
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;

Cases(iCase).case_id='P22_01';
Cases(iCase).group='PART22_ROI_ANATOMICAL';
Cases(iCase).name='ANATOMICAL_ERP_GUIDED_CD';

Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};

Cases(iCase).time_window=[0.17 0.53];

Cases(iCase).useROI=true;

Cases(iCase).analysis_rois={ ...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};

Cases(iCase).doTSNE=true;

%% ============================================================
% PART23
% ROI CONVERGENCE
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;

Cases(iCase).case_id='P23_01';
Cases(iCase).group='PART23_ROI_CONVERGENCE';
Cases(iCase).name='CONVERGENCE_ERP_GUIDED_CD';

Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};

Cases(iCase).time_window=[0.17 0.53];

Cases(iCase).useROI=true;

Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};

Cases(iCase).doTSNE=true;

%% ============================================================
% PART24
% CONTROL
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P24_01';
Cases(iCase).group='PART24_CONTROL';
Cases(iCase).name='CON_CONTROL';
Cases(iCase).class_codes=[7 3];
Cases(iCase).class_labels={ ...
    'Consonant',...
    'ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P24_02';
Cases(iCase).group='PART24_CONTROL';
Cases(iCase).name='DIS_CONTROL';
Cases(iCase).class_codes=[8 3];
Cases(iCase).class_labels={ ...
    'Dissonant',...
    'ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P24_03';
Cases(iCase).group='PART24_CONTROL';
Cases(iCase).name='CDC';
Cases(iCase).class_codes=[7 8 3];
Cases(iCase).class_labels={ ...
    'Consonant',...
    'Dissonant',...
    'ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];

%% ============================================================
% PART25
% ROI FUNCTIONAL + CONTROL
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P25_01';
Cases(iCase).group='PART25_FUNCTIONAL_CONTROL';
Cases(iCase).name='FUNCTIONAL_CON_CONTROL';
Cases(iCase).class_codes=[7 3];
Cases(iCase).class_labels={'Consonant','ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT'};

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P25_02';
Cases(iCase).group='PART25_FUNCTIONAL_CONTROL';
Cases(iCase).name='FUNCTIONAL_DIS_CONTROL';
Cases(iCase).class_codes=[8 3];
Cases(iCase).class_labels={'Dissonant','ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT'};

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P25_03';
Cases(iCase).group='PART25_FUNCTIONAL_CONTROL';
Cases(iCase).name='FUNCTIONAL_CDC';
Cases(iCase).class_codes=[7 8 3];
Cases(iCase).class_labels={ ...
    'Consonant',...
    'Dissonant',...
    'ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT'};

%% ============================================================
% PART26
% ROI CONVERGENCE + CONTROL
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P26_01';
Cases(iCase).group='PART26_CONVERGENCE_CONTROL';
Cases(iCase).name='CONVERGENCE_CON_CONTROL';
Cases(iCase).class_codes=[7 3];
Cases(iCase).class_labels={'Consonant','ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};
Cases(iCase).doTSNE=true;

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P26_02';
Cases(iCase).group='PART26_CONVERGENCE_CONTROL';
Cases(iCase).name='CONVERGENCE_DIS_CONTROL';
Cases(iCase).class_codes=[8 3];
Cases(iCase).class_labels={'Dissonant','ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};
Cases(iCase).doTSNE=true;

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P26_03';
Cases(iCase).group='PART26_CONVERGENCE_CONTROL';
Cases(iCase).name='CONVERGENCE_CDC';
Cases(iCase).class_codes=[7 8 3];
Cases(iCase).class_labels={ ...
    'Consonant',...
    'Dissonant',...
    'ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};
Cases(iCase).doTSNE=true;

%% ============================================================
% PART27
% BEST CANDIDATES
%% ============================================================

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P27_01';
Cases(iCase).group='PART27_BEST';
Cases(iCase).name='CONVERGENCE_ERP_GUIDED_CD_CSP8_MI16';
Cases(iCase).class_codes=[7 8];
Cases(iCase).class_labels={'Consonant','Dissonant'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};
Cases(iCase).csp_components=8;
Cases(iCase).mi_k=16;
Cases(iCase).doTSNE=true;

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P27_02';
Cases(iCase).group='PART27_BEST';
Cases(iCase).name='CONVERGENCE_CON_CONTROL_CSP8_MI16';
Cases(iCase).class_codes=[7 3];
Cases(iCase).class_labels={'Consonant','ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};
Cases(iCase).csp_components=8;
Cases(iCase).mi_k=16;
Cases(iCase).doTSNE=true;

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P27_03';
Cases(iCase).group='PART27_BEST';
Cases(iCase).name='CONVERGENCE_DIS_CONTROL_CSP8_MI16';
Cases(iCase).class_codes=[8 3];
Cases(iCase).class_labels={'Dissonant','ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};
Cases(iCase).csp_components=8;
Cases(iCase).mi_k=16;
Cases(iCase).doTSNE=true;

iCase=iCase+1;
Cases(iCase)=base;
Cases(iCase).case_id='P27_04';
Cases(iCase).group='PART27_BEST';
Cases(iCase).name='CONVERGENCE_CDC_CSP8_MI16';
Cases(iCase).class_codes=[7 8 3];
Cases(iCase).class_labels={ ...
    'Consonant',...
    'Dissonant',...
    'ControlGOAL'};
Cases(iCase).time_window=[0.17 0.53];
Cases(iCase).useROI=true;
Cases(iCase).analysis_rois={ ...
    'ERAN_CORE',...
    'aMMN',...
    'N5_FRONT',...
    'FrontoCentral',...
    'Occipital',...
    'Parietal'};
Cases(iCase).csp_components=8;
Cases(iCase).mi_k=16;
Cases(iCase).doTSNE=true;

end