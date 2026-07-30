function Stats = compute_roi_window_statistics(roiData,cfg)

assert(numel(cfg.conditions)==2,...
    'Exactly two conditions required');

condA = cfg.conditions{1};
condB = cfg.conditions{2};

assert(isfield(roiData,condA),...
    'Condition missing');

assert(isfield(roiData,condB),...
    'Condition missing');

tt = roiData.time;

idxWin = ...
    tt >= cfg.window(1) & ...
    tt <= cfg.window(2);

A = roiData.(condA);
B = roiData.(condB);

% ---------------------------------------------------------
% ROI average
% [channels x time x subjects]
% ->
% [time x subjects]
% ---------------------------------------------------------

A = squeeze(mean(A,1,'omitnan'));
B = squeeze(mean(B,1,'omitnan'));

% ---------------------------------------------------------
% Window average
% ---------------------------------------------------------

Awin = ...
    mean(A(idxWin,:),1,'omitnan')';

Bwin = ...
    mean(B(idxWin,:),1,'omitnan')';

% ---------------------------------------------------------
% Paired t-test
% ---------------------------------------------------------

[~,p,ci,stats] = ...
    ttest(Bwin,Awin);

Stats = struct();

Stats.subjectA = Awin;
Stats.subjectB = Bwin;

Stats.meanA = mean(Awin,'omitnan');
Stats.meanB = mean(Bwin,'omitnan');
Stats.subjectDiff = Bwin - Awin;

Stats.meanDiff = ...
    mean(Stats.subjectDiff,'omitnan');

Stats.sdDiff = ...
    std(Stats.subjectDiff,'omitnan');

Stats.t = stats.tstat;
Stats.df = stats.df;
Stats.p = p;
Stats.ci = ci;

Stats.window = cfg.window;

Stats.resultsTable = table( ...
    Stats.meanA,...
    Stats.meanB,...
    Stats.diffMean,...
    Stats.diffSD,...
    Stats.t,...
    Stats.df,...
    Stats.p,...
    'VariableNames',{ ...
    'MeanCond1',...
    'MeanCond2',...
    'MeanDiff',...
    'SdDiff',...
    't',...
    'df',...
    'p'});
end