%% =========================================================================
% STEP11C_NSA_SINGLE_SUBJECT
%
% X-SONANCE
%
% Neural Space Analysis
%
% INPUT
%
%   STEP11A_NSA_DATASET/Subject/Subj#_NSA_Dataset.mat
%
% OUTPUT
%
%   STEP11C_NSA_SINGLE_SUBJECT/NSA_Subj#.mat
%   STEP11C_NSA_SINGLE_SUBJECT/Figures/*.png, *.pdf, *.fig
%
%% =========================================================================
clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

set(groot, ...
    'defaultTextInterpreter','tex', ...
    'defaultAxesTickLabelInterpreter','tex', ...
    'defaultLegendInterpreter','tex');

disable_eeglab();

%% =========================================================================
% CONFIG
%% =========================================================================
cfgNSA = struct();

% Paths
cfgNSA.projectRoot = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';
cfgNSA.subjectsDir = ...
    fullfile(cfgNSA.projectRoot, ...
    'STEP11A_NSA_DATASET', ...
    'Subjects');

cfgNSA.subjectFilePattern = ...
    'Subj*_NSA_Dataset.mat';
cfgNSA.outSubdir = ...
    'STEP11C_NSA_SINGLE_SUBJECT';

% General
cfgNSA.randomSeed       = 10;
cfgNSA.ifplot           = false;
cfgNSA.saveFigures      = true;
cfgNSA.figureResolution = 300;

% Signals
cfgNSA.signal_name      = 'eeg';
cfgNSA.signal_process   = 'dpca';

% Time selection, in s from ZeroEvent
cfgNSA.t1 = 0.0;
cfgNSA.t2 = 1.5;

% Preprocessing / smoothing
cfgNSA.binWidth = 20;          % ms
cfgNSA.kernSD   = 30;            % ms

% PCA
cfgNSA.pcaVariance      = 99;       % %
cfgNSA.pcaNumComponents = 0;   % 0 = usa pcaVariance

% Condition means / confidence intervals
cfgNSA.P                = 95;

% Classes used for the Consonant vs Dissonant analysis
cfgNSA.class_codes  = [1 2];
cfgNSA.class_labels = { ...
    'Consonant', ...
    'Dissonant'};

% Plot components
cfgNSA.traj3D_components = 1:3;
cfgNSA.traj2D_components = [1 2];
cfgNSA.eachDimCols       = 3;

rng(cfgNSA.randomSeed);

subjectFiles = dir(fullfile(cfgNSA.subjectsDir, ...
    cfgNSA.subjectFilePattern));

subjectFiles = subjectFiles([subjectFiles.isdir] == 0);

nSubjects = numel(subjectFiles);

assert(nSubjects > 0, ...
    'Nessun file soggetto trovato in:\n%s', ...
    cfgNSA.subjectsDir);

for iSub = 1:nSubjects

    subjectFile = ...
        fullfile(subjectFiles(iSub).folder, ...
        subjectFiles(iSub).name);

    [~,subjectName] = ...
        fileparts(subjectFiles(iSub).name);

    fprintf('\n');
    fprintf('================================\n');
    fprintf('SUBJECT %d/%d\n', ...
        iSub,nSubjects);
    fprintf('%s\n', ...
        subjectName);
    fprintf('================================\n');
    %% =========================================================================
    % LOAD
    %% =========================================================================
    load(subjectFile);

    EEG_trials = ...
        Subject_Dataset.trials;

    %% =========================================================================
    % OUT DIR
    %% =========================================================================
    outdir = fullfile( ...
        cfgNSA.projectRoot, ...
        cfgNSA.outSubdir, ...
        subjectName);

    figdir = fullfile(outdir,'Figures');

    if ~exist(outdir,'dir')
        mkdir(outdir);
    end
    if cfgNSA.saveFigures && ~exist(figdir,'dir')
        mkdir(figdir);
    end

    %% =========================================================================
    % STEP 0
    % TIME SELECTION FROM CUE
    %% =========================================================================
    % Time interpolation and selection from Cue
    par.TimeSelect               = TimeSelectParams;
    par.TimeSelect.t1            = cfgNSA.t1; % in s from ZeroEvent time
    par.TimeSelect.t2            = cfgNSA.t2; % in s from ZeroEvent time
    par.TimeSelect.InField       = cfgNSA.signal_name;
    par.TimeSelect.OutField      = cfgNSA.signal_name;
    par.TimeSelect.dt            = 1;

    par.exec.funname ={'TimeSelect'};
    [EEG_trials, par.execinfo]=run_trials(EEG_trials,par);

    %% =========================================================================
    % STEP 1
    % NORMALIZATION, SMOOTHING, REMOVE INACTIVE
    %% =========================================================================
    % signalNormalize
    par.signalNormalize             = signalNormalizeParams;
    par.signalNormalize.InField     = cfgNSA.signal_name;
    par.signalNormalize.OutField    = cfgNSA.signal_process;

    % SmoothWindow (moving window smoothing)
    par.SmoothWindow                = SmoothWindowParams;
    par.SmoothWindow.InField        = cfgNSA.signal_process;
    par.SmoothWindow.OutField       = cfgNSA.signal_process;
    par.SmoothWindow.binWidth       = cfgNSA.binWidth;
    % removeInactives (0 mean channels removal)
    par.removeInactive              = removeInactiveParams;
    par.removeInactive.InField      = cfgNSA.signal_process;
    par.removeInactive.OutField     = cfgNSA.signal_process;

    % function to be execute
    par.exec.funname                = {'signalNormalize','SmoothWindow','removeInactive'};
    [data_trials, outStep2]         = run_trials(EEG_trials,par);

    %% =========================================================================
    % STEP 2
    % PCA ON CONDITION AVERAGES
    %% =========================================================================
    % meanData
    par.meanData                    = meanDataParams;
    par.meanData.trialTypes         = [data_trials.trialType];
    par.meanData.InField            = cfgNSA.signal_process;
    par.meanData.OutField           = cfgNSA.signal_process;
    % AverageWindow (average window selection with sqrt)
    par.AverageWindow               = AverageWindowParams;
    par.AverageWindow.useSqrt       = false;
    par.AverageWindow.InField       = cfgNSA.signal_process;
    par.AverageWindow.OutField      = cfgNSA.signal_process;
    par.AverageWindow.binWidth      = cfgNSA.binWidth;
    % GaussianSmoother (kernel smoothing)
    par.GaussianSmoother            = GaussianSmootherParams;
    par.GaussianSmoother.InField    = cfgNSA.signal_process;
    par.GaussianSmoother.OutField   = cfgNSA.signal_process;
    par.GaussianSmoother.kernSD     = cfgNSA.kernSD;       % standard deviation of Gaussian kernel, in msec
    par.GaussianSmoother.stepSize   = cfgNSA.binWidth;     % time between 2 consecutive datapoints, in msec
    % pcaModel or pcaModel
    par.pcaModel                    = pcaModelParams();
    par.pcaModel.numComponents      = cfgNSA.pcaNumComponents;
    par.pcaModel.perc               = cfgNSA.pcaVariance;
    par.pcaModel.InField            = cfgNSA.signal_process;
    par.pcaModel.OutField           = cfgNSA.signal_process;
    %%%%%%%%%%%%% nsa_pca 2-Stage Engine Churchland : kernel smooth + pca -> %%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% 'AverageWindow','GaussianSmoother','pcaModel'            %%%%%%%%%%%%%%%%%%
    % see
    % Yu, B. M., Cunningham, J. P., Santhanam, G., Ryu, S., Shenoy, K. V., & Sahani, M. (2008).
    % Gaussian-process factor analysis for low-dimensional single-trial analysis of neural population activity.
    % Advances in neural information processing systems, 21.
    % https://journals.physiology.org/doi/full/10.1152/jn.90941.2008
    % Note: perform pca on trials averaged on conditions, similar to demixed pca. see->
    % Kobak, D., Brendel, W., Constantinidis, C., Feierstein, C. E., Kepecs, A., Mainen, Z. F., ... & Machens, C. K. (2016).
    % Demixed principal component analysis of neural population data. elife, 5, e10989.
    % https://elifesciences.org/articles/10989
    par.exec.funname                = {'meanData','AverageWindow','GaussianSmoother','pcaModel'};
    [data_trials_class, out]        = run_trials(data_trials,par);

    %% =========================================================================
    % STEP 3
    % ENCODE CLASS MEANS
    %% =========================================================================
    % pcaEncode
    par.pcaEncode.Wpca              = out.pcaModel.Wpca;
    par.pcaEncode.mu                = out.pcaModel.mu;
    par.pcaEncode.explained         = out.pcaModel.explained;
    par.pcaEncode.InField           = cfgNSA.signal_process;
    par.pcaEncode.OutField          = cfgNSA.signal_process;
    par.exec.funname                = {'pcaEncode'};
    data_trials_class               = run_trials(data_trials_class,par);
    %% =========================================================================
    % STEP 4
    % PROJECT ALL TRIALS
    %% =========================================================================
    % pcaEncode or Project
    par.pcaEncode.Wpca              = out.pcaModel.Wpca;
    par.pcaEncode.mu                = out.pcaModel.mu;
    par.pcaEncode.explained         = out.pcaModel.explained;
    par.pcaEncode.InField           = cfgNSA.signal_process;
    par.pcaEncode.OutField          = cfgNSA.signal_process;
    par.exec.funname                = {'AverageWindow','GaussianSmoother','pcaEncode'};
    [data_trials, out2]             = run_trials(data_trials,par);

    %% =========================================================================
    % STEP 5
    % SEPARABILITY ACROSS COMPONENTS AND TIME
    %% =========================================================================
    timeField                       = data_trials_class(1).(['time' par.pcaEncode.OutField]);

    par.dpca_pCompute.it_start  = cfgNSA.t1;
    par.dpca_pCompute.it_stop   = cfgNSA.t2;

    valmin  = nan(size(data_trials(1).dpca,1),1);
    t_point = nan(size(data_trials(1).dpca,1),1);

    for icomp = 1:size(data_trials(1).dpca,1)
        [valmin(icomp),t_point(icomp)] = dpca_pCompute(icomp,data_trials,par.dpca_pCompute);
    end

    [pmin,dpca_comp] = min(valmin);
    ctime = t_point(dpca_comp);
    %% =========================================================================
    % STEP 6
    % PSEPARABILITY
    %% =========================================================================
    %% pSeparability
    par.pSeparability                   = pSeparabilityParams;
    par.pSeparability.InField           = par.pcaModel.OutField;
    par.pSeparability.OutField          = 'comparisons';
    par.pSeparability.exec              = true;
    [pVals,pClasses]                    = pSeparabilityCLASS(data_trials,par.pSeparability);
    %% =========================================================================
    % STEP 7
    % CONDITION COLORS
    %% =========================================================================
    classes = unique([data_trials.trialType]);
    nClasses = length(classes);
    cmaps = linspecer(nClasses);

    [~,i0]                          = min(abs(timeField));      % select   0  ms % TargetOn
    %% =========================================================================
    % FIGURE 1
    % 3D TRAJECTORY
    %% =========================================================================
    %% Plot 3D Trajectories
    hfg = struct();
    par.plot_trajectory3D           = plot_trajectory3DParams;
    hfig                            = figure;
    % par.plot_trajectory3D.hfig      = figure('Visible',cfgNSA.ifplot);
    par.plot_trajectory3D.keep      = 1:nClasses;               % which conditions u-path, shortcut, deadend
    par.plot_trajectory3D.wd        = 1:3;                      % which components
    par.plot_trajectory3D.axlab     = 'x';
    par.plot_trajectory3D.cmaps     = cmaps;
    par.plot_trajectory3D.cmapslight= lightCmaps(par.plot_trajectory3D.cmaps);
    par.plot_trajectory3D.explained = out.pcaModel.explained;
    par.plot_trajectory3D.InField   = par.pcaEncode.OutField;  % take pca projections to show
    par.plot_trajectory3D.istart    = 1;
    par.plot_trajectory3D.center    = i0;
    par.plot_trajectory3D.iend      = length(timeField);
    hfg.trajectory3D                = plot_trajectory3D(data_trials_class,par.plot_trajectory3D);

    %% =========================================================================
    % FIGURE 2
    % 2D TRAJECTORY
    %% =========================================================================

    par.plot_trajectory2D           = plot_trajectory2DParams;
    par.plot_trajectory2D.keep      = 1:nClasses;
    par.plot_trajectory2D.wd        = [1 2];
    par.plot_trajectory2D.axlab     ='x';
    par.plot_trajectory2D.cmaps     = cmaps;
    par.plot_trajectory2D.cmapslight= lightCmaps(cmaps);
    par.plot_trajectory2D.explained = out.pcaModel.explained;
    par.plot_trajectory2D.InField   = par.pcaEncode.OutField;
    par.plot_trajectory2D.istart    = 1;
    par.plot_trajectory2D.center    = i0;
    par.plot_trajectory2D.iend      = length(timeField);

    hfg.trajectory2D                = plot_trajectory2D(data_trials_class,par.plot_trajectory2D);
    %% =========================================================================
    % STEP 8
    % REMAP TO CONSONANT VS DISSONANT
    %% =========================================================================
    % 1:    Consonant
    % 2:    Dissonant
    % remapTypes
    par.remapTypes                  = remapTypesParams;
    par.remapTypes.selection        = {1, 2};
    nSels                           = length(par.remapTypes.selection);
    cmaps_CD                        = nan(nSels,3);
    for isel=1:length(par.remapTypes.selection)
        cmaps_CD(isel,:)            = mean(cmaps(par.remapTypes.selection{isel},:),1);
    end
    par.remapTypes.names            = {'Consonant', 'Dissonant'};
    data_trials_CD                  = remapTypes(data_trials,par.remapTypes);
    %% =========================================================================
    % STEP 9
    % CONDITION MEANS WITH CONFIDENCE INTERVALS
    %% =========================================================================
    %% meanData
    par.meanData                    = meanDataParams;
    par.meanData.ifclass            = true;
    par.meanData.trialTypes         = [data_trials.trialType];
    par.meanData.InField            = par.pcaEncode.OutField;
    par.meanData.OutField           = par.pcaEncode.OutField;
    par.meanData.P                  = cfgNSA.P;
    par.meanData.opt                = [1,0,0];
    data_trials_means               = meanData(data_trials,par.meanData);

    classes                          = unique([data_trials_means.trialType]);
    nClasses                         = length(classes);
    %% =========================================================================
    % FIGURE 3
    % EACH PCA DIMENSION VS TIME
    %% =========================================================================
    % plot_EachDimVsTime
    par.plot_EachDimVsTime              = plot_EachDimVsTimeParams;
    par.plot_EachDimVsTime.cmaps        = cmaps;
    par.plot_EachDimVsTime.cmapslight   = lightCmaps(par.plot_EachDimVsTime.cmaps);
    par.plot_EachDimVsTime.InField      = par.pcaEncode.OutField;  % take pca projection to show;
    par.plot_EachDimVsTime.ylabel       = '$pca$';
    par.plot_EachDimVsTime.keep         = 1:nClasses;
    par.plot_EachDimVsTime.nCols        = 3;
    par.plot_EachDimVsTime.legplot      = 2;
    % GRAPH SUBPLOT TITLES
    explained                           = out.pcaModel.explained;
    channels                            = 1:out.pcaModel.numComponents;
    nChannels                           = length(channels); %% number of graphs
    str                                 = cell(nChannels,1);
    for ichannel=1:nChannels
        str{ichannel} = sprintf('$$\\tilde{\\mathbf x}_{%d,t}$$',ichannel);
        if ~isempty(explained)
            str{ichannel} = sprintf('%s (%2.1f)',str{ichannel},explained(ichannel));
        end
    end
    par.plot_EachDimVsTime.titles       = str;

    hfg.pcas                            = plot_EachDimVsTime(data_trials_means,par.plot_EachDimVsTime);

    %% =========================================================================
    % FIGURE 4
    % P VALUES
    %% =========================================================================
    %% pvalue plot per feature
    par.plot_pValues                    = plot_pValuesParams;
    par.plot_pValues.InField            = par.pSeparability.OutField;
    par.plot_pValues.hfig               = figure('visible',cfgNSA.ifplot);
    par.plot_pValues.nRows              = 1;
    par.plot_pValues.decisions          = [];
    hfg.pvals                           = plot_pValues(pClasses,par.plot_pValues);
    % sgtitle(hfg.pvals,[RatName ' ' daystr ' ' feedstr]);

    %% =========================================================================
    % SAVE FIGURES
    %% =========================================================================
    if cfgNSA.saveFigures

        figNames = fieldnames(hfg);

        for iFig = 1:numel(figNames)

            figName = figNames{iFig};
            hFig = hfg.(figName);

            if isempty(hFig) || ~isgraphics(hFig)
                continue;
            end

            baseName = ...
                sprintf('NSA_SINGLE_SUBJECT_%s',figName);

            pngFile = ...
                fullfile(figdir,[baseName '.png']);
            pdfFile = ...
                fullfile(figdir,[baseName '.pdf']);
            figFile = ...
                fullfile(figdir,[baseName '.fig']);

            exportgraphics(hFig,pngFile, ...
                'Resolution',cfgNSA.figureResolution);

            exportgraphics(hFig,pdfFile, ...
                'ContentType','image');

            savefig(hFig,figFile);

        end

    end

    %% =========================================================================
    % COMPONENT TABLE
    %% =========================================================================
    nComp = length(valmin);

    ComponentTable = table( ...
        nan(nComp,1), ...
        nan(nComp,1), ...
        nan(nComp,1), ...
        nan(nComp,1), ...
        'VariableNames',{ ...
        'Component', ...
        'ExplainedVariance', ...
        'BestTime', ...
        'Separability'});

    for iComp = 1:nComp
        ComponentTable.Component(iComp) = iComp;
        ComponentTable.ExplainedVariance(iComp) = ...
            out.pcaModel.explained(iComp);
        ComponentTable.BestTime(iComp) = ...
            t_point(iComp);
        ComponentTable.Separability(iComp) = ...
            valmin(iComp);
    end
    fprintf('\n');
    disp(ComponentTable);
    %% =========================================================================
    % OUTPUT
    %% =========================================================================
    NSA_SINGLE_SUBJECT = struct();

    NSA_SINGLE_SUBJECT.cfgNSA = cfgNSA;

    NSA_SINGLE_SUBJECT.pcaModel = out.pcaModel;

    NSA_SINGLE_SUBJECT.Wpca = out.pcaModel.Wpca;

    NSA_SINGLE_SUBJECT.mu = out.pcaModel.mu;

    NSA_SINGLE_SUBJECT.explained = out.pcaModel.explained;

    NSA_SINGLE_SUBJECT.data_trials = data_trials;

    NSA_SINGLE_SUBJECT.data_trials_class = data_trials_class;

    NSA_SINGLE_SUBJECT.data_trials = data_trials;

    NSA_SINGLE_SUBJECT.data_trials_means = data_trials_means;

    NSA_SINGLE_SUBJECT.timeField = timeField;

    NSA_SINGLE_SUBJECT.pVals = pVals;

    NSA_SINGLE_SUBJECT.pClasses = pClasses;

    NSA_SINGLE_SUBJECT.best_component = dpca_comp;

    NSA_SINGLE_SUBJECT.valmin = valmin;

    NSA_SINGLE_SUBJECT.t_point = t_point;

    NSA_SINGLE_SUBJECT.best_time = ctime;

    NSA_SINGLE_SUBJECT.best_pvalue = pmin;

    NSA_SINGLE_SUBJECT.outPCA = out;

    NSA_SINGLE_SUBJECT.figureDir = figdir;

    [~,idxRank] = sort(valmin);

    NSA_SINGLE_SUBJECT.ComponentRanking = idxRank;

    NSA_SINGLE_SUBJECT.ComponentTable = ComponentTable;

    %% =========================================================================
    % SUMMARY
    %% =========================================================================
    fprintf('\n');
    fprintf('================================\n');
    fprintf('NSA MANIFOLD\n');
    fprintf('================================\n');
    fprintf('Trials        : %d\n', ...
        numel(data_trials));
    fprintf('Classes       : %d\n', ...
        nClasses);
    fprintf('Components    : %d\n', ...
        out.pcaModel.numComponents);
    fprintf('Variance      : %.2f %%\n', ...
        sum(out.pcaModel.explained));
    fprintf('Best PC       : %d\n', ...
        dpca_comp);
    fprintf('Best Time     : %.4f s\n', ...
        ctime);
    fprintf('Best p-value  : %.6f\n', ...
        pmin);
    fprintf('Figures       : %s\n', ...
        figdir);
    fprintf('================================\n');

    %% =========================================================================
    % SAVE
    %% =========================================================================
    save( ...
        fullfile(outdir,'NSA_SINGLE_SUBJECT.mat'), ...
        'NSA_SINGLE_SUBJECT', ...
        '-v7.3');

    fprintf('\n');
    fprintf('STEP11C COMPLETED\n');
    fprintf('\n');
end
%% =========================================================================
% RESTORE
%% =========================================================================
set(0,'DefaultFigureVisible',origState);