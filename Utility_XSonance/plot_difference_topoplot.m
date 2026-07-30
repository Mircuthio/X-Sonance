function OUT = plot_difference_topoplot(ERPTopo,cfg)

if nargin < 2
    cfg = struct();
end

if ~isfield(cfg,'title_str')
    cfg.title_str = 'Difference Topography';
end

if ~isfield(cfg,'save_path')
    cfg.save_path = '';
end

if ~isfield(cfg,'clim')
    cfg.clim = [];
end

if ~isfield(cfg,'electrodes')
    cfg.electrodes = 'on';
end

values = ERPTopo.values(:);

f = figure( ...
    'Color','w',...
    'Position',[100 100 700 550]);

topoplot( ...
    values,...
    ERPTopo.chanlocs,...
    'electrodes',cfg.electrodes);

colorbar

if ~isempty(cfg.clim)
    clim(cfg.clim)
end

title(cfg.title_str)

set(gca,'FontSize',11)

if ~isempty(cfg.save_path)

    [p,~,~] = fileparts(cfg.save_path);

    if ~isempty(p) && ~exist(p,'dir')
        mkdir(p);
    end

    exportgraphics( ...
        f,...
        cfg.save_path,...
        'Resolution',300);

end

OUT.figure = f;
OUT.values = values;
OUT.cfg = cfg;

end