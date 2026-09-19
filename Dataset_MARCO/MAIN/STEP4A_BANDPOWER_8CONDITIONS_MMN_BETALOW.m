%% =========================================================================
% STEP4A_BANDPOWER_8CONDITIONS_MMN_BETALOW
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD DATA
%% ============================================================

step2_indir = ...
'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA';

files = dir(fullfile(step2_indir,'*_epochData.mat'));

nFiles = numel(files);

subj_list = struct( ...
    'subj_id',cell(nFiles,1),...
    'data_trials',cell(nFiles,1));

for i = 1:nFiles

    S = load(fullfile( ...
        files(i).folder,...
        files(i).name));

    subj_list(i).subj_id = ...
        S.subjectEpochData.subjectID;

    subj_list(i).data_trials = ...
        S.subjectEpochData.data_trials;

end

%% ============================================================
% CONFIG
%% ============================================================

cfgBP = struct();

cfgBP.conditions = { ...
    'ConsonantGOAL',...
    'DissonantGOAL',...
    'ControlGOAL',...
    'ConsonantNoGOAL',...
    'DissonantNoGOAL',...
    'ControlNoGOAL',...
    'Consonant',...
    'Dissonant'};

cfgBP.cond_field = 'eventLabel';

cfgBP.time_field = 'time';

cfgBP.baseline_win = [-0.2 0];

cfgBP.normalization = 'db';

%% ============================================================
% MMN ROI
%% ============================================================

MAIN_ROI

cfgBP.rois = ROI;

cfgBP.analysis_rois = {'MMN'};

%% ============================================================
% BETALOW ONLY
%% ============================================================

cfgBP.bands = struct();

cfgBP.bands.BetaLow = [13 20];

%% ============================================================
% OUTPUT
%% ============================================================

outdir = ...
'D:\X-SONANCE\Dataset_MARCO\STEP4A_MMN_BETALOW_8CONDITIONS';

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% SUBJECT LEVEL
%% ============================================================

BandPower_Subj = struct();

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);

    subjID = ...
        matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    cfgCurr = cfgBP;

    cfgCurr.roi_labels = ...
        ROI.MMN;

    cfgCurr.band = ...
        cfgBP.bands.BetaLow;

    BandPower_Subj.(subjID).MMN.BetaLow = ...
        extract_roi_bandpower( ...
        subj_curr,...
        cfgCurr);

end

%% ============================================================
% GROUP LEVEL
%% ============================================================

BandPower_Group = ...
    average_group_bandpower( ...
    BandPower_Subj,...
    'MMN',...
    'BetaLow');
%% ============================================================
% WAVEFORM PLOT
%% ============================================================

cfgPlot = struct();

cfgPlot.plot_window = [-0.2 0.8];
cfgPlot.doLIMO = false;
cfgPlot.alpha = 0.05;

plot_bandpower_waveforms( ...
    BandPower_Group,...
    'MMN',...
    'BetaLow',...
    outdir,...
    cfgPlot);

%% ============================================================
% MEAN POWER (200-800 ms)
%% ============================================================

statsWindow = [0.20 0.80];

subs = fieldnames(BandPower_Subj);

Results = table();

for c = 1:numel(cfgBP.conditions)

    condName = cfgBP.conditions{c};

    values = nan(numel(subs),1);

    for s = 1:numel(subs)

        BP = ...
            BandPower_Subj.(subs{s}) ...
            .MMN ...
            .BetaLow;

        idxTime = ...
            BP.time >= statsWindow(1) & ...
            BP.time <= statsWindow(2);

        values(s) = ...
            mean(BP.(condName).waveform(idxTime));

    end

    T = table( ...
        repmat(string(condName),numel(values),1), ...
        string(subs(:)), ...
        values, ...
        'VariableNames',{ ...
        'Condition', ...
        'Subject', ...
        'MeanPower'});

    Results = [Results; T];

end

%% ============================================================
% SAVE EXCEL
%% ============================================================

writetable( ...
    Results,...
    fullfile(outdir,...
    'MMN_BetaLow_8Conditions.xlsx'));

%% ============================================================
% BOXPLOT
%% ============================================================

figure('Color','w');

boxchart( ...
    categorical(Results.Condition),...
    Results.MeanPower);

ylabel('Mean BetaLow Power');

title('MMN BetaLow (200-800 ms)');

grid on

xtickangle(30)

saveas( ...
    gcf,...
    fullfile(outdir,...
    'MMN_BetaLow_Boxplot.png'));

close

%% ============================================================
% CONDITION SUMMARY
%% ============================================================

Summary = groupsummary( ...
    Results,...
    'Condition',...
    {'mean','std'},...
    'MeanPower');

writetable( ...
    Summary,...
    fullfile(outdir,...
    'MMN_BetaLow_ConditionSummary.xlsx'));

disp(Summary)

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'MMN_BetaLow_8Conditions.mat'),...
    'BandPower_Subj',...
    'BandPower_Group',...
    'Results',...
    'Summary',...
    'cfgBP',...
    '-v7.3');

%% ============================================================
% END
%% ============================================================

set(0,'DefaultFigureVisible',origState);

fprintf('\n');
fprintf('====================================\n');
fprintf('MMN BETALOW 8 CONDITIONS COMPLETED\n');
fprintf('====================================\n');