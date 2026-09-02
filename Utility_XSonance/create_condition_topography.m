function ERPTopo = create_condition_topography( ...
    subj_list,...
    cfg,...
    conditionName)

% ============================================================
% CREATE_CONDITION_TOPOGRAPHY
%
% Computes condition-specific ERP topography
%
% Output is averaged across subjects.
%
% ============================================================

if ~isfield(cfg,'measure')
    cfg.measure = 'mean';
end

assert(isfield(cfg,'cond_field'),...
    'cfg.cond_field missing');

assert(isfield(cfg,'time_field'),...
    'cfg.time_field missing');

assert(isfield(cfg,'window'),...
    'cfg.window missing');

nSubj = numel(subj_list);

trial0 = subj_list(1).data_trials(1);

chanlocs = trial0.chanlocs;

time0 = double(trial0.(cfg.time_field));

if isfield(cfg,'analysis_win') && ...
        ~isempty(cfg.analysis_win)

    keep = ...
        time0 >= cfg.analysis_win(1) & ...
        time0 <= cfg.analysis_win(2);

    time0 = time0(keep);

end

nChan = size(trial0.eeg,1);

subjTopo = nan(nSubj,nChan);

for iSub = 1:nSubj

    dt = subj_list(iSub).data_trials;

    condValues = string({dt.(cfg.cond_field)});

    idxCond = strcmpi( ...
        condValues,...
        string(conditionName));

    if ~any(idxCond)

        warning( ...
            'Missing condition %s in %s',...
            conditionName,...
            string(subj_list(iSub).subj_id));

        continue

    end

    nTrials = sum(idxCond);

    eegCond = nan( ...
        nChan,...
        numel(time0),...
        nTrials);

    kk = 0;

    for iT = find(idxCond)

        kk = kk + 1;

        eeg = double(dt(iT).eeg);

        t = double(dt(iT).(cfg.time_field));

        % --------------------------------------------
        % Analysis window
        % --------------------------------------------

        if isfield(cfg,'analysis_win') && ...
                ~isempty(cfg.analysis_win)

            sel = ...
                t >= cfg.analysis_win(1) & ...
                t <= cfg.analysis_win(2);

            eeg = eeg(:,sel);
            t   = t(sel);

        end

        % --------------------------------------------
        % Baseline correction
        % --------------------------------------------

        if isfield(cfg,'baseline_win') && ...
                ~isempty(cfg.baseline_win)

            bsel = ...
                t >= cfg.baseline_win(1) & ...
                t <= cfg.baseline_win(2);

            if any(bsel)

                base = ...
                    mean(eeg(:,bsel),...
                    2,...
                    'omitnan');

                eeg = eeg - base;

            end

        end

        eegCond(:,:,kk) = eeg;

    end

    erpCond = mean( ...
        eegCond,...
        3,...
        'omitnan');

    % --------------------------------------------
    % Topography window
    % --------------------------------------------

    tsel = ...
        time0 >= cfg.window(1) & ...
        time0 <= cfg.window(2);

    switch lower(cfg.measure)

        case 'mean'

            subjTopo(iSub,:) = ...
                mean( ...
                erpCond(:,tsel),...
                2,...
                'omitnan');

        case 'min'

            subjTopo(iSub,:) = ...
                min( ...
                erpCond(:,tsel),...
                [],...
                2);

        case 'max'

            subjTopo(iSub,:) = ...
                max( ...
                erpCond(:,tsel),...
                [],...
                2);

        otherwise

            error( ...
                'Unknown measure: %s',...
                cfg.measure);

    end

end

% ------------------------------------------------------------
% Group topography
% ------------------------------------------------------------

groupTopo = ...
    mean( ...
    subjTopo,...
    1,...
    'omitnan');

groupSEM = ...
    std( ...
    subjTopo,...
    0,...
    1,...
    'omitnan') ./ sqrt(nSubj);

% ------------------------------------------------------------
% Output
% ------------------------------------------------------------

ERPTopo = struct();

ERPTopo.values = groupTopo;

ERPTopo.sem = groupSEM;

ERPTopo.subject_values = subjTopo;

ERPTopo.window = cfg.window;

ERPTopo.condition = conditionName;

ERPTopo.chanlocs = chanlocs;

ERPTopo.nSubjects = nSubj;

ERPTopo.cfg = cfg;

end