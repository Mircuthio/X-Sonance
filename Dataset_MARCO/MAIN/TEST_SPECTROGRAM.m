%% =========================================================================
% MAIN_SPECTROGRAM_TEST
%% =========================================================================

clear
close all
clc

origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

%% ============================================================
% LOAD
%% ============================================================

load('subj_list.mat')

subj_list = subj_list(1:min(3,numel(subj_list)));

%% ============================================================
% CONFIG
%% ============================================================

cfgSpec = struct();

cfgSpec.conditions = { ...
    'Consonant',...
    'Dissonant'};

cfgSpec.cond_field = 'eventLabel';

cfgSpec.window_length = 64;
cfgSpec.overlap      = 32;
cfgSpec.nfft         = 256;

cfgSpec.freq_limits = [1 90];

cfgSpec.interp_n = 300;

%% ============================================================
% ROI
%% ============================================================

MAIN_ROI

cfgSpec.roi = 'ERAN_CORE';

roi_labels = ROI.(cfgSpec.roi);

%% ============================================================
% TIME WINDOW
%% ============================================================

timeVec = subj_list(1).data_trials(1).time;

time_idx = ...
    timeVec >= -0.2 & ...
    timeVec <= 0.8;

%% ============================================================
% OUTPUT
%% ============================================================

outdir = fullfile( ...
    pwd,...
    'SPECTROGRAM_TEST');

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

    data_trials = subj_curr.data_trials;

    fprintf('[%02d/%02d] %s\n', ...
        iSub,...
        numel(subj_list),...
        subjID);

    for ic = 1:numel(cfgSpec.conditions)

        condName = cfgSpec.conditions{ic};

        idxCond = strcmp( ...
            {data_trials.(cfgSpec.cond_field)},...
            condName);

        trials_cond = data_trials(idxCond);

        ERP_trials = nan( ...
            numel(trials_cond), ...
            sum(time_idx));

        for iTr = 1:numel(trials_cond)

            eeg = trials_cond(iTr).eeg;

            labels = ...
                {trials_cond(iTr).chanlocs.labels};

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

subs = fieldnames(ERP_Subj);

ERP_CON = [];
ERP_DIS = [];

for i = 1:numel(subs)

    ERP_CON(i,:) = ...
        ERP_Subj.(subs{i}).Consonant;

    ERP_DIS(i,:) = ...
        ERP_Subj.(subs{i}).Dissonant;

end

GroupERP.time = ...
    ERP_Subj.(subs{1}).time;

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

fs = subj_list(1).data_trials(1).srate;

fprintf('Fs = %d Hz\n',fs);

%% ============================================================
% SPECTROGRAMS
%% ============================================================

conditions = { ...
    'Consonant',...
    'Dissonant',...
    'Difference'};

Spec = struct();

for ic = 1:numel(conditions)

    condName = conditions{ic};

    signal = GroupERP.(condName);

    [S,F,T] = spectrogram( ...
        signal,...
        hamming(cfgSpec.window_length),...
        cfgSpec.overlap,...
        cfgSpec.nfft,...
        fs);

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

    Pinterp = interp2( ...
        X,...
        Y,...
        double(P),...
        Xq,...
        Yq,...
        'spline');

    Spec.(condName).T = Xq(1,:);
    Spec.(condName).F = Yq(:,1);
    Spec.(condName).P = Pinterp;

end

%% ============================================================
% COMMON COLOR SCALE
%% ============================================================

allP = [];

for ic = 1:numel(conditions)

    condName = conditions{ic};

    allP = [ ...
        allP;
        Spec.(condName).P(:)];

end

clims = [ ...
    min(allP) ...
    max(allP)];

%% ============================================================
% SINGLE PLOTS
%% ============================================================

for ic = 1:numel(conditions)

    condName = conditions{ic};

    figure('Color','w');

    imagesc( ...
        Spec.(condName).T,...
        Spec.(condName).F,...
        Spec.(condName).P);

    axis xy

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    ylim(cfgSpec.freq_limits)

    title(sprintf( ...
        '%s | %s', ...
        cfgSpec.roi,...
        condName))

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

for ic = 1:3

    condName = conditions{ic};

    subplot(1,3,ic)

    imagesc( ...
        Spec.(condName).T,...
        Spec.(condName).F,...
        Spec.(condName).P);

    axis xy

    ylim(cfgSpec.freq_limits)

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    title(condName)

    colormap(turbo)

    colorbar

    clim(clims)

end

sgtitle(sprintf( ...
    'ROI %s', ...
    cfgSpec.roi));

exportgraphics( ...
    gcf,...
    fullfile(outdir,...
    'ERAN_CORE_3Panel.png'),...
    'Resolution',300);

%% ============================================================
figure('Color','w',...
    'Position',[100 100 1200 500]);

subplot(1,2,1)

imagesc( ...
    Spec.Difference.T,...
    Spec.Difference.F,...
    Spec.Difference.P);

axis xy

title('Spec(Dissonant-Consonant)')
colormap(turbo)

colorbar
clim(clims)
subplot(1,2,2)

imagesc( ...
    Spec.DiffSpect.T,...
    Spec.DiffSpect.F,...
    Spec.DiffSpect.P);

axis xy

title('Spec(Dissonant)-Spec(Consonant)')

colormap(turbo)

colorbar
clim(clims)


% SAVE
%% ============================================================

save( ...
    fullfile(outdir,...
    'Spectrogram_TEST.mat'),...
    'ERP_Subj',...
    'GroupERP',...
    'Spec',...
    'cfgSpec');

set(0,'DefaultFigureVisible',origState);

disp('SPECTROGRAM TEST COMPLETED');