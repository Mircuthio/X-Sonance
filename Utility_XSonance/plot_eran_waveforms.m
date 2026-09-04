function plot_eran_waveforms( ...
    subj_list,...
    cfgERAN,...
    outdir)

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
waveDir = fullfile(outdir,'Waveforms');

if ~exist(waveDir,'dir')
    mkdir(waveDir);
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

    nTime = ...
        numel(timeVec);

    ERP_CON = zeros(nSub,nTime);
    ERP_DIS = zeros(nSub,nTime);

    %% ========================================================
    % SUBJECT LOOP
    %% ========================================================
    for iSub = 1:nSub

        data_trials = ...
            subj_list(iSub).data_trials;

        %% ----------------------------------------------------
        % ROI INDEX (COMPUTED ONCE)
        %% ----------------------------------------------------
        labels = ...
            {data_trials(1).chanlocs.labels};

        roi_idx = ...
            ismember(labels,roi_labels);

        %% ----------------------------------------------------
        % CONDITIONS
        %% ----------------------------------------------------
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

        %% ----------------------------------------------------
        % PREALLOCATE TRIAL MATRICES
        %% ----------------------------------------------------
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

        %% ----------------------------------------------------
        % SUBJECT AVERAGES
        %% ----------------------------------------------------
        ERP_CON(iSub,:) = ...
            mean(ERPcon_trials,1);

        ERP_DIS(iSub,:) = ...
            mean(ERPdis_trials,1);

    end

    %% ========================================================
    % GROUP AVERAGES
    %% ========================================================
    ERPcon = mean(ERP_CON,1);

    ERPdis = mean(ERP_DIS,1);

    ERPdiff = ERPdis - ERPcon;

    %% ========================================================
    % WINDOW LABELS
    %% ========================================================
    nWindows = ...
        numel(cfgERAN.windows);

    winLabels = ...
        cell(1,nWindows);

    for iw = 1:nWindows

        win = ...
            cfgERAN.windows{iw};

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
        'Position',[100 100 1300 600]);

    hold on

    %% ========================================================
    % Y LIMITS
    %% ========================================================
    yL = [ ...
        min([ERPcon ERPdis ERPdiff]) ...
        max([ERPcon ERPdis ERPdiff])];

    %% ========================================================
    % WINDOW PATCHES
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
            'FaceAlpha',0.10,...
            'EdgeColor','none');

    end

    %% ========================================================
    % ERP CURVES
    %% ========================================================
    hCon = plot( ...
        timeVec,...
        ERPcon,...
        'LineWidth',2);

    hDis = plot( ...
        timeVec,...
        ERPdis,...
        'LineWidth',2);

    hDiff = plot( ...
        timeVec,...
        ERPdiff,...
        'k',...
        'LineWidth',2);

    %% ========================================================
    % REFERENCE LINES
    %% ========================================================
    yline(0,'k:');

    xline(0,'k:');

    %% ========================================================
    % AXES
    %% ========================================================
    xlim([-0.2 0.8])

    xlabel('Time (s)')

    ylabel('\muV')

    title(sprintf( ...
        '%s ERP', ...
        format_tex_name(roiName)));

    %% ========================================================
    % LEGEND
    %% ========================================================
    legendHandles = [ ...
        patchHandles(:)' ...
        hCon ...
        hDis ...
        hDiff];

    legendLabels = [ ...
        winLabels ...
        {'Consonant',...
         'Dissonant',...
         'Difference'}];

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
        waveDir,...
        sprintf('%s_ERP.png',roiName)),...
        'Resolution',300);

    close

end

end