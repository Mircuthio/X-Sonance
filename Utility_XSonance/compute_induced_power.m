function powerTF = compute_induced_power( ...
    signal,...
    freqs,...
    Fs,...
    nCycles)
% ============================================================
% COMPUTE_INDUCED_POWER
%
% Morlet time-frequency decomposition.
%
% Input
% -----
% signal:
%   1 x time EEG signal
%
% freqs:
%   Scalar frequency or vector of central frequencies in Hz
%
% Fs:
%   Sampling rate in Hz
%
% nCycles:
%   Scalar number of Morlet cycles applied to every frequency,
%   or a vector with one cycle value per frequency.
%
% Output
% ------
% powerTF:
%   nFreq x nTime linear power matrix: |Z|^2
% ============================================================

signal = double(signal);
freqs = freqs(:)';

nFreq = numel(freqs);
nTime = numel(signal);

% ------------------------------------------------------------
% Validate and standardize nCycles
% ------------------------------------------------------------
if isscalar(nCycles)

    nCycles = repmat(nCycles,1,nFreq);

elseif numel(nCycles) == nFreq

    nCycles = nCycles(:)';

else

    error( ...
        ['nCycles must be scalar or contain one value ', ...
        'for each requested frequency.']);

end

powerTF = zeros(nFreq,nTime);

% ------------------------------------------------------------
% Morlet convolution and linear power
% ------------------------------------------------------------
for f = 1:nFreq

    cf = freqs(f);
    currentCycles = nCycles(f);

    wavelet = create_morlet_wavelet( ...
        cf, ...
        currentCycles, ...
        Fs);

    z = conv(signal,wavelet,'same');

    powerTF(f,:) = abs(z).^2;

end

end