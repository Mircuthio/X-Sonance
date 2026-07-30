function OUT = plot_erp_waveforms(ERP, cfg)

% PLOT_ERP_WAVEFORMS
%
% Visualizes ERP waveforms from an ERP structure.
%
% The function can be used for:
%   - single-subject ERP
%   - ROI-averaged ERP
%   - group-average ERP
%
% INPUT
%   ERP : ERP structure containing:
%       .time_erp
%       .conditions
%       .grand_avg   (Conditions x Time)
%
%   cfg :
%       cond_idx
%       line_colors
%       show_zero
%       show_error
%       error_type      ('sem' or 'ci')
%       error_data
%       title_str
%       xlabel_str
%       ylabel_str
%       xlim
%       ylim
%       save_path
%
% OUTPUT
%   OUT.figure
%   OUT.handles
%   OUT.time
%   OUT.conditions
%   OUT.cfg

if nargin < 2, cfg = struct(); end
if ~isfield(cfg, 'cond_idx'),   cfg.cond_idx = 1:numel(ERP.conditions); end
if ~isfield(cfg, 'line_colors'), cfg.line_colors = lines(numel(cfg.cond_idx)); end
if ~isfield(cfg, 'show_zero'),  cfg.show_zero = true; end
if ~isfield(cfg, 'title_str'),  cfg.title_str = 'Single-subject ERP'; end
if ~isfield(cfg, 'ylabel_str'), cfg.ylabel_str = '\muV'; end
if ~isfield(cfg, 'xlim'),       cfg.xlim = []; end
if ~isfield(cfg, 'ylim'),       cfg.ylim = []; end
if ~isfield(cfg, 'save_path'),  cfg.save_path = ''; end
if ~isfield(cfg, 'smooth_plot'),    cfg.smooth_plot = false; end
if ~isfield(cfg, 'smooth_window'),    cfg.smooth_window = 5; end

assert(isfield(ERP,'time_erp'), 'ERP.time_erp missing');
assert(isfield(ERP,'conditions'),'ERP.conditions missing');
assert(isfield(ERP,'grand_avg'), 'ERP.grand_avg missing');
tt = ERP.time_erp(:).';
cond_idx = cfg.cond_idx(:).';
nCond = numel(cond_idx);

f = figure('Color','w','Position',[100 100 1100 500]); 
hold on;

hLines = gobjects(nCond,1);

for i = 1:nCond
    cidx = cond_idx(i);
    m = squeeze(ERP.grand_avg(cidx,:));
    if cfg.smooth_plot
        m = movmean(m,cfg.smooth_window);
    end
    if cfg.show_error && ~isempty(cfg.error_data)
        err = squeeze(cfg.error_data(cidx,:));
        if cfg.smooth_plot
            err = movmean(err,cfg.smooth_window);
        end
        xPatch = [tt fliplr(tt)];
        yPatch = [(m-err) fliplr(m+err)];
        patch( ...
            xPatch,...
            yPatch,...
            cfg.line_colors(i,:),...
            'FaceAlpha',0.20,...
            'EdgeColor','none');
    end
    hLines(i) = plot(tt, m, 'Color', cfg.line_colors(i,:), 'LineWidth', 2);
end

if cfg.show_zero
    xline(0,'k--','LineWidth',1);
    yline(0,'k:','LineWidth',1);
end

if ~isempty(cfg.xlim), xlim(cfg.xlim); end
if ~isempty(cfg.ylim), ylim(cfg.ylim); end

if max(abs(tt)) < 10
    xlabel('Time (s)');
else
    xlabel('Time (ms)');
end
ylabel(cfg.ylabel_str);
title(cfg.title_str);
legend(hLines, ERP.conditions(cond_idx), 'Location','best');
set(gca,'FontSize',11,'Box','off');
set(gca,'Layer','top')
if ~isempty(cfg.save_path)
    [p,~,~] = fileparts(cfg.save_path);
    if ~isempty(p) && ~exist(p,'dir'), mkdir(p); end
    exportgraphics( ...
    f,...
    cfg.save_path,...
    'Resolution',300);
end

OUT = struct();
OUT.figure     = f;
OUT.handles    = hLines;
OUT.time       = tt;
OUT.conditions = ERP.conditions(cond_idx);
OUT.cfg        = cfg;
end