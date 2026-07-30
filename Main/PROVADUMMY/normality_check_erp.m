function OUT = normality_check_erp(ERP, cfg)
% NORMALITY_CHECK_ERP  Normality diagnostics for ERP trial values.
% Uses Q-Q plots, skewness, kurtosis, KS test, and optional Shapiro-Wilk.
%
% INPUT
%   ERP: struct with condition fields.
%        Each condition must contain a numeric vector in:
%          - ERP.(cond).values
%          - or ERP.(cond).trial_values
%   cfg: struct with fields:
%        - conditions   cell array of condition names
%        - save_dir     folder to save outputs
%        - run_label    label used in filenames
%        - alpha        significance level, default 0.05
%        - shapiro_fun  optional function handle for Shapiro-Wilk
%
% OUTPUT
%   OUT: struct with descriptive stats and test results per condition.

if nargin < 2, cfg = struct(); end
if ~isfield(cfg,'alpha') || isempty(cfg.alpha), cfg.alpha = 0.05; end
if ~isfield(cfg,'run_label') || isempty(cfg.run_label), cfg.run_label = 'run'; end
if ~isfield(cfg,'save_dir') || isempty(cfg.save_dir), cfg.save_dir = pwd; end
if ~exist(cfg.save_dir,'dir'), mkdir(cfg.save_dir); end

if ~isfield(cfg,'conditions') || isempty(cfg.conditions)
    cond_fields = fieldnames(ERP);
    conditions = cond_fields;
else
    conditions = cfg.conditions;
end

OUT = struct();
summary = table();

for ic = 1:numel(conditions)
    cond = conditions{ic};
    if ~isfield(ERP, cond)
        error('Condition not found in ERP: %s', cond);
    end

    if isfield(ERP.(cond), 'values')
        x = ERP.(cond).values(:);
    elseif isfield(ERP.(cond), 'trial_values')
        x = ERP.(cond).trial_values(:);
    else
        error('Condition %s must contain values or trial_values.', cond);
    end

    x = x(~isnan(x));
    if numel(x) < 3
        error('Too few samples for condition %s.', cond);
    end

    mu = mean(x);
    sd = std(x);
    if sd == 0
        z = zeros(size(x));
    else
        z = (x - mu) ./ sd;
    end

    [h_ks, p_ks] = kstest(z);
    sk = skewness(x);
    ku = kurtosis(x);

    sh_h = NaN;
    sh_p = NaN;
    sh_w = NaN;
    if isfield(cfg,'shapiro_fun') && ~isempty(cfg.shapiro_fun)
        try
            [sh_h, sh_p, sh_w] = cfg.shapiro_fun(x);
        catch ME
            warning('Shapiro-Wilk failed for %s: %s', cond, ME.message);
        end
    end

    fig = figure('Visible','off','Color','w');
    qqplot(x);
    grid on;
    title(sprintf('Q-Q plot - %s', cond), 'Interpreter','none');
    txt = sprintf('n=%d | skew=%.3f | kurt=%.3f | KS p=%.4g | SW p=%.4g', numel(x), sk, ku, p_ks, sh_p);
    annotation(fig,'textbox',[0.12 0.01 0.78 0.05], 'String', txt, ...
        'EdgeColor','none','HorizontalAlignment','center','FontSize',9);
    png_name = fullfile(cfg.save_dir, sprintf('QQ_%s_%s.png', cfg.run_label, cond));
    exportgraphics(fig, png_name, 'Resolution', 200);
    close(fig);

    OUT.(cond).n = numel(x);
    OUT.(cond).mean = mu;
    OUT.(cond).std = sd;
    OUT.(cond).skewness = sk;
    OUT.(cond).kurtosis = ku;
    OUT.(cond).ks_h = h_ks;
    OUT.(cond).ks_p = p_ks;
    OUT.(cond).shapiro_h = sh_h;
    OUT.(cond).shapiro_p = sh_p;
    OUT.(cond).shapiro_w = sh_w;
    OUT.(cond).alpha = cfg.alpha;

    summary = [summary; table(string(cond), numel(x), mu, sd, sk, ku, h_ks, p_ks, sh_h, sh_p, sh_w, ...
        'VariableNames', {'Condition','N','Mean','STD','Skewness','Kurtosis','KS_H','KS_P','SW_H','SW_P','SW_W'})];
end

OUT.summary = summary;
writetable(summary, fullfile(cfg.save_dir, sprintf('normality_%s.csv', cfg.run_label)));
save(fullfile(cfg.save_dir, sprintf('normality_%s.mat', cfg.run_label)), 'OUT', 'cfg');
end