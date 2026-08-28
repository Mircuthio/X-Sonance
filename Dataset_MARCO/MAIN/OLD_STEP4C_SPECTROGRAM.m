%% =========================================================================
% STEP4_SPECTROGRAM
% MAIN_SPECTROGRAM_STEP4
%% =========================================================================
%
% PROJECT
% -------
% X-SONANCE EEG
%
% PURPOSE
% -------
% ROI-based ERP spectrogram visualization.
%
% Pipeline:
%
% Subject
%   ->
% ROI average
%   ->
% Trial average
%   ->
% Condition ERP
%   ->
% Group ERP
%   ->
% Spectrogram
%
% Outputs:
%
%   Consonant
%   Dissonant
%   Difference
%
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

load(fullfile(step2_indir,'subj_list.mat'));

%% ============================================================
% CONFIG
%% ============================================================

cfgSpec = struct();

cfgSpec.conditions = { ...
    'Consonant' ...
    'Dissonant'};

cfgSpec.cond_field = 'eventLabel';

cfgSpec.roi = 'ERAN_CORE';

cfgSpec.time_window = [-0.2 0.8];

cfgSpec.window_length = 64;
cfgSpec.overlap = 32;
cfgSpec.nfft = 256;

cfgSpec.freq_limits = [1 90];

cfgSpec.interp_n = 300;

cfgSpec.clim = [];

%% ============================================================
% TIME WINDOW
%% ============================================================

timeVec = subj_list(1).data_trials(1).time;

time_idx = ...
    timeVec >= cfgSpec.time_window(1) & ...
    timeVec <= cfgSpec.time_window(2);

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

roi_labels = ROI.(cfgSpec.roi);

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    step2_indir,...
    'SPECTROGRAM_STEP4');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% SUBJECT ERP
%% ============================================================

ERP_Subj = struct();

for iSub = 1:numel(subj_list)

    subj_curr = subj_list(iSub);

    subjID = matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    fprintf('[%02d/%02d] %s\n', ...
        iSub,...
        numel(subj_list),...
        subjID);

    data_trials = subj_curr.data_trials;

    for ic = 1:numel(cfgSpec.conditions)

        condName = cfgSpec.conditions{ic};

        idxCond = strcmp( ...
            {data_trials.(cfgSpec.cond_field)}, ...
            condName);

        trials_cond = data_trials(idxCond);

        ERP_trials = nan( ...
            numel(trials_cond), ...
            sum(time_idx));

        for iTr = 1:numel(trials_cond)

            eeg = trials_cond(iTr).eeg;

            labels = { ...
                trials_cond(iTr).chanlocs.labels};

            roi_idx = ismember( ...
                labels,...
                roi_labels);

            roi_signal = ...
                mean(eeg(roi_idx,:),1);

            roi_signal = ...
                roi_signal(time_idx);

            ERP_trials(iTr,:) = roi_signal;

        end

        ERP_Subj.(subjID).(condName) = ...
            mean(ERP_trials,1);

    end

    ERP_Subj.(subjID).time = ...
        timeVec(time_idx);

end

%% ============================================================
% GROUP ERP
%% ============================================================

subjNames = fieldnames(ERP_Subj);

ERP_CON = [];
ERP_DIS = [];

for i = 1:numel(subjNames)

    ERP_CON(i,:) = ...
        ERP_Subj.(subjNames{i}).Consonant;

    ERP_DIS(i,:) = ...
        ERP_Subj.(subjNames{i}).Dissonant;

end

GroupERP.time = ...
    ERP_Subj.(subjNames{1}).time;

GroupERP.Consonant = ...
    mean(ERP_CON,1);

GroupERP.Dissonant = ...
    mean(ERP_DIS,1);

GroupERP.Difference = ...
    GroupERP.Dissonant - ...
    GroupERP.Consonant;

%% ============================================================
% SAMPLE RATE
%% ============================================================

