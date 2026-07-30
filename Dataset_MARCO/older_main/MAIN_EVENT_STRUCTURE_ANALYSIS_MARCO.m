% ========================================================================
% MAIN_EVENT_STRUCTURE_ANALYSIS_MARCO
% ========================================================================
clear; clc; close all

rootFolder = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials';

subjectDirs = dir(fullfile(rootFolder,'Subj*'));
subjectDirs = subjectDirs([subjectDirs.isdir]);

allISI = [];
allTransitions = zeros(8,8);

eventStats = struct();

for s = 1:numel(subjectDirs)

    subjName = subjectDirs(s).name;

    subjFolder = fullfile(rootFolder,subjName);

    matFile = dir(fullfile(subjFolder,'*_trial.mat'));

    if isempty(matFile)
        fprintf('No continuous file found for %s\n',subjName);
        continue
    end

    fprintf('\n=====================================\n');
    fprintf('SUBJECT: %s\n',subjName);
    fprintf('=====================================\n');

    tmp = load(fullfile(subjFolder,matFile(1).name));

    y = tmp.y;

    time    = y(1,:);
    trigger = y(end,:);

    dt = mean(diff(time));
    Fs = round(1/dt);

    eventOnsets = find(diff([0 trigger~=0])==1);

    eventCodes = trigger(eventOnsets);

    eventTimes = time(eventOnsets);

    ISI = diff(eventTimes);
    ISI(ISI<10)
    allISI = [allISI ; ISI(:)];

    fprintf('N events : %d\n',numel(eventOnsets));

    fprintf('ISI min  : %.3f sec\n',min(ISI));
    fprintf('ISI mean : %.3f sec\n',mean(ISI));
    fprintf('ISI med  : %.3f sec\n',median(ISI));
    fprintf('ISI max  : %.3f sec\n',max(ISI));

    % --------------------------------------------------
    % ISI PER TRIGGER
    % --------------------------------------------------
    triggerStats = struct();

    for tr = 1:8

        idx = find(eventCodes == tr);

        triggerStats(tr).trigger = tr;

        if numel(idx) > 1

            ISItr = diff(eventTimes(idx));

            triggerStats(tr).meanISI = mean(ISItr);
            triggerStats(tr).medianISI = median(ISItr);
            triggerStats(tr).minISI = min(ISItr);
            triggerStats(tr).maxISI = max(ISItr);

        else

            triggerStats(tr).meanISI = NaN;
            triggerStats(tr).medianISI = NaN;
            triggerStats(tr).minISI = NaN;
            triggerStats(tr).maxISI = NaN;

        end

    end

    % --------------------------------------------------
    % TRANSITION MATRIX
    % --------------------------------------------------
    T = zeros(8,8);

    transitionTimes = nan(8,8);

    for k = 1:numel(eventCodes)-1

        a = eventCodes(k);
        b = eventCodes(k+1);
        validTriggers = 1:8;
        if ~ismember(a,validTriggers) || ...
                ~ismember(b,validTriggers)
            continue
        end
        T(a,b) = T(a,b) + 1;

    end

    allTransitions = allTransitions + T;

    % --------------------------------------------------
    % TRANSITION DURATIONS
    % --------------------------------------------------
    for a = 1:8

        for b = 1:8

            idx = find( ...
                eventCodes(1:end-1)==a & ...
                eventCodes(2:end)==b );

            if ~isempty(idx)

                transitionTimes(a,b) = ...
                    mean(eventTimes(idx+1)-eventTimes(idx));

            end

        end

    end

    eventStats(s).subjectID = subjName;
    eventStats(s).nEvents = numel(eventOnsets);
    eventStats(s).ISI = ISI;

    eventStats(s).minISI = min(ISI);
    eventStats(s).meanISI = mean(ISI);
    eventStats(s).medianISI = median(ISI);
    eventStats(s).maxISI = max(ISI);

    eventStats(s).triggerStats = triggerStats;
    eventStats(s).transitionMatrix = T;
    eventStats(s).transitionTimes = transitionTimes;

    % --------------------------------------------------
    % SUBJECT FIGURE
    % --------------------------------------------------
    fig = figure('Color','w');

    subplot(2,2,1)
    histogram(ISI,50)
    xlabel('ISI (s)')
    ylabel('Count')
    title(sprintf('%s - ISI',subjName))

    subplot(2,2,2)
    imagesc(T)
    axis square
    colorbar
    title('Transitions')
    xlabel('Next trigger')
    ylabel('Current trigger')

    subplot(2,2,[3 4])
    imagesc(transitionTimes)
    axis square
    colorbar
    title('Mean transition duration (s)')
    xlabel('Next trigger')
    ylabel('Current trigger')

    drawnow

end

% ========================================================================
% GLOBAL SUMMARY
% ========================================================================

fprintf('\n=====================================\n');
fprintf('GLOBAL SUMMARY\n');
fprintf('=====================================\n');

fprintf('Global min ISI : %.3f s\n',min(allISI));
fprintf('Global meanISI : %.3f s\n',mean(allISI));
fprintf('Global medISI  : %.3f s\n',median(allISI));
fprintf('Global maxISI  : %.3f s\n',max(allISI));

figure('Color','w');

subplot(1,2,1)
histogram(allISI,100)
xlabel('ISI (s)')
ylabel('Count')
title('Global ISI Distribution')

subplot(1,2,2)
imagesc(allTransitions)
axis square
colorbar
xlabel('Next Trigger')
ylabel('Current Trigger')
title('Global Transition Matrix')

save('EVENT_STRUCTURE_SUMMARY.mat',...
    'eventStats',...
    'allISI',...
    'allTransitions');