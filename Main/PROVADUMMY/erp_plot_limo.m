function OUT = erp_plot_limo(ERP, cfg)
% ERP_PLOT_LIMO
% Plot ERP da struct ERP con opzione LIMO per confronto temporale.
%
% INPUT
%   ERP : struct prodotto da classic_erp_extraction
%   cfg : struct con campi opzionali
%       .cond_idx      = condizioni da plottare (default: 1:2)
%       .line_colors   = Nx3 RGB
%       .show_ci       = true/false
%       .show_sem      = true/false
%       .ci_alpha      = 0.05
%       .show_zero     = true/false
%       .show_signif   = true/false
%       .alpha         = 0.05
%       .use_limo      = true/false
%       .title_str     = stringa titolo
%       .xlabel_str    = etichetta x
%       .ylabel_str    = etichetta y
%       .xlim          = [xmin xmax]
%       .ylim          = [ymin ymax]
%       .save_path     = '' per non salvare
%
% OUTPUT
%   OUT : struct con figure, p-values e mask

if nargin < 2, cfg = struct(); end
if ~isfield(cfg, 'cond_idx'),    cfg.cond_idx = 1:min(2, numel(ERP.conditions)); end
if ~isfield(cfg, 'line_colors'), cfg.line_colors = lines(numel(cfg.cond_idx)); end
if ~isfield(cfg, 'show_ci'),     cfg.show_ci = true; end
if ~isfield(cfg, 'show_sem'),    cfg.show_sem = false; end
if ~isfield(cfg, 'ci_alpha'),    cfg.ci_alpha = 0.05; end
if ~isfield(cfg, 'show_zero'),   cfg.show_zero = true; end
if ~isfield(cfg, 'show_signif'), cfg.show_signif = true; end
if ~isfield(cfg, 'alpha'),       cfg.alpha = 0.05; end
if ~isfield(cfg, 'use_limo'),    cfg.use_limo = true; end
if ~isfield(cfg, 'title_str'),   cfg.title_str = 'ERP comparison'; end
if ~isfield(cfg, 'xlabel_str'),  cfg.xlabel_str = 'Time'; end
if ~isfield(cfg, 'ylabel_str'),  cfg.ylabel_str = '\muV'; end
if ~isfield(cfg, 'xlim'),        cfg.xlim = []; end
if ~isfield(cfg, 'ylim'),        cfg.ylim = []; end
if ~isfield(cfg, 'save_path'),   cfg.save_path = ''; end

tt = ERP.time_erp(:).';
cond_idx = cfg.cond_idx(:).';
nCond = numel(cond_idx);

f = figure('Color','w','Position',[100 100 1100 500]); hold on;
hLines = gobjects(nCond,1);

for i = 1:nCond
    cidx = cond_idx(i);
    m = squeeze(ERP.grand_avg(cidx,:));
    if isfield(ERP, 'grand_se') && ~isempty(ERP.grand_se)
        se = squeeze(ERP.grand_se(cidx,:));
    else
        se = zeros(size(m));
    end

    col = cfg.line_colors(i,:);

    if cfg.show_ci
        z = 1.96;
        lo = m - z*se;
        hi = m + z*se;
        fill([tt fliplr(tt)], [lo fliplr(hi)], col, ...
            'FaceAlpha',0.15, 'EdgeColor','none');
    elseif cfg.show_sem
        fill([tt fliplr(tt)], [m-se fliplr(m+se)], col, ...
            'FaceAlpha',0.15, 'EdgeColor','none');
    end

    hLines(i) = plot(tt, m, 'Color', col, 'LineWidth', 2);
end

pvals = [];
signif_mask = [];

if cfg.use_limo && nCond == 2 && isfield(ERP, 'subject_erp') && ~isempty(ERP.subject_erp)
    c1 = squeeze(ERP.subject_erp(:, cond_idx(1), :));
    c2 = squeeze(ERP.subject_erp(:, cond_idx(2), :));
    pvals = nan(1, numel(tt));
    signif_mask = false(1, numel(tt));
    for t = 1:numel(tt)
        x = c1(:, t);
        y = c2(:, t);
        valid = ~isnan(x) & ~isnan(y);
        if sum(valid) > 1
            try
                [~, p] = ttest(x(valid), y(valid), 'Alpha', cfg.alpha);
            catch
                p = NaN;
            end
            pvals(t) = p;
            signif_mask(t) = ~isnan(p) && p <= cfg.alpha;
        end
    end
end

if cfg.show_zero
    xline(0,'k--','LineWidth',1);
    yline(0,'k:','LineWidth',1);
end

if cfg.show_signif && ~isempty(signif_mask)
    yl = ylim;
    sig_y = yl(1) + 0.05*(yl(2)-yl(1));
    plot(tt(signif_mask), sig_y*ones(1,sum(signif_mask)), 'k.', 'MarkerSize', 8);
end

if ~isempty(cfg.xlim), xlim(cfg.xlim); end
if ~isempty(cfg.ylim), ylim(cfg.ylim); end

xlabel(cfg.xlabel_str);
ylabel(cfg.ylabel_str);
title(cfg.title_str);
legend(hLines, ERP.conditions(cond_idx), 'Location','best');
set(gca,'FontSize',11,'Box','off');

if ~isempty(cfg.save_path)
    [p,~,~] = fileparts(cfg.save_path);
    if ~isempty(p) && ~exist(p,'dir'), mkdir(p); end
    saveas(f, cfg.save_path);
end

OUT = struct();
OUT.figure = f;
OUT.handles = hLines;
OUT.time = tt;
OUT.conditions = ERP.conditions(cond_idx);
OUT.pvals = pvals;
OUT.signif_mask = signif_mask;
OUT.cfg = cfg;
end