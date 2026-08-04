function plot_spn_topoplots( ...
    subj_list_spn,...
    cfgSPN,...
    outdir)

topoDir = fullfile(outdir,'Topoplots');

if ~exist(topoDir,'dir')
    mkdir(topoDir);
end

%% ============================================================
% CHANNEL INFO
%% ============================================================

chanlocs = ...
    subj_list_spn(1).data_trials(1).chanlocs;

timeVec = ...
    subj_list_spn(1).data_trials(1).time;

conds = { ...
    'Consonant',...
    'Dissonant',...
    'Difference'};

%% ============================================================
% BUILD GROUP ERP
%% ============================================================

ERP_CON = [];
ERP_DIS = [];

for iSub = 1:numel(subj_list_spn)

    data_trials = ...
        subj_list_spn(iSub).data_trials;

    idxCon = strcmp( ...
        {data_trials.eventLabel}, ...
        'Consonant');

    idxDis = strcmp( ...
        {data_trials.eventLabel}, ...
        'Dissonant');

    %% -------------------------
    % Consonant
    %% -------------------------

    tmpCon = [];

    for it = find(idxCon)

        tmpCon(:,:,end+1) = ...
            data_trials(it).eeg;

    end

    ERP_CON(:,:,iSub) = ...
        mean(tmpCon,3);

    %% -------------------------
    % Dissonant
    %% -------------------------

    tmpDis = [];

    for it = find(idxDis)

        tmpDis(:,:,end+1) = ...
            data_trials(it).eeg;

    end

    ERP_DIS(:,:,iSub) = ...
        mean(tmpDis,3);

end

ERPcon = mean(ERP_CON,3);

ERPdis = mean(ERP_DIS,3);

ERPdiff = ERPdis - ERPcon;

%% ============================================================
% GLOBAL COLOR SCALE
%% ============================================================

allVals = [];

for iw = 1:numel(cfgSPN.windows)

    idxWin = ...
        timeVec >= cfgSPN.windows{iw}(1) & ...
        timeVec <= cfgSPN.windows{iw}(2);

    allVals = [ ...
        allVals ...
        mean(ERPcon(:,idxWin),2)' ...
        mean(ERPdis(:,idxWin),2)' ...
        mean(ERPdiff(:,idxWin),2)' ];
end

% cLim = [ ...
%     min(allVals) ...
%     max(allVals)];
% 
% maxAbs = max(abs(allVals));
% 
% cLim = [-maxAbs maxAbs];

cMin = prctile(allVals,5);
cMax = prctile(allVals,95);

cLim = [cMin cMax];
%% ============================================================
% FIGURE
%% ============================================================

figure( ...
'Position',[100 100 1800 1200]);

plotCounter = 0;

for ic = 1:numel(conds)

    condName = conds{ic};

    switch condName

        case 'Consonant'
            ERP = ERPcon;

        case 'Dissonant'
            ERP = ERPdis;

        case 'Difference'
            ERP = ERPdiff;

    end

    for iw = 1:numel(cfgSPN.windows)

        plotCounter = ...
            plotCounter + 1;

        win = cfgSPN.windows{iw};

        idxWin = ...
            timeVec >= win(1) & ...
            timeVec <= win(2);

        meanTopo = ...
            mean(ERP(:,idxWin),2);

        subplot(3,...
                numel(cfgSPN.windows),...
                plotCounter)

        topoplot( ...
            meanTopo,...
            chanlocs,...
            'maplimits',cLim,...
            'electrodes','off');

        title(sprintf( ...
            '%s\n%s', ...
            condName,...
            cfgSPN.window_names{iw}));

    end

end

sgtitle('SPN Topographical Maps');

cb = colorbar;

cb.Position = [ ...
    0.92 ...
    0.15 ...
    0.015 ...
    0.7];

ylabel(cb,'\muV')

exportgraphics( ...
    gcf,...
    fullfile( ...
    topoDir,...
    'SPN_Topoplots.png'),...
    'Resolution',300);

close

end