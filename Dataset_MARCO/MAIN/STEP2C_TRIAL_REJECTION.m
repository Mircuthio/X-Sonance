%% ========================================================================
% STEP2C_TRIAL_REJECTION
%
% Automatic trial rejection based on:
%   RMS percentile threshold
%   MaxAbs percentile threshold
%
% Input:
%   subj_list_epoched.mat
%
% Outputs:
%   subj_list.mat
%   subj_list_STEP2C.mat
%
% Saved variables:
%   subj_list                  in subj_list.mat
%   subj_list_clean            in subj_list_STEP2C.mat
%   badTrialsBySubject
%   RemovalTable
%   SummaryTable
%   CondSummary
%   thrRMS
%   thrMaxAbs
%% ========================================================================

clear
close all
clc

origState = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');

% addpath('C:\Users\mirco\Desktop\eeglab2026.1.0')
% eeglab nogui
%% =========================================================================
% SETTINGS
%% =========================================================================

PERCENTILE_THRESHOLD = 99.5;

inputFile  = 'subj_list_epoched.mat';
outputFile = 'subj_list_STEP2C.mat';

step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\';
%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================
outdir = ...
    fullfile(step2_indir, 'STEP2C_TRIAL_REJECTION');

if ~exist(outdir,'dir')
    mkdir(outdir);
end
%% =========================================================================
% LOAD
%% =========================================================================

load(inputFile,'subj_list')

assert(~isempty(subj_list), ...
    'subj_list is empty.')
%% =========================================================================
% GLOBAL THRESHOLDS
%% =========================================================================
subj_list_clean = subj_list;
totalTrials = 0;

for iSub = 1:numel(subj_list_clean)

    totalTrials = totalTrials + ...
        numel(subj_list_clean(iSub).data_trials);

end

AllRMS    = nan(totalTrials,1);
AllMaxAbs = nan(totalTrials,1);

idxGlobal = 0;

for iSub = 1:numel(subj_list_clean)

    trials = subj_list_clean(iSub).data_trials;

    for tr = 1:numel(trials)

        idxGlobal = idxGlobal + 1;

        X = double(trials(tr).eeg);

        AllRMS(idxGlobal) = ...
            rms(X(:),'omitnan');

        AllMaxAbs(idxGlobal) = ...
            max(abs(X(:)),[],'omitnan');

    end

end

thrRMS = prctile(AllRMS,PERCENTILE_THRESHOLD);

thrMaxAbs = prctile(AllMaxAbs,PERCENTILE_THRESHOLD);

fprintf('\n');
fprintf('====================================\n');
fprintf('GLOBAL THRESHOLDS\n');
fprintf('====================================\n');
fprintf('RMS percentile %.1f = %.3f\n', ...
    PERCENTILE_THRESHOLD,thrRMS);
fprintf('MaxAbs percentile %.1f = %.3f\n', ...
    PERCENTILE_THRESHOLD,thrMaxAbs);
fprintf('Trials above RMS threshold    : %d\n', ...
    sum(AllRMS > thrRMS));
fprintf('Trials above MaxAbs threshold : %d\n', ...
    sum(AllMaxAbs > thrMaxAbs));

fprintf('\n');
fprintf('Total trials    : %d\n',totalTrials);
fprintf('RMS outliers    : %d (%.2f%%)\n', ...
    sum(AllRMS > thrRMS), ...
    100*sum(AllRMS > thrRMS)/totalTrials);

fprintf('MaxAbs outliers : %d (%.2f%%)\n', ...
    sum(AllMaxAbs > thrMaxAbs), ...
    100*sum(AllMaxAbs > thrMaxAbs)/totalTrials);
fprintf('\n');

fprintf('====================================\n');
%% =========================================================================
% INITIALIZATION
%% =========================================================================

nSubjects = numel(subj_list_clean);

% Preallocazione RMS per grafici
trialRMS_all = cell(nSubjects,1);

% Salva gli indici dei trial rimossi per ogni soggetto
badTrialsBySubject = cell(nSubjects,1);

