%% ============================================================
% TEST_SUBJ4_CLEAN_TFR
%% ============================================================

clear
close all
clc

%% ============================================================
% LOAD
%% ============================================================

load('subj_list.mat','subj_list');

MAIN_ROI

%% ============================================================
% SELECT SUBJECT
%% ============================================================

subjOrig = subj_list(4);

%% ============================================================
% REMOVE BAD TRIALS
%% ============================================================

badTrials = ...
    [359 817 1091 1145 1158 ...
     1180 1181 1191 1200 1573];

subjClean = subjOrig;

keepTrials = ...
    setdiff( ...
    1:numel(subjOrig.data_trials), ...
    badTrials);

subjClean.data_trials = ...
    subjOrig.data_trials(keepTrials);

fprintf('Original trials : %d\n', ...
    numel(subjOrig.data_trials));

fprintf('Clean trials    : %d\n', ...
    numel(subjClean.data_trials));

%% ============================================================
% TFR CONFIG
%% ============================================================

trial0 = subjOrig.data_trials(1);

cfg = struct();

cfg.method = 'channel_first';

cfg.conditions = ...
    {'Consonant','Dissonant'};

cfg.cond_field = 'eventLabel';

cfg.freqs = 1:1:90;

cfg.nCycles = 7;

cfg.baseline_win = [-0.2 -0.05];

cfg.srate = trial0.srate;

cfg.time = trial0.time(:)';

cfg.save_trial_level = false;

cfg.roi_labels = ROI.ERAN_CORE;

%% ============================================================
% COMPUTE TFR
%% ============================================================

fprintf('\nComputing ORIGINAL...\n');

tfrOrig = ...
    extract_roi_tfr_park( ...
    subjOrig, ...
    cfg);

fprintf('\nComputing CLEAN...\n');

tfrClean = ...
    extract_roi_tfr_park( ...
    subjClean, ...
    cfg);

%% ============================================================
% RANGE CHECK
%% ============================================================

fprintf('\n');
fprintf('============================\n');

fprintf('ORIGINAL\n');

fprintf('Con min %.2f max %.2f\n', ...
    min(tfrOrig.Consonant.power(:)), ...
    max(tfrOrig.Consonant.power(:)));

fprintf('Dis min %.2f max %.2f\n', ...
    min(tfrOrig.Dissonant.power(:)), ...
    max(tfrOrig.Dissonant.power(:)));

fprintf('============================\n');

fprintf('CLEAN\n');

fprintf('Con min %.2f max %.2f\n', ...
    min(tfrClean.Consonant.power(:)), ...
    max(tfrClean.Consonant.power(:)));

fprintf('Dis min %.2f max %.2f\n', ...
    min(tfrClean.Dissonant.power(:)), ...
    max(tfrClean.Dissonant.power(:)));

fprintf('============================\n');

%% ============================================================
% DIFFERENCE MAPS
%% ============================================================

diffOrig = ...
    tfrOrig.Consonant.power - ...
    tfrOrig.Dissonant.power;

diffClean = ...
    tfrClean.Consonant.power - ...
    tfrClean.Dissonant.power;

%% ============================================================
% TFR VISUAL COMPARISON
%% ============================================================

figure('Color','w',...
       'Position',[100 100 1300 900]);

subplot(2,2,1)

imagesc( ...
    tfrOrig.time,...
    tfrOrig.freq,...
    diffOrig);

axis xy
colorbar

title('Original Difference')

subplot(2,2,2)

imagesc( ...
    tfrClean.time,...
    tfrClean.freq,...
    diffClean);

axis xy
colorbar

title('Clean Difference')

subplot(2,2,3)

imagesc( ...
    tfrOrig.time,...
    tfrOrig.freq,...
    tfrOrig.Consonant.power);

axis xy
colorbar

title('Original Consonant')

subplot(2,2,4)

imagesc( ...
    tfrClean.time,...
    tfrClean.freq,...
    tfrClean.Consonant.power);

axis xy
colorbar

title('Clean Consonant')

%% ============================================================
% BAND COMPARISON
%% ============================================================

bands = struct();

bands.Theta = [4 8];
bands.BetaLow = [13 20];
bands.GammaLow = [30 60];

bandNames = fieldnames(bands);

figure('Color','w',...
       'Position',[100 100 1200 900]);

for b = 1:numel(bandNames)

    bandName = bandNames{b};

    frange = bands.(bandName);

    idxFreq = ...
        tfrOrig.freq >= frange(1) & ...
        tfrOrig.freq <= frange(2);

    tcOrig = mean( ...
        diffOrig(idxFreq,:), ...
        1,'omitnan');

    tcClean = mean( ...
        diffClean(idxFreq,:), ...
        1,'omitnan');

    subplot(numel(bandNames),1,b)

    plot( ...
        tfrOrig.time,...
        tcOrig,...
        'r',...
        'LineWidth',2)

    hold on

    plot( ...
        tfrClean.time,...
        tcClean,...
        'b',...
        'LineWidth',2)

    xline(0,'k--')

    legend( ...
        'Original',...
        'Clean')

    title(bandName)

    grid on

end

return
for s=1:5

    fprintf('\nSubj%d\n',s);
    
    sub = TFR_Subj.(subjNames{s}).ERAN_CORE;
    fprintf('Con mean %.2f\n', ...
        mean(sub.Consonant.power(:)));

    fprintf('Dis mean %.2f\n', ...
        mean(sub.Dissonant.power(:)));

    fprintf('Con max abs %.2f\n', ...
        max(abs(sub.Consonant.power(:))));

    fprintf('Dis max abs %.2f\n', ...
        max(abs(sub.Dissonant.power(:))));

    fprintf('Con max %.2f\n', ...
        max(sub.Consonant.power(:)));

    fprintf('Dis max %.2f\n', ...
        max(sub.Dissonant.power(:)));

    fprintf('Con min %.2f\n', ...
        min(sub.Consonant.power(:)));

    fprintf('Dis min %.2f\n', ...
        min(sub.Dissonant.power(:)));
end

color = {'b','r','g','m','c'};
RMStrial = struct();
for s=1:numel(subj_list)
    Subbi1 = subj_list(s);
    trialRMS = nan(1,numel(numel(Subbi1.data_trials)));
    for k = 1:numel(Subbi1.data_trials)
        eeg = Subbi1.data_trials(k).eeg;
        trialRMS(k) = rms(eeg(:));
    end
    RMStrial(s).RMS = trialRMS;
    figure
    plot(trialRMS,'o-','Color',color{s})
    grid on
    title(sprintf('subj %d',s))
    numel(find(trialRMS > 100))
end