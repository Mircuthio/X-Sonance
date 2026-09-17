addpath(genpath('D:\eeglab2026.0.0\'))

filename = 'sub-S04_ses-CH04_task-Default_run-001_eeg.xdf';
% Carica il file XDF
streams = load_xdf(filename);
% streams = load_xdf(filename, 'Verbose', true);
% Ipeziona i flussi (streams) presenti nel file
for i = 1:length(streams)
    fprintf('Stream %d:\n', i);
    fprintf('  - Nome: %s\n', streams{i}.info.name);
    fprintf('  - Tipo: %s\n', streams{i}.info.type);
    fprintf('  - Numero di campioni: %d\n\n', size(streams{i}.time_series, 2));
end


% try
%     % Esegue il caricamento (con la modifica fatta su load_xdf)
%     streams = load_xdf(filename, 'Verbose', true);
%     disp('Caricamento completato (con recupero parziale del file troncato).');
% catch ME
%     warning('Errore imprevisto durante il caricamento: %s', ME.message);
% end
% 
% % Verifica rapida dei flussi recuperati
% for i = 1:length(streams)
%     fprintf('Stream %d: %s (%s) - Campioni: %d\n', ...
%         i, streams{i}.info.name, streams{i}.info.type, size(streams{i}.time_series, 2));
% end


%% MARKERS CONTROL
markerStream = streams{3};
markerStream.time_series(1:20)

for k = 1:20
disp(markerStream.time_series{k})
end

markers = markerStream.time_series;

codes = strings(length(markers),1);

for i=1:length(markers)
    codes(i) = string(markers{i});
end

unique(codes)

tabulate(codes)

u = unique(codes);

for i=1:length(u)
    fprintf('%s -> %d\n',u(i),sum(codes==u(i)));
end


for i=1:30
    disp(markers{i})
end

%controllo con eeg
eeg = streams{2};
mrk = streams{3};

eeg.time_stamps(1)
mrk.time_stamps(1)
eeg.time_stamps(end)
mrk.time_stamps(end)
if eeg.time_stamps(1) < mrk.time_stamps(1)
    disp("Primo marker > inizio EEG")
end
if eeg.time_stamps(end) > mrk.time_stamps(end)
    disp("Ultimo marker < fine EEG")
end

%%CHECK CHIESTO
markerStream = streams{3};

markers = markerStream.time_series;
times = markerStream.time_stamps;

for k = 1:30
    fprintf('%f --> %s\n',times(k),markers{k});
end

% CHECK MARKERS USATI
markers = string(markerStream.time_series);

target_idx = markers ~= "10" & markers ~= "20";

targets = markers(target_idx);

unique(targets)

markers = string(markerStream.time_series);

ok = true;

for k = 1:3:length(markers)

    if markers(k) ~= "10"
        ok = false;
        fprintf("Errore posizione %d\n",k);
        break;
    end

    if markers(k+2) ~= "20"
        ok = false;
        fprintf("Errore posizione %d\n",k);
        break;
    end

end

disp(ok)

codes = str2double(cellstr(markers));
codes(1:10)
eeg = streams{2};

baselineSec = markerStream.time_stamps(1) - eeg.time_stamps(1)

baselineMin = baselineSec/60
startIdx = find(codes==10);

condIdx = find(ismember(codes,[101 102 103]));

endIdx = find(codes==20);
start_to_cond = ...
    markerStream.time_stamps(condIdx) - ...
    markerStream.time_stamps(startIdx);

cond_to_end = ...
    markerStream.time_stamps(endIdx) - ...
    markerStream.time_stamps(condIdx);

mean(start_to_cond)
mean(cond_to_end)

iti = ...
    markerStream.time_stamps(startIdx(2:end)) - ...
    markerStream.time_stamps(endIdx(1:end-1));

mean(iti)
min(iti)
max(iti)

expDuration = ...
markerStream.time_stamps(end) - ...
markerStream.time_stamps(1);
expDuration/60

%% disp values
baselineSec
mean(start_to_cond)
mean(cond_to_end)
mean(iti)
min(iti)
max(iti)
expDuration/60
sum(codes==101)
sum(codes==102)
sum(codes==103)


figure

for ch = 1:66
    subplot(11,6,ch)
    plot(EEG.data(ch,1:5000))
    axis tight
    title(num2str(ch))
end