%% =========================================================================
% STEP4A_BANDPOWER_ROI_PLOTS
% %STEP4A_BANDPOWER_PLOTS_ALL_FROM_RESULTS
% X-SONANCE EEG
%% =========================================================================
%
% INPUT
% -----
% STEP4A_BANDPOWER/Consonance/<ROI>/
%     BANDPOWER_STEP4A_RESULTS_<ROI>.mat
%
% EXPECTED STRUCTURES
% -------------------
% BandPower_Group_ROI.<ROI>.<band>.<condition>.power
% BandPower_Subj_ROI.<subjectID>.<ROI>.<band>.<condition>.power
%
% OUTPUT, INSIDE EACH ROI DIRECTORY
% --------------------------------
% Plots_Group/
% Plots_Subjects_Grid/
% Plots_Subjects/
%
% No band-power extraction.
% No modification of the original MAT files.
%
% Difference is plotted explicitly as Dissonant - Consonant.
%% =========================================================================

clear
close all
clc

%% ============================================================
% PATHS
%% ============================================================

step4_outroot = fullfile( ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO', ...
    'STEP4A_BANDPOWER');

comparisonName = 'Consonance';
resultsDir = fullfile(step4_outroot,comparisonName);

assert(isfolder(resultsDir), ...
    'Results folder not found: %s',resultsDir);

%% ============================================================
% SETTINGS
%% ============================================================

% Empty = discover ROI folders containing the expected MAT file.
roiNames = {};

% Empty = use all available bands.
bandNames = {};

cfgPlot = struct();

cfgPlot.plot_window = [-0.2 0.8];

cfgPlot.save_group = true;
cfgPlot.save_subject_grid = true;
cfgPlot.save_subject_both = true;
cfgPlot.save_subject_diff = true;

cfgPlot.save_png = true;
cfgPlot.save_fig = false;

cfgPlot.colors.Consonant = [0 0.35 0.80];
cfgPlot.colors.Dissonant = [0.85 0.15 0.15];
cfgPlot.colors.Difference = [0 0 0];

assert(cfgPlot.save_png || cfgPlot.save_fig, ...
    'Enable at least one output format.');

%% ============================================================
% FIND ROI RESULT FILES
%% ============================================================

if isempty(roiNames)

    folders = dir(resultsDir);

    for k = 1:numel(folders)

        if ~folders(k).isdir || startsWith(folders(k).name,'.')
            continue
        end

        candidateROI = folders(k).name;

        candidateFile = fullfile( ...
            resultsDir,candidateROI, ...
            sprintf('BANDPOWER_STEP4A_RESULTS_%s.mat',candidateROI));

        if isfile(candidateFile)
            roiNames{end+1} = candidateROI; %#ok<SAGROW>
        end

    end

end

roiNames = sort(roiNames);

assert(~isempty(roiNames), ...
    'No ROI result files found in: %s',resultsDir);

fprintf('\n================================\n');
fprintf('BANDPOWER PLOTS FROM RESULTS\n');
fprintf('================================\n');
fprintf('ROIs: %d\n',numel(roiNames));

%% ============================================================
% LOOP ROIS
%% ============================================================

