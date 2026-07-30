function powerTF = compute_induced_power( ...
    signal,...
    freqs,...
    Fs,...
    nCycles)

% ============================================================
% COMPUTE_INDUCED_POWER
%
% Morlet Time-Frequency decomposition
%
% Input
% -----
% signal   : 1 x time
% freqs    : frequencies
% Fs       : sampling rate
% nCycles  : Morlet cycles
%
% Output
% ------
% powerTF
%   [nFreq x nTime]
%
% ============================================================

signal = double(signal);

nFreq = numel(freqs);
nTime = numel(signal);

powerTF = zeros(nFreq,nTime);

for f = 1:nFreq

    cf = freqs(f);

    wavelet = create_morlet_wavelet( ...
        cf,...
        nCycles,...
        Fs);

    z = conv(signal,wavelet,'same');

    powerTF(f,:) = abs(z).^2;

end