fs = ...
    subj_list(1).data_trials(1).srate;

fprintf('Fs = %d Hz\n',fs);

%% ============================================================
% COMPUTE SPECTROGRAMS
%% ============================================================

conditions = { ...
    'Consonant' ...
    'Dissonant' ...
    'Difference'};

Spectrogram_Group = struct();

for ic = 1:numel(conditions)

    condName = conditions{ic};

    signal = ...
        GroupERP.(condName);

    [S,F,T] = spectrogram( ...
        signal,...
        hamming(cfgSpec.window_length),...
        cfgSpec.overlap,...
        cfgSpec.nfft,...
        fs);

    % allineamento asse temporale ERP
    T = T + GroupERP.time(1);

    idxFreq = ...
        F >= cfgSpec.freq_limits(1) & ...
        F <= cfgSpec.freq_limits(2);

    F = F(idxFreq);

    P = ...
        10*log10(abs(S(idxFreq,:)).^2);

    minFinite = ...
        min(P(isfinite(P)));

    P(~isfinite(P)) = minFinite;

    [X,Y] = meshgrid(double(T),double(F));

    [Xq,Yq] = meshgrid( ...
        linspace(double(min(T)),double(max(T)),cfgSpec.interp_n), ...
        linspace(double(min(F)),double(max(F)),cfgSpec.interp_n));

    Pinterp = interp2(X,Y,double(P),Xq,Yq,'spline');

    Spectrogram_Group.(condName).F = Yq(:,1);
    Spectrogram_Group.(condName).T = Xq(1,:);
    Spectrogram_Group.(condName).P = Pinterp;

end

%% ============================================================
% COMMON COLOR SCALE
%% ============================================================

allP = [];

for ic = 1:numel(conditions)

    condName = conditions{ic};

    allP = [ ...
        allP;
        Spectrogram_Group.(condName).P(:)];

end

clims = [ ...
    min(allP) ...
    max(allP)];

%% ============================================================
% INDIVIDUAL PLOTS
%% ============================================================

conds = fieldnames(Spectrogram_Group);

for i = 1:numel(conds)

    condName = conds{i};

    figure('Color','w');

    imagesc( ...
        Spectrogram_Group.(condName).T,...
        Spectrogram_Group.(condName).F,...
        Spectrogram_Group.(condName).P);

    axis xy

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    title(sprintf( ...
        '%s | %s', ...
        cfgSpec.roi,...
        condName))

    ylim(cfgSpec.freq_limits)

    colormap(turbo)

    colorbar

    clim(clims)

    exportgraphics( ...
        gcf,...
        fullfile(outdir,...
        sprintf('%s_%s.png', ...
        cfgSpec.roi,...
        condName)),...
        'Resolution',300);

    close

end

%% ============================================================
% 3 PANEL FIGURE
%% ============================================================

figure( ...
    'Color','w',...
    'Position',[100 100 1600 500]);

for i = 1:3

    condName = conditions{i};

    subplot(1,3,i)

    imagesc( ...
        Spectrogram_Group.(condName).T,...
        Spectrogram_Group.(condName).F,...
        Spectrogram_Group.(condName).P);

    axis xy

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    ylim(cfgSpec.freq_limits)

    title(condName)

    colormap(turbo)

    colorbar

    clim(clims)

end

sgtitle(sprintf( ...
    '%s Spectrogram', ...
    cfgSpec.roi));

exportgraphics( ...
    gcf,...
    fullfile(outdir,...
    sprintf('%s_3Panel.png', ...
    cfgSpec.roi)),...
    'Resolution',300);

close

%% ============================================================
% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'Spectrogram_STEP4.mat'),...
    'ERP_Subj',...
    'GroupERP',...
    'Spectrogram_Group',...
    'cfgSpec',...
    '-v7.3');

set(0,'DefaultFigureVisible',origState);

disp('STEP4 SPECTROGRAM COMPLETED');