for r = 1:numel(roiNames)

    roiName = roiNames{r};
    roiDir = fullfile(resultsDir,roiName);

    resultFile = fullfile(roiDir, ...
        sprintf('BANDPOWER_STEP4A_RESULTS_%s.mat',roiName));

    if ~isfile(resultFile)
        warning('Missing result file: %s',resultFile);
        continue
    end

    fprintf('\n================================\n');
    fprintf('ROI: %s\n',roiName);
    fprintf('================================\n');

    S = load(resultFile, ...
        'BandPower_Subj_ROI','BandPower_Group_ROI','cfgBP');

    % Local aliases: one ROI loaded at a time.
    G = struct();
    U = struct();

    if isfield(S,'BandPower_Group_ROI') && ...
            isfield(S.BandPower_Group_ROI,roiName)
        G = S.BandPower_Group_ROI.(roiName);
    end

    if isfield(S,'BandPower_Subj_ROI')
        U = S.BandPower_Subj_ROI;
    end

    subjNames = fieldnames(U);

    [ylabelStr,diffYlabelStr] = power_axis_labels(S);

    % Discover all bands, including bands present only in subjects.
    availableBands = fieldnames(G);

    for s = 1:numel(subjNames)
        subjID = subjNames{s};

        if isfield(U.(subjID),roiName)
            names = fieldnames(U.(subjID).(roiName));
            availableBands = unique( ...
                [availableBands; names],'stable');
        end
    end

    if isempty(bandNames)
        bandsCurr = availableBands;
    else
        bandsCurr = bandNames;
    end

    if isempty(bandsCurr)
        warning('No bands found for ROI: %s',roiName);
        continue
    end

    % Output directories are inside the source ROI folder.
    groupDir = fullfile(roiDir,'Plots_Group');
    gridDir = fullfile(roiDir,'Plots_Subjects_Grid');
    subjectDir = fullfile(roiDir,'Plots_Subjects');

    if cfgPlot.save_group
        ensure_dir(groupDir);
    end

    if cfgPlot.save_subject_grid
        ensure_dir(gridDir);
    end

    if cfgPlot.save_subject_both || cfgPlot.save_subject_diff
        ensure_dir(subjectDir);
    end

    %% ========================================================
    % LOOP BANDS
    %% ========================================================

    for b = 1:numel(bandsCurr)

        bandName = bandsCurr{b};

        fprintf('\nBand: %s\n',bandName);

        % Validate subject data once, then reuse for all plots.
        validSubjects = {};
        subjectData = {};

        for s = 1:numel(subjNames)

            subjID = subjNames{s};

            if ~isfield(U.(subjID),roiName) || ...
                    ~isfield(U.(subjID).(roiName),bandName)
                warning('Missing subject data: %s | %s | %s', ...
                    subjID,roiName,bandName);
                continue
            end

            bp = U.(subjID).(roiName).(bandName);

            try
                [t,pCon,pDis] = get_waveforms(bp,[]);

                D = struct();
                D.time = t;
                D.con = pCon;
                D.dis = pDis;
                D.diff = pDis - pCon;

                validSubjects{end+1} = subjID; %#ok<SAGROW>
                subjectData{end+1} = D; %#ok<SAGROW>

            catch ME
                warning('Invalid subject data: %s | %s | %s\n%s', ...
                    subjID,roiName,bandName,ME.message);
            end

        end

        %% ====================================================
        % GROUP PLOT
        %% ====================================================

        if cfgPlot.save_group

            if ~isfield(G,bandName)
                warning('Missing group data: %s | %s', ...
                    roiName,bandName);
            else

                figH = [];

                try
                    fallbackTime = [];

                    % If group.time is missing, use the subject grid
                    % only when all validated subjects share that grid.
                    if ~isempty(subjectData)

                        fallbackTime = subjectData{1}.time;

                        for j = 2:numel(subjectData)
                            if ~isequal(fallbackTime,subjectData{j}.time)
                                fallbackTime = [];
                                break
                            end
                        end

                    end

                    [t,pCon,pDis] = get_waveforms( ...
                        G.(bandName),fallbackTime);

                    figH = figure( ...
                        'Visible','off','Color','w', ...
                        'Position',[100 100 1100 650]);

                    ax = axes('Parent',figH);

                    draw_waveforms(ax,t,pCon,pDis,'all',cfgPlot);

                    xlabel(ax,'Time (s)');
                    ylabel(ax,ylabelStr);

                    title(ax,sprintf('%s | %s | Group mean', ...
                        roiName,bandName),'Interpreter','none');

                    save_plot(figH,fullfile(groupDir, ...
                        sprintf('%s_%s_Group',roiName,bandName)), ...
                        cfgPlot);

                    close(figH);

                    fprintf('   GROUP OK\n');

                catch ME
                    close_if_valid(figH);
                    warning('Group plot failed: %s | %s\n%s', ...
                        roiName,bandName,ME.message);
                end

            end

        end

        %% ====================================================
        % SUBJECT GRID
        %% ====================================================

        if cfgPlot.save_subject_grid && ~isempty(subjectData)

            figH = [];

            try
                nSubj = numel(validSubjects);
                nRows = ceil(sqrt(nSubj));
                nCols = ceil(nSubj/nRows);

                figH = figure( ...
                    'Visible','off','Color','w', ...
                    'Position',[100 100 1500 900]);

                layout = tiledlayout(figH,nRows,nCols, ...
                    'TileSpacing','compact','Padding','compact');

                for s = 1:nSubj

                    D = subjectData{s};
                    ax = nexttile(layout);

                    draw_waveforms( ...
                        ax,D.time,D.con,D.dis,'all',cfgPlot);

                    title(ax,validSubjects{s},'Interpreter','none');
                    xlabel(ax,'Time (s)');
                    ylabel(ax,ylabelStr);

                    % Avoid repeating a legend in every panel.
                    if s > 1
                        legend(ax,'off');
                    end

                end

                title(layout,sprintf( ...
                    '%s | %s | Subject band power', ...
                    roiName,bandName),'Interpreter','none');

                save_plot(figH,fullfile(gridDir, ...
                    sprintf('%s_%s_Subjects',roiName,bandName)), ...
                    cfgPlot);

                close(figH);

                fprintf('   SUBJECT GRID OK (%d subjects)\n',nSubj);

            catch ME
                close_if_valid(figH);
                warning('Grid plot failed: %s | %s\n%s', ...
                    roiName,bandName,ME.message);
            end

        end

        %% ====================================================
        % INDIVIDUAL SUBJECT PLOTS
        %% ====================================================

        for s = 1:numel(validSubjects)

            subjID = validSubjects{s};
            D = subjectData{s};

            modes = {};
            suffixes = {};

            if cfgPlot.save_subject_both
                modes{end+1} = 'both';
                suffixes{end+1} = 'BOTH';
            end

            if cfgPlot.save_subject_diff
                modes{end+1} = 'diff';
                suffixes{end+1} = 'DIFF';
            end

            for m = 1:numel(modes)

                figH = [];

                try
                    figH = figure( ...
                        'Visible','off','Color','w', ...
                        'Position',[100 100 900 500]);

                    ax = axes('Parent',figH);

                    draw_waveforms( ...
                        ax,D.time,D.con,D.dis,modes{m},cfgPlot);

                    xlabel(ax,'Time (s)');

                    if strcmp(modes{m},'diff')
                        ylabel(ax,diffYlabelStr);
                        plotTitle = sprintf( ...
                            '%s | %s | %s | Dissonant - Consonant', ...
                            subjID,roiName,bandName);
                    else
                        ylabel(ax,ylabelStr);
                        plotTitle = sprintf('%s | %s | %s', ...
                            subjID,roiName,bandName);
                    end

                    title(ax,plotTitle,'Interpreter','none');

                    save_plot(figH,fullfile(subjectDir, ...
                        sprintf('%s_%s_%s_%s', ...
                        subjID,roiName,bandName,suffixes{m})), ...
                        cfgPlot);

                    close(figH);

                catch ME
                    close_if_valid(figH);
                    warning('Subject plot failed: %s | %s | %s | %s\n%s', ...
                        subjID,roiName,bandName,suffixes{m},ME.message);
                end

            end

        end

    end

    clear S G U subjectData

