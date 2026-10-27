function BP = ...
    extract_bandpower_features_v2( ...
    tr,...
    cfgFD)

nROI     = numel(cfgFD.analysis_rois);
nBands   = numel(cfgFD.analysis_bands);
nWindows = numel(cfgFD.window_order);

maxFeatures = nROI * nBands * nWindows;

Names  = cell(1,maxFeatures);
Values = nan(1,maxFeatures);
k = 0;

chanLabels = {tr.chanlocs.labels};
windowNames = cfgFD.window_order;
idxBase = ...
    tr.time >= cfgFD.baseline_win(1) & ...
    tr.time <= cfgFD.baseline_win(2);
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
    for b = 1:numel(cfgFD.analysis_bands)
        bandName = cfgFD.analysis_bands{b};
        bandRange = cfgFD.bands.(bandName);
        
        sigF = bandpass(roiSignal,bandRange,tr.srate);
        H = hilbert(sigF);
        P = abs(H).^2;
              
        basePower = mean(P(idxBase),'omitnan');
        if isempty(basePower) || isnan(basePower) || basePower <= 0
            basePower = eps;
        end
        
        Pdb = 10*log10(P ./ basePower);
        
        for w = 1:numel(windowNames)
            winName = windowNames{w};
            idxWin = windowIdx.(winName);
            
            k = k + 1;
            
            Names{k} = sprintf('%s_%s_%s', ...
                roiName,...
                bandName,...
                winName);
            
            Values(k) = mean(Pdb(idxWin),'omitnan');
        end
    end
end

% Rimuove eventuali slot non utilizzati
Names  = Names(1:k);
Values = Values(1:k);

BP.Names = Names;
BP.Values = Values;
end