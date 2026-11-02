function Xf = bandpass_matrix(X,bandRange,fs)
% X: nSignals x nTime
Xt = X.';                 % nTime x nSignals
Xtf = bandpass(Xt,bandRange,fs); % filtra lungo colonne? verificare
Xf = Xtf.';
end