function OUT = ...
    plot_erp_spectrogram_subject( ...
    subjTF,...
    subjID,...
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

if ~isfield(cfg,'SpecLimits')
    cfg.SpecLimits = [];
end

if ~isfield(cfg,'DiffLimits')
    cfg.DiffLimits = [];
end

if ~isfield(cfg,'showDifference')
    cfg.showDifference = true;
end

%% ============================================================
% CONDITIONS
%% ============================================================

allFields = fieldnames(subjTF);

condMask = false(size(allFields));

for k = 1:numel(allFields)

    condMask(k) = ...
        isstruct(subjTF.(allFields{k})) && ...
        isfield(subjTF.(allFields{k}),...
        'power');

end

plotFields = allFields(condMask);

condNames = ...
    setdiff(plotFields,...
    {'Difference'});

nCond = numel(condNames);

if cfg.showDifference && ...
        isfield(subjTF,'Difference')
    nPanels = nCond + 1;
else
    nPanels = nCond;
end

%% ============================================================
% FIGURE
%% ============================================================

f = figure( ...
    'Color','w',...
    'Position',[100 100 1400 450]);

panelIdx = 1;

for iCond = 1:nCond

    condName = condNames{iCond};

    subplot(1,nPanels,panelIdx)

    imagesc( ...
        subjTF.(condName).time,...
        subjTF.(condName).freq,...
        subjTF.(condName).power);

    axis xy

    freqVec = ...
        subjTF.(condName).freq;

    freqMaxDisplay = ...
        ceil(max(freqVec)/10)*10;

    ylim([ ...
        min(freqVec) ...
        freqMaxDisplay])

    yticks(0:10:freqMaxDisplay)

    colorbar
    colormap(cfg.colormap)

    if ~isempty(cfg.SpecLimits)
        clim(cfg.SpecLimits)
    end

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    title(format_tex_name(condName))

    panelIdx = panelIdx + 1;

end

if cfg.showDifference && ...
        isfield(subjTF,'Difference')

    subplot(1,nPanels,panelIdx)

    imagesc( ...
        subjTF.Difference.time,...
        subjTF.Difference.freq,...
        subjTF.Difference.power);

    axis xy

    freqVec = ...
        subjTF.Difference.freq;

    freqMaxDisplay = ...
        ceil(max(freqVec)/10)*10;

    ylim([ ...
        min(freqVec) ...
        freqMaxDisplay])

    yticks(0:10:freqMaxDisplay)

    colorbar
    colormap(cfg.colormap)

    if ~isempty(cfg.DiffLimits)
        clim(cfg.DiffLimits)
    end

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')
    title(format_tex_name(subjTF.Difference.label))

end

sgtitle(sprintf( ...
    '%s | %s', ...
    format_tex_name(subjID),...
    format_tex_name(roiName)));
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
OUT.figure = f;
OUT.subjID = subjID;
OUT.roiName = roiName;