end

fprintf('\n================================\n');
fprintf('ALL BANDPOWER PLOTS COMPLETED\n');
fprintf('================================\n');

%% =========================================================================
% LOCAL FUNCTIONS
%% =========================================================================

function ensure_dir(folder)

    if ~isfolder(folder)
        mkdir(folder);
    end

end

function [yLabel,diffLabel] = power_axis_labels(S)

    normType = 'unknown';

    if isfield(S,'cfgBP') && isfield(S.cfgBP,'normalization')
        normType = char(S.cfgBP.normalization);
    end

    switch lower(normType)

        case 'db'
            yLabel = 'Band power (dB)';
            diffLabel = 'Dissonant - Consonant (dB)';

        case 'relative'
            yLabel = 'Relative band power';
            diffLabel = 'Dissonant - Consonant (relative power)';

        case 'subtract'
            yLabel = 'Baseline-corrected band power';
            diffLabel = 'Dissonant - Consonant';

        otherwise
            yLabel = 'Band power';
            diffLabel = 'Dissonant - Consonant';

    end

end

function [t,pCon,pDis] = get_waveforms(bp,fallbackTime)

    assert(isfield(bp,'Consonant') && ...
        isfield(bp.Consonant,'power'), ...
        'Missing Consonant.power.');

    assert(isfield(bp,'Dissonant') && ...
        isfield(bp.Dissonant,'power'), ...
        'Missing Dissonant.power.');

    pCon = bp.Consonant.power;
    pDis = bp.Dissonant.power;

    assert(isnumeric(pCon) && isvector(pCon) && ~isempty(pCon), ...
        'Consonant.power must be a nonempty numeric vector.');

    assert(isnumeric(pDis) && isvector(pDis) && ~isempty(pDis), ...
        'Dissonant.power must be a nonempty numeric vector.');

    pCon = pCon(:).';
    pDis = pDis(:).';

    assert(numel(pCon) == numel(pDis), ...
        'Consonant and Dissonant have different lengths.');

    % Prefer the common time field used by the original pipeline.
    if isfield(bp,'time') && ~isempty(bp.time)

        t = bp.time;

    elseif isfield(bp.Consonant,'time') && ...
            isfield(bp.Dissonant,'time')

        tc = bp.Consonant.time;
        td = bp.Dissonant.time;

        assert(isequal(tc(:),td(:)), ...
            'Condition time vectors do not match.');

        t = tc;

    elseif ~isempty(fallbackTime)

        t = fallbackTime;

    else
        error(['Time vector unavailable. Expected bp.time or ' ...
            'a validated subject time vector for the group.']);
    end

    assert(isnumeric(t) && isvector(t), ...
        'Time must be a numeric vector.');

    t = t(:).';

    assert(numel(t) == numel(pCon), ...
        'Time and power vectors have different lengths.');

    assert(all(isfinite(t)) && all(diff(t) > 0), ...
        'Time must be finite and strictly increasing.');

