function step10A_plot_erp_heatmap( ...
    Ranking,...
    outdir)

%% ============================================================
% SETTINGS
%% ============================================================

roiNames = { ...
    'MMN',...
    'ERAN_CORE',...
    'ERAN_RIGHT',...
    'N5_CENTRAL'};

windowNames = { ...
    'MMN',...
    'ERAN',...
    'REBOUND',...
    'N5'};

H = nan( ...
    numel(roiNames),...
    numel(windowNames));

%% ============================================================
% BUILD MATRIX
%% ============================================================

for iR = 1:numel(roiNames)

    roiName = roiNames{iR};

    for iW = 1:numel(windowNames)

        winName = windowNames{iW};

        featName = ...
            sprintf( ...
            '%s_%s_Mean',...
            roiName,...
            winName);

        idx = strcmp( ...
            Ranking.Feature,...
            featName);

        if any(idx)

            H(iR,iW) = ...
                abs( ...
                Ranking.CohenD(idx));

        end

    end
end

%% ============================================================
% FIGURE
%% ============================================================

f = figure( ...
    'Color','w');

imagesc(H);

axis tight

colorbar

title( ...
    'ERP Heatmap | Cohen''s d |');

xticks(1:numel(windowNames))
xticklabels(windowNames)

yticks(1:numel(roiNames))
yticklabels(roiNames)

set(gca,...
    'FontSize',12);

%% VALUES
for r = 1:size(H,1)

    for c = 1:size(H,2)

        text( ...
            c,...
            r,...
            sprintf('%.2f',H(r,c)),...
            'HorizontalAlignment','center',...
            'Color','k',...
            'FontWeight','bold');

    end

end

%% SAVE

saveas( ...
    f,...
    fullfile( ...
    outdir,...
    'ERP_Heatmap.png'));

close(f)

end