% Preallocazione summary
SummaryTable = table( ...
    strings(nSubjects,1), ...   % Subject
    zeros(nSubjects,1), ...     % NTrials
    zeros(nSubjects,1), ...     % NRemoved
    nan(nSubjects,1), ...       % PercRemoved
    nan(nSubjects,1), ...       % MeanRMS
    nan(nSubjects,1), ...       % MedianRMS
    nan(nSubjects,1), ...       % MaxRMS
    nan(nSubjects,1), ...       % MaxABS
    'VariableNames',{ ...
    'Subject',...
    'NTrials',...
    'NRemoved',...
    'PercRemoved',...
    'MeanRMS',...
    'MedianRMS',...
    'MaxRMS',...
    'MaxAbs'});

% Preallocazione RemovalTable.
% All'inizio non sappiamo il numero effettivo di trial rimossi.
% Usiamo quindi il massimo teorico possibile.

maxRemovedTrials = totalTrials;
RemovalTable = table( ...
    strings(maxRemovedTrials,1), ... % Subject
    zeros(maxRemovedTrials,1), ...   % Trial
    nan(maxRemovedTrials,1), ...     % RMS
    nan(maxRemovedTrials,1), ...     % MaxAbs
    strings(maxRemovedTrials,1), ... % Condition
    strings(maxRemovedTrials,1), ... % Reason
    'VariableNames',{ ...
    'Subject',...
    'Trial',...
    'RMS',...
    'MaxAbs',...
    'Condition',...
    'Reason'});

nRemovedTotal = 0;

fprintf('\n');
fprintf('====================================\n');
fprintf('RMS OUTLIER REMOVAL\n');
fprintf('RMS threshold    = %.3f\n',thrRMS);
fprintf('MaxAbs threshold = %.3f\n',thrMaxAbs);
fprintf('====================================\n');

%% =========================================================================
% SUBJECT LOOP
%% =========================================================================