end

function draw_waveforms(ax,t,pCon,pDis,mode,cfg)

    hold(ax,'on');

    handles = gobjects(0);
    labels = {};

    if strcmp(mode,'both') || strcmp(mode,'all')

        handles(end+1) = plot(ax,t,pCon, ...
            'Color',cfg.colors.Consonant,'LineWidth',1.8);
        labels{end+1} = 'Consonant';

        handles(end+1) = plot(ax,t,pDis, ...
            'Color',cfg.colors.Dissonant,'LineWidth',1.8);
        labels{end+1} = 'Dissonant';

    end

    if strcmp(mode,'diff') || strcmp(mode,'all')

        handles(end+1) = plot(ax,t,pDis-pCon, ...
            'Color',cfg.colors.Difference,'LineWidth',1.5);
        labels{end+1} = 'Dissonant - Consonant';

    end

    xline(ax,0,'k:','HandleVisibility','off');
    yline(ax,0,'k:','HandleVisibility','off');

    if ~isempty(cfg.plot_window)
        xlim(ax,cfg.plot_window);
    end

    grid(ax,'on');
    box(ax,'on');

    legend(ax,handles,labels,'Location','best', ...
        'Interpreter','none');

    hold(ax,'off');

end

function save_plot(figH,baseName,cfg)

    if cfg.save_png
        saveas(figH,[baseName '.png']);
    end

    if cfg.save_fig
        savefig(figH,[baseName '.fig']);
    end

end

function close_if_valid(figH)

    if ~isempty(figH) && isgraphics(figH)
        close(figH);
    end

end