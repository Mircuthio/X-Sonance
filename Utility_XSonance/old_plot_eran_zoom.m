function old_plot_eran_zoom( ...
    subj_list,...
    cfgERAN,...
    outdir)

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
zoomDir = fullfile(outdir,'Zoom');

if ~exist(zoomDir,'dir')
    mkdir(zoomDir);
end

%% ============================================================
% LOOP ROIs
%% ============================================================
for r = 1:numel(cfgERAN.analysis_rois)

    roiName = cfgERAN.analysis_rois{r};

    roi_labels = ...
        cfgERAN.rois.(roiName);

    %% ========================================================
    % PREALLOCATE SUBJECT MATRICES
    %% ========================================================
    nSub = numel(subj_list);

    timeVec = ...
        subj_list(1).data_trials(1).time;

    nTime = numel(timeVec);

    ERP_CON = nan(nSub,nTime);
    ERP_DIS = nan(nSub,nTime);

    %% ========================================================
    % SUBJECT LOOP
    %% ========================================================
    for iSub = 1:nSub

        data_trials = ...
            subj_list(iSub).data_trials;

        labels = ...
            {data_trials(1).chanlocs.labels};

        roi_idx = ...
            ismember(labels,roi_labels);

        idxCon = strcmp( ...
            {data_trials.eventLabel}, ...
            'Consonant');

        idxDis = strcmp( ...
            {data_trials.eventLabel}, ...
            'Dissonant');

        conTrials = find(idxCon);
        disTrials = find(idxDis);

        nCon = numel(conTrials);
        nDis = numel(disTrials);

        ERPcon_trials = ...
            zeros(nCon,nTime);

        ERPdis_trials = ...
            zeros(nDis,nTime);

        for k = 1:nCon

            it = conTrials(k);

            ERPcon_trials(k,:) = ...
                mean( ...
                data_trials(it).eeg(roi_idx,:), ...
                1);

        end

        for k = 1:nDis

            it = disTrials(k);

            ERPdis_trials(k,:) = ...
                mean( ...
                data_trials(it).eeg(roi_idx,:), ...
                1);

        end

        ERP_CON(iSub,:) = ...
            mean(ERPcon_trials,1);

        ERP_DIS(iSub,:) = ...
            mean(ERPdis_trials,1);

    end

    %% ========================================================
    % GROUP ERP
    %% ========================================================
    ERPcon = ...
        mean(ERP_CON,1,'omitnan');

    ERPdis = ...
        mean(ERP_DIS,1,'omitnan');

    switch lower(cfgERAN.diff_mode)

        case 'dis_minus_con'

            ERPdiff = ERPdis - ERPcon;
            diffLabel = 'Dissonant - Consonant';

        case 'con_minus_dis'

            ERPdiff = ERPcon - ERPdis;
            diffLabel = 'Consonant - Dissonant';

        otherwise

            error('Unknown diff_mode');

    end

    %% ========================================================
    % PEAK DIFFERENCE (LAST WINDOW)
    %% ========================================================
    peakWindow = ...
        cfgERAN.windows{end};

    idxPeakWin = ...
        timeVec >= peakWindow(1) & ...
        timeVec <= peakWindow(2);

    diffWin = ...
        ERPdiff(idxPeakWin);

    timeWin = ...
        timeVec(idxPeakWin);

    switch lower(cfgERAN.peak_mode)

        case 'min'

            [peakAmp,idxPeak] = min(diffWin);

        case 'max'

            [peakAmp,idxPeak] = max(diffWin);

        otherwise

            error('Unknown peak_mode');

    end

    peakLat = ...
        timeWin(idxPeak);
    %% ========================================================
    % PLOT OPTIONS
    %% ========================================================
    showCon  = false;
    showDis  = false;
    showDiff = false;
    showPeak = false;

    switch lower(cfgERAN.plot_mode)

        case 'all'

            showCon  = true;
            showDis  = true;
            showDiff = true;
            showPeak = true;

        case 'conditions'

            showCon = true;
            showDis = true;

        case 'diff'

            showDiff = true;
            showPeak = true;

        otherwise

            error('Unknown plot_mode');

    end
    %% ========================================================
    % WINDOW LABELS
    %% ========================================================
    nWindows = ...
        numel(cfgERAN.windows);

    winLabels = ...
        cell(1,nWindows);

    for iw = 1:nWindows

        win = cfgERAN.windows{iw};

        winLabels{iw} = ...
            sprintf( ...
            '%s (%d-%d ms)',...
            format_tex_name(cfgERAN.window_names{iw}),...
            round(win(1)*1000),...
            round(win(2)*1000));

    end

    %% ========================================================
    % FIGURE
    %% ========================================================
    figure( ...
        'Color','w',...
        'Position',[100 100 1200 600]);

    hold on

    yL = [ ...
        min([ERPcon ERPdis ERPdiff]) ...
        max([ERPcon ERPdis ERPdiff])];

    %% ========================================================
    % WINDOWS
    %% ========================================================
    colors = ...
        lines(nWindows);

    patchHandles = ...
        gobjects(nWindows,1);

    for iw = 1:nWindows

        win = ...
            cfgERAN.windows{iw};

        patchHandles(iw) = ...
            patch( ...
            [win(1) win(2) win(2) win(1)],...
            [yL(1) yL(1) yL(2) yL(2)],...
            colors(iw,:),...
            'FaceAlpha',0.08,...
            'EdgeColor','none');

    end

    %% ========================================================
    % ERP
    %% ========================================================
    hCon  = [];
    hDis  = [];
    hDiff = [];

    if showCon

        hCon = plot( ...
            timeVec,...
            ERPcon,...
            'b',...
            'LineWidth',2);

    end

    if showDis

        hDis = plot( ...
            timeVec,...
            ERPdis,...
            'r',...
            'LineWidth',2);

    end

    if showDiff

        hDiff = plot( ...
            timeVec,...
            ERPdiff,...
            'k',...
            'LineWidth',2);

    end

    %% ========================================================
    % PEAK
    %% ========================================================
    hPeak = [];

    if showPeak

        hPeak = plot( ...
            peakLat,...
            peakAmp,...
            'rp',...
            'MarkerFaceColor','r',...
            'MarkerSize',8);

        xline( ...
            peakLat,...
            'r--',...
            'LineWidth',1.5);

    end

    %% ========================================================
    % REFERENCE
    %% ========================================================
    yline(0,'k:');

    xline(0,'k:');

    %% ========================================================
    % AXES
    %% ========================================================
    xlim(cfgERAN.zoom_window)

    xlabel('Time (s)')

    ylabel('\muV')

    if showPeak

        title(sprintf( ...
            '%s ERAN Zoom\nPeak = %.0f ms | %.2f \\muV',...
            format_tex_name(roiName),...
            peakLat*1000,...
            peakAmp));

    else

        title(sprintf( ...
            '%s ERAN Zoom',...
            format_tex_name(roiName)));

    end

    %% ========================================================
    % LEGEND
    %% ========================================================
    legendHandles = patchHandles(:)';
    legendLabels  = winLabels;

    if showCon

        legendHandles(end+1) = hCon;
        legendLabels{end+1} = 'Consonant';

    end

    if showDis

        legendHandles(end+1) = hDis;
        legendLabels{end+1} = 'Dissonant';

    end

    if showDiff

        legendHandles(end+1) = hDiff;
        legendLabels{end+1} = diffLabel;

    end

    if showPeak

        legendHandles(end+1) = hPeak;
        legendLabels{end+1} = 'Peak ERAN';

    end

    legend( ...
        legendHandles,...
        legendLabels,...
        'Location','best');

    %% ========================================================
    % SAVE
    %% ========================================================
    exportgraphics( ...
        gcf,...
        fullfile( ...
        zoomDir,...
        sprintf( ...
        '%s_ERAN_Zoom_%s.png',...
        roiName,...
        cfgERAN.plot_mode)),...
        'Resolution',300);

    close

end

end