for iSub = 1:nSubjects

    subjID = string(subj_list_clean(iSub).subj_id);

    fprintf('\n------------------------------------\n');
    fprintf('%s\n',subjID);
    fprintf('------------------------------------\n');

    trials = subj_list_clean(iSub).data_trials;
    nTrials = numel(trials);

    % Gestione del caso di soggetto senza trial
    if nTrials == 0

        subj_list_clean(iSub).data_trials = trials;

        SummaryTable.Subject(iSub)     = subjID;
        SummaryTable.NTrials(iSub)     = 0;
        SummaryTable.NRemoved(iSub)    = 0;
        SummaryTable.PercRemoved(iSub) = NaN;
        SummaryTable.MeanRMS(iSub)     = NaN;
        SummaryTable.MedianRMS(iSub)   = NaN;
        SummaryTable.MaxRMS(iSub)      = NaN;
        SummaryTable.MaxAbs(iSub)      = NaN;

        trialRMS_all{iSub} = [];

        fprintf('No trials found.\n');
        continue
    end

    % Preallocazione RMS del soggetto
    trialRMS    = nan(nTrials,1);
    trialMaxAbs = nan(nTrials,1);

    %% ---------------------------------------------------------------------
    % RMS COMPUTATION
    %% ---------------------------------------------------------------------

    for tr = 1:nTrials

        if ~isfield(trials(tr),'eeg')
            error('%s | Trial %d has no field "eeg".', ...
                subjID,tr);
        end

        X = double(trials(tr).eeg);

        % RMS globale del trial.
        % "omitnan" evita che pochi NaN rendano tutto il RMS NaN.
        trialRMS(tr) = rms(X(:),'omitnan');

        trialMaxAbs(tr) = ...
            max(abs(X(:)),[],'omitnan');

    end

    % Salva RMS per il grafico
    trialRMS_all{iSub} = trialRMS;

    %% ---------------------------------------------------------------------
    % FIND BAD TRIALS
    %% ---------------------------------------------------------------------

    isBad = ...
        trialRMS    > thrRMS ...
        |  trialMaxAbs > thrMaxAbs;

    badTrials = find(isBad);

    % Salva gli indici dei trial rimossi
    badTrialsBySubject{iSub} = badTrials;

    goodTrials = true(nTrials,1);
    goodTrials(badTrials) = false;

    %% ---------------------------------------------------------------------
    % SAVE REMOVAL INFO
    %% ---------------------------------------------------------------------

    nBad = numel(badTrials);

    if nBad > 0

        idx = nRemovedTotal + (1:nBad);

        RemovalTable.Subject(idx) = subjID;
        RemovalTable.Trial(idx)   = badTrials;
        RemovalTable.RMS(idx)     = trialRMS(badTrials);
        RemovalTable.MaxAbs(idx)  = trialMaxAbs(badTrials);

        conditionValues = strings(nBad,1);

        for k = 1:nBad

            tr = badTrials(k);

            if isfield(trials(tr),'eventLabel') && ...
                    ~isempty(trials(tr).eventLabel)

                conditionValues(k) = string(trials(tr).eventLabel);

            else
                conditionValues(k) = "Unknown";
            end
        end
        reasonValues = strings(nBad,1);

        for k = 1:nBad

            tr = badTrials(k);

            r1 = trialRMS(tr)    > thrRMS;
            r2 = trialMaxAbs(tr) > thrMaxAbs;

            if r1 && r2
                reasonValues(k) = "RMS+MAXABS";
            elseif r1
                reasonValues(k) = "RMS";
            elseif r2
                reasonValues(k) = "MAXABS";
            end

        end

        RemovalTable.Reason(idx) = reasonValues;
        RemovalTable.Condition(idx) = conditionValues;

        nRemovedTotal = nRemovedTotal + nBad;
    end

    %% ---------------------------------------------------------------------
    % BUILD CLEAN DATASET
    %% ---------------------------------------------------------------------

    subj_list_clean(iSub).data_trials = trials(goodTrials);

    %% ---------------------------------------------------------------------
    % SUMMARY
    %% ---------------------------------------------------------------------

    SummaryTable.Subject(iSub)     = subjID;
    SummaryTable.NTrials(iSub)     = nTrials;
    SummaryTable.NRemoved(iSub)    = nBad;
    SummaryTable.PercRemoved(iSub) = 100*nBad/nTrials;
    SummaryTable.MeanRMS(iSub)     = mean(trialRMS,'omitnan');
    SummaryTable.MedianRMS(iSub)   = median(trialRMS,'omitnan');
    SummaryTable.MaxRMS(iSub)      = max(trialRMS,[],'omitnan');
    SummaryTable.MaxAbs(iSub)      = max(trialMaxAbs,[],'omitnan');
    %% ---------------------------------------------------------------------
    % PRINT
    %% ---------------------------------------------------------------------

    fprintf('Original trials : %d\n',nTrials);
    fprintf('Removed trials  : %d\n',nBad);
    fprintf('Remaining       : %d\n',sum(goodTrials));
    fprintf('Mean RMS        : %.3f\n', ...
        mean(trialRMS,'omitnan'));

    fprintf('Median RMS      : %.3f\n', ...
        median(trialRMS,'omitnan'));

    fprintf('Max RMS         : %.3f\n', ...
        max(trialRMS,[],'omitnan'));

    fprintf('Max ABS         : %.3f\n', ...
        max(trialMaxAbs,[],'omitnan'));
    if nBad > 0

        fprintf('Removed trial indices:\n');

        disp(badTrials(:)')

    end
end

%% =========================================================================
% TRIM REMOVAL TABLE
%% =========================================================================

RemovalTable = RemovalTable(1:nRemovedTotal,:);

%% =========================================================================
% DISPLAY SUMMARY
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('SUMMARY\n');
fprintf('====================================\n');

SummaryTable.RMSThreshold = ...
    repmat(thrRMS,height(SummaryTable),1);

SummaryTable.MaxAbsThreshold = ...
    repmat(thrMaxAbs,height(SummaryTable),1);

disp(SummaryTable)
%% =========================================================================
% CONDITION COUNTS
%% =========================================================================

if ~isempty(RemovalTable)

    fprintf('\n');
    fprintf('====================================\n');
    fprintf('REMOVED TRIALS BY CONDITION\n');
    fprintf('====================================\n');

    CondSummary = groupsummary( ...
        RemovalTable,...
        {'Subject','Condition'});

    disp(CondSummary)
    for iSub = 1:nSubjects

        if ~isempty(badTrialsBySubject{iSub})

            fprintf('\n%s\n', ...
                SummaryTable.Subject(iSub));

            fprintf('Removed trials:\n');

            disp(badTrialsBySubject{iSub}(:)')

        end

    end
else

    CondSummary = table();
end

%% =========================================================================
% SAVE MAT
%% =========================================================================

subj_list = subj_list_clean;
save( fullfile(step2_indir,...
    'subj_list.mat'), ...
    'subj_list', ...
    '-v7.3');

save( fullfile(outdir,outputFile), ...
    'subj_list_clean', ...
    'badTrialsBySubject', ...
    'thrRMS', ...
    'thrMaxAbs', ...
    'RemovalTable', ...
    'SummaryTable', ...
    'CondSummary', ...
    '-v7.3');

save(fullfile(outdir,...
    'STEP2C_THRESHOLDS.mat'), ...
    'thrRMS', ...
    'thrMaxAbs', ...
    'PERCENTILE_THRESHOLD');
%% =========================================================================
% SAVE XLS
%% =========================================================================

writetable( ...
    SummaryTable,...
    fullfile(outdir,...
    'STEP2C_SubjectSummary.xls'));

if ~isempty(RemovalTable)

    writetable( ...
        RemovalTable,...
        fullfile(outdir,...
        'STEP2C_RemovedTrials.xls'));

    writetable( ...
        CondSummary,...
        fullfile(outdir,...
        'STEP2C_RemovedTrials_ByCondition.xls'));

end

%% =========================================================================
% RMS DISTRIBUTIONS
%% =========================================================================

fig = figure( ...
    'Color','w',...
    'Position',[100 100 1400 700]);

for iSub = 1:nSubjects

    trialRMS = trialRMS_all{iSub};
    nTrials = numel(trialRMS);

    subplot(nSubjects,1,iSub)

    if nTrials > 0

        stem(1:nTrials,trialRMS,'.')
        hold on

        if ~isempty(badTrialsBySubject{iSub})

            plot( ...
                badTrialsBySubject{iSub}, ...
                trialRMS(badTrialsBySubject{iSub}), ...
                'ro', ...
                'MarkerSize',6, ...
                'LineWidth',1.5);

        end

        yline( ...
            thrRMS,...
            'r--',...
            'LineWidth',1.5)

        legend( ...
            'RMS',...
            'Removed',...
            'Threshold',...
            'Location','best')

        xlim([1 nTrials])

    else

        text(0.5,0.5,'No trials', ...
            'HorizontalAlignment','center')

        xlim([0 1])
    end

    title(char(string(subj_list_clean(iSub).subj_id)))
    ylabel('RMS')
end

xlabel('Trial')

saveas(fig,...
    fullfile(outdir,...
    'STEP2C_TrialDistributions.png'))
close(fig)
%% =========================================================================
% BARPLOT SUMMARY
%% =========================================================================

fig = figure( ...
    'Color','w', ...
    'Position',[100 100 1000 500]);

subplot(1,2,1)

bar(SummaryTable.MaxRMS)

xticks(1:nSubjects)
xticklabels(SummaryTable.Subject)

ylabel('Max RMS')

title('Maximum RMS per Subject')

grid on

subplot(1,2,2)

bar(SummaryTable.NRemoved)

xticks(1:nSubjects)
xticklabels(SummaryTable.Subject)

ylabel('Removed Trials')

title('Removed Trials per Subject')

grid on

saveas(fig,...
    fullfile(outdir,...
    'STEP2C_SubjectComparison.png'))

close(fig)
%% =========================================================================
% DONE
%% =========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('RMS CLEANING COMPLETED\n');
fprintf('====================================\n');
fprintf('Saved:\n');
fprintf('  %s\n',outputFile);
fprintf('  STEP2C_SubjectSummary.xls\n');

if ~isempty(RemovalTable)
    fprintf('  STEP2C_RemovedTrials.xls\n');
    fprintf('  STEP2C_RemovedTrials_ByCondition.xls\n');
end

fprintf('  STEP2C_TrialDistributions.png\n');
fprintf('====================================\n');

set(0, 'DefaultFigureVisible', origState);