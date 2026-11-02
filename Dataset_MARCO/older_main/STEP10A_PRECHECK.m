%% =========================================================================
% STEP10A_PRECHECK
%
% Verifica automatica della configurazione prima di lanciare STEP10A
%% =========================================================================

clear
close all
clc

fprintf('\n');
fprintf('========================================\n');
fprintf('STEP10A CONFIGURATION CHECK\n');
fprintf('========================================\n');

%% ============================================================
% LOAD CONFIG
%% ============================================================

cfgFD = step10A_config();

MAIN_ROI

%% ============================================================
% ROI CHECK
%% ============================================================

fprintf('\n');
fprintf('ROI CHECK\n');
fprintf('----------------------------------------\n');

roiFields = fieldnames(ROI);

for i = 1:numel(cfgFD.analysis_rois)

    roiName = cfgFD.analysis_rois{i};

    if isfield(ROI,roiName)

        fprintf('[OK] %s\n',roiName);

    else

        error('Missing ROI: %s',roiName);

    end

end

%% ============================================================
% WINDOW CHECK
%% ============================================================

fprintf('\n');
fprintf('WINDOW CHECK\n');
fprintf('----------------------------------------\n');

windowNames = fieldnames(cfgFD.windows);

for i = 1:numel(windowNames)

    wName = windowNames{i};

    w = cfgFD.windows.(wName);

    assert(numel(w)==2,...
        'Window %s invalid',wName);

    assert(w(1)<w(2),...
        'Window %s start >= end',wName);

    fprintf('[OK] %s : %.3f %.3f\n',...
        wName,...
        w(1),...
        w(2));

end

%% ============================================================
% BAND CHECK
%% ============================================================

fprintf('\n');
fprintf('BAND CHECK\n');
fprintf('----------------------------------------\n');

for i = 1:numel(cfgFD.analysis_bands)

    bandName = cfgFD.analysis_bands{i};

    if isfield(cfgFD.bands,bandName)

        f = cfgFD.bands.(bandName);

        fprintf('[OK] %s : %.1f-%.1f Hz\n',...
            bandName,...
            f(1),...
            f(2));

    else

        error('Band missing: %s',bandName);

    end

end

%% ============================================================
% ERP FEATURES
%% ============================================================

fprintf('\n');
fprintf('ERP FEATURE CHECK\n');
fprintf('----------------------------------------\n');

disp(cfgFD.erp_features(:))

fprintf('\n');
fprintf('ERP COMPLEX FEATURES\n');
fprintf('----------------------------------------\n');

disp(cfgFD.erp_complex_features(:))

%% ============================================================
% FEATURE COUNT
%% ============================================================

nROI = numel(cfgFD.analysis_rois);
nWin = numel(fieldnames(cfgFD.windows));
nERPFeat = numel(cfgFD.erp_features);
nComplex = numel(cfgFD.erp_complex_features);
nBands = numel(cfgFD.analysis_bands);

nFeatures = ...
    nROI*nWin*nERPFeat + ...
    nROI*nComplex + ...
    nROI*nWin*nBands;

fprintf('\n');
fprintf('EXPECTED FEATURE COUNT\n');
fprintf('----------------------------------------\n');

fprintf('ROI           : %d\n',nROI);
fprintf('WINDOWS       : %d\n',nWin);
fprintf('ERP FEATURES  : %d\n',nERPFeat);
fprintf('COMPLEX       : %d\n',nComplex);
fprintf('BANDS         : %d\n',nBands);
fprintf('\n');
fprintf('TOTAL FEATURES: %d\n',nFeatures);

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');
fprintf('========================================\n');
fprintf('CONFIGURATION VALID\n');
fprintf('READY FOR STEP10A\n');
fprintf('========================================\n');