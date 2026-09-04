function OUT = ...
    plot_erp_spectrogram( ...
    groupTF,...
    roiName,...
    cfg)

%% ============================================================
% DEFAULT CONFIG
%% ============================================================

if nargin < 4
    cfg = struct();
end

if ~isfield(cfg,'colormap')
    cfg.colormap = turbo;
end

if ~isfield(cfg,'clim')
    cfg.clim = 'auto';
end

if ~isfield(cfg,'showDifference')
    cfg.showDifference = true;
end

%% ============================================================
% FIND CONDITIONS
%% ============================================================

allFields = ...
    fieldnames(groupTF);

condMask = ...
    false(size(allFields));

for iField = 1:numel(allFields)

    condMask(iField) = ...
        isstruct(groupTF.(allFields{iField})) && ...
        isfield(groupTF.(allFields{iField}), ...
        'power');

end

plotFields = ...
    allFields(condMask);

%% ============================================================
% REMOVE DIFFERENCE
%% ============================================================

condNames = ...
    setdiff(plotFields,...
    {'Difference'});

nCond = ...
    numel(condNames);

if cfg.showDifference && ...
        isfield(groupTF,'Difference')

    nPanels = ...
        nCond + 1;

else

    nPanels = ...
        nCond;

end

%% ============================================================
% FIGURE
%% ============================================================

f = figure( ...
    'Color','w',...
    'Position',[100 100 1400 450]);

%% ============================================================
% CONDITIONS
%% ============================================================
freqVec = ...
    groupTF.freq;

freqMaxDisplay = ...
    ceil(max(freqVec)/10)*10;

panelIdx = 1;

for iCond = 1:nCond

    condName = ...
        condNames{iCond};

    subplot(1,nPanels,panelIdx)

    imagesc( ...
        groupTF.time,...
        groupTF.freq,...
        groupTF.(condName).power);

    axis xy

    ylim([ ...
        min(freqVec) ...
        freqMaxDisplay])

    yticks(0:10:freqMaxDisplay)

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    title(format_tex_name(condName))

    colormap(cfg.colormap)

    colorbar

    if isfield(cfg,'SpecLimits')
        clim(cfg.SpecLimits)
    end

    panelIdx = ...
        panelIdx + 1;

end

%% ============================================================
% DIFFERENCE
%% ============================================================

if cfg.showDifference && ...
        isfield(groupTF,'Difference')

    subplot(1,nPanels,panelIdx)

    imagesc( ...
        groupTF.time,...
        groupTF.freq,...
        groupTF.Difference.power);

    axis xy

    ylim([ ...
        min(freqVec) ...
        freqMaxDisplay])

    yticks(0:10:freqMaxDisplay)

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    title(format_tex_name(groupTF.Difference.label))

    colormap(cfg.colormap)

    colorbar

    if isfield(cfg,'DiffLimits')
        clim(cfg.DiffLimits)
    end


end

%% ============================================================
% SGTITLE
%% ============================================================

sgtitle( ...
    sprintf('ERP Spectrogram - %s', ...
    format_tex_name(roiName)),...
    'FontWeight','bold');

%% ============================================================
% SAVE
%% ============================================================

if isfield(cfg,'save_path') && ...
        ~isempty(cfg.save_path)

    [saveDir,~,~] = ...
        fileparts(cfg.save_path);

    if ~isempty(saveDir) && ...
            ~exist(saveDir,'dir')

        mkdir(saveDir);

    end

    exportgraphics( ...
        f,...
        cfg.save_path,...
        'Resolution',300);

end

%% ============================================================
% OUTPUT
%% ============================================================

OUT = struct();

OUT.figure = f;

OUT.roiName = roiName;

OUT.conditions = condNames;

OUT.cfg = cfg;

end
