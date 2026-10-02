%% =========================================================================
% STEP2B_EPOCH_QUALITY_CHECK
%% =========================================================================

clear
close all
clc
% %% 1) PATH SUBJ DATA
% %% ============================================================
% % INPUT DIRECTORY
% %% ============================================================
% step2_indir = ...
%     fullfile( ...
%     'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO',...
%     'DATA_SUBJECTS',...
%     'All_trials',...
%     'EPOCH_DATA');
% if ~exist(step2_indir, 'dir')
%     error('Cartella STEP2 non trovata: %s', step2_indir);
% end
% %% ============================================================
% % OUTPUT DIRECTORY
% %% ============================================================
% step3_outroot = ...
%     fullfile( ...
%     'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO',...
%     'STEP3_ERP');
% 
% if ~exist(step3_outroot,'dir')
%     mkdir(step3_outroot);
% end
% %% 2) LOAD FILES STEP2
% files = dir(fullfile(step2_indir, '*_epochData.mat'));
% if isempty(files)
%     error('Nessun file *_epochData.mat trovato in %s', step2_indir);
% end
% 
% nFiles = numel(files);
% subj_list = struct('subj_id', cell(nFiles,1), 'data_trials', cell(nFiles,1));
% 
% for i = 1:nFiles
%     S = load(fullfile(files(i).folder, files(i).name));
% 
%     if ~isfield(S, 'subjectEpochData')
%         error('Nel file %s non trovo subjectEpochData.', files(i).name);
%     end
% 
%     subjData = S.subjectEpochData;
% 
%     if isfield(subjData, 'subjectID')
%         subj_list(i).subj_id = subjData.subjectID;
%     else
%         subj_list(i).subj_id = regexprep(files(i).name, '_epochData\.mat$', '');
%     end
% 
%     if isfield(subjData, 'data_trials')
%         subj_list(i).data_trials = subjData.data_trials;
%     else
%         error('Nel file %s non trovo data_trials.', files(i).name);
%     end
% 
%     fprintf('Caricato soggetto %s\n', string(subj_list(i).subj_id));
% end
%% =========================================================================
% PATHS
%% =========================================================================

projectRoot = ...
'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

outdir = fullfile( ...
    projectRoot,...
    'STEP2B_EPOCH_QUALITY_CHECK');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% =========================================================================
% LOAD
%% =========================================================================

load(fullfile(projectRoot,...
    'subj_list.mat'),...
    'subj_list');

%% =========================================================================
% GLOBAL TABLE
%% =========================================================================

GlobalTable = table();

%% =========================================================================
% SUBJECT LOOP
%% =========================================================================

for iSub = 1:numel(subj_list)

    subj = subj_list(iSub);

    subjID = ...
        matlab.lang.makeValidName( ...
        char(subj.subj_id));

    fprintf('\n================================\n');
    fprintf('%s\n',subjID);
    fprintf('================================\n');

    subjDir = ...
        fullfile(outdir,subjID);

    if ~exist(subjDir,'dir')
        mkdir(subjDir);
    end

    nTrials = numel(subj.data_trials);

    trialRMS    = nan(nTrials,1);
    trialMAX    = nan(nTrials,1);

    pct50       = nan(nTrials,1);
    pct75       = nan(nTrials,1);
    pct100      = nan(nTrials,1);

    labels      = strings(nTrials,1);

    %% =========================================================
    % TRIAL METRICS
    %% =========================================================

    for tr = 1:nTrials

        eeg = ...
            double( ...
            subj.data_trials(tr).eeg);

        vals = eeg(:);

        trialRMS(tr) = rms(vals);

        trialMAX(tr) = max(abs(vals));

        pct50(tr) = ...
            100*mean(abs(vals)>50);

        pct75(tr) = ...
            100*mean(abs(vals)>75);

        pct100(tr) = ...
            100*mean(abs(vals)>100);

        if isfield( ...
                subj.data_trials(tr), ...
                'eventLabel')

            labels(tr) = ...
                string( ...
                subj.data_trials(tr).eventLabel);

        else

            labels(tr) = "Unknown";

        end

    end

    %% =========================================================
    % THRESHOLDS
    %% =========================================================

    rms99   = prctile(trialRMS,99);

    rms995  = prctile(trialRMS,99.5);

    rms999  = prctile(trialRMS,99.9);

    badTrials = ...
        find(trialRMS > rms995);

    %% =========================================================
    % TABLE
    %% =========================================================

    T = table( ...
        (1:nTrials)', ...
        labels, ...
        trialRMS, ...
        trialMAX, ...
        pct50, ...
        pct75, ...
        pct100, ...
        'VariableNames',{ ...
        'Trial', ...
        'Label', ...
        'RMS', ...
        'MaxAbs', ...
        'PctOver50', ...
        'PctOver75', ...
        'PctOver100'});

    writetable( ...
        T,...
        fullfile(subjDir,...
        'TrialMetrics.xls'));

    %% =========================================================
    % BAD TRIAL TABLE
    %% =========================================================

    Tbad = T(badTrials,:);

    writetable( ...
        Tbad,...
        fullfile(subjDir,...
        'BadTrials_99_5.xls'));

    %% =========================================================
    % RMS FIGURE
    %% =========================================================

    fig = figure( ...
        'Color','w',...
        'Position',[100 100 1400 700]);

    subplot(3,1,1)

    plot(trialRMS,'o-')

    hold on

    yline(rms99,'k--','99%');

    yline(rms995,'r--','99.5%');

    yline(rms999,'m--','99.9%');

    title('Trial RMS')

    grid on

    subplot(3,1,2)

    plot(trialMAX,'o-')

    title('Trial Max Abs')

    grid on

    subplot(3,1,3)

    plot(pct50,'o-')

    title('% Samples > 50 uV')

    grid on

    saveas( ...
        fig,...
        fullfile( ...
        subjDir,...
        'TrialQuality.png'));

    close(fig)

    %% =========================================================
    % BAD TRIAL CLASS DISTRIBUTION
    %% =========================================================

    if ~isempty(Tbad)

        fig = figure( ...
            'Color','w');

        cats = categorical(Tbad.Label);

        histogram(cats)

        title(sprintf( ...
            '%s Bad Trial Classes', ...
            subjID));

        saveas( ...
            fig,...
            fullfile( ...
            subjDir,...
            'BadTrialClasses.png'));

        close(fig)

    end

    %% =========================================================
    % GLOBAL
    %% =========================================================

    T.Subject = ...
        repmat( ...
        string(subjID), ...
        height(T),1);

    GlobalTable = ...
        [GlobalTable ; T];

    fprintf('Trials      : %d\n',nTrials);
    fprintf('Bad 99.5%%   : %d\n', ...
        numel(badTrials));

end

%% =========================================================================
% GLOBAL EXPORT
%% =========================================================================

writetable( ...
    GlobalTable,...
    fullfile(outdir,...
    'ALL_SUBJECTS_METRICS.xls'));

save( ...
    fullfile(outdir,...
    'STEP2B_EPOCH_QUALITY_CHECK.mat'),...
    'GlobalTable',...
    '-v7.3');

fprintf('\n====================================\n');
fprintf('STEP2B COMPLETED\n');
fprintf('====================================\n');