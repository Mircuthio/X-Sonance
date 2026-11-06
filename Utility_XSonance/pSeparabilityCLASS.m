function [p_all,p_classes] = ...
    pSeparabilityCLASS( ...
    data_trials,...
    par)

% function [p_all,p_classes] = pSeparability(data_trials,par)

execinfo = par.exec;

if ~isempty(execinfo)
    t=tic;
    fprintf('Function: %s ',mfilename);
end

%% ============================================================
% BASIC INFO
%% ============================================================

trialTypes = ...
    [data_trials.trialType];

trialNames = ...
    {data_trials.trialName};

[classes,idx] = ...
    unique(trialTypes);

names = ...
    trialNames(idx);

xfld = ...
    par.xfld;

InField = ...
    par.InField;

OutField = ...
    par.OutField;

time = ...
    data_trials(1).([xfld InField]);

nChannels = ...
    size(data_trials(1).(InField),1);

nTimes = ...
    length(time);

nClasses = ...
    length(classes);

%% ============================================================
% CLASS SIZES
%% ============================================================

nTrialsPerClass = ...
    zeros(1,nClasses);

for ic = 1:nClasses

    nTrialsPerClass(ic) = ...
        sum(trialTypes == classes(ic));

end

maxTrials = ...
    max(nTrialsPerClass);

%% ============================================================
% PREALLOCATION
%% ============================================================

X_data = ...
    nan(maxTrials,nClasses);

p_data = ...
    nan(nChannels,nTimes);

%% ============================================================
% LOOP
%% ============================================================

for iTime = 1:nTimes

    for iChannel = 1:nChannels

        % reset
        X_data(:) = NaN;

        %% ----------------------------------------------------
        % BUILD DATA MATRIX
        %% ----------------------------------------------------

        for ic = 1:nClasses

            data_class = ...
                data_trials( ...
                trialTypes == classes(ic));

            nClassTrials = ...
                numel(data_class);

            for inc = 1:nClassTrials

                X_class = ...
                    data_class(inc).(InField);

                X_data(inc,ic) = ...
                    X_class(iChannel,iTime);

            end

        end

        %% ----------------------------------------------------
        % REMOVE EMPTY ROWS
        %% ----------------------------------------------------

        validRows = ...
            any(~isnan(X_data),2);

        XdataValid = ...
            X_data(validRows,:);

        %% ----------------------------------------------------
        % ANOVA
        %% ----------------------------------------------------

        [pval,~,st] = ...
            anova1( ...
            XdataValid,...
            [],...
            'off');

        pval(pval==0) = eps;

        comparison = ...
            multcompare( ...
            st,...
            'display',...
            'off');

        p_data(iChannel,iTime) = ...
            pval;

        %% ----------------------------------------------------
        % PER CLASS COMPARISONS
        %% ----------------------------------------------------

        for iClass = 1:nClasses

            p_classes(iClass).(OutField)( ...
                iChannel,...
                iTime,...
                :) = ...
                ones(1,1,nClasses);

            for iClassComp = 1:nClasses

                if iClass == iClassComp
                    continue
                end

                ind = ...
                    comparison(:,1)==iClass & ...
                    comparison(:,2)==iClassComp;

                if ~any(ind)

                    ind = ...
                        comparison(:,2)==iClass & ...
                        comparison(:,1)==iClassComp;

                end

                p_classes(iClass).(OutField)( ...
                    iChannel,...
                    iTime,...
                    iClassComp) = ...
                    max( ...
                    comparison(ind,end),...
                    eps);

            end

            p_classes(iClass).trialName = ...
                names{iClass};

            p_classes(iClass).trialType = ...
                classes(iClass);

        end

    end

end

%% ============================================================
% OUTPUT
%% ============================================================

p_all(1).(OutField) = ...
    p_data;

p_classes(1).([xfld OutField]) = ...
    time;

vsTrialName = ...
    p_classes(1).trialName;

for iClass = 2:nClasses

    p_classes(iClass).([xfld OutField]) = ...
        time;

    vsTrialName = ...
        [vsTrialName ...
         ' vs ' ...
         p_classes(iClass).trialName];

end

p_all(1).([xfld OutField]) = ...
    time;

p_all(1).trialName = ...
    vsTrialName;

p_all(1).trialType = 1;

%% ============================================================
% EXECUTION INFO
%% ============================================================

if ~isempty(execinfo)

    out.exectime = toc(t);

    fprintf('| Time Elapsed: %.2f s\n', ...
        out.exectime);

end

end