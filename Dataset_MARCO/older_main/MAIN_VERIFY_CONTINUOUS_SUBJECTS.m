% ========================================================================
% MAIN_VERIFY_CONTINUOUS_SUBJECTS
% ========================================================================

clear; clc; close all
EXTRAC
rootFolder = ...
    'D:\X-SONANCE\Dataset_MARCO\DATA_SUBJECTS\All_trials';

subjectList = {'Subj2','Subj3','Subj4','Subj5'};

REPORT = struct();

for s = 1:numel(subjectList)

    subjName = subjectList{s};

    fprintf('\n');
    fprintf('=====================================\n');
    fprintf('CHECKING %s\n',subjName);
    fprintf('=====================================\n');

    subjFolder = fullfile(rootFolder,subjName);

    contFiles = dir(fullfile(subjFolder,'*_trial.mat'));

    if isempty(contFiles)

        warning('Continuous file not found')
        continue

    end

    fileName = fullfile( ...
        subjFolder,...
        contFiles(1).name);

    tmp = load(fileName);

    y = tmp.y;

    time    = y(1,:);
    EEGraw  = y(2:end-1,:);
    trigger = y(end,:);
    dt = diff(time);

    fprintf('mean dt = %.12f\n',mean(dt));
    fprintf('min dt  = %.12f\n',min(dt));
    fprintf('max dt  = %.12f\n',max(dt));
    idx = find(abs(dt-mean(dt)) > 10*std(dt));
    if ~isempty(idx)

        fprintf('First dt outliers:\n');
        disp(idx(1:min(10,end)));

    end
    Fs = round(1/mean(diff(time)));

    fprintf('Fs = %.2f Hz\n',Fs);

    % ---------------------------------------------------------
    % TIME VECTOR CHECK
    % ---------------------------------------------------------

    REPORT(s).subject = subjName;

    REPORT(s).Fs = Fs;

    REPORT(s).dtMean = mean(dt);
    REPORT(s).dtStd  = std(dt);
    REPORT(s).nDtOutliers = numel(idx);

    fprintf('dt outliers = %d\n',numel(idx));

    REPORT(s).maxDtDeviation = ...
        max(abs(dt - mean(dt)));

    fprintf('dt std = %.12f\n',REPORT(s).dtStd);

    % ---------------------------------------------------------
    % EVENT CHECK
    % ---------------------------------------------------------

    eventOnsets = find(diff([0 trigger~=0])==1);

    eventCodes = trigger(eventOnsets);

    REPORT(s).nEvents = numel(eventOnsets);

    REPORT(s).uniqueTriggers = unique(eventCodes);

    fprintf('Events = %d\n',numel(eventOnsets));

    fprintf('Triggers:\n');
    disp(unique(eventCodes))

    % ---------------------------------------------------------
    % CHECK TRIALBOUNDARIES
    % ---------------------------------------------------------

    if isfield(tmp,'trialBoundaries')

        TB = tmp.trialBoundaries;

        REPORT(s).nTrials = numel(TB);

        fprintf('Trials found = %d\n',numel(TB));

        boundaryJump = zeros(numel(TB)-1,1);

        for k = 1:numel(TB)-1

            endIdx = TB(k).endSample;
            nextIdx = TB(k+1).startSample;

            x1 = EEGraw(:,endIdx);
            x2 = EEGraw(:,nextIdx);

            boundaryJump(k) = ...
                mean(abs(x2-x1));

        end

        REPORT(s).boundaryJumpMean = ...
            mean(boundaryJump);

        REPORT(s).boundaryJumpMax = ...
            max(boundaryJump);

        fprintf('Mean boundary jump = %.3f\n', ...
            REPORT(s).boundaryJumpMean);

        fprintf('Max boundary jump = %.3f\n', ...
            REPORT(s).boundaryJumpMax);

        REPORT(s).globalRMS = ...
            rms(single(EEGraw(:)));
        % ---------------------------------------------
        % CONSISTENCY CHECK
        % ---------------------------------------------

        assert(TB(1).startSample == 1)

        assert(TB(end).endSample == size(y,2))

        totalEventsBoundary = sum([TB.nEvents]);

        REPORT(s).eventsFromBoundaries = ...
            totalEventsBoundary;

        fprintf('Boundary events = %d\n', ...
            totalEventsBoundary);

        if totalEventsBoundary ~= numel(eventOnsets)

            warning('Event mismatch detected')

        end

    end

    % ---------------------------------------------------------
    % CHANNEL STATS
    % ---------------------------------------------------------

    chanSTD = std(EEGraw,0,2);

    zSTD = zscore(chanSTD);

    REPORT(s).nPotentialOutliers = ...
        sum(abs(zSTD)>3);

    fprintf('Outlier channels = %d\n', ...
        REPORT(s).nPotentialOutliers);

    fprintf('Global RMS: %.2f\n', ...
    rms(single(EEGraw(:))));
end

% ========================================================================
% FINAL SUMMARY
% ========================================================================

fprintf('\n');
fprintf('=====================================\n');
fprintf('FINAL SUMMARY\n');
fprintf('=====================================\n');

for s = 1:numel(REPORT)

    fprintf('\n%s\n',REPORT(s).subject);

    fprintf('Fs ............. %.1f Hz\n', ...
        REPORT(s).Fs);

    fprintf('Events ......... %d\n', ...
        REPORT(s).nEvents);

    fprintf('Boundary Jump .. %.2f\n', ...
        REPORT(s).boundaryJumpMax);

    fprintf('Outlier Ch ..... %d\n', ...
        REPORT(s).nPotentialOutliers);

end

save('VERIFY_CONTINUOUS_REPORT.mat','REPORT');