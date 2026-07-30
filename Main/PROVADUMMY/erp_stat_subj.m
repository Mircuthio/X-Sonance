function OUT = erp_stat_subj(ERP, cfg)
% ERP_STAT_SUBJ  Single-subject ERP statistics on ERP.time_erp using a chosen window.
% Works on ERP output from classic_erp_extraction.
%
% INPUT
%   ERP: struct returned by classic_erp_extraction
%   cfg: struct with fields:
%       - conditions   cell array, e.g. {'consonant','dissonant'}
%       - time_window  [t1 t2] window for scalar ERP measure; if omitted uses full ERP.time_erp
%       - alpha        significance level, default 0.05
%       - save_dir     folder for outputs
%       - run_label    label for filenames
%       - use_normality logical, default true
%       - shapiro_fun  optional function handle [h,p,w] = f(x)
%
% OUTPUT
%   OUT: struct with normality checks and paired statistics.

if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'conditions') || numel(cfg.conditions) < 2
    cfg.conditions = ERP.conditions;
end
if ~isfield(cfg,'time_window') || isempty(cfg.time_window)
    cfg.time_window = [min(ERP.time_erp) max(ERP.time_erp)];
end
if ~isfield(cfg,'alpha') || isempty(cfg.alpha), cfg.alpha = 0.05; end
if ~isfield(cfg,'save_dir') || isempty(cfg.save_dir), cfg.save_dir = pwd; end
if ~isfield(cfg,'run_label') || isempty(cfg.run_label), cfg.run_label = 'run'; end
if ~isfield(cfg,'use_normality') || isempty(cfg.use_normality), cfg.use_normality = true; end
if ~exist(cfg.save_dir,'dir'), mkdir(cfg.save_dir); end

conds = cfg.conditions;
assert(numel(conds) == 2, 'erp_stat_subj requires exactly 2 conditions.');
cond1 = conds{1};
cond2 = conds{2};
assert(isfield(ERP, 'data') && ndims(ERP.data) == 3, 'ERP.data must be nSubj x nCond x nTime');
assert(isfield(ERP, 'conditions'), 'ERP.conditions missing');
assert(isfield(ERP, 'time_erp'), 'ERP.time_erp missing');

idx1 = find(strcmpi(ERP.conditions, cond1), 1);
idx2 = find(strcmpi(ERP.conditions, cond2), 1);
assert(~isempty(idx1) && ~isempty(idx2), 'Requested conditions not found in ERP.conditions');

t = ERP.time_erp(:).';
sel = t >= cfg.time_window(1) & t <= cfg.time_window(2);
assert(any(sel), 'No time points found in the selected time window');

X1 = squeeze(mean(ERP.data(:, idx1, sel), 3, 'omitnan'));
X2 = squeeze(mean(ERP.data(:, idx2, sel), 3, 'omitnan'));
X1 = X1(:);
X2 = X2(:);
valid = ~isnan(X1) & ~isnan(X2);
X1 = X1(valid);
X2 = X2(valid);
assert(numel(X1) >= 2, 'Too few paired observations for statistics');

diffX = X2 - X1;

OUT = struct();
OUT.conditions = conds;
OUT.time_window = cfg.time_window;
OUT.alpha = cfg.alpha;
OUT.n = numel(X1);
OUT.values.cond1 = X1;
OUT.values.cond2 = X2;
OUT.values.diff = diffX;
OUT.descr.cond1.mean = mean(X1);
OUT.descr.cond1.std = std(X1);
OUT.descr.cond2.mean = mean(X2);
OUT.descr.cond2.std = std(X2);
OUT.descr.diff.mean = mean(diffX);
OUT.descr.diff.std = std(diffX);

OUT.normality = struct();
if cfg.use_normality
    [OUT.normality.cond1, ~] = local_normality(X1, cond1, cfg);
    [OUT.normality.cond2, ~] = local_normality(X2, cond2, cfg);
    [OUT.normality.diff,  ~] = local_normality(diffX, sprintf('%s_minus_%s', cond2, cond1), cfg);
end

OUT.tests = struct();
OUT.tests.paired_t = struct();
[OUT.tests.paired_t.h, OUT.tests.paired_t.p, OUT.tests.paired_t.ci, OUT.tests.paired_t.stats] = ttest(X1, X2, 'Alpha', cfg.alpha);
OUT.tests.paired_t.df = OUT.tests.paired_t.stats.df;
OUT.tests.paired_t.tstat = OUT.tests.paired_t.stats.tstat;

OUT.tests.wilcoxon = struct();
[OUT.tests.wilcoxon.p, OUT.tests.wilcoxon.h, OUT.tests.wilcoxon.stats] = signrank(X1, X2, 'alpha', cfg.alpha);
OUT.tests.wilcoxon.signedrank = OUT.tests.wilcoxon.stats.signedrank;

OUT.effect = struct();
OUT.effect.mean_diff = mean(diffX);
OUT.effect.cohens_dz = mean(diffX) / std(diffX);
OUT.effect.sem_diff = std(diffX) / sqrt(numel(diffX));

OUT.summary = table(string(cond1), string(cond2), numel(X1), mean(X1), mean(X2), mean(diffX), ...
    OUT.tests.paired_t.tstat, OUT.tests.paired_t.df, OUT.tests.paired_t.p, ...
    OUT.tests.wilcoxon.p, OUT.effect.cohens_dz, ...
    'VariableNames', {'Cond1','Cond2','N','Mean1','Mean2','MeanDiff','Tstat','DF','P_ttest','P_signrank','Cohens_dz'});

writetable(OUT.summary, fullfile(cfg.save_dir, sprintf('erp_stat_%s.csv', cfg.run_label)));
save(fullfile(cfg.save_dir, sprintf('erp_stat_%s.mat', cfg.run_label)), 'OUT', 'cfg');
end

function [N, fig] = local_normality(x, label, cfg)
N = struct();
N.n = numel(x);
N.mean = mean(x);
N.std = std(x);
N.skewness = skewness(x);
N.kurtosis = kurtosis(x);
if N.std == 0
    z = zeros(size(x));
else
    z = (x - N.mean) ./ N.std;
end
[N.ks_h, N.ks_p] = kstest(z);
N.shapiro_h = NaN;
N.shapiro_p = NaN;
N.shapiro_w = NaN;
if isfield(cfg,'shapiro_fun') && ~isempty(cfg.shapiro_fun)
    try
        [N.shapiro_h, N.shapiro_p, N.shapiro_w] = cfg.shapiro_fun(x);
    catch ME
        warning('Shapiro-Wilk failed for %s: %s', label, ME.message);
    end
end
fig = figure('Visible','off','Color','w');
qqplot(x);
grid on;
title(sprintf('Q-Q plot - %s', label), 'Interpreter','none');
subtitle(sprintf('n=%d | skew=%.3f | kurt=%.3f | KS p=%.4g | SW p=%.4g', N.n, N.skewness, N.kurtosis, N.ks_p, N.shapiro_p));
exportgraphics(fig, fullfile(cfg.save_dir, sprintf('QQ_%s_%s.png', cfg.run_label, label)), 'Resolution', 200);
close(fig);
end