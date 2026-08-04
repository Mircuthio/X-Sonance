function SPN_Subj = extract_spn_metrics( ...
    subj_list_spn,...
    cfgSPN)

SPN_Subj = struct();

for iSub = 1:numel(subj_list_spn)

    subj_curr = subj_list_spn(iSub);

    subjID = matlab.lang.makeValidName( ...
        char(subj_curr.subj_id));

    fprintf('[%02d/%02d] %s\n', ...
        iSub,...
        numel(subj_list_spn),...
        subjID);

    data_trials = subj_curr.data_trials;

    timeVec = data_trials(1).time;

    %% ========================================================
    % ROI LOOP
    %% ========================================================

    for r = 1:numel(cfgSPN.analysis_rois)

        roiName = ...
            cfgSPN.analysis_rois{r};

        roi_labels = ...
            cfgSPN.rois.(roiName);

        ERP = struct();

        %% ====================================================
        % CONDITIONS
        %% ====================================================

        for ic = 1:numel(cfgSPN.conditions)

            condName = ...
                cfgSPN.conditions{ic};

            idxCond = strcmp( ...
                {data_trials.eventLabel}, ...
                condName);

            trials_cond = ...
                data_trials(idxCond);

            if isempty(trials_cond)

                warning('%s | %s has no trials', ...
                    subjID,...
                    condName);

                continue

            end

            ERP_trials = nan( ...
                numel(trials_cond),...
                size(trials_cond(1).eeg,2));

            for iTr = 1:numel(trials_cond)

                eeg = ...
                    trials_cond(iTr).eeg;

                labels = ...
                    {trials_cond(iTr).chanlocs.labels};

                roi_idx = ...
                    ismember(labels,roi_labels);

                roi_signal = ...
                    mean(eeg(roi_idx,:),1);

                ERP_trials(iTr,:) = ...
                    roi_signal;

            end

            ERP.(condName) = ...
                mean(ERP_trials,1);

        end

        %% ====================================================
        % DIFFERENCE
        %% ====================================================

        ERP.Difference = ...
            ERP.Dissonant - ...
            ERP.Consonant;

        %% ====================================================
        % WINDOWS
        %% ====================================================

        for iw = 1:numel(cfgSPN.windows)

            win = ...
                cfgSPN.windows{iw};

            winName = ...
                cfgSPN.window_names{iw};

            idxWin = ...
                timeVec >= win(1) & ...
                timeVec <= win(2);

            timeWin = ...
                timeVec(idxWin);

            conds = { ...
                'Consonant',...
                'Dissonant',...
                'Difference'};

            for ic = 1:numel(conds)

                condName = ...
                    conds{ic};

                signalWin = ...
                    ERP.(condName)(idxWin);

                %% ============================================
                % Mean Amplitude
                %% ============================================

                MeanAmplitude = ...
                    mean(signalWin);

                %% ============================================
                % Area Under Curve
                %% ============================================

                AUC = ...
                    trapz(timeWin,signalWin);

                %% ============================================
                % Negative Area
                %% ============================================

                signalNeg = signalWin;

                signalNeg(signalNeg > 0) = 0;

                NegativeArea = ...
                    trapz(timeWin,signalNeg);

                %% ============================================
                % Slope
                %% ============================================

                p = polyfit( ...
                    timeWin,...
                    signalWin,...
                    1);

                Slope = p(1);

                %% ============================================
                % SAVE
                %% ============================================

                SPN_Subj.(subjID) ...
                    .(roiName) ...
                    .(winName) ...
                    .(condName) ...
                    .MeanAmplitude = ...
                    MeanAmplitude;

                SPN_Subj.(subjID) ...
                    .(roiName) ...
                    .(winName) ...
                    .(condName) ...
                    .AUC = ...
                    AUC;

                SPN_Subj.(subjID) ...
                    .(roiName) ...
                    .(winName) ...
                    .(condName) ...
                    .NegativeArea = ...
                    NegativeArea;

                SPN_Subj.(subjID) ...
                    .(roiName) ...
                    .(winName) ...
                    .(condName) ...
                    .Slope = ...
                    Slope;

            end

        end

    end

end