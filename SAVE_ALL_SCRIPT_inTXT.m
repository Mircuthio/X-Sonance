clc; clear;

% Cartella dove ci sono gli script .m
cartella = 'D:\X-SONANCE\Dataset_MARCO\MAIN';

% % Ordine deciso da te
% listaFile = { ...
%     'script1.m', ...
%     'script3.m', ...
%     'script2.m' ...
%     };

% File txt finale
fileOutput = fullfile(cartella, 'NEWtutti_gli_script.txt');

fidOut = fopen(fileOutput, 'w');
if fidOut == -1
    error('Impossibile creare il file di output.');
end
files = dir(fullfile(cartella, '*.m'));
listaFile = {files.name};

listaFile = sort(listaFile);

for i = 1:numel(listaFile)
    fileCorrente = fullfile(cartella, listaFile{i});
    
    if ~isfile(fileCorrente)
        warning('File non trovato: %s', fileCorrente);
        continue;
    end
    
    testo = fileread(fileCorrente);
    
    fprintf(fidOut, '==============================\n');
    fprintf(fidOut, 'FILE: %s\n', listaFile{i});
    fprintf(fidOut, '==============================\n\n');
    fprintf(fidOut, '%s\n\n', testo);
end

fclose(fidOut);

disp(['Creato file: ' fileOutput]);