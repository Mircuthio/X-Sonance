function [featureVector,FeatureNames] = ...
    step10A_extract_trial_features( ...
    tr,...
    cfgFD)

%% ============================================================
% ROIs
%% ============================================================

roiNames = ...
    cfgFD.analysis_rois;

windowNames = ...
    fieldnames(cfgFD.windows);

bandNames = ...
    cfgFD.analysis_bands;

%% ============================================================
% FEATURE COUNT
%% ============================================================

nROI = numel(roiNames);

nWin = numel(windowNames);

nERP = numel(cfgFD.erp_features);

nComplex = ...
    numel(cfgFD.erp_complex_features);

nBands = numel(bandNames);

nFeatures = ...
    nROI*nWin*nERP + ...
    nROI*nComplex + ...
    nROI*nWin*nBands;

%% ============================================================
% PREALLOCATION
%% ============================================================

featureVector = ...
    nan(1,nFeatures);

FeatureNames = ...
    cell(1,nFeatures);

iFeat = 0;

%% ============================================================
% CHANNEL LABELS
%% ============================================================

chanLabels = ...
    {tr.chanlocs.labels};

%% ============================================================
% ROI LOOP
%% ============================================================

for r = 1:nROI

    roiName = roiNames{r};

    roiLabels = ...
        cfgFD.rois.(roiName);

    roiIdx = ...
        get_roi_indices( ...
        chanLabels,...
        roiLabels);

    if isempty(roiIdx)
        continue;
    end

    %% --------------------------------------------------------
    % ROI SIGNAL
    %% --------------------------------------------------------

    roiSignal = ...
        mean( ...
        double(tr.eeg(roiIdx,:)),...
        1,...
        'omitnan');

    %% ========================================================
    % ERP FEATURES
    %% ========================================================

    for w = 1:nWin

        winName = ...
            windowNames{w};

        winRange = ...
            cfgFD.windows.(winName);

        idxWin = ...
            tr.time >= winRange(1) & ...
            tr.time <= winRange(2);

        seg = ...
            roiSignal(idxWin);

        %% Mean

        iFeat = iFeat + 1;

        featureVector(iFeat) = ...
            mean(seg,'omitnan');

        FeatureNames{iFeat} = ...
            sprintf('%s_%s_Mean',...
            roiName,winName);

        %% MinPeak

        iFeat = iFeat + 1;

        featureVector(iFeat) = ...
            min(seg);

        FeatureNames{iFeat} = ...
            sprintf('%s_%s_MinPeak',...
            roiName,winName);

        %% MaxPeak

        iFeat = iFeat + 1;

        featureVector(iFeat) = ...
            max(seg);

        FeatureNames{iFeat} = ...
            sprintf('%s_%s_MaxPeak',...
            roiName,winName);

        %% AUC

        iFeat = iFeat + 1;

        featureVector(iFeat) = ...
            trapz(seg);

        FeatureNames{iFeat} = ...
            sprintf('%s_%s_AUC',...
            roiName,winName);

    end

    %% ========================================================
    % ERP COMPLEX FEATURES
    %% ========================================================

    idxERAN = ...
        tr.time >= cfgFD.windows.ERAN_A(1) & ...
        tr.time <= cfgFD.windows.ERAN_B(2);

    idxREB = ...
        tr.time >= cfgFD.windows.REB_A(1) & ...
        tr.time <= cfgFD.windows.REB_B(2);
    eranSeg = ...
        roiSignal(idxERAN);

    rebSeg = ...
        roiSignal(idxREB);

    eranMin = ...
        min(eranSeg);

    reboundMax = ...
        max(rebSeg);

    %% PeakToPeak

    iFeat = iFeat + 1;

    featureVector(iFeat) = ...
        reboundMax - eranMin;

    FeatureNames{iFeat} = ...
        sprintf('%s_PeakToPeak',...
        roiName);

    %% ERPIndex

    iFeat = iFeat + 1;

    featureVector(iFeat) = ...
        mean(rebSeg,'omitnan') - ...
        mean(eranSeg,'omitnan');

    FeatureNames{iFeat} = ...
        sprintf('%s_ERPIndex',...
        roiName);

  
    %% ========================================================
    % BANDPOWER FEATURES
    %% ========================================================


    for b = 1:nBands

        bandName = ...
            bandNames{b};

        bandRange = ...
            cfgFD.bands.(bandName);

        %% BANDPASS

        sigF = ...
            bandpass( ...
            roiSignal,...
            bandRange,...
            tr.srate);

        %% HILBERT

        H = hilbert(sigF);

        P = abs(H).^2;

        %% BASELINE

        idxBase = ...
            tr.time >= cfgFD.baseline_win(1) & ...
            tr.time <= cfgFD.baseline_win(2);

        basePower = ...
            mean(P(idxBase),...
            'omitnan');

        if basePower <= 0
            basePower = eps;
        end

        Pdb = ...
            10*log10(P./basePower);

        %% WINDOW LOOP

        for w = 1:nWin

            winName = ...
                windowNames{w};

            winRange = ...
                cfgFD.windows.(winName);

            idxWin = ...
                tr.time >= winRange(1) & ...
                tr.time <= winRange(2);

            iFeat = iFeat + 1;

            featureVector(iFeat) = ...
                mean(Pdb(idxWin),...
                'omitnan');

            FeatureNames{iFeat} = ...
                sprintf( ...
                '%s_%s_%s',...
                roiName,...
                bandName,...
                winName);
        end
    end
end

%% ============================================================
% SANITY CHECK
%% ============================================================

fprintf('\n');
fprintf('Created = %d\n',iFeat);

if iFeat ~= nFeatures

    error( ...
        'Feature count mismatch (%d/%d)',...
        iFeat,...
        nFeatures);

end

end
