function plot_eran_mmn_comparison( ...
    subj_list,...
    cfgMMN,...
    outdir)

cmpDir = fullfile(outdir,'Comparisons');

if ~exist(cmpDir,'dir')
    mkdir(cmpDir);
end

roiCompare = cfgMMN.analysis_rois;

colors = lines(numel(roiCompare));

ERP_DIFF = struct();

%% ============================================================
% COMPUTE DIFFERENCE WAVES
%% ============================================================

for r = 1:numel(roiCompare)

    roiName = roiCompare{r};

    roi_labels = ...
        cfgMMN.rois.(roiName);

    ERP_CON = [];
    ERP_DIS = [];

    for iSub = 1:numel(subj_list)

        data_trials = ...
            subj_list(iSub).data_trials;

        timeVec = ...
            data_trials(1).time;

        idxCon = strcmp( ...
            {data_trials.eventLabel}, ...
            'Consonant');

        idxDis = strcmp( ...
            {data_trials.eventLabel}, ...
            'Dissonant');

        CON_trials = [];
        DIS_trials = [];

        %% Consonant
        for it = find(idxCon)

            labels = ...
                {data_trials(it).chanlocs.labels};

            roi_idx = ...
                ismember(labels,roi_labels);

            CON_trials(end+1,:) = ...
                mean(data_trials(it).eeg(roi_idx,:),1);

        end

        %% Dissonant
        for it = find(idxDis)

            labels = ...
                {data_trials(it).chanlocs.labels};

            roi_idx = ...
                ismember(labels,roi_labels);

            DIS_trials(end+1,:) = ...
                mean(data_trials(it).eeg(roi_idx,:),1);

        end

        ERP_CON(iSub,:) = ...
            mean(CON_trials,1);

        ERP_DIS(iSub,:) = ...
            mean(DIS_trials,1);

    end

    ERPcon = mean(ERP_CON,1);

    ERPdis = mean(ERP_DIS,1);

    ERP_DIFF.(roiName) = ...
        ERPdis - ERPcon;

end

%% ============================================================
% MULTI PANEL
%% ============================================================

figure( ...
    'Color','w',...
    'Position',[100 100 1400 900]);

for r = 1:numel(roiCompare)

    roiName = roiCompare{r};

    subplot(2,2,r)

    plot( ...
        timeVec,...
        ERP_DIFF.(roiName),...
        'k',...
        'LineWidth',2);

    hold on

    yline(0,'k:')

    xline(0,'k:')

    xlim([0 0.30])

    title(format_tex_name(roiName))

    xlabel('Time (s)')
    ylabel('\muV')

end

sgtitle('Difference Wave Comparison');

exportgraphics( ...
    gcf,...
    fullfile( ...
    cmpDir,...
    'ERAN_MMN_MultiPanel.png'),...
    'Resolution',300);

close

%% ============================================================
% OVERLAY
%% ============================================================

figure( ...
    'Color','w',...
    'Position',[100 100 1000 600]);

hold on

for r = 1:numel(roiCompare)

    roiName = roiCompare{r};

    plot( ...
        timeVec,...
        ERP_DIFF.(roiName),...
        'LineWidth',2,...
        'Color',colors(r,:));

end

yline(0,'k:')

xline(0,'k:')

xlim([0 0.30])

xlabel('Time (s)')
ylabel('\muV')

title('ERAN vs MMN ROI Comparison')

legend( ...
    roiCompare,...
    'Location','best');

exportgraphics( ...
    gcf,...
    fullfile( ...
    cmpDir,...
    'ERAN_MMN_Overlay.png'),...
    'Resolution',300);

close

end