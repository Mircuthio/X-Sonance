function plot_spn_zoom( ...
    subj_list_spn, ...
    cfgSPN, ...
    outdir)

%% ============================================================
% DEFAULTS
%% ============================================================
if ~isfield(cfgSPN, 'smooth_plot')
    cfgSPN.smooth_plot = false;
end

if ~isfield(cfgSPN, 'smooth_window')
    cfgSPN.smooth_window = 5;
end

if ~isfield(cfgSPN, 'smooth_slope')
    cfgSPN.smooth_slope = false;
end

assert( ...
    isnumeric(cfgSPN.smooth_window) && ...
    isscalar(cfgSPN.smooth_window) && ...
    cfgSPN.smooth_window >= 1 && ...
    mod(cfgSPN.smooth_window, 1) == 0, ...
    'cfgSPN.smooth_window must be a positive integer');

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
zoomDir = fullfile(outdir, 'Zoom');

if ~exist(zoomDir, 'dir')
    mkdir(zoomDir);
end

%% ============================================================
% LOOP ROIs
%% ============================================================
for r = 1:numel(cfgSPN.analysis_rois)

    roiName   = cfgSPN.analysis_rois{r};
    roiLabels = cfgSPN.rois.(roiName);

    %% ========================================================
    % PREALLOCATE SUBJECT MATRICES
    %% ========================================================
    nSub    = numel(subj_list_spn);
    timeVec = subj_list_spn(1).data_trials(1).time;
    nTime   = numel(timeVec);

    ERP_CON = nan(nSub, nTime);
    ERP_DIS = nan(nSub, nTime);

    %% ========================================================
    % SUBJECT LOOP
    %% ========================================================
    for iSub = 1:nSub

        data_trials = subj_list_spn(iSub).data_trials;

        labels = {data_trials(1).chanlocs.labels};
        roiIdx = ismember(labels, roiLabels);

        if ~any(roiIdx)
            error('Nessun canale della ROI "%s" trovato per il soggetto %d.', ...
                roiName, iSub);
        end

        idxCon = strcmp({data_trials.eventLabel}, 'Consonant');
        idxDis = strcmp({data_trials.eventLabel}, 'Dissonant');

        conTrials = find(idxCon);
        disTrials = find(idxDis);

        nCon = numel(conTrials);
        nDis = numel(disTrials);

        % PREALLOCAZIONE trial-ERP
        ERPconTrials = nan(nCon, nTime);
        ERPdisTrials = nan(nDis, nTime);

        %% ----------------------------------------------------
        % CONSONANT
        %% ----------------------------------------------------
        for k = 1:nCon
            it = conTrials(k);

            ERPconTrials(k, :) = mean( ...
                data_trials(it).eeg(roiIdx, :), ...
                1, ...
                'omitnan');
        end

        %% ----------------------------------------------------
        % DISSONANT
        %% ----------------------------------------------------
        for k = 1:nDis
            it = disTrials(k);

            ERPdisTrials(k, :) = mean( ...
                data_trials(it).eeg(roiIdx, :), ...
                1, ...
                'omitnan');
        end

        % ERP soggettivo
        if nCon > 0
            ERP_CON(iSub, :) = mean(ERPconTrials, 1, 'omitnan');
        else
            ERP_CON(iSub, :) = nan(1, nTime);
        end

        if nDis > 0
            ERP_DIS(iSub, :) = mean(ERPdisTrials, 1, 'omitnan');
        else
            ERP_DIS(iSub, :) = nan(1, nTime);
        end

    end

    %% ========================================================
    % GROUP ERP
    %% ========================================================
    ERPconRaw = mean(ERP_CON, 1, 'omitnan');
    ERPdisRaw = mean(ERP_DIS, 1, 'omitnan');

    switch lower(cfgSPN.diff_mode)

        case 'dis_minus_con'
            ERPdiffRaw = ERPdisRaw - ERPconRaw;
            diffLabel  = 'Dissonant - Consonant';

        case 'con_minus_dis'
            ERPdiffRaw = ERPconRaw - ERPdisRaw;
            diffLabel  = 'Consonant - Dissonant';

        otherwise
            error('Unknown diff_mode: %s', cfgSPN.diff_mode);

    end

    %% ========================================================
    % OPTIONAL SMOOTHING FOR DISPLAY
    %% ========================================================
    ERPconPlot  = ERPconRaw;
    ERPdisPlot  = ERPdisRaw;
    ERPdiffPlot = ERPdiffRaw;

    if cfgSPN.smooth_plot

        ERPconPlot  = movmean( ...
            ERPconRaw, ...
            cfgSPN.smooth_window, ...
            'omitnan');

        ERPdisPlot  = movmean( ...
            ERPdisRaw, ...
            cfgSPN.smooth_window, ...
            'omitnan');

        ERPdiffPlot = movmean( ...
            ERPdiffRaw, ...
            cfgSPN.smooth_window, ...
            'omitnan');

    end

    %% ========================================================
    % LATE SPN SLOPE
    %% ========================================================
    slopeWindow = cfgSPN.windows{end};

    idxLate = timeVec >= slopeWindow(1) & ...
              timeVec <= slopeWindow(2);

    timeLate = timeVec(idxLate);

    if cfgSPN.smooth_slope
        diffLate = ERPdiffPlot(idxLate);
    else
        diffLate = ERPdiffRaw(idxLate);
    end

    validSlope = isfinite(timeLate) & isfinite(diffLate);

    timeLate = timeLate(validSlope);
    diffLate = diffLate(validSlope);

    if numel(timeLate) >= 2

        p = polyfit(timeLate, diffLate, 1);

        slopeVal = p(1);
        fitLine  = polyval(p, timeLate);

    else
        slopeVal = NaN;
        fitLine  = nan(size(timeLate));
    end

    %% ========================================================
    % PLOT OPTIONS
    %% ========================================================
    showCon   = false;
    showDis   = false;
    showDiff  = false;
    showSlope = false;

    switch lower(cfgSPN.plot_mode)

        case 'all'
            showCon   = true;
            showDis   = true;
            showDiff  = true;
            showSlope = true;

        case 'conditions'
            showCon   = true;
            showDis   = true;

        case 'diff'
            showDiff  = true;
            showSlope = true;

        case 'overlay'
            showCon   = true;
            showDis   = true;
            showDiff  = true;

        otherwise
            error('Unknown plot_mode: %s', cfgSPN.plot_mode);

    end

    %% ========================================================
    % WINDOW LABELS
    %% ========================================================
    nWindows  = numel(cfgSPN.windows);
    winLabels = cell(1, nWindows);

    for iw = 1:nWindows

        win = cfgSPN.windows{iw};

        winLabels{iw} = sprintf( ...
            '%s (%d-%d ms)', ...
            format_tex_name(cfgSPN.window_names{iw}), ...
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

    allY = [ ...
        ERPconPlot, ...
        ERPdisPlot, ...
        ERPdiffPlot];

    yL = [ ...
        min(allY, [], 'omitnan'), ...
        max(allY, [], 'omitnan')];

    if any(~isfinite(yL)) || yL(1) == yL(2)
        yL = [-1 1];
    end

    %% ========================================================
    % WINDOWS
    %% ========================================================
    colors = lines(nWindows);

    % PREALLOCAZIONE patch handles
    patchHandles = gobjects(nWindows, 1);

    for iw = 1:nWindows

        win = cfgSPN.windows{iw};

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
    hCon   = [];
    hDis   = [];
    hDiff  = [];
    hSlope = [];

    if showCon
        hCon = plot( ...
            timeVec, ...
            ERPconPlot, ...
            'b', ...
            'LineWidth', 2);
    end

    if showDis
        hDis = plot( ...
            timeVec, ...
            ERPdisPlot, ...
            'r', ...
            'LineWidth', 2);
    end

    if showDiff
        hDiff = plot( ...
            timeVec, ...
            ERPdiffPlot, ...
            'k', ...
            'LineWidth', 2);
    end

    %% ========================================================
    % SPN SLOPE FIT
    %% ========================================================
    if showSlope
        hSlope = plot( ...
            timeLate, ...
            fitLine, ...
            'r--', ...
            'LineWidth', 2.5);
    end

    %% ========================================================
    % REFERENCES
    %% ========================================================
    yline(0, 'k:');

    if showSlope
        xline(0, 'r:', 'LineWidth', 1.5);
    else
        xline(0, 'k:');
    end

    %% ========================================================
    % AXES
    %% ========================================================
    xlim(cfgSPN.zoom_window)

    xlabel('Time (s)')
    ylabel('\muV')

    if cfgSPN.smooth_plot
        smoothText = sprintf( ...
            ', smoothed: %d samples', ...
            cfgSPN.smooth_window);
    else
        smoothText = ', raw';
    end

    if showSlope
        title(sprintf( ...
            '%s SPN Zoom%s\n%s | Late Slope = %.5f', ...
            format_tex_name(roiName), ...
            smoothText, ...
            diffLabel, ...
            slopeVal));
    else
        title(sprintf( ...
            '%s SPN Zoom%s\n%s', ...
            format_tex_name(roiName), ...
            smoothText, ...
            diffLabel));
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

    if showSlope
        nLegend = nLegend + 1;
        legendHandles(nLegend) = hSlope;
        legendLabels{nLegend}  = 'SPN Slope';
    end

    % Remove unused preallocated entries
    legendHandles = legendHandles(1:nLegend);
    legendLabels  = legendLabels(1:nLegend);

    legend( ...
        legendHandles, ...
        legendLabels, ...
        'Location', 'best');

    set(gca, ...
        'FontSize', 11, ...
        'Box', 'off', ...
        'Layer', 'top');

    %% ========================================================
    % SAVE
    %% ========================================================
    exportgraphics( ...
        gcf, ...
        fullfile(zoomDir, sprintf( ...
            '%s_SPN_Zoom_%s.png', ...
            roiName, ...
            cfgSPN.plot_mode)), ...
        'Resolution', 300);

    close(gcf)

end

end