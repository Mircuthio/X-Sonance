%% =========================================================================
% STEP4_BANDPOWER_TOPOPLOT
% MAIN_DATASET_MARCO_BANDPOWER_STEP4
%% =========================================================================
%
% PROJECT
% -------
% X-SONANCE EEG
%
% PURPOSE
% -------
% Extract channel-level band power and create topographic maps.
%
% This script is independent from the ROI band-power analysis.
%
% PIPELINE
% --------
% Trial
%   ↓
% Channel
%   ↓
% Band-pass filtering
%   ↓
% Hilbert transform
%   ↓
% Instantaneous power
%   ↓
% Baseline correction
%   ↓
% Trial averaging
%   ↓
% Subject channel-level band power
%   ↓
% Group channel-level band power
%   ↓
% Time-window averaging
%   ↓
% Topoplot
%
% OUTPUT
% ------
% STEP4A_BANDPOWER/Consonance/Topoplots/<band>/
%     <band>_<window>_<condition>.png
%
% RESULT FILE
% -----------
% STEP4A_BANDPOWER/Consonance/BANDPOWER_STEP4A_CHANNEL_RESULTS.mat
%
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');
set(groot,'defaultTextInterpreter','tex');
set(groot,'defaultAxesTickLabelInterpreter','tex');
set(groot,'defaultLegendInterpreter','tex');

% ---------------------------------------------------------------------------
% EEGLAB
% ---------------------------------------------------------------------------
% Se topoplot non è nel path, decommenta e adatta:
%
% addpath('C:\Users\mirco\Desktop\eeglab2026.1.0')
% eeglab nogui

%% ============================================================
% PATHS
%% ============================================================

