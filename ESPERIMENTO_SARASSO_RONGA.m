% =========================================================================
% ESPERIMENTO_SARASSO_RONGA
% SCRIPT MATLAB: Generazione degli stimoli acustici (Consonanti e Dissonanti)
% basato sui dati dell'Esperimento 2 del paper (Sarasso et al., 2021)
% =========================================================================

clear; clc; close all;

Fs = 44100;          % Frequenza di campionamento standard (44.1 kHz)
dur = 0.05;          % Durata del suono: 50 millisecondi (come nel paper)[cite: 8]
t = 0:1/Fs:dur;      % Asse temporale

%% 1. BLOCCO CONSONANTE (Quinte)
% Frequenze Standard (230 Hz + 153.33 Hz) e Deviante alto (260 Hz + 173.33 Hz)[cite: 8]
f1_std_cons = 230;     f2_std_cons = 153.33;
f1_dev_cons = 260;     f2_dev_cons = 173.33;

suono_cons_standard = sin(2*pi*f1_std_cons*t) + sin(2*pi*f2_std_cons*t);
suono_cons_deviante = sin(2*pi*f1_dev_cons*t) + sin(2*pi*f2_dev_cons*t);

%% 2. BLOCCO DISSONANTE (Tritoni)
% Frequenze Standard (230 Hz + 163.55 Hz) e Deviante alto (260 Hz + 184.88 Hz)[cite: 6, 8]
f1_std_diss = 230;     f2_std_diss = 163.55;
f1_dev_diss = 260;     f2_dev_diss = 184.88;

suono_diss_standard = sin(2*pi*f1_std_diss*t) + sin(2*pi*f2_std_diss*t);
suono_diss_deviante = sin(2*pi*f1_dev_diss*t) + sin(2*pi*f2_dev_diss*t);

%% Visualizzazione grafica delle forme d'onda
figure('Name', 'Stimoli Acustici del Paper', 'Color', 'w', 'Position', [100, 100, 900, 600]);

subplot(2,2,1);
plot(t*1000, suono_cons_standard, 'g');
title('Consonante - Standard (230 Hz)');
xlabel('Tempo (ms)'); ylabel('Ampiezza'); grid on;

subplot(2,2,2);
plot(t*1000, suono_cons_deviante, 'b');
title('Consonante - Deviante (260 Hz - Sorpresa!)[cite: 8]');
xlabel('Tempo (ms)'); ylabel('Ampiezza'); grid on;

subplot(2,2,3);
plot(t*1000, suono_diss_standard, 'r');
title('Dissonante - Standard (230 Hz)');
xlabel('Tempo (ms)'); ylabel('Ampiezza'); grid on;

subplot(2,2,4);
plot(t*1000, suono_diss_deviante, 'm');
title('Dissonante - Deviante (260 Hz - Sorpresa!)[cite: 6, 8]');
xlabel('Tempo (ms)'); ylabel('Ampiezza'); grid on;

%% Riproduzione audio (Ascolta la differenza tra consonante e dissonante!)
disp('Riproduzione in corso: Intervallo Consonante Standard (Quinta)...');
sound(suono_cons_standard, Fs);
pause(0.5);

disp('Riproduzione in corso: Intervallo Dissonante Standard (Tritone)...');
sound(suono_diss_standard, Fs);




% =========================================================================
% SCRIPT MATLAB: Esempi ad alto contrasto (Consonante vs Dissonante Netto)
% =========================================================================

Fs = 44100;          % Frequenza di campionamento (44.1 kHz)
dur_nota = 0.5;      % Durata di ogni singola nota (500 ms)
t = 0:1/Fs:dur_nota;

%% 1. BLOCCO CONSONANTE (Accordo Maggiore Dolce e Aperto)
% Frequenze basate su accordo maggiore puro (Do - Mi - Sol)
f_cons_std = [261.63, 329.63, 392.00];   % C - E - G (Standard)
f_cons_dev = [293.66, 369.99, 440.00];   % D - F# - A (Deviante più acuto/sorpresa)

accordo_cons_std = [];
accordo_cons_dev = [];
for i = 1:3
    n_std = sin(2 * pi * f_cons_std(i) * t) .* hanning(length(t))';
    accordo_cons_std = [accordo_cons_std, n_std, zeros(1, round(Fs*0.03))];
    
    n_dev = sin(2 * pi * f_cons_dev(i) * t) .* hanning(length(t))';
    accordo_cons_dev = [accordo_cons_dev, n_dev, zeros(1, round(Fs*0.03))];
end

%% 2. BLOCCO DISSONANTE (Accordo Teso / Tritoni e Semitoni Stretti)
% Frequenze vicine e con intervalli di tritone (forte battito acustico)
f_diss_std = [261.63, 277.18, 369.99];   % Do - Do# - Fa# (Standard aspro)
f_diss_dev = [293.66, 311.13, 415.30];   % Re - Re# - Sol# (Deviante aspro)

accordo_diss_std = [];
accordo_diss_dev = [];
for i = 1:3
    n_std = sin(2 * pi * f_diss_std(i) * t) .* hanning(length(t))';
    accordo_diss_std = [accordo_diss_std, n_std, zeros(1, round(Fs*0.03))];
    
    n_dev = sin(2 * pi * f_diss_dev(i) * t) .* hanning(length(t))';
    accordo_diss_dev = [accordo_diss_dev, n_dev, zeros(1, round(Fs*0.03))];
end

%% Riproduzione Audio Sequenziale
disp('--------------------------------------------------');
disp(' 1. ASCOLTO BLOCCO CONSONANTE (Accordo maggiore pulito)');
disp('--------------------------------------------------');
disp('-> Standard consonante (suono stabile e aperto):');
sound(accordo_cons_std, Fs);
pause(2.5);
disp('-> Deviante consonante (stesso stile, altezza diversa - la sorpresa):');
sound(accordo_cons_dev, Fs);

pause(3);

disp('--------------------------------------------------');
disp(' 2. ASCOLTO BLOCCO DISSONANTE (Accordo teso / aspro)');
disp('--------------------------------------------------');
disp('-> Standard dissonante (sentirai subito l attrito/fastidio):');
sound(accordo_diss_std, Fs);
pause(2.5);
disp('-> Deviante dissonante (la sorpresa nello stesso mondo teso):');
sound(accordo_diss_dev, Fs);