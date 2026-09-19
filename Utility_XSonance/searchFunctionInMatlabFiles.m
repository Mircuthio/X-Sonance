function results = searchFunctionInMatlabFiles(functionName, rootFolder)
%SEARCHFUNCTIONINMATLABFILES Cerca una funzione nei file .m.
%
%   results = searchFunctionInMatlabFiles(functionName)
%   cerca FUNCTIONNAME nella cartella corrente e nelle sottocartelle.
%
%   results = searchFunctionInMatlabFiles(functionName, rootFolder)
%   cerca FUNCTIONNAME nella cartella ROOTFOLDER e nelle sottocartelle.
%
%   Esempi:
%       searchFunctionInMatlabFiles("circlecenter")
%
%       searchFunctionInMatlabFiles( ...
%           "circlecenter", ...
%           "C:\Users\Nome\Documents\MATLAB")
%
%   RESULTS contiene:
%       results.file      - percorso completo del file
%       results.line      - numero della riga
%       results.text      - contenuto della riga

    arguments
        functionName (1,1) string
        rootFolder (1,1) string = string(pwd)
    end

    % Elimina eventuali spazi iniziali e finali
    functionName = strtrim(functionName);
    rootFolder = strtrim(rootFolder);

    if strlength(functionName) == 0
        error('Il nome della funzione non può essere vuoto.');
    end

    if ~isfolder(rootFolder)
        error('La cartella non esiste:\n%s', rootFolder);
    end

    % Ricerca ricorsiva nella cartella specificata
    files = dir(fullfile(rootFolder, '**', '*.m'));

    % Struttura per salvare i risultati
    results = struct( ...
        'file', {}, ...
        'line', {}, ...
        'text', {});

    % Espressione regolare:
    % cerca il nome come parola indipendente, seguito eventualmente da "("
    escapedName = regexptranslate('escape', char(functionName));

    pattern = ['(?<![A-Za-z0-9_])', escapedName, ...
               '(?![A-Za-z0-9_])'];

    for k = 1:numel(files)

        filePath = fullfile(files(k).folder, files(k).name);

        % Evita di analizzare il file che contiene la funzione stessa
        if strcmpi(files(k).name, functionName + ".m")
            continue;
        end

        try
            lines = readlines(filePath);
        catch ME
            warning('Impossibile leggere "%s": %s', ...
                filePath, ME.message);
            continue;
        end

        % Cerca la funzione in ogni riga
        matchIdx = find(~cellfun('isempty', ...
            regexp(cellstr(lines), pattern, 'once')));

        for i = 1:numel(matchIdx)

            resultIndex = numel(results) + 1;

            results(resultIndex).file = filePath;
            results(resultIndex).line = matchIdx(i);
            results(resultIndex).text = strtrim(lines(matchIdx(i)));

        end
    end

    % Stampa i risultati
    if isempty(results)

        fprintf('Nessuna occorrenza di "%s" trovata in:\n%s\n', ...
            functionName, rootFolder);

    else

        fprintf('\nTrovate %d occorrenze di "%s" in:\n%s\n', ...
            numel(results), functionName, rootFolder);

        currentFile = "";

        for k = 1:numel(results)

            if ~strcmp(results(k).file, currentFile)
                fprintf('\nFile: %s\n', results(k).file);
                currentFile = results(k).file;
            end

            fprintf('  Riga %d: %s\n', ...
                results(k).line, results(k).text);
        end
    end
end