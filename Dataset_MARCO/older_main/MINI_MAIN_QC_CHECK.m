%% MINI_MAIN_QC_CHECK

clear; clc

load('Subj2_trial1_data_extracted.mat')

%% =====================================================
% BASIC INFO
% =====================================================

fprintf('\n=====================================\n');
fprintf('SUBJECT: %s\n',subjectData.subjectID);
fprintf('TRIAL  : %s\n',subjectData.trialID);
fprintf('=====================================\n');

%% =====================================================
% EVENTS
% =====================================================

fprintf('\nEVENTS\n');

fprintf('Events table: %d\n', ...
    height(subjectData.eventsTable));

fprintf('EEG events  : %d\n', ...
    numel(subjectData.events));

%% =====================================================
% CHANNELS
% =====================================================

fprintf('\nCHANNELS\n');

fprintf('Original channels : %d\n', ...
    subjectData.preprocessingInfo.nChannelsOriginal);

fprintf('Final channels    : %d\n', ...
    subjectData.preprocessingInfo.nChannelsFinal);

fprintf('Bad channels removed: %d\n', ...
    subjectData.nBadChannels);

disp(subjectData.badChannelsRemoved')

%% =====================================================
% ICA
% =====================================================

fprintf('\nICA\n');

fprintf('Rank before ICA : %d\n', ...
    subjectData.preprocessingInfo.rankBeforeICA);

fprintf('Rank after clean: %d\n', ...
    subjectData.preprocessingInfo.rankAfterClean);

fprintf('Bad ICs : %d\n', ...
    subjectData.nBadICs);

disp(subjectData.badICs')

%% =====================================================
% SAMPLING
% =====================================================

fprintf('\nSAMPLING\n');

fprintf('Original Fs : %.1f Hz\n', ...
    subjectData.preprocessingInfo.originalFs);

fprintf('Final Fs    : %.1f Hz\n', ...
    subjectData.preprocessingInfo.finalFs);

%% =====================================================
% EVENT LATENCY ERROR
% =====================================================

fprintf('\nEVENT LATENCY\n');

fprintf('Max latency error after resample = %.4f samples\n', ...
    subjectData.QC.maxEventLatencyError);

%% =====================================================
% TRIGGER DISTRIBUTION
% =====================================================

fprintf('\nTRIGGERS\n');

disp(subjectData.QC.triggerDistribution)

%% =====================================================
% STD SUMMARY
% =====================================================

fprintf('\nSIGNAL STD\n');

fprintf('RAW      mean STD : %.3f\n', ...
    subjectData.QC.meanSTD_raw);

fprintf('PRE ICA  mean STD : %.3f\n', ...
    subjectData.QC.meanSTD_preICA);

fprintf('FINAL    mean STD : %.3f\n', ...
    subjectData.QC.meanSTD_clean);

%% =====================================================
% FINAL EEG
% =====================================================

fprintf('\nFINAL DATASET\n');

disp(size(subjectData.cleanContinuous.data))

fprintf('Duration: %.2f min\n', ...
    subjectData.cleanContinuous.pnts / ...
    subjectData.cleanContinuous.srate / 60);

%% =====================================================
% ICLABEL SUMMARY
% =====================================================

fprintf('\nICLABEL\n');

ICL = subjectData.ICLabel;

[~,maxClass] = max(ICL,[],2);

disp(tabulate(maxClass))
subjectData.cleanContinuous.etc.ic_classification.ICLabel.classes

% 1)nBadChannels
% bene: 0-6
% da investigare: >10
% 2)nBadICs
% bene: 2-10 circa
% sospetto: 0 oppure >20
% 3)Rank
% deve essere coerente col numero di canali tenuti per ICA
% 4)MaxEventLatencyError
% idealmente <1 campione
% 5)TriggerDistribution
% nessuna classe completamente assente
% 6)Size final data
% 64*N