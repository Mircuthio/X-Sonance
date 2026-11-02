function BP = extract_bandpower_features_v2(tr,cfgFD)

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
% ROI signals
% S: nROI x nTime
%% ----------------------------------------------------------
nTime = numel(tr.time);
S = nan(nROI,nTime);

validROI = false(1,nROI);

for r = 1:nROI
    roiName = cfgFD.analysis_rois{r};
    roiLabels = cfgFD.rois.(roiName);
    
    roiIdx = get_roi_indices_v2(chanLabels,roiLabels);
    
    if isempty(roiIdx)
        continue
    end
    
    S(r,:) = mean(double(tr.eeg(roiIdx,:)),1,'omitnan');
    validROI(r) = true;
end

%% ----------------------------------------------------------
% Window indices
%% ----------------------------------------------------------
windowIdx = struct();

for w = 1:numel(windowNames)
    winName = windowNames{w};
    winRange = cfgFD.windows.(winName);
    
    windowIdx.(winName) = ...
        tr.time >= winRange(1) & ...
        tr.time <= winRange(2);
end

%% ----------------------------------------------------------
% Bandpower computation
% Una sola filtrata + Hilbert per banda, per tutte le ROI
%
% Pdb_all: nROI x nBands x nTime
%% ----------------------------------------------------------
Pdb_all = nan(nROI,nBands,nTime);

validRoiIdx = find(validROI);

for b = 1:nBands
    bandName = cfgFD.analysis_bands{b};
    bandRange = cfgFD.bands.(bandName);
    
    % Filtra tutte le ROI valide insieme
    Sf = bandpass_matrix(S(validROI,:),bandRange,tr.srate);
    
    % Hilbert lungo il tempo
    % Sf: nROIvalid x nTime
    H = hilbert(Sf.').';   % nROIvalid x nTime
    
    % Instantaneous power
    P = abs(H).^2;
    
    % Baseline correction per ogni ROI
    basePower = mean(P(:,idxBase),2,'omitnan');
    basePower(basePower <= 0 | isnan(basePower)) = eps;
    
    Pdb = 10 * log10(P ./ basePower);
    
    % Rimetti le ROI valide nelle loro posizioni originali
    Pdb_all(validRoiIdx,b,:) = Pdb;
end

%% ----------------------------------------------------------
% Feature extraction
% ORDINE IDENTICO ALLA VERSIONE ORIGINALE:
% ROI -> BAND -> WINDOW
%% ----------------------------------------------------------
for r = 1:nROI
    roiName = cfgFD.analysis_rois{r};
    
    if ~validROI(r)
        continue
    end
    
    for b = 1:nBands
        bandName = cfgFD.analysis_bands{b};
        
        for w = 1:nWindows
            winName = windowNames{w};
            idxWin = windowIdx.(winName);
            
            k = k + 1;
            
            Names{k} = sprintf('%s_%s_%s', ...
                roiName,...
                bandName,...
                winName);
            
            Values(k) = mean(Pdb_all(r,b,idxWin),'omitnan');
        end
    end
end

%% ----------------------------------------------------------
% Output
%% ----------------------------------------------------------
Names  = Names(1:k);
Values = Values(1:k);

BP.Names = Names;
BP.Values = Values;
end