step2_indir = fullfile( ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO');

step4_outroot = fullfile( ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO', ...
    'STEP4A_BANDPOWER');

comparisonName = 'Consonance';

outdir = fullfile(step4_outroot,comparisonName);

if ~exist(outdir,'dir')
    mkdir(outdir);
end

outdir_topoplots = fullfile(outdir,'Topoplots');

if ~exist(outdir_topoplots,'dir')
    mkdir(outdir_topoplots);
end

%% ============================================================
% LOAD STEP2 DATA
%% ============================================================

load(fullfile(step2_indir,'subj_list.mat'));

assert(~isempty(subj_list),'subj_list is empty.');

%% ============================================================
% CONFIGURATION
%% ============================================================

cfgBP = struct();
cfgBP.conditions = { ...
    'Consonant', ...
    'Dissonant'};

cfgBP.cond_field = 'eventLabel';
cfgBP.time_field = 'time';
cfgBP.baseline_win = [-0.2 0];
cfgBP.target_time_units = 's';

cfgBP.bands = struct();
cfgBP.bands.Delta     = [1 4];
cfgBP.bands.Theta     = [4 8];
cfgBP.bands.Alpha     = [8 13];
cfgBP.bands.BetaLow   = [13 20];
cfgBP.bands.BetaHigh  = [20 30];
cfgBP.bands.GammaLow  = [30 40];
cfgBP.bands.GammaHigh = [40 90];

cfgBP.normalization = 'db';

%% ============================================================
% TOPOPLOT CONFIGURATION
%% ============================================================

cfgTopo = struct();
cfgTopo.enable = true;

% Time windows in seconds.
cfgTopo.windows = { ...
    [0.17 0.22], ...
    [0.22 0.32], ...
    [0.45 0.55]};

cfgTopo.window_names = { ...
    'EarlyNeg_170_220ms', ...
    'Rebound_220_320ms', ...
    'Late_450_550ms'};

cfgTopo.conditions = { ...
    'Consonant', ...
    'Dissonant', ...
    'Difference'};

cfgTopo.maplimits = 'absmax';
cfgTopo.colormap = turbo;

% If your channel locations are not returned by
% extract_channel_bandpower, specify the field in subj_list:
%
% cfgTopo.chanlocs_source = 'subj';
% cfgTopo.chanlocs_field = 'chanlocs';
%
% Or provide an external chanlocs structure:
%
% cfgTopo.chanlocs_source = 'external';
% load('chanlocs.mat','chanlocs');
% cfgTopo.chanlocs = chanlocs;

cfgTopo.chanlocs_source = 'auto';

%% ============================================================
% PLOT SETTINGS
%% ============================================================

cfgPlot = struct();
cfgPlot.save_png = true;
cfgPlot.save_fig = false;
cfgPlot.electrodes = 'labelpoint';

%% ============================================================
% QUALITY CHECK
%% ============================================================

num_trials = cellfun( ...
    @(x) numel(x), ...
    {subj_list.data_trials});

total_trials = sum(num_trials);

QC = struct();
QC.nSubjects = numel(subj_list);
QC.totalTrials = total_trials;
QC.trialsPerSubject = num_trials;
QC.comparisonName = comparisonName;
QC.conditions = cfgBP.conditions;
QC.baselineWindow = cfgBP.baseline_win;
QC.normalization = cfgBP.normalization;
QC.timeUnits = cfgBP.target_time_units;
QC.bandDefinitions = cfgBP.bands;
QC.topoWindows = cfgTopo.windows;
QC.topoWindowNames = cfgTopo.window_names;

fprintf('\n');
fprintf('================================\n');
fprintf('CHANNEL-LEVEL BANDPOWER TOPOPLOTS\n');
fprintf('================================\n');
fprintf('Subjects: %d\n',QC.nSubjects);
fprintf('Trials:   %d\n',QC.totalTrials);
fprintf('Bands:    %d\n',numel(fieldnames(cfgBP.bands)));
fprintf('Windows:  %d\n',numel(cfgTopo.windows));
fprintf('Normalization: %s\n',cfgBP.normalization);

%% ============================================================
% INITIALIZE OUTPUT
%% ============================================================

BandPower_Channel = struct();
BandPower_Channel_Group = struct();

bandNames = fieldnames(cfgBP.bands);

%% ============================================================
% SUBJECT-LEVEL CHANNEL BANDPOWER
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('SUBJECT-LEVEL CHANNEL BANDPOWER\n');
fprintf('================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);
    subjID = matlab.lang.makeValidName(char(subj_curr.subj_id));

    fprintf('\n[%02d/%02d] Subject: %s\n', ...
        iSub,numel(subj_list),subjID);

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        cfgCurr = cfgBP;
        cfgCurr.band = cfgBP.bands.(bandName);
        cfgCurr.band_name = bandName;

        bp_channel = extract_channel_bandpower(subj_curr,cfgCurr);

        BandPower_Channel.(subjID).(bandName) = bp_channel;

        fprintf('   %s OK\n',bandName);

    end
end

%% ============================================================
% GROUP-LEVEL CHANNEL BANDPOWER
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('GROUP-LEVEL CHANNEL BANDPOWER\n');
fprintf('================================\n');

for b = 1:numel(bandNames)

    bandName = bandNames{b};

    fprintf('%s\n',bandName);

    BandPower_Channel_Group.(bandName) = ...
        average_group_channel_bandpower( ...
        BandPower_Channel, ...
        bandName);

end

%% ============================================================
% GET CHANNEL LOCATIONS
%% ============================================================

chanlocs = get_topo_chanlocs( ...
    subj_list, ...
    BandPower_Channel, ...
    cfgTopo);

if isempty(chanlocs)
    error('Channel locations not found. Check cfgTopo.chanlocs_source.');
end

%% ============================================================
% CREATE TOPOPLOTS
%% ============================================================

if cfgTopo.enable

    fprintf('\n');
    fprintf('================================\n');
    fprintf('CREATING TOPOPLOTS\n');
    fprintf('================================\n');

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        bandDir = fullfile(outdir_topoplots,bandName);

        if ~exist(bandDir,'dir')
            mkdir(bandDir);
        end

        bpGroup = BandPower_Channel_Group.(bandName);

        for w = 1:numel(cfgTopo.windows)

            win = cfgTopo.windows{w};
            winName = cfgTopo.window_names{w};

            % Extract channel means in the current time window.
            valuesCon = mean_channel_window( ...
                bpGroup.Consonant.power, ...
                bpGroup.time, ...
                win);

            valuesDis = mean_channel_window( ...
                bpGroup.Dissonant.power, ...
                bpGroup.time, ...
                win);

            valuesDiff = valuesDis - valuesCon;

            % Common color scale across the three maps.
            allValues = [valuesCon(:); valuesDis(:); valuesDiff(:)];
            absMax = max(abs(allValues));

            if isnan(absMax) || absMax == 0
                absMax = 1;
            end

            % ----------------------------------------------------
            % CONSONANT
            % ----------------------------------------------------
            if ismember('Consonant',cfgTopo.conditions)
                make_topoplot( ...
                    valuesCon, ...
                    chanlocs, ...
                    sprintf('%s | %s | Consonant', ...
                    bandName,winName), ...
                    cfgTopo, ...
                    cfgPlot, ...
                    absMax, ...
                    fullfile(bandDir, ...
                    sprintf('%s_%s_Consonant.png', ...
                    bandName,winName)));
            end

            % ----------------------------------------------------
            % DISSONANT
            % ----------------------------------------------------
            if ismember('Dissonant',cfgTopo.conditions)
                make_topoplot( ...
                    valuesDis, ...
                    chanlocs, ...
                    sprintf('%s | %s | Dissonant', ...
                    bandName,winName), ...
                    cfgTopo, ...
                    cfgPlot, ...
                    absMax, ...
                    fullfile(bandDir, ...
                    sprintf('%s_%s_Dissonant.png', ...
                    bandName,winName)));
            end

            % ----------------------------------------------------
            % DIFFERENCE
            % ----------------------------------------------------
            if ismember('Difference',cfgTopo.conditions)
                make_topoplot( ...
                    valuesDiff, ...
                    chanlocs, ...
                    sprintf('%s | %s | Dissonant - Consonant', ...
                    bandName,winName), ...
                    cfgTopo, ...
                    cfgPlot, ...
                    absMax, ...
                    fullfile(bandDir, ...
                    sprintf('%s_%s_Difference.png', ...
                    bandName,winName)));
            end

            fprintf('   %s | %s OK\n',bandName,winName);

        end
    end
end

%% ============================================================
% SAVE CHANNEL-LEVEL RESULTS
%% ============================================================

resultFile = fullfile(outdir, ...
    'BANDPOWER_STEP4A_CHANNEL_RESULTS.mat');

save(resultFile, ...
    'BandPower_Channel', ...
    'BandPower_Channel_Group', ...
    'QC', ...
    'cfgBP', ...
    'cfgTopo', ...
    '-v7.3');

%% ============================================================
% RESTORE SETTINGS
%% ============================================================

close all
set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('================================\n');
fprintf('STEP4 BANDPOWER TOPOPLOTS COMPLETED\n');
fprintf('================================\n');
fprintf('Results:\n%s\n',resultFile);
fprintf('Plots:\n%s\n',outdir_topoplots);

%% =========================================================================
% LOCAL FUNCTIONS
%% =========================================================================

function chanlocs = get_topo_chanlocs(subj_list,BandPower_Channel,cfgTopo)

    chanlocs = [];

    switch lower(cfgTopo.chanlocs_source)

        case 'external'
            if isfield(cfgTopo,'chanlocs')
                chanlocs = cfgTopo.chanlocs;
            end

        case 'subj'
            if isfield(cfgTopo,'chanlocs_field') && ...
                    isfield(subj_list(1),cfgTopo.chanlocs_field)
                chanlocs = subj_list(1).(cfgTopo.chanlocs_field);
            end

        otherwise
            % Try to find chanlocs inside the first subject/channel result.
            subjNames = fieldnames(BandPower_Channel);
            bandNames = fieldnames(BandPower_Channel.(subjNames{1}));
            bp = BandPower_Channel.(subjNames{1}).(bandNames{1});

            if isfield(bp,'chanlocs')
                chanlocs = bp.chanlocs;
            elseif isfield(bp,'chanlocsGroup')
                chanlocs = bp.chanlocsGroup;
            end
    end

end

function values = mean_channel_window(powerMatrix,timeVector,timeWindow)

    % powerMatrix is expected as [nChannels x nTime].
    if size(powerMatrix,1) == numel(timeVector) && ...
            size(powerMatrix,2) ~= numel(timeVector)
        powerMatrix = powerMatrix.';
    end

    idx = timeVector >= timeWindow(1) & ...
        timeVector <= timeWindow(2);

    if ~any(idx)
        error('No samples found in window [%g %g].', ...
            timeWindow(1),timeWindow(2));
    end

    values = mean(powerMatrix(:,idx),2);

end

function make_topoplot(values,chanlocs,plotTitle,cfgTopo,cfgPlot,absMax,outFile)

    figH = figure( ...
        'Color','w', ...
        'Position',[100 100 700 650]);

    ax = axes(figH);

    topoplot( ...
        values(:).', ...
        chanlocs, ...
        'style','map', ...
        'maplimits',[-absMax absMax], ...
        'colormap',cfgTopo.colormap, ...
        'electrodes',cfgPlot.electrodes, ...
        'chaninfo',chanlocs);

    title(plotTitle);
    colorbar;

    axis square
    axis off

    if cfgPlot.save_png
        saveas(figH,outFile);
    end

    if cfgPlot.save_fig
        [pathstr,name,] = fileparts(outFile);
        figFile = fullfile(pathstr,[name '.fig']);
        savefig(figH,figFile);
    end

    close(figH);

end