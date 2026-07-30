function results = main_park(data_trials, opts)
% MAIN_PARK_PIPELINE
% Processing pipeline inspired by Park et al. (2011) for induced gamma.
%
% INPUT
%   data_trials : 1xN struct array, one struct per trial.
%       Expected fields per trial:
%         - eeg    : [nChannels x nTime] double
%         - label  : string/char/numeric condition label ('consonant','dissonant', etc.)
%       Optional fields:
%         - bad    : logical flag for pre-marked bad trials
%         - rt/other metadata ignored here
%
%   opts : struct with optional fields
%       .time_ms            = -500:1500 in ms (vector length must match eeg time dim)
%       .fs                 = 1000
%       .baseline_ms        = [-200 -50]
%       .analysis_ms        = [100 250]
%       .freqs              = 30:1:60
%       .waveletWidth       = 7
%       .artifact_uV        = 70
%       .labels             = cellstr of channel labels
%       .roi                = struct with fields anterior,left,right,posterior
%       .condition_map      = struct or containers.Map for mapping labels
%       .consonant_labels   = {'consonant','cons','major','minor',1}
%       .dissonant_labels   = {'dissonant','diss','augmented','diminished',2}
%       .do_plot            = true
%
% OUTPUT
%   results : struct containing trial power, ROI summaries, stats, and figures data
%
% NOTE
%   This reproduces the logical processing steps reported in Park et al.:
%   1) artifact rejection
%   2) time-frequency decomposition with Morlet wavelets
%   3) single-trial power computation |W*x|^2
%   4) baseline correction
%   5) ROI averaging
%   6) repeated-measures statistics + post hoc paired t-tests

if nargin < 2, opts = struct; end
opts = set_defaults(opts, data_trials);

nTrials = numel(data_trials);
assert(nTrials > 0, 'data_trials is empty');

sample = data_trials(1).eeg;
[nCh, nT] = size(sample);
assert(numel(opts.time_ms) == nT, 'opts.time_ms length must match eeg time dimension');

% Indices
baseIdx = opts.time_ms >= opts.baseline_ms(1) & opts.time_ms <= opts.baseline_ms(2);
anaIdx  = opts.time_ms >= opts.analysis_ms(1) & opts.time_ms <= opts.analysis_ms(2);

% ROI channel indices
roiIdx = resolve_rois(opts.labels, opts.roi);

% Condition assignment + artifact rejection
isBad = false(1, nTrials);
cond  = strings(1, nTrials);
for tr = 1:nTrials
    x = double(data_trials(tr).eeg);
    if isfield(data_trials(tr), 'bad') && logical(data_trials(tr).bad)
        isBad(tr) = true;
    end
    if any(abs(x(:)) > opts.artifact_uV)
        isBad(tr) = true;
    end
    cond(tr) = normalize_condition(data_trials(tr).label, opts);
end

keep = ~isBad & (cond == "consonant" | cond == "dissonant");
assert(any(keep), 'No valid trials left after rejection/condition filtering');

validTrials = find(keep);
cond = cond(keep);
nValid = numel(validTrials);

% Time-frequency power per trial/channel/frequency/time
freqs = opts.freqs;
nF = numel(freqs);
power4d = nan(nValid, nCh, nF, nT, 'single');

for ii = 1:nValid
    tr = validTrials(ii);
    x = double(data_trials(tr).eeg);
    for ch = 1:nCh
        sig = x(ch,:);
        for fi = 1:nF
            f = freqs(fi);
            w = morlet_wavelet(f, opts.fs, opts.waveletWidth);
            convRes = conv(sig, w, 'same');
            p = abs(convRes).^2; % induced power
            b = mean(p(baseIdx), 'omitnan');
            if b <= 0 || isnan(b)
                pCorr = p;
            else
                pCorr = 10*log10(p ./ b); % dB baseline correction
            end
            power4d(ii,ch,fi,:) = single(pCorr);
        end
    end
end

% Average across gamma frequencies 30-60 Hz
power_ch_time = squeeze(mean(power4d, 3, 'omitnan')); % [trial x ch x time]

% Per-trial ROI summary in analysis window
roiNames = fieldnames(roiIdx);
nRoi = numel(roiNames);
roi_trial_values = nan(nValid, nRoi);
for r = 1:nRoi
    idx = roiIdx.(roiNames{r});
    roi_trial_values(:,r) = squeeze(mean(mean(power_ch_time(:,idx,anaIdx), 3, 'omitnan'), 2, 'omitnan'));
end

% Subject-level means are not available if input is only trials. So here we do two options:
% 1) if subject_id exists, aggregate within subject and condition
% 2) otherwise warn and use trial-level summaries (not identical to paper)
hasSubj = isfield(data_trials, 'subject_id');
if hasSubj
    subj_all = strings(1, nTrials);
    for tr = 1:nTrials
        subj_all(tr) = string(data_trials(tr).subject_id);
    end
    subj = subj_all(keep);
    subjects = unique(subj);
    nS = numel(subjects);
    Y = nan(nS, 2, nRoi);
    for s = 1:nS
        for c = 1:2
            cname = ["consonant","dissonant"];
            sel = subj == subjects(s) & cond == cname(c);
            for r = 1:nRoi
                Y(s,c,r) = mean(roi_trial_values(sel,r), 'omitnan');
            end
        end
    end
    stats = rm_stats(Y, roiNames);
else
    warning('No subject_id field found. Statistics will be trial-level and not equivalent to repeated-measures by subject.');
    stats = struct();
    stats.note = 'No subject_id available; provide data_trials(tr).subject_id for subject-level repeated-measures analysis.';
    for r = 1:nRoi
        c1 = roi_trial_values(cond=="consonant",r);
        c2 = roi_trial_values(cond=="dissonant",r);
        [~,p,~,st] = ttest2(c1,c2);
        stats.posthoc_triallevel.(roiNames{r}).tstat = st.tstat;
        stats.posthoc_triallevel.(roiNames{r}).p = p;
        stats.posthoc_triallevel.(roiNames{r}).mean_consonant = mean(c1,'omitnan');
        stats.posthoc_triallevel.(roiNames{r}).mean_dissonant = mean(c2,'omitnan');
    end
end

% Grand averages for plotting
consIdx = cond == "consonant";
dissIdx = cond == "dissonant";
results.time_ms = opts.time_ms;
results.freqs = freqs;
results.keep_trials = validTrials;
results.conditions = cond;
results.power4d = power4d;
results.power_ch_time = power_ch_time;
results.roi_trial_values = roi_trial_values;
results.roi_names = roiNames;
results.roi_idx = roiIdx;
results.stats = stats;
results.mean_gamma_time.consonant = squeeze(mean(mean(power4d(consIdx,:,:,:),2,'omitnan'),1,'omitnan')); % [freq x time]
results.mean_gamma_time.dissonant = squeeze(mean(mean(power4d(dissIdx,:,:,:),2,'omitnan'),1,'omitnan')); % [freq x time]
results.mean_ch_time.consonant = squeeze(mean(power_ch_time(consIdx,:,:),1,'omitnan')); % [ch x time]
results.mean_ch_time.dissonant = squeeze(mean(power_ch_time(dissIdx,:,:),1,'omitnan')); % [ch x time]

if opts.do_plot
    make_plots(results, opts);
end

end

function opts = set_defaults(opts, data_trials)
if ~isfield(opts,'fs'), opts.fs = 1000; end
if ~isfield(opts,'time_ms'), opts.time_ms = -500:1500; end
if ~isfield(opts,'baseline_ms'), opts.baseline_ms = [-200 -50]; end
if ~isfield(opts,'analysis_ms'), opts.analysis_ms = [100 250]; end
if ~isfield(opts,'freqs'), opts.freqs = 30:1:60; end
if ~isfield(opts,'waveletWidth'), opts.waveletWidth = 7; end
if ~isfield(opts,'artifact_uV'), opts.artifact_uV = 70; end
if ~isfield(opts,'do_plot'), opts.do_plot = true; end
if ~isfield(opts,'consonant_labels'), opts.consonant_labels = {'consonant','cons','major','minor',1}; end
if ~isfield(opts,'dissonant_labels'), opts.dissonant_labels = {'dissonant','diss','augmented','diminished',2}; end
if ~isfield(opts,'labels')
    if isfield(data_trials(1),'labels')
        opts.labels = data_trials(1).labels;
    else
        opts.labels = arrayfun(@(k) sprintf('Ch%d',k), 1:size(data_trials(1).eeg,1), 'uni', 0);
    end
end
if ~isfield(opts,'roi')
    opts.roi.anterior  = {'AFz','Fz','F3','F4'};
    opts.roi.left      = {'F7','C3','T3','T7','P3','T5','P7'};
    opts.roi.right     = {'F8','C4','T4','T8','P4','T6','P8'};
    opts.roi.posterior = {'Pz','Oz','O1','O2'};
end
end

function c = normalize_condition(lbl, opts)
if isstring(lbl) || ischar(lbl)
    s = lower(string(lbl));
else
    s = string(lbl);
end
if any(strcmpi(cellfun(@stringify, opts.consonant_labels, 'uni', 0), stringify(s)))
    c = "consonant";
elseif any(strcmpi(cellfun(@stringify, opts.dissonant_labels, 'uni', 0), stringify(s)))
    c = "dissonant";
else
    c = "other";
end
end

function s = stringify(x)
s = char(string(x));
end

function roiIdx = resolve_rois(labels, roi)
labels = cellfun(@(x) upper(string(x)), labels, 'uni', 0);
roiNames = fieldnames(roi);
for i = 1:numel(roiNames)
    want = upper(string(roi.(roiNames{i})));
    idx = [];
    for j = 1:numel(want)
        m = find(strcmp(labels, want(j)), 1);
        if ~isempty(m), idx(end+1) = m; end %#ok<AGROW>
    end
    if isempty(idx)
        warning('No channels found for ROI %s', roiNames{i});
    end
    roiIdx.(roiNames{i}) = unique(idx);
end
end

function w = morlet_wavelet(f, fs, width)
% Complex Morlet with approximately constant ratio f/sigma_f = width
sigma_t = width / (2*pi*f);
t = -3.5*sigma_t : 1/fs : 3.5*sigma_t;
A = 1 / sqrt(sigma_t * sqrt(pi));
w = A .* exp(1i*2*pi*f.*t) .* exp(-(t.^2) ./ (2*sigma_t^2));
end

function stats = rm_stats(Y, roiNames)
% Y: subjects x 2 conditions x nROI
[nS,~,nR] = size(Y);
stats = struct();
stats.subjects = nS;

% Main effect stimulus across ROI-averaged values
cons = squeeze(mean(Y(:,1,:),3,'omitnan'));
diss = squeeze(mean(Y(:,2,:),3,'omitnan'));
[~,pStim,~,stStim] = ttest(cons, diss);
stats.main_effect_stimulus.tstat = stStim.tstat;
stats.main_effect_stimulus.p = pStim;
stats.main_effect_stimulus.mean_consonant = mean(cons,'omitnan');
stats.main_effect_stimulus.mean_dissonant = mean(diss,'omitnan');

% Main effect ROI via one-way repeated measure on condition-averaged ROI values
roiAvg = squeeze(mean(Y,2,'omitnan')); % subjects x roi
stats.main_effect_roi.note = 'Use fitrm/ranova if available for formal repeated-measures ROI effect.';
stats.main_effect_roi.mean_by_roi = mean(roiAvg,1,'omitnan');

% Interaction proxy: paired test by ROI + Bonferroni
alpha = 0.05 / nR;
for r = 1:nR
    [~,p,~,st] = ttest(Y(:,1,r), Y(:,2,r));
    stats.posthoc.(roiNames{r}).tstat = st.tstat;
    stats.posthoc.(roiNames{r}).p = p;
    stats.posthoc.(roiNames{r}).p_bonf = min(p*nR,1);
    stats.posthoc.(roiNames{r}).sig_bonf = p < alpha;
    stats.posthoc.(roiNames{r}).mean_consonant = mean(Y(:,1,r),'omitnan');
    stats.posthoc.(roiNames{r}).mean_dissonant = mean(Y(:,2,r),'omitnan');
end
end

function make_plots(results, ~)
figure('Name','Park pipeline results','Color','w','Position',[100 100 1300 800]);

subplot(2,3,1)
imagesc(results.time_ms, results.freqs, results.mean_gamma_time.consonant);
axis xy; xlabel('ms'); ylabel('Hz'); title('Consonant TF'); colorbar;

subplot(2,3,2)
imagesc(results.time_ms, results.freqs, results.mean_gamma_time.dissonant);
axis xy; xlabel('ms'); ylabel('Hz'); title('Dissonant TF'); colorbar;

subplot(2,3,3)
consLine = squeeze(mean(results.mean_gamma_time.consonant,1,'omitnan'));
dissLine = squeeze(mean(results.mean_gamma_time.dissonant,1,'omitnan'));
plot(results.time_ms, consLine, 'r', 'LineWidth', 1.5); hold on;
plot(results.time_ms, dissLine, 'b', 'LineWidth', 1.5);
xlabel('ms'); ylabel('Power (dB)'); title('Gamma time course 30-60 Hz'); legend({'Consonant','Dissonant'});

subplot(2,3,4)
barData = nan(numel(results.roi_names),2);
for r = 1:numel(results.roi_names)
    rn = results.roi_names{r};
    if isfield(results.stats,'posthoc') && isfield(results.stats.posthoc,rn)
        barData(r,1) = results.stats.posthoc.(rn).mean_consonant;
        barData(r,2) = results.stats.posthoc.(rn).mean_dissonant;
    elseif isfield(results.stats,'posthoc_triallevel')
        barData(r,1) = results.stats.posthoc_triallevel.(rn).mean_consonant;
        barData(r,2) = results.stats.posthoc_triallevel.(rn).mean_dissonant;
    end
end
bar(barData); set(gca,'XTickLabel',results.roi_names); legend({'Consonant','Dissonant'}); title('ROI means 100-250 ms');

a = annotation('textbox',[0.64 0.08 0.3 0.15],'String',summary_text(results),'FitBoxToText','on');
a.BackgroundColor = 'white';
a.EdgeColor = [0.7 0.7 0.7];
end

function txt = summary_text(results)
if isfield(results.stats,'main_effect_stimulus')
    p = results.stats.main_effect_stimulus.p;
    txt = sprintf('Main stimulus effect p = %.4g', p);
else
    txt = 'Subject-level repeated measures not available';
end
end
