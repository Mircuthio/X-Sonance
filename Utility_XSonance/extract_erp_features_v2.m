function ERP = ...
    extract_erp_features_v2( ...
    tr,...
    cfgFD)

nROI     = numel(cfgFD.analysis_rois);
nWindows = numel(cfgFD.window_order);

% 8 feature per ROI/window + 2 feature extra per ROI
maxFeatures = nROI * (nWindows * 8 + 2);

Names  = cell(1,maxFeatures);
Values = nan(1,maxFeatures);
k = 0;

chanLabels = {tr.chanlocs.labels};
windowNames = cfgFD.window_order;
%% ----------------------------------------------------------
% Cached window indices
%% ----------------------------------------------------------
windowIdx = struct();

for w = 1:numel(windowNames)

    winName = windowNames{w};

    winRange = cfgFD.windows.(winName);

    windowIdx.(winName) = ...
        tr.time >= winRange(1) & ...
        tr.time <= winRange(2);

end
for r = 1:numel(cfgFD.analysis_rois)
    roiName = cfgFD.analysis_rois{r};
    roiLabels = cfgFD.rois.(roiName);
    roiIdx = get_roi_indices_v2(chanLabels,roiLabels);
    
    if isempty(roiIdx)
        continue
    end
    
    roiSignal = mean(double(tr.eeg(roiIdx,:)),1,'omitnan');
    
    for w = 1:numel(windowNames)
        winName = windowNames{w};
        idxWin = windowIdx.(winName);
        
        seg = roiSignal(idxWin);
        if isempty(seg)
            continue
        end
        tSeg = tr.time(idxWin);
        
        [minVal,minIdx] = min(seg,[],'omitnan');
        [maxVal,maxIdx] = max(seg,[],'omitnan');
        if isempty(minIdx) || isempty(maxIdx)
            minVal = NaN;
            maxVal = NaN;
            latencyMin = NaN;
            latencyMax = NaN;
        else
            latencyMin = tSeg(minIdx);
            latencyMax = tSeg(maxIdx);
        end
        featNames = { ...
            sprintf('%s_%s_Mean',roiName,winName)
            sprintf('%s_%s_MinPeak',roiName,winName)
            sprintf('%s_%s_MaxPeak',roiName,winName)
            sprintf('%s_%s_AUC',roiName,winName)
            sprintf('%s_%s_LatencyMin',roiName,winName)
            sprintf('%s_%s_LatencyMax',roiName,winName)
            sprintf('%s_%s_RMS',roiName,winName)
            sprintf('%s_%s_STD',roiName,winName)};
        
        featValues = [ ...
            mean(seg,'omitnan')
            minVal
            maxVal
            trapz(tSeg,seg)
            latencyMin
            latencyMax
            sqrt(mean(seg.^2,'omitnan')) %rms(seg)
            std(seg,'omitnan')];
        
        Names(k+1:k+8) = featNames;
        Values(k+1:k+8) = featValues';
        k = k + 8;
    end
    
    idxEarly = windowIdx.EARLY;
    idxCore  = windowIdx.CORE;
    
    earlySeg = roiSignal(idxEarly);
    coreSeg  = roiSignal(idxCore);
    if isempty(earlySeg) || isempty(coreSeg)
        p2p = NaN;
        erpIndex = NaN;
    else
        p2p = max(coreSeg) - min(earlySeg);
        erpIndex = mean(coreSeg,'omitnan') - ...
            mean(earlySeg,'omitnan');
    end

    k = k + 1;
    Names{k} = sprintf('%s_PeakToPeak',roiName);
    Values(k) = p2p;
    
    k = k + 1;
    Names{k} = sprintf('%s_ERPIndex',roiName);
    Values(k) = erpIndex;
end

% Rimuove eventuali slot non utilizzati
Names  = Names(1:k);
Values = Values(1:k);

ERP.Names = Names;
ERP.Values = Values;
end