function STAT = erp_stats(ERP, cfg)
% ERP_STATS
% Statistiche ERP su misure riassuntive per soggetto/condizione.
%
% INPUT
%   ERP : struct prodotto da classic_erp_extraction
%   cfg : struct con campi opzionali
%       .metric_field   = 'data' oppure 'subject_erp'
%       .cond_idx       = indices condizioni da confrontare
%       .window_idx     = indice tempo o range di indici
%       .alpha          = 0.05
%       .paired         = true
%       .tail           = 'both'
%
% OUTPUT
%   STAT : struct con risultati statistici

if nargin < 2, cfg = struct(); end
if ~isfield(cfg, 'metric_field'), cfg.metric_field = 'subject_erp'; end
if ~isfield(cfg, 'cond_idx'), cfg.cond_idx = 1:numel(ERP.conditions); end
if ~isfield(cfg, 'window_idx'), cfg.window_idx = []; end
if ~isfield(cfg, 'alpha'), cfg.alpha = 0.05; end
if ~isfield(cfg, 'paired'), cfg.paired = true; end
if ~isfield(cfg, 'tail'), cfg.tail = 'both'; end

X = ERP.(cfg.metric_field);
if isempty(cfg.window_idx)
    win = 1:size(X,3);
elseif numel(cfg.window_idx) == 2
    win = cfg.window_idx(1):cfg.window_idx(2);
else
    win = cfg.window_idx;
end

Xw = squeeze(mean(X(:,:,win), 3, 'omitnan')); % subjects x conditions

STAT = struct();
STAT.alpha = cfg.alpha;
STAT.conditions = ERP.conditions(cfg.cond_idx);
STAT.window_idx = win;
STAT.subject_values = Xw;
STAT.time_erp = ERP.time_erp(win);

nCond = numel(cfg.cond_idx);

if nCond == 2
    x = Xw(:, cfg.cond_idx(1));
    y = Xw(:, cfg.cond_idx(2));
    valid = ~isnan(x) & ~isnan(y);
    x = x(valid);
    y = y(valid);
    [h,p,ci,stats] = ttest(x, y, 'Alpha', cfg.alpha, 'Tail', cfg.tail);
    STAT.test = 'paired_ttest';
    STAT.h = h;
    STAT.p = p;
    STAT.ci = ci;
    STAT.stats = stats;
    STAT.n = sum(valid);
    STAT.dz = mean(x-y,'omitnan') / std(x-y,'omitnan');
else
    Y = Xw(:, cfg.cond_idx);
    STAT.test = 'rm_anova_preparation';
    STAT.table = array2table(Y, 'VariableNames', matlab.lang.makeValidName(string(STAT.conditions)));
    STAT.note = 'Per RM-ANOVA usare fitrm/ranova su questa tabella.';
end
end