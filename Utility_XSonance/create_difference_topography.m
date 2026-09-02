function ERPTopo = create_difference_topography(subj_list,cfg)

% ============================================================
% CREATE_DIFFERENCE_TOPOGRAPHY
%
% Computes channel-wise difference topography
%
% Difference:
%
%   Condition2 - Condition1
%
% Output is averaged across subjects.
%
% Processing:
%
%   1) Analysis window selection
%   2) Baseline correction
%   3) ERP computation
%   4) Difference ERP
%   5) Topography extraction
%
% ============================================================

if ~isfield(cfg,'measure')
    cfg.measure = 'mean';
end

assert(numel(cfg.conditions)==2,...
    'Exactly two conditions required');

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

    idxA = strcmpi( ...
        condValues,...
        string(cfg.conditions{1}));

    idxB = strcmpi( ...
        condValues,...
        string(cfg.conditions{2}));

    if ~any(idxA) || ~any(idxB)

        warning('Missing condition in %s',...
            subj_list(iSub).subj_id);

        continue

    end

    ERPcond = cell(1,2);

    for cc = 1:2

        if cc == 1
            idxCond = idxA;
        else
            idxCond = idxB;
        end

        nTrials = sum(idxCond);

        eegTrials = nan( ...
            nChan,...
            numel(time0),...
            nTrials);

        kk = 0;

        for iT = find(idxCond)

            kk = kk + 1;

            eeg = double(dt(iT).eeg);

            t = double(dt(iT).(cfg.time_field));

            % ----------------------------------------
            % Analysis window
            % ----------------------------------------

            if isfield(cfg,'analysis_win') && ...
                    ~isempty(cfg.analysis_win)

                sel = ...
                    t >= cfg.analysis_win(1) & ...
                    t <= cfg.analysis_win(2);

                eeg = eeg(:,sel);

                t = t(sel);

            end

            % ----------------------------------------
            % Baseline correction
            % ----------------------------------------

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

            eegTrials(:,:,kk) = eeg;

        end

        ERPcond{cc} = ...
            mean(eegTrials,3,'omitnan');

    end

    % --------------------------------------------------------
    % Difference ERP
    % --------------------------------------------------------

    diffERP = ERPcond{2} - ERPcond{1};

    % --------------------------------------------------------
    % Topography window
    % --------------------------------------------------------

    tsel = ...
        time0 >= cfg.window(1) & ...
        time0 <= cfg.window(2);

    switch lower(cfg.measure)

        case 'mean'

            subjTopo(iSub,:) = ...
                mean(diffERP(:,tsel),...
                2,...
                'omitnan');

        case 'min'

            subjTopo(iSub,:) = ...
                min(diffERP(:,tsel),[],2);

        case 'max'

            subjTopo(iSub,:) = ...
                max(diffERP(:,tsel),[],2);

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
    mean(subjTopo,1,'omitnan');

groupSEM = ...
    std(subjTopo,0,1,'omitnan') ./ ...
    sqrt(nSubj);

% ------------------------------------------------------------
% Output
% ------------------------------------------------------------

ERPTopo = struct();

ERPTopo.values = groupTopo;

ERPTopo.sem = groupSEM;

ERPTopo.subject_values = subjTopo;

ERPTopo.window = cfg.window;

ERPTopo.conditions = cfg.conditions;

ERPTopo.chanlocs = chanlocs;

ERPTopo.nSubjects = nSubj;

ERPTopo.cfg = cfg;

end