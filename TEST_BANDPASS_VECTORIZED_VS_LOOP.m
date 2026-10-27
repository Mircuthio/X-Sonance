%% ============================================================
% TEST_BANDPASS_VECTORIZED_VS_LOOP
%
% Verifica che:
%   bandpass canale-per-canale
% sia equivalente a:
%   bandpass su matrice nTime x nChan
%
% e che:
%   hilbert per canale
% sia equivalente a:
%   hilbert(X,[],2)
%% ============================================================
clear
close all
clc

rng(1);

%% ------------------------------------------------------------
% Parametri
%% ------------------------------------------------------------
Fs = 250;
t = (-0.5:1/Fs:1.5)';
nTime = numel(t);
nChan = 3;

band = [8 12];
baseline_win = [-0.5 0];
normalization = 'db';

%% ------------------------------------------------------------
% Segnale sintetico: 3 canali
% ------------------------------------------------------------
% Ogni canale ha una diversa combinazione di frequenze
eeg = zeros(nTime,nChan);

for ch = 1:nChan
    freq1 = 10 + ch;
    freq2 = 20 + 2*ch;
    
    eeg(:,ch) = ...
        sin(2*pi*freq1*t) + ...
        0.5*sin(2*pi*freq2*t) + ...
        0.2*randn(nTime,1);
end

% La tua funzione usa eeg come nChan x nTime
eegChanTime = eeg.';

%% ------------------------------------------------------------
% METODO ORIGINALE: loop canale per canale
%% ------------------------------------------------------------
P_loop = nan(nChan,nTime);

idxBase = t >= baseline_win(1) & ...
          t <= baseline_win(2);

for ch = 1:nChan
    signal = eegChanTime(ch,:);
    
    signalF = bandpass(signal,band,Fs);
    H = hilbert(signalF);
    P = abs(H).^2;
    
    baselinePower = mean(P(idxBase),'omitnan');
    
    if baselinePower <= 0
        baselinePower = eps;
    end
    
    P_loop(ch,:) = ...
        10*log10(P ./ baselinePower);
end

roiPower_loop = mean(P_loop,1,'omitnan');

%% ------------------------------------------------------------
% METODO VETTORIZZATO
%% ------------------------------------------------------------
% bandpass filtra lungo le colonne.
% Trasponiamo: nTime x nChan
signalF_vec = bandpass(eeg,band,Fs);

% Ritrasponiamo: nChan x nTime
signalF_vec = signalF_vec.';

% Hilbert lungo il tempo:
% transponiamo, applichiamo hilbert, ritrasponiamo
H_vec = hilbert(signalF_vec.').';

P_vec = abs(H_vec).^2;

% Baseline per canale
baselinePower_vec = ...
    mean(P_vec(:,idxBase),2,'omitnan');

baselinePower_vec(baselinePower_vec <= 0) = eps;

% Normalizzazione dB
P_vec_db = ...
    10*log10(P_vec ./ baselinePower_vec);

roiPower_vec = ...
    mean(P_vec_db,1,'omitnan');

%% ------------------------------------------------------------
% CONFRONTO
%% ------------------------------------------------------------
diffPower = max(abs(P_loop(:) - P_vec_db(:)));
diffROI = max(abs(roiPower_loop - roiPower_vec));

fprintf('\n');
fprintf('====================================\n');
fprintf('TEST EQUIVALENZA BANDPASS + HILBERT\n');
fprintf('====================================\n');
fprintf('Dimensioni segnale       : %d canali x %d campioni\n', ...
    nChan,nTime);
fprintf('Max |P_loop - P_vector|  : %.3e\n',diffPower);
fprintf('Max |ROI loop - ROI vec| : %.3e\n',diffROI);
fprintf('====================================\n');

if diffPower < 1e-8
    fprintf('OK: le due implementazioni sono equivalenti.\n');
else
    fprintf('ATTENZIONE: differenza troppo grande.\n');
end

%% ------------------------------------------------------------
% PLOT DI CONTROLLO
%% ------------------------------------------------------------
figure('Name','Bandpower validation');

subplot(2,1,1)
plot(t,roiPower_loop,'b','LineWidth',1.5)
hold on
plot(t,roiPower_vec,'r--','LineWidth',1.2)
xlabel('Time (s)')
ylabel('ROI power (dB)')
title('ROI power: loop vs vectorized')
legend('Loop canale per canale','Vettorizzato')
grid on

subplot(2,1,2)
plot(t,roiPower_loop - roiPower_vec,'k')
xlabel('Time (s)')
ylabel('\Delta power (dB)')
title('Differenza loop - vettorizzato')
grid on