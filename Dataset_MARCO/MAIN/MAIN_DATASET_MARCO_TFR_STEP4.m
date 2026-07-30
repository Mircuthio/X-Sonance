%% =========================================================================
% MAIN_DATASET_MARCO_TFR_STEP4
% =========================================================================
%
% PROJECT
% -------
% X-SONANCE EEG
%
% PURPOSE
% -------
% Time-Frequency analysis for replication of:
%
% Park et al. (2011)
% "Consonant chords stimulate higher EEG gamma activity
% than dissonant chords"
%
% Current comparison:
%
% Trigger 7 = Consonant
% Trigger 8 = Dissonant
%
%
% =========================================================================
% ANALYSIS STRATEGIES
% =========================================================================
%
% Two alternative ROI implementations are supported.
%
% -------------------------------------------------------------------------
% METHOD 1 : CHANNEL-FIRST (OFFICIAL ANALYSIS)
% -------------------------------------------------------------------------
%
% This is the primary pipeline used for all scientific analyses.
%
% Processing:
%
% Trial
%   ↓
% Each ROI channel separately
%   ↓
% Morlet Wavelet Transform
%   ↓
% Power = |Z|²
%   ↓
% Baseline correction
%   ↓
% Average power across ROI channels
%   ↓
% Average power across trials
%   ↓
% Subject TFR
%   ↓
% Group TFR
%
% Advantages:
%
% - Preserves channel-specific oscillatory activity
% - Avoids signal cancellation before TFR estimation
% - Standard approach in modern EEG TFR analyses
% - Recommended for publication-quality analyses
%
%
% -------------------------------------------------------------------------
% METHOD 2 : ROI-FIRST (PARK-STYLE REPLICA)
% -------------------------------------------------------------------------
%
% Implemented separately for methodological comparison.
%
% Processing:
%
% Trial
%   ↓
% Average EEG channels within ROI
%   ↓
% Single ROI signal
%   ↓
% Morlet Wavelet Transform
%   ↓
% Power = |Z|²
%   ↓
% Baseline correction
%   ↓
% Average power across trials
%
% Notes:
%
% - Computationally simpler
% - May reduce oscillatory activity if channels are
%   not perfectly phase aligned
% - Potentially closer to the original Park et al.
%   implementation, although the paper does not
%   explicitly report the exact ROI processing order.
%
%
% =========================================================================
% CURRENT IMPLEMENTATION
% =========================================================================
%
% cfgTFR.method = 'channel_first'
%
% The project currently uses METHOD 1.
%
%
% =========================================================================
% STEP4 OBJECTIVES
% =========================================================================
%
% Generate:
%
% 1) Subject-level induced gamma TFR
% 2) Group-level induced gamma TFR
% 3) Consonant Time-Frequency Maps
% 4) Dissonant Time-Frequency Maps
% 5) Mean Gamma Time Courses
%
%
% =========================================================================
% STEP5 CONNECTION
% =========================================================================
%
% Outputs generated here will be used by STEP5
% for replication of Figure 3.
%
% Planned statistical window:
%
% Frequency:
%   30-60 Hz
%
% Time:
%   100-250 ms
%
%
% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

addpath(genpath('D:\eeglab2026.0.0\'))

%% ============================================================
% LOAD STEP2 DATA
%% ============================================================

step2_indir = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials\EPOCH_DATA';

if ~exist(step2_indir,'dir')
    error('STEP2 folder not found:\n%s',step2_indir);
end

files = dir(fullfile(step2_indir,'*_epochData.mat'));

if isempty(files)
    error('No epoch files found');
end

nFiles = numel(files);

subj_list = struct( ...
    'subj_id',cell(nFiles,1), ...
    'data_trials',cell(nFiles,1));

for i = 1:nFiles

    S = load(fullfile(files(i).folder,files(i).name));

    subjData = S.subjectEpochData;
    assert(isfield(subjData,'data_trials'), ...
        'data_trials missing');

    assert(~isempty(subjData.data_trials), ...
        'Empty data_trials');

    subj_list(i).subj_id = subjData.subjectID;

    subj_list(i).data_trials = ...
        subjData.data_trials;

    fprintf('[%02d/%02d] Loaded %s\n',i,nFiles,string(subjData.subjectID));
end
% Time check
time0 = subj_list(1).data_trials(1).time;

for i = 1:numel(subj_list)
    t = subj_list(i).data_trials(1).time;
    assert(isequal(size(t),size(time0)), ...
        'Time vector size mismatch');
end
% Frequency check
Fs_all = zeros(numel(subj_list),1);
for i = 1:numel(subj_list)
    Fs_all(i) = ...
        subj_list(i).data_trials(1).srate;
end
assert(numel(unique(Fs_all))==1,...
    'Sampling rates differ across subjects');
fprintf('\n');
fprintf('=====================================\n');
fprintf('LOAD COMPLETED\n');
fprintf('Subjects : %d\n',numel(subj_list));
fprintf('Fs       : %.1f Hz\n',Fs_all(1));
fprintf('=====================================\n');
%% ============================================================
% CONFIGURATION
%% ============================================================

cfgTFR = struct();

cfgTFR.method = 'roi_first';

% available:
% 'channel_first'
% 'roi_first'

cfgTFR.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgTFR.cond_field = 'eventLabel';

cfgTFR.freqs = 30:1:60;

cfgTFR.nCycles = 7;

cfgTFR.baseline_win = [-0.2 -0.05];

cfgTFR.save_trial_level = false;

cfgTFR.srate = Fs_all(1);

cfgTFR.time = time0;
%% ============================================================
% ROI DEFINITIONS
%% ============================================================

MAIN_ROI_TFR

cfgTFR.rois = ParkROI;

roiNames = fieldnames(cfgTFR.rois);

fprintf('\n');
fprintf('=====================================\n');
fprintf('ROI CONFIGURATION\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    fprintf('%02d) %s\n', ...
        r,...
        roiNames{r});

    disp(cfgTFR.rois.(roiNames{r})')

end
%% ============================================================
% OUTPUT FOLDER
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'TFR_STEP4',cfgTFR.method);

if ~exist(outdir,'dir')
    mkdir(outdir);
end

fprintf('\n');
fprintf('Output folder:\n');
fprintf('%s\n',outdir);

%% ============================================================
% INITIALIZE OUTPUT
%% ============================================================

TFR_Subj = struct();
%% ============================================================
% SUBJECT LEVEL TFR
%% ============================================================

fprintf('\n');
fprintf('=====================================\n');
fprintf('SUBJECT LEVEL TFR\n');
fprintf('=====================================\n');

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);

    subjID = matlab.lang.makeValidName( ...
    char(subj_curr.subj_id));

    fprintf('\n');
    fprintf('-------------------------------------\n');
    fprintf('SUBJECT: %s\n',subjID);
    fprintf('-------------------------------------\n');
    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        fprintf('\n');
        fprintf('ROI : %s\n',roiName);

        cfgROI = cfgTFR;

        cfgROI.roi_labels = ...
            cfgTFR.rois.(roiName);
        roi_tfr = extract_roi_tfr( ...
            subj_curr,...
            cfgROI);
        if isempty(roi_tfr)

            warning('%s | %s empty result',...
                subjID,...
                roiName);

            continue

        end
        TFR_Subj.(subjID).(roiName) = ...
            roi_tfr;
        if isfield(roi_tfr,'Consonant')

            sz = size( ...
                roi_tfr.Consonant.power);

            fprintf( ...
                'Consonant TFR: [%d x %d]\n',...
                sz(1),...
                sz(2));

        end

        if isfield(roi_tfr,'Dissonant')

            sz = size( ...
                roi_tfr.Dissonant.power);

            fprintf( ...
                'Dissonant TFR: [%d x %d]\n',...
                sz(1),...
                sz(2));

        end
    end

end
%% ============================================================
% SANITY CHECK
%% ============================================================

fprintf('\n');
fprintf('=====================================\n');
fprintf('SANITY CHECK\n');
fprintf('=====================================\n');

subjectNames = fieldnames(TFR_Subj);

fprintf('Subjects processed: %d\n', ...
    numel(subjectNames));
%% ============================================================
% GROUP LEVEL TFR
%% ============================================================

TFR_Group = struct();

fprintf('\n');
fprintf('=====================================\n');
fprintf('GROUP LEVEL TFR\n');
fprintf('=====================================\n');

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    fprintf('Building ROI: %s\n',roiName);

    TFR_Group.(roiName) = ...
        average_group_tfr( ...
        TFR_Subj,...
        roiName);

end
for r=1:numel(roiNames)
    roiName = roiNames{r};
    groupData = ...
        TFR_Group.(roiName);

    gammaStats.(roiName) = ...
        extract_gamma_window( ...
        TFR_Group.(roiName),...
        [30 60],...
        [0.10 0.25]);
    stats = gammaStats.(roiName);

    fprintf('\n');
    fprintf('=====================================\n');
    fprintf('PARK WINDOW RESULTS\n');
    fprintf('ROI : %s\n',roiName);
    fprintf('Consonant : %.4f dB\n',stats.Consonant);
    fprintf('Dissonant : %.4f dB\n',stats.Dissonant);
    fprintf('Difference: %.4f dB\n',stats.Difference);
    fprintf('=====================================\n');

    diffMap = groupData.Difference.power;

    fprintf('\n');
    fprintf('ROI: %s\n',roiName);
    fprintf('Mean Difference: %.4f dB\n', ...
        mean(diffMap(:)));
    figure

    subplot(3,1,1)

    imagesc( ...
        groupData.time,...
        groupData.freq,...
        groupData.Consonant.power)

    axis xy
    colorbar

    title(sprintf('%s - Consonant',roiName))

    subplot(3,1,2)

    imagesc( ...
        groupData.time,...
        groupData.freq,...
        groupData.Dissonant.power)

    axis xy
    colorbar

    title(sprintf('%s - Dissonant',roiName))

    subplot(3,1,3)

    imagesc( ...
        groupData.time,...
        groupData.freq,...
        diffMap)

    axis xy
    colorbar

    title(sprintf('%s - Difference',roiName))
    saveas( ...
        gcf,...
        fullfile( ...
        outdir,...
        sprintf('TFR_Group_%s.png',roiName)));

    gammaConTime = ...
    mean(groupData.Consonant.power,1);
    gammaDisTime = ...
        mean(groupData.Dissonant.power,1);
    
    figure
    plot(groupData.time,...
        gammaConTime,...
        'LineWidth',2)
    hold on
    plot(groupData.time,...
        gammaDisTime,...
        'LineWidth',2)
    xline(0,'k')
    legend('Consonant','Dissonant')
    xlabel('Time (s)')
    ylabel('Power (dB)')
    title(sprintf('Gamma Time Course - %s',roiName))
    saveas( ...
        gcf,...
        fullfile( ...
        outdir,...
        sprintf('GammaTimeCourse_%s.png',roiName)));
end
%% ============================================================
% SAVE
%% ============================================================
assert(~isempty(fieldnames(TFR_Subj)), ...
    'No subject results generated');
save( ...
    fullfile(outdir,'TFR_Subj.mat'),...
    'TFR_Subj',...
    'TFR_Group',...
    'gammaStats',...
    'cfgTFR',...
    'ParkROI',...
    '-v7.3');

fprintf('\n');
fprintf('=====================================\n');
fprintf('STEP4 SUBJECT LEVEL SAVED\n');
fprintf('=====================================\n');

set(0,'DefaultFigureVisible',origState);