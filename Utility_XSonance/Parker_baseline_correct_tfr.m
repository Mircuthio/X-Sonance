function powerOut = Parker_baseline_correct_tfr( ...
    powerIn,...
    time,...
    baselineWin)
% ============================================================
% BASELINE_CORRECT_TFR
%
% Park-style absolute baseline correction:
% power(t,f) - mean(power_baseline(f))
%
% Input/output: linear wavelet power (microvolt^2)
% ============================================================

idxBase = time >= baselineWin(1) & ...
    time <= baselineWin(2);

assert(any(idxBase), ...
    'Empty baseline window');

% Una baseline distinta per ogni frequenza
baselineMean = mean(powerIn(:,idxBase), 2, 'omitnan');

% Evita incompatibilità di orientamento
powerOut = powerIn - baselineMean;
end