%% ========================================================================
% STEP2C_CHECK_CLEANING
%
% Compare original vs clean datasets
%
% Input:
%   subj_list_epoched.mat
%   subj_list_clean_STEP2C.mat
%
% Output:
%   Validation figures
%% ========================================================================

clear
close all
clc

origState = get(0, 'DefaultFigureVisible');
set(0, 'DefaultFigureVisible', 'off');

%% ========================================================================
% PATHS
%% ========================================================================

projectRoot = ...
'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

origFile = fullfile( ...
    projectRoot,...
    'subj_list_epoched.mat');

cleanFile = fullfile( ...
    projectRoot,...
    'STEP2C_TRIAL_REJECTION',...
    'subj_list_STEP2C.mat');

outdir = fullfile( ...
    projectRoot,...
    'STEP2C_TRIAL_REJECTION',...
    'CHECK_CLEANING');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ========================================================================
% LOAD
%% ========================================================================

load(origFile,'subj_list');

subj_list_original = subj_list;

load(cleanFile, ...
    'subj_list_clean', ...
    'SummaryTable', ...
    'RemovalTable', ...
    'badTrialsBySubject');

%% ========================================================================
% SUMMARY REPORT
%% ========================================================================

disp(SummaryTable)

%% ========================================================================
% ERP COMPARISON
%% ========================================================================
ValidationTable = table( ...
    strings(nSubjects,1), ...
    nan(nSubjects,1), ...
    'VariableNames',{ ...
    'Subject',...
    'ERP_Correlation'});

nSubjects = numel(subj_list_original);

for iSub = 1:nSubjects

    subjID = ...
        char(subj_list_original(iSub).subj_id);

    fprintf('\n%s\n',subjID);

    trialsOrig  = ...
        subj_list_original(iSub).data_trials;

    trialsClean = ...
        subj_list_clean(iSub).data_trials;

    %% --------------------------------------------------------
    % Build ERP ORIGINAL
    %% --------------------------------------------------------

    ERP_Con_Orig = [];
    ERP_Dis_Orig = [];

    for tr = 1:numel(trialsOrig)

        X = trialsOrig(tr).eeg;

        if strcmpi( ...
                trialsOrig(tr).eventLabel,...
                'Consonant')

            ERP_Con_Orig(:,:,end+1) = X;

        elseif strcmpi( ...
                trialsOrig(tr).eventLabel,...
                'Dissonant')

            ERP_Dis_Orig(:,:,end+1) = X;

        end

    end

    ERP_Con_Orig = ...
        mean(ERP_Con_Orig,3,'omitnan');

    ERP_Dis_Orig = ...
        mean(ERP_Dis_Orig,3,'omitnan');

    %% --------------------------------------------------------
    % Build ERP CLEAN
    %% --------------------------------------------------------

    ERP_Con_Clean = [];
    ERP_Dis_Clean = [];

    for tr = 1:numel(trialsClean)

        X = trialsClean(tr).eeg;

        if strcmpi( ...
                trialsClean(tr).eventLabel,...
                'Consonant')

            ERP_Con_Clean(:,:,end+1) = X;

        elseif strcmpi( ...
                trialsClean(tr).eventLabel,...
                'Dissonant')

            ERP_Dis_Clean(:,:,end+1) = X;

        end

    end

    ERP_Con_Clean = ...
        mean(ERP_Con_Clean,3,'omitnan');

    ERP_Dis_Clean = ...
        mean(ERP_Dis_Clean,3,'omitnan');

    %% --------------------------------------------------------
    % ERAN_CORE ROI
    %% --------------------------------------------------------

    MAIN_ROI

    eranLabels = ROI.ERAN_CORE;

    chanLabels = ...
        {trialsOrig(1).chanlocs.labels};

    idxROI = find( ...
        ismember( ...
        upper(chanLabels), ...
        upper(eranLabels)));

    conOrig = ...
        mean(ERP_Con_Orig(idxROI,:),1);

    disOrig = ...
        mean(ERP_Dis_Orig(idxROI,:),1);

    conClean = ...
        mean(ERP_Con_Clean(idxROI,:),1);

    disClean = ...
        mean(ERP_Dis_Clean(idxROI,:),1);

    t = trialsOrig(1).time;
    diffWaveOrig  = conOrig  - disOrig;
    diffWaveClean = conClean - disClean;

    r = corr( ...
        diffWaveOrig(:), ...
        diffWaveClean(:), ...
        'Rows','complete');
    fprintf('ERP correlation = %.3f\n',r);
    ValidationTable.Subject(iSub) = subjID;
    ValidationTable.ERP_Correlation(iSub) = r;
    %% --------------------------------------------------------
    % Plot
    %% --------------------------------------------------------

    fig = figure( ...
        'Color','w', ...
        'Position',[100 100 1200 700]);

    subplot(2,1,1)

    plot(t*1000, ...
        conOrig-disOrig, ...
        'r', ...
        'LineWidth',2);

    hold on

    plot(t*1000, ...
        conClean-disClean, ...
        'b', ...
        'LineWidth',2);

    xline(0,'k--')

    legend( ...
        'Original',...
        'Clean')

    title(sprintf( ...
        '%s | ERAN CORE Difference', ...
        subjID))

    ylabel('\muV')

    grid on

    subplot(2,1,2)

    plot(t*1000, ...
        conOrig, ...
        'Color',[0.8 0.2 0.2], ...
        'LineWidth',1.5);

    hold on

    plot(t*1000, ...
        disOrig, ...
        'Color',[0.2 0.2 0.8], ...
        'LineWidth',1.5);

    plot(t*1000, ...
        conClean, ...
        '--r', ...
        'LineWidth',2);

    plot(t*1000, ...
        disClean, ...
        '--b', ...
        'LineWidth',2);

    xline(0,'k--')

    legend( ...
        'Con Orig',...
        'Dis Orig',...
        'Con Clean',...
        'Dis Clean')

    xlabel('Time (ms)')
    ylabel('\muV')

    grid on

    saveas(fig, ...
        fullfile(outdir, ...
        sprintf( ...
        '%s_ERAN_CORE_OriginalVsClean.png', ...
        subjID)));

    close(fig)

end

%% ========================================================================
% REMOVED TRIAL REPORT
%% ========================================================================

if ~isempty(RemovalTable)
    writetable( ...
        RemovalTable,...
        fullfile(outdir,...
        'RemovedTrialsReport.xls'));
end

writetable( ...
    ValidationTable,...
    fullfile(outdir,...
    'STEP2C_ERP_Validation.xls'));
%% ========================================================================
% DONE
%% ========================================================================

fprintf('\n');
fprintf('====================================\n');
fprintf('STEP2C CHECK COMPLETED\n');
fprintf('====================================\n');

set(0, 'DefaultFigureVisible', origState);