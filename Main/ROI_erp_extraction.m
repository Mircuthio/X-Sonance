function ERP = ROI_erp_extraction(subj_list, cfg)
% ROI_erp_extraction


assert(~isempty(subj_list), 'subj_list vuoto');

if ~isfield(cfg, 'conditions'),   cfg.conditions = {'standard','deviant'}; end
if ~isfield(cfg, 'cond_field'),   cfg.cond_field = 'trialName'; end
if ~isfield(cfg, 'roi_labels'),   cfg.roi_labels = {}; end
if ~isfield(cfg, 'time_field'),   cfg.time_field = 'time'; end
if ~isfield(cfg, 'baseline_win'), cfg.baseline_win = []; end
if ~isfield(cfg, 'analysis_win'), cfg.analysis_win = []; end
if ~isfield(cfg, 'subject_ids'),  cfg.subject_ids = {}; end
if ~isfield(cfg, 'target_time_units'),   cfg.target_time_units = 'ms'; end

keep = true(numel(subj_list),1);
if ~isempty(cfg.subject_ids)
    ids_all  = string({subj_list.subj_id});
    ids_want = string(cfg.subject_ids);
    keep = ismember(ids_all, ids_want);
end

subj_list = subj_list(keep);
assert(~isempty(subj_list), 'Nessun soggetto selezionato');

nSubj = numel(subj_list);
nCond = numel(cfg.conditions);

firstTrials = subj_list(1).data_trials;
assert(~isempty(firstTrials), 'Primo soggetto senza data_trials');

time0 = double(firstTrials(1).(cfg.time_field)(:).');
fprintf('Time range: %.1f -> %.1f %s\n', ...
    min(time0), max(time0), cfg.target_time_units);
switch lower(cfg.target_time_units)

    case 'ms'
        time0 = time0 * 1000;

    case 's'

    otherwise
        error('Unrecognized time units');

end
if ~isempty(cfg.analysis_win)
    tsel0 = time0 >= cfg.analysis_win(1) & time0 <= cfg.analysis_win(2);
    time_erp = time0(tsel0);
else
    tsel0 = true(size(time0));
    time_erp = time0;
end
nTime = numel(time_erp);

% -------------------------
% CANALI / ROI
% -------------------------
trial0 = firstTrials(1);
chan_labels = {};

if isfield(trial0, 'chanlocs') && ~isempty(trial0.chanlocs)
    chan_labels = {trial0.chanlocs.labels};

elseif isfield(trial0, 'chanLabels') && ~isempty(trial0.chanLabels)
    chan_labels = trial0.chanLabels;

elseif isfield(trial0, 'chanlabels') && ~isempty(trial0.chanlabels)
    chan_labels = trial0.chanlabels;

elseif isfield(trial0, 'labels') && ~isempty(trial0.labels)
    chan_labels = trial0.labels;

elseif isfield(trial0, 'label') && ~isempty(trial0.label)
    chan_labels = trial0.label;
end

assert(~isempty(chan_labels), 'Nessuna informazione canali trovata nel trial');

chan_labels = cellstr(string(chan_labels));
roi_labels  = cellstr(string(cfg.roi_labels));

if ~isempty(cfg.roi_labels)
    chanROI = find(ismember(lower(chan_labels), lower(roi_labels)));
else
    chanROI = 1:numel(chan_labels);
end

if isempty(chanROI)
    warning('ROI non trovata');
    ERP = [];
    return
end

% -------------------------
% PREALLOCAZIONE
% -------------------------
subject_erp  = nan(nSubj, nCond, nTime);
nTrials_cond = nan(nSubj, nCond);
trial_se = nan(nSubj,nCond,nTime);
cond_trials = cell(nSubj,nCond);
TrialinfoMat = struct();
% -------------------------
% LOOP SOGGETTI
% -------------------------
for iS = 1:nSubj
    dt = subj_list(iS).data_trials;
    assert(~isempty(dt), 'data_trials vuoto per un soggetto');

    cond_values = string({dt.(cfg.cond_field)});

    for c = 1:nCond
        cond_target = string(cfg.conditions{c});
        idx = find(strcmpi(cond_values, cond_target));

        if isempty(idx)
            continue
        end

        trial_mat = nan(numel(idx), nTime);

        for k = 1:numel(idx)
            tr = dt(idx(k));

            eeg = double(tr.eeg);
            t   = double(tr.(cfg.time_field)(:).');
            switch lower(cfg.target_time_units)

                case 'ms'
                    t = t * 1000;
                case 's'

                otherwise
                    error('Unita'' temporali non riconosciute');

            end
            if ~isempty(cfg.analysis_win)
                sel = t >= cfg.analysis_win(1) & t <= cfg.analysis_win(2);
                eeg = eeg(:, sel);
                t   = t(sel);
            end

            if ~isempty(cfg.baseline_win)
                bsel = t >= cfg.baseline_win(1) & t <= cfg.baseline_win(2);
                if any(bsel)
                    base = mean(eeg(:, bsel), 2, 'omitnan');
                    eeg  = eeg - base;
                end
            end

            trial_mat(k,:) = mean(eeg(chanROI,:), 1, 'omitnan');
        end

        subject_erp(iS,c,:) = mean(trial_mat,1,'omitnan');
        trial_se(iS,c,:) = std(trial_mat,0,1,'omitnan') ./ sqrt(size(trial_mat,1));
        nTrials_cond(iS,c) = sum(~all(isnan(trial_mat),2));
        cond_trials{iS,c} = trial_mat;
        TrialinfoMat.trial_info{iS,c}.subject = subj_list(iS).subj_id;
        TrialinfoMat.trial_info{iS,c}.condition = cfg.conditions{c};
        TrialinfoMat.trial_info{iS,c}.nTrials = size(trial_mat,1);
    end
end

% -------------------------
% GRAND AVERAGE
% -------------------------
grand_avg = squeeze(mean(subject_erp, 1, 'omitnan'));
if nSubj == 1
    grand_se = squeeze(trial_se);
else
    grand_se = ...
        squeeze(std(subject_erp,0,1,'omitnan')) ./ sqrt(nSubj);
end
% -------------------------
% OUTPUT
% -------------------------
ERP = struct();
ERP.data        = subject_erp;
ERP.time_erp    = time_erp;
ERP.subject_erp = subject_erp;
ERP.grand_avg   = grand_avg;
ERP.grand_se    = grand_se;
ERP.conditions  = cfg.conditions;
ERP.subjects    = {subj_list.subj_id};
ERP.roi_labels  = cfg.roi_labels;
ERP.chanROI     = chanROI;
ERP.chan_labels = chan_labels;
ERP.nTrials_cond = nTrials_cond;
ERP.cfg         = cfg;
ERP.cond_trials = cond_trials;
ERP.trialinfo = TrialinfoMat;
ERP.stats = struct();
ERP.stats.nSubjects   = nSubj;
ERP.stats.nConditions = nCond;
ERP.stats.nTime       = nTime;
ERP.roiName = '';
for c = 1:nCond
    condName = matlab.lang.makeValidName(cfg.conditions{c});
    ERP.(condName) = reshape(squeeze(subject_erp(:, c, :)), 1, []);
    ERP.([condName '_mean']) = reshape(squeeze(mean(subject_erp(:, c, :), 1, 'omitnan')), 1, []);
    if nSubj == 1
        ERP.([condName '_se']) = reshape(squeeze(trial_se(:,c,:)), 1, []);
    else
        ERP.([condName '_se']) = reshape(squeeze(std(subject_erp(:,c,:),0,1,'omitnan'))./ sqrt(nSubj),1, []);
    end
end
end