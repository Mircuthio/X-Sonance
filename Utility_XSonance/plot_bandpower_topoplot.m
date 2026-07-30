function plot_bandpower_topoplot( ...
    GroupChanBP,...
    bandName,...
    cfgTopo,...
    outdir)

% ============================================================
% PLOT_BANDPOWER_TOPOPLOT
%
% Group-level topographies of band power.
%
% Conditions:
%
%   Consonant
%   Dissonant
%   Difference
%
% ============================================================

tt = GroupChanBP.time;

chanlocs = GroupChanBP.chanlocs;

for iw = 1:numel(cfgTopo.windows)

    win = cfgTopo.windows{iw};

    winName = cfgTopo.window_names{iw};

    idxWin = ...
        tt >= win(1) & ...
        tt <= win(2);

    if ~any(idxWin)

        warning( ...
            'No samples in window %s', ...
            winName);

        continue

    end

    for ic = 1:numel(cfgTopo.conditions)

        condName = cfgTopo.conditions{ic};

        if ~isfield(GroupChanBP,condName)

            continue

        end

        % --------------------------------------------
        % Average power inside time window
        % --------------------------------------------

        topoData = mean( ...
            GroupChanBP.(condName).power(:,idxWin),...
            2,...
            'omitnan');

        % --------------------------------------------
        % Figure
        % --------------------------------------------

        fig = figure( ...
            'Color','w',...
            'Position',[100 100 900 700]);

        % --------------------------------------------
        % Difference maps
        % --------------------------------------------

        if strcmpi(condName,'Difference')

            mx = max(abs(topoData));

            if mx == 0
                mx = 1;
            end

            mapLimits = [-mx mx];

        else

            mapLimits = cfgTopo.maplimits;

        end

        % --------------------------------------------
        % Topoplot
        % --------------------------------------------

        topoplot( ...
            topoData,...
            chanlocs,...
            'maplimits',mapLimits,...
            'electrodes','on');

        colorbar

        if isfield(cfgTopo,'colormap')

            colormap(cfgTopo.colormap);

        end

        title(sprintf( ...
            '%s | %s | %s',...
            bandName,...
            winName,...
            condName), ...
            'Interpreter','none');

        % --------------------------------------------
        % Save
        % --------------------------------------------

        fileName = sprintf( ...
            'Topo_%s_%s_%s.png',...
            bandName,...
            winName,...
            condName);

        saveas( ...
            fig,...
            fullfile( ...
            outdir,...
            fileName));

        close(fig)

    end

end

end