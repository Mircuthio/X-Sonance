%% =========================================================================
% STEP4A_TOPOPLOT_MMN_SELECTED
%
% Focused BandPower Topoplots
%
% ROI rationale:
%     MMN
%
% Bands:
%     Alpha
%     Theta
%     BetaLow
%
% Windows:
%     100-200 ms
%     200-400 ms
%     100-800 ms
%
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');
set(groot,...
    'defaultTextInterpreter','tex');
set(groot,...
    'defaultAxesTickLabelInterpreter','tex');
set(groot,...
    'defaultLegendInterpreter','tex');
% addpath('C:\Users\mirco\Desktop\eeglab2026.1.0')
% eeglab nogui
%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

%% =========================================================================
% LOAD
%% =========================================================================

load(fullfile(step2_indir,'subj_list.mat'));

assert(~isempty(subj_list), ...
    'subj_list is empty.')

%% ============================================================
% CONFIG
%% ============================================================

cfgBP = struct();

cfgBP.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgBP.cond_field = 'eventLabel';

cfgBP.baseline_win = [-0.2 0];

cfgBP.normalization = 'db';

%% ------------------------------------------------------------
% BANDS
%% ------------------------------------------------------------

cfgBP.bands = struct();

cfgBP.bands.Theta   = [4 8];
cfgBP.bands.Alpha   = [8 13];
cfgBP.bands.BetaLow = [13 20];

bandNames = fieldnames(cfgBP.bands);

%% ============================================================
% OUTPUT
%% ============================================================

outdir = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO\STEP4A_TOPOPLOT_MMN';

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% SUBJECT CHANNEL BANDPOWER
%% ============================================================

BandPower_Channel = struct();

fprintf('\n');
fprintf('=======================================\n');
fprintf('CHANNEL BANDPOWER\n');
fprintf('=======================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);

    subjID = matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    fprintf('\n[%02d/%02d] %s\n',...
        iSub,...
        numel(subj_list),...
        subjID);

    for b = 1:numel(bandNames)

        bandName = bandNames{b};

        fprintf('   %s\n',bandName);

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
% GROUP LEVEL
%% ============================================================

BandPower_Channel_Group = struct();

fprintf('\n');
fprintf('=======================================\n');
fprintf('GROUP AVERAGE\n');
fprintf('=======================================\n');

for b = 1:numel(bandNames)

    bandName = bandNames{b};

    fprintf('%s\n',bandName);

    BandPower_Channel_Group.(bandName) = ...
        average_group_channel_bandpower( ...
        BandPower_Channel,...
        bandName);

end

%% ============================================================
% TOPOPLOT CONFIGURATION
%% ============================================================

cfgTopo = struct();

cfgTopo.windows = {
    [0.10 0.20]
    [0.20 0.40]
    [0.10 0.80]
};

cfgTopo.window_names = {
    'Early100_200'
    'Late200_400'
    'Full100_800'
};

cfgTopo.conditions = {
    'Consonant'
    'Dissonant'
    'Difference'
};

cfgTopo.maplimits = 'absmax';

cfgTopo.colormap = turbo;

%% ============================================================
% PLOTS
%% ============================================================

fprintf('\n');
fprintf('=======================================\n');
fprintf('TOPOPLOTS\n');
fprintf('=======================================\n');

for b = 1:numel(bandNames)

    bandName = bandNames{b};

    fprintf('%s\n',bandName);

    plot_bandpower_topoplot( ...
        BandPower_Channel_Group.(bandName),...
        bandName,...
        cfgTopo,...
        outdir);

end

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'MMN_TOPOPLOT_RESULTS.mat'),...
    'BandPower_Channel',...
    'BandPower_Channel_Group',...
    'cfgBP',...
    'cfgTopo',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('=======================================\n');
fprintf('DONE\n');
fprintf('=======================================\n');