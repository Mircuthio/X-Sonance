%% =========================================================================
% MAIN_BANDPOWER_TEST
%% =========================================================================

% clear
% close all
% clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD SUBJECT LIST
%% ============================================================
% 
% load('subj_list.mat')
% 
% % 1 soggetto
% subj_list = subj_list(1);

% oppure:
% subj_list = subj_list(1:min(3,numel(subj_list)));

%% ============================================================
% CONFIGURATION
%% ============================================================

comparisonName = 'TEST_GAMMA';

cfgBP = struct();

cfgBP.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgBP.cond_field = 'eventLabel';
cfgBP.time_field = 'time';

cfgBP.baseline_win = [-0.2 0];

cfgBP.target_time_units = 's';

cfgBP.normalization = 'db';

%% ============================================================
% SINGLE BAND
%% ============================================================

cfgBP.bands = struct();

cfgBP.bands.GammaLow = [30 40];

% alternativa
% cfgBP.bands.GammaHigh = [40 90];

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

cfgBP.rois = ROI;

cfgBP.analysis_rois = { ...
    'ERAN_CORE'};

roiNames = cfgBP.analysis_rois;
bandNames = fieldnames(cfgBP.bands);

%% ============================================================
% TOPOPLOT
%% ============================================================

cfgTopo = struct();

cfgTopo.enable = true;

cfgTopo.windows = { ...
    [0.10 0.25]};

cfgTopo.window_names = { ...
    '100_250ms'};

cfgTopo.conditions = { ...
    'Difference'};

cfgTopo.maplimits = 'absmax';
cfgTopo.colormap = turbo;

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    pwd,...
    'BANDPOWER_TEST');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

outdir_waveforms = ...
    fullfile(outdir,'Waveforms');

if ~exist(outdir_waveforms,'dir')
    mkdir(outdir_waveforms);
end

outdir_topoplots = ...
    fullfile(outdir,'Topoplots');

if ~exist(outdir_topoplots,'dir')
    mkdir(outdir_topoplots);
end

%% ============================================================
% INITIALIZE
%% ============================================================

BandPower_Subj = struct();
BandPower_Group = struct();

BandPower_Channel = struct();
BandPower_Channel_Group = struct();

%% ============================================================
% SUBJECT LEVEL
%% ============================================================

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);

    subjID = matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        for b = 1:numel(bandNames)

            bandName = bandNames{b};

            cfgCurr = cfgBP;

            cfgCurr.roi_labels = ...
                cfgBP.rois.(roiName);

            cfgCurr.band = ...
                cfgBP.bands.(bandName);

            cfgCurr.band_name = bandName;

            roi_bp = ...
                extract_roi_bandpower( ...
                subj_curr,...
                cfgCurr);

            BandPower_Subj.(subjID) ...
                .(roiName) ...
                .(bandName) = roi_bp;

        end
    end

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        cfgCurr = cfgBP;

        cfgCurr.band = ...
            cfgBP.bands.(bandName);

        bp_channel = ...
            extract_channel_bandpower( ...
            subj_curr,...
            cfgCurr);

        BandPower_Channel.(subjID) ...
            .(bandName) = bp_channel;

    end

end

%% ============================================================
% GROUP
%% ============================================================

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        BandPower_Group.(roiName).(bandName) = ...
            average_group_bandpower( ...
            BandPower_Subj,...
            roiName,...
            bandName);

    end
end

%% ============================================================
% GROUP CHANNEL
%% ============================================================

for b = 1:numel(bandNames)

    bandName = bandNames{b};

    BandPower_Channel_Group.(bandName) = ...
        average_group_channel_bandpower( ...
        BandPower_Channel,...
        bandName);

end

%% ============================================================
% WAVEFORM PLOT
%% ============================================================

cfgPlot = struct();

cfgPlot.plot_window = [-0.2 0.8];
cfgPlot.doLIMO = false;
cfgPlot.alpha = 0.05;

plot_bandpower_waveforms( ...
    BandPower_Group.ERAN_CORE.(bandNames{1}), ...
    'ERAN_CORE',...
    bandNames{1},...
    outdir_waveforms,...
    cfgPlot);

%% ============================================================
% TOPOPLOT
%% ============================================================

if cfgTopo.enable

    plot_bandpower_topoplot( ...
        BandPower_Channel_Group.(bandNames{1}),...
        bandNames{1},...
        cfgTopo,...
        outdir_topoplots);

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'BandPower_TEST.mat'),...
    'BandPower_Subj',...
    'BandPower_Group',...
    'BandPower_Channel',...
    'BandPower_Channel_Group',...
    'cfgBP',...
    'cfgTopo');

set(0,'DefaultFigureVisible',origState);

disp('TEST COMPLETED')