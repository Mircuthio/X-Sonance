function main_kirsanov_consonance_dissonance_replication()
% Replication-oriented main pipeline for:
% Kirsanov et al., Frontiers in Human Neuroscience (2025)
% "Electrophysiological and Behavioural Responses to Consonant and Dissonant
% Piano Chords as Standardised Affective Stimuli"
%
% Goal:
% Recreate the paper workflow with modular MATLAB functions.
%
% Assumptions:
% - Raw EEG available per subject
% - Event markers indicate stimulus onset
% - Behavioral file contains subject responses and reaction times
% - Stimulus labels available: consonant / dissonant / neutral
%
% Suggested toolbox support:
% - EEGLAB and/or BBCI-style functions
% - Statistics and Machine Learning Toolbox
% - Signal Processing Toolbox
%
% Output:
% - ERP structures
% - GFP summary
% - cluster/permutation statistics
% - spectral amplitude features
% - DFA/LRTC features
% - GLMM results
% - exportable tables for figures and stats

    %% --------------------------------------------------------------------
    % 0) PROJECT SETUP
    % ---------------------------------------------------------------------
    clc; close all;

    cfg = init_kirsanov_cfg();

    paths = init_project_paths(cfg);

    subjects = get_subject_list(paths);

    create_output_folders(paths);

    %% --------------------------------------------------------------------
    % 1) LOAD ALL SUBJECTS
    % ---------------------------------------------------------------------
    allSubjects = struct();
    allTrialTable = table();
    allERP = struct();

    for s = 1:numel(subjects)

        subjID = subjects{s};
        fprintf('\n=== Processing subject: %s ===\n', subjID);

        %% 1.1 Load raw EEG + behavior + stimulus metadata
        rawEEG      = load_raw_eeg_subject(subjID, paths, cfg);
        behav       = load_behavior_subject(subjID, paths, cfg);
        stimInfo    = load_stimulus_metadata(subjID, paths, cfg);

        %% 1.2 Synchronize events and behavioral responses
        eventStruct = build_event_table(rawEEG, behav, stimInfo, cfg);

        %% ----------------------------------------------------------------
        % 2) PREPROCESSING
        % According to paper:
        % - Downsample to 250 Hz
        % - Notch 45-55 Hz
        % - Band-pass 1-45 Hz
        % - Common average reference
        % - Bad channel detection
        % - ICA/FastICA for ocular artifacts
        % -----------------------------------------------------------------
        eeg_ds      = downsample_eeg(rawEEG, cfg);
        eeg_notch   = apply_notch_filter(eeg_ds, cfg);
        eeg_bp      = apply_bandpass_filter(eeg_notch, cfg);
        eeg_car     = rereference_common_average(eeg_bp, cfg);

        [eeg_clean1, badChanInfo] = detect_and_handle_noisy_channels(eeg_car, cfg);

        icaModel    = run_fastica_decomposition(eeg_clean1, cfg);
        ocularICs   = detect_ocular_components(icaModel, eeg_clean1, cfg);
        eeg_clean2  = remove_ica_components(eeg_clean1, icaModel, ocularICs, cfg);

        save_preprocessing_report(subjID, badChanInfo, ocularICs, paths, cfg);

        %% ----------------------------------------------------------------
        % 3) EPOCHING AND BASELINE
        % Paper:
        % - epochs: -100 to 800 ms
        % - baseline: -100 to 0 ms
        % -----------------------------------------------------------------
        EEG_epo = epoch_eeg_to_stimulus_onset(eeg_clean2, eventStruct, cfg);
        EEG_epo = apply_baseline_correction(EEG_epo, cfg);

        EEG_epo = reject_bad_epochs(EEG_epo, cfg);

        %% ----------------------------------------------------------------
        % 4) CONDITION LABELING
        % Stimulus classes:
        % - consonant
        % - dissonant
        % - neutral
        % Behavioral labels:
        % - pleasant / unpleasant / neutral
        % Derived variables:
        % - response congruency
        % - accuracy
        % -----------------------------------------------------------------
        trialTable = build_trial_level_table(subjID, EEG_epo, eventStruct, behav, cfg);

        %% ----------------------------------------------------------------
        % 5) ERP COMPUTATION
        % Grand condition ERPs for:
        % - consonant
        % - dissonant
        % - neutral
        % Also optional FCz extraction as in figure
        % -----------------------------------------------------------------
        ERP = compute_condition_erps(EEG_epo, trialTable, cfg);

        ERP_FCz = extract_single_channel_erps(ERP, 'FCz', cfg);

        save_subject_erp(subjID, ERP, ERP_FCz, paths, cfg);

        %% ----------------------------------------------------------------
        % 6) GFP-BASED TIME WINDOWS
        % Paper windows:
        % - 90-110 ms
        % - 190-210 ms
        % - 290-310 ms
        % They say these were selected from global field power
        % -----------------------------------------------------------------
        GFP = compute_global_field_power(ERP, cfg);

        if cfg.usePaperFixedWindows
            timeWindows = cfg.paperTimeWindows;
        else
            timeWindows = detect_gfp_peaks_and_windows(GFP, cfg);
        end

        save_subject_gfp(subjID, GFP, timeWindows, paths, cfg);

        %% ----------------------------------------------------------------
        % 7) ERP AMPLITUDE EXTRACTION
        % Extract mean amplitudes in each time window across all channels,
        % and/or channel subsets if needed
        % -----------------------------------------------------------------
        erpFeatures = extract_erp_window_features(EEG_epo, trialTable, timeWindows, cfg);

        %% ----------------------------------------------------------------
        % 8) CLUSTER-BASED / PERMUTATION STATISTICS
        % Contrasts described in the paper:
        % - consonant vs neutral
        % - dissonant vs neutral
        % - consonant vs dissonant
        %
        % Across electrode space, cluster-based permutation
        % -----------------------------------------------------------------
        permStats = run_cluster_permutation_subject_level(ERP, timeWindows, cfg);

        save_subject_permutation_results(subjID, permStats, paths, cfg);

        %% ----------------------------------------------------------------
        % 9) FREQUENCY-DOMAIN ANALYSIS
        % Paper:
        % - use entire EEG recording
        % - alpha: 8-12 Hz
        % - beta: 20-25 Hz
        % - gamma: 35-40 Hz
        % - two-way Butterworth band-pass
        % - Hilbert envelope
        % - mean envelope amplitude
        % -----------------------------------------------------------------
        oscillatoryFeatures = extract_oscillatory_amplitude_features(eeg_clean2, trialTable, cfg);

        %% ----------------------------------------------------------------
        % 10) LRTC / DFA ANALYSIS
        % Paper:
        % - DFA windows 5-50 s on log scale
        % - band-specific LRTC
        % - alpha, beta, gamma
        % -----------------------------------------------------------------
        dfaFeatures = extract_dfa_lrtc_features(eeg_clean2, trialTable, cfg);

        %% ----------------------------------------------------------------
        % 11) MERGE ALL FEATURES
        % One row per trial
        % -----------------------------------------------------------------
        subjectFeatureTable = merge_trial_features( ...
            trialTable, erpFeatures, oscillatoryFeatures, dfaFeatures, cfg);

        save_subject_feature_table(subjID, subjectFeatureTable, paths, cfg);

        %% Store for grand analyses
        allSubjects.(matlab.lang.makeValidName(subjID)).trialTable = subjectFeatureTable;
        allSubjects.(matlab.lang.makeValidName(subjID)).ERP = ERP;
        allSubjects.(matlab.lang.makeValidName(subjID)).GFP = GFP;
        allSubjects.(matlab.lang.makeValidName(subjID)).permStats = permStats;

        allTrialTable = [allTrialTable; subjectFeatureTable]; %#ok<AGROW>
        allERP = append_subject_erp_to_group(allERP, subjID, ERP, cfg);
    end

    %% --------------------------------------------------------------------
    % 12) GROUP-LEVEL BEHAVIORAL ANALYSIS
    % Paper:
    % - Fisher exact test: stimulus type x response category
    % - Kruskal-Wallis on RT across 6 groups:
    %   consonant/dissonant/neutral x congruent/incongruent
    % - post hoc with Bonferroni
    % ---------------------------------------------------------------------
    behavStats = run_behavioral_statistics(allTrialTable, cfg);
    save_behavioral_results(behavStats, paths, cfg);

    %% --------------------------------------------------------------------
    % 13) GRAND-AVERAGE ERP + GFP
    % ---------------------------------------------------------------------
    grandERP = compute_grand_average_erps(allERP, cfg);
    grandGFP = compute_global_field_power(grandERP, cfg);

    save_group_erp_results(grandERP, grandGFP, paths, cfg);

    %% --------------------------------------------------------------------
    % 14) GROUP-LEVEL PERMUTATION / CLUSTER TESTS
    % Paper mentions cluster-based permutation across subjects
    % ---------------------------------------------------------------------
    groupPermStats = run_group_cluster_permutation(grandERP, cfg);
    save_group_permutation_results(groupPermStats, paths, cfg);

    %% --------------------------------------------------------------------
    % 15) SOURCE ANALYSIS PREPARATION
    % Paper:
    % - sLORETA/eLORETA on grand averages
    % - dissonant vs neutral
    % - in significant time windows (especially 190-210, 290-310 ms)
    % ---------------------------------------------------------------------
    sourceInput = prepare_sloreta_input(grandERP, cfg);
    export_sloreta_files(sourceInput, paths, cfg);

    %% --------------------------------------------------------------------
    % 16) GLMM / MIXED-EFFECTS LOGISTIC MODELS
    % Outcome:
    % - trial-level categorization accuracy
    %
    % Fixed effects:
    % - stimulus type
    % - neural predictor (band amplitude OR DFA)
    % - interaction stimulusType * predictor
    %
    % Random effects:
    % - random intercepts for stimuli/items
    % - random intercepts for participants
    % - random slopes for stimulus type within participants
    % ---------------------------------------------------------------------
    glmmResults = struct();

    glmmResults.alphaAmp = fit_accuracy_glmm(allTrialTable, ...
        'Accuracy ~ StimulusType * AlphaAmp + (1 + StimulusType | Subject) + (1 | Item)', cfg);

    glmmResults.betaAmp = fit_accuracy_glmm(allTrialTable, ...
        'Accuracy ~ StimulusType * BetaAmp + (1 + StimulusType | Subject) + (1 | Item)', cfg);

    glmmResults.gammaAmp = fit_accuracy_glmm(allTrialTable, ...
        'Accuracy ~ StimulusType * GammaAmp + (1 + StimulusType | Subject) + (1 | Item)', cfg);

    glmmResults.alphaDFA = fit_accuracy_glmm(allTrialTable, ...
        'Accuracy ~ StimulusType * AlphaDFA + (1 + StimulusType | Subject) + (1 | Item)', cfg);

    glmmResults.betaDFA = fit_accuracy_glmm(allTrialTable, ...
        'Accuracy ~ StimulusType * BetaDFA + (1 + StimulusType | Subject) + (1 | Item)', cfg);

    glmmResults.gammaDFA = fit_accuracy_glmm(allTrialTable, ...
        'Accuracy ~ StimulusType * GammaDFA + (1 + StimulusType | Subject) + (1 | Item)', cfg);

    glmmComparisons = compare_glmm_models(glmmResults, cfg);
    save_glmm_results(glmmResults, glmmComparisons, paths, cfg);

    %% --------------------------------------------------------------------
    % 17) OPTIONAL PAPER-LIKE FIGURES
    % ---------------------------------------------------------------------
    make_figure_behavioral_distributions(allTrialTable, behavStats, paths, cfg);
    make_figure_reaction_times(allTrialTable, behavStats, paths, cfg);
    make_figure_gfp_and_time_windows(grandERP, grandGFP, cfg.paperTimeWindows, paths, cfg);
    make_figure_fcz_erps(grandERP, paths, cfg);
    make_figure_cluster_topographies(groupPermStats, paths, cfg);
    make_figure_oscillatory_glmm_effects(allTrialTable, glmmResults, paths, cfg);

    %% --------------------------------------------------------------------
    % 18) EXPORT MASTER TABLES
    % ---------------------------------------------------------------------
    writetable(allTrialTable, fullfile(paths.results, 'all_trial_level_features.csv'));
    save(fullfile(paths.results, 'replication_workspace.mat'), ...
        'cfg', 'allTrialTable', 'grandERP', 'grandGFP', 'groupPermStats', ...
        'behavStats', 'glmmResults', 'glmmComparisons', '-v7.3');

    fprintf('\nReplication pipeline completed.\n');
end


%% ========================================================================
% CONFIG
% ========================================================================
function cfg = init_kirsanov_cfg()

    cfg = struct();

    % Sampling / preprocessing
    cfg.originalFs = 500;
    cfg.targetFs   = 250;
    cfg.notchHz    = [45 55];
    cfg.bandpassHz = [1 45];
    cfg.reference  = 'CAR';

    % Epoching
    cfg.epochWindowMs    = [-100 800];
    cfg.baselineWindowMs = [-100 0];

    % Artifact thresholds
    cfg.absAmplitudeThresholdUV = 100;
    cfg.performICA = true;
    cfg.icaMethod  = 'fastica';

    % Conditions
    cfg.conditionNames = {'consonant','dissonant','neutral'};
    cfg.responseNames  = {'pleasant','unpleasant','neutral'};

    % Congruency mapping for behavioral accuracy
    cfg.expectedResponse.consonant = 'pleasant';
    cfg.expectedResponse.dissonant = 'unpleasant';
    cfg.expectedResponse.neutral   = 'neutral';

    % GFP windows from paper
    cfg.usePaperFixedWindows = true;
    cfg.paperTimeWindows = [
         90 110;
        190 210;
        290 310
    ];

    % Frequency-domain analysis
    cfg.freqBands.alpha = [8 12];
    cfg.freqBands.beta  = [20 25];
    cfg.freqBands.gamma = [35 40];

    % DFA / LRTC
    cfg.dfaWindowSec = [5 50];
    cfg.dfaNumScales = 20;

    % Statistics
    cfg.nPermutations = 800;
    cfg.alphaLevel    = 0.05;
    cfg.multcomp      = 'bonferroni';

    % ERP options
    cfg.erpMeasure = 'mean';

    % Channels of interest for paper-like plotting
    cfg.plotChannel = 'FCz';

    % Source analysis export
    cfg.sourceConditions = {'dissonant','neutral'};
    cfg.sourceWindowsMs  = [
        190 210;
        290 310
    ];
end