function plot_mmn_zoom( ...
    subj_list, ...
    cfgMMN, ...
    outdir)

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
zoomDir = fullfile(outdir, 'Zoom');

if ~exist(zoomDir, 'dir')
    mkdir(zoomDir);
end

%% ============================================================
% DEFAULTS
%% ============================================================
if ~isfield(cfgMMN, 'smooth_plot')
    cfgMMN.smooth_plot = false;
end

if ~isfield(cfgMMN, 'smooth_window')
    cfgMMN.smooth_window = 5;
end

assert( ...
    isnumeric(cfgMMN.smooth_window) && ...
    isscalar(cfgMMN.smooth_window) && ...
    cfgMMN.smooth_window >= 1 && ...
    mod(cfgMMN.smooth_window, 1) == 0, ...
    'cfgMMN.smooth_window must be a positive integer');

%% ============================================================
% LOOP ROIs
%% ============================================================
for r = 1:numel(cfgMMN.analysis_rois)

    roiName   = cfgMMN.analysis_rois{r};
    roiLabels = cfgMMN.rois.(roiName);

    %% ========================================================
    % PREALLOCATE SUBJECT MATRICES
    %% ========================================================
    nSub    = numel(subj_list);
    timeVec = subj_list(1).data_trials(1).time;
    nTime   = numel(timeVec);

    ERP_CON = nan(nSub, nTime);
    ERP_DIS = nan(nSub, nTime);

    %% ========================================================
    % SUBJECT LOOP
    %% ========================================================
    for iSub = 1:nSub

        data_trials = subj_list(iSub).data_trials;

        labels = {data_trials(1).chanlocs.labels};
        roiIdx = ismember(labels, roiLabels);

        idxCon = strcmp({data_trials.eventLabel}, 'Consonant');
        idxDis = strcmp({data_trials.eventLabel}, 'Dissonant');

        conTrials = find(idxCon);
        disTrials = find(idxDis);

        nCon = numel(conTrials);
        nDis = numel(disTrials);

        ERPconTrials = nan(nCon, nTime);
        ERPdisTrials = nan(nDis, nTime);

        for k = 1:nCon
            it = conTrials(k);

            ERPconTrials(k, :) = mean( ...
                data_trials(it).eeg(roiIdx, :), ...
                1);
        end

        for k = 1:nDis
            it = disTrials(k);

            ERPdisTrials(k, :) = mean( ...
                data_trials(it).eeg(roiIdx, :), ...
                1);
        end

        ERP_CON(iSub, :) = mean(ERPconTrials, 1);
        ERP_DIS(iSub, :) = mean(ERPdisTrials, 1);

    end

    %% ========================================================
    % GROUP ERP
    %% ========================================================
    ERPcon = mean(ERP_CON, 1, 'omitnan');
    ERPdis = mean(ERP_DIS, 1, 'omitnan');

    switch lower(cfgMMN.diff_mode)

        case 'dis_minus_con'
            ERPdiff   = ERPdis - ERPcon;
            diffLabel = 'Dissonant - Consonant';

        case 'con_minus_dis'
            ERPdiff   = ERPcon - ERPdis;
            diffLabel = 'Consonant - Dissonant';

        otherwise
            error('Unknown diff_mode');

    end
    ERPdiff_raw = ERPdiff;
    %% ========================================================
    % OPTIONAL SMOOTHING FOR DISPLAY
    %% ========================================================
    if cfgMMN.smooth_plot

        ERPcon  = movmean( ...
            ERPcon, ...
            cfgMMN.smooth_window, ...
            'omitnan');

        ERPdis  = movmean( ...
            ERPdis, ...
            cfgMMN.smooth_window, ...
            'omitnan');

        ERPdiff = movmean( ...
            ERPdiff, ...
            cfgMMN.smooth_window, ...
            'omitnan');

    end

    %% ========================================================
    % PEAK DIFFERENCE (LAST WINDOW)
    %% ========================================================
    peakWindow = cfgMMN.windows{end};

    idxPeakWin = timeVec >= peakWindow(1) & ...
                 timeVec <= peakWindow(2);

    diffWin = ERPdiff_raw(idxPeakWin);
    timeWin = timeVec(idxPeakWin);

    switch lower(cfgMMN.peak_mode)

        case 'min'
            [peakAmp, idxPeak] = min(diffWin);

        case 'max'
            [peakAmp, idxPeak] = max(diffWin);

        otherwise
            error('Unknown peak_mode');

    end

    peakLat = timeWin(idxPeak);

    [~,peakPlotIdx] = ...
        min(abs(timeVec - peakLat));

    peakAmpPlot = ...
        ERPdiff(peakPlotIdx);
    %% ========================================================
    % PLOT OPTIONS
    %% ========================================================
    showCon  = false;
    showDis  = false;
    showDiff = false;
    showPeak = false;

    switch lower(cfgMMN.plot_mode)

        case 'all'
            showCon  = true;
            showDis  = true;
            showDiff = true;
            showPeak = true;

        case 'conditions'
            showCon  = true;
            showDis  = true;

        case 'diff'
            showDiff = true;
            showPeak = true;

        case 'overlay'
            showCon  = true;
            showDis  = true;
            showDiff = true;

        otherwise
            error('Unknown plot_mode');

    end

    %% ========================================================
    % WINDOW LABELS
    %% ========================================================
    nWindows  = numel(cfgMMN.windows);
    winLabels = cell(1, nWindows);

    for iw = 1:nWindows

        win = cfgMMN.windows{iw};

        winLabels{iw} = sprintf( ...
            '%s (%d-%d ms)', ...
            format_tex_name(cfgMMN.window_names{iw}), ...
            round(win(1) * 1000), ...
            round(win(2) * 1000));

    end

    %% ========================================================
    % FIGURE
    %% ========================================================
    figure( ...
        'Color', 'w', ...
        'Position', [100 100 1200 600]);

    hold on

    allData = [ERPcon ERPdis ERPdiff];

    yL = [ ...
        min(allData,[],'omitnan') ...
        max(allData,[],'omitnan')];

    %% ========================================================
    % WINDOWS
    %% ========================================================
    colors = lines(nWindows);

    patchHandles = gobjects(nWindows, 1);

    for iw = 1:nWindows

        win = cfgMMN.windows{iw};

        patchHandles(iw) = patch( ...
            [win(1) win(2) win(2) win(1)], ...
            [yL(1) yL(1) yL(2) yL(2)], ...
            colors(iw, :), ...
            'FaceAlpha', 0.08, ...
            'EdgeColor', 'none');

    end

    %% ========================================================
    % ERP CURVES
    %% ========================================================
    hCon  = [];
    hDis  = [];
    hDiff = [];
    hPeak = [];

    if showCon
        hCon = plot( ...
            timeVec, ...
            ERPcon, ...
            'b', ...
            'LineWidth', 2);
    end

    if showDis
        hDis = plot( ...
            timeVec, ...
            ERPdis, ...
            'r', ...
            'LineWidth', 2);
    end

    if showDiff
        hDiff = plot( ...
            timeVec, ...
            ERPdiff, ...
            'k', ...
            'LineWidth', 2);
    end

    %% ========================================================
    % PEAK
    %% ========================================================
    if showPeak
        hPeak = plot( ...
            peakLat, ...
            peakAmpPlot, ...
            'rp', ...
            'MarkerFaceColor', 'r', ...
            'MarkerSize', 10);

        xline( ...
            peakLat, ...
            'r--', ...
            'LineWidth', 1.5);
    end

    %% ========================================================
    % REFERENCES
    %% ========================================================
    yline(0, 'k:');
    xline(0, 'k:');

    %% ========================================================
    % AXES
    %% ========================================================
    xlim(cfgMMN.zoom_window)

    xlabel('Time (s)')
    ylabel('\muV')

    if showPeak
        title(sprintf( ...
            '%s MMN Zoom\nPeak = %.0f ms | %.2f \\muV', ...
            format_tex_name(roiName), ...
            peakLat * 1000, ...
            peakAmp));
    else
        title(sprintf( ...
            '%s MMN Zoom', ...
            format_tex_name(roiName)));
    end

    %% ========================================================
    % LEGEND - PREALLOCATION
    %% ========================================================
    maxLegendItems = nWindows + 4;

    legendHandles = gobjects(1, maxLegendItems);
    legendLabels  = cell(1, maxLegendItems);

    nLegend = 0;

    % Time windows
    for iw = 1:nWindows
        nLegend = nLegend + 1;
        legendHandles(nLegend) = patchHandles(iw);
        legendLabels{nLegend}  = winLabels{iw};
    end

    % ERP curves
    if showCon
        nLegend = nLegend + 1;
        legendHandles(nLegend) = hCon;
        legendLabels{nLegend}  = 'Consonant';
    end

    if showDis
        nLegend = nLegend + 1;
        legendHandles(nLegend) = hDis;
        legendLabels{nLegend}  = 'Dissonant';
    end

    if showDiff
        nLegend = nLegend + 1;
        legendHandles(nLegend) = hDiff;
        legendLabels{nLegend}  = diffLabel;
    end

    if showPeak
        nLegend = nLegend + 1;
        legendHandles(nLegend) = hPeak;
        legendLabels{nLegend}  = 'Peak MMN';
    end

    % Remove unused preallocated entries
    legendHandles = legendHandles(1:nLegend);
    legendLabels  = legendLabels(1:nLegend);

    legend( ...
        legendHandles, ...
        legendLabels, ...
        'Location', 'best');

    %% ========================================================
    % SAVE
    %% ========================================================
    exportgraphics( ...
        gcf, ...
        fullfile(zoomDir, sprintf( ...
            '%s_MMN_Zoom_%s.png', ...
            roiName, ...
            cfgMMN.plot_mode)), ...
        'Resolution', 300);

    close(gcf)

end

end