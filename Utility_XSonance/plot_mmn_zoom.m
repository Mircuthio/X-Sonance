function plot_mmn_zoom( ...
    subj_list,...
    cfgMMN,...
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
for r = 1:numel(cfgMMN.analysis_rois)

    roiName = cfgMMN.analysis_rois{r};

    roi_labels = ...
        cfgMMN.rois.(roiName);

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

        %% ----------------------------------------------------
        % CONSONANT
        %% ----------------------------------------------------
        for k = 1:nCon

            it = conTrials(k);

            ERPcon_trials(k,:) = ...
                mean( ...
                data_trials(it).eeg(roi_idx,:), ...
                1);

        end

        %% ----------------------------------------------------
        % DISSONANT
        %% ----------------------------------------------------
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

    ERPdiff = ...
        ERPdis - ERPcon;

    %% ========================================================
    % PEAK DIFFERENCE (LAST WINDOW)
    %% ========================================================
    peakWindow = ...
        cfgMMN.windows{end};

    idxPeakWin = ...
        timeVec >= peakWindow(1) & ...
        timeVec <= peakWindow(2);

    diffWin = ERPdiff(idxPeakWin);

    timeWin = timeVec(idxPeakWin);

    [peakAmp,idxPeak] = ...
        min(diffWin);

    peakLat = ...
        timeWin(idxPeak);

    %% ========================================================
    % WINDOW LABELS
    %% ========================================================
    nWindows = ...
        numel(cfgMMN.windows);

    winLabels = ...
        cell(1,nWindows);

    for iw = 1:nWindows

        win = cfgMMN.windows{iw};

        winLabels{iw} = ...
            sprintf( ...
            '%s (%d-%d ms)',...
            format_tex_name(cfgMMN.window_names{iw}),...
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
    colors = lines(nWindows);

    patchHandles = ...
        gobjects(nWindows,1);

    for iw = 1:nWindows

        win = cfgMMN.windows{iw};

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
    hCon = plot(timeVec,ERPcon,'LineWidth',2);

    hDis = plot(timeVec,ERPdis,'LineWidth',2);

    hDiff = plot( ...
        timeVec,...
        ERPdiff,...
        'k',...
        'LineWidth',2);

    %% ========================================================
    % PEAK
    %% ========================================================
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

    %% ========================================================
    % REFERENCE
    %% ========================================================
    yline(0,'k:');

    xline(0,'k:');

    %% ========================================================
    % AXES
    %% ========================================================
    xlim(cfgMMN.zoom_window)

    xlabel('Time (s)')

    ylabel('\muV')

    title(sprintf( ...
        '%s MMN Zoom\nPeak MMN = %.0f ms | %.2f \\muV', ...
        format_tex_name(roiName),...
        peakLat*1000,...
        peakAmp));

    %% ========================================================
    % LEGEND
    %% ========================================================
    legendHandles = [ ...
        patchHandles(:)' ...
        hCon ...
        hDis ...
        hDiff ...
        hPeak];

    legendLabels = [ ...
        winLabels,...
        {'Consonant',...
         'Dissonant',...
         'Difference',...
         'Peak MMN'}];

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
        sprintf('%s_MMN_Zoom.png', ...
        roiName)),...
        'Resolution',300);

    close

end

end