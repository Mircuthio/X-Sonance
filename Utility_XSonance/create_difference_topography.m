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
% Example:
%
%   Dissonant - Consonant
%
% Output is averaged across subjects.
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

    % --------------------------------------------------------
    % ERP condition A
    % --------------------------------------------------------

    eegA = cat(3,dt(idxA).eeg);

    erpA = mean( ...
        eegA,...
        3,...
        'omitnan');

    % --------------------------------------------------------
    % ERP condition B
    % --------------------------------------------------------

    eegB = cat(3,dt(idxB).eeg);

    erpB = mean( ...
        eegB,...
        3,...
        'omitnan');

    % --------------------------------------------------------
    % Difference ERP
    % --------------------------------------------------------

    diffERP = erpB - erpA;

    % --------------------------------------------------------
    % Time window
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

            error('Unknown measure: %s',cfg.measure);

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