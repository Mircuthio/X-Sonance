function OUT = plot_difference_wave(ERP,cfg)

if nargin < 2
    cfg = struct();
end

if ~isfield(cfg,'line_color')
    cfg.line_color = [0 0 0];
end

if ~isfield(cfg,'show_zero')
    cfg.show_zero = true;
end

if ~isfield(cfg,'title_str')
    cfg.title_str = 'Difference Wave';
end

if ~isfield(cfg,'save_path')
    cfg.save_path = '';
end

if ~isfield(cfg,'smooth_plot')
    cfg.smooth_plot = false;
end

if ~isfield(cfg,'smooth_window')
    cfg.smooth_window = 5;
end
if ~isfield(cfg,'ylabel_str')
    cfg.ylabel_str = '\muV';
end

if ~isfield(cfg,'smooth_plot')
    cfg.smooth_plot = false;
end

if ~isfield(cfg,'smooth_window')
    cfg.smooth_window = 5;
end

assert(numel(ERP.conditions)==2,...
    'Difference wave requires exactly two conditions');

tt = ERP.time_erp(:)';

diffWave = ...
    ERP.grand_avg(2,:) - ERP.grand_avg(1,:);

if cfg.smooth_plot
    diffWave = movmean( ...
        diffWave,...
        cfg.smooth_window);
end

f = figure( ...
    'Color','w',...
    'Position',[100 100 900 500]);

hold on

plot( ...
    tt,...
    diffWave,...
    'Color',cfg.line_color,...
    'LineWidth',2);

if cfg.show_zero
    xline(0,'k--','LineWidth',1);
    yline(0,'k:','LineWidth',1);
end

if max(abs(tt)) < 10
    xlabel('Time (s)');
else
    xlabel('Time (ms)');
end

ylabel(cfg.ylabel_str);

title(cfg.title_str);

grid on
box off

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
OUT.time = tt;
OUT.diffWave = diffWave;
OUT.cfg = cfg;

end