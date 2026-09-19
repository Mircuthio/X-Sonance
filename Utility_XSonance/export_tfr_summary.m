function export_tfr_summary(TFRBandResults,outputFile)

roiNames = fieldnames(TFRBandResults);

%% ------------------------------------------------------------
% count rows
%% ------------------------------------------------------------

nRows = 0;

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    windows = ...
        fieldnames(TFRBandResults.(roiName));

    windows = ...
        setdiff(windows,{'Broadband','TimeCourse'});

    for w = 1:numel(windows)

        winName = windows{w};

        bands = ...
            fieldnames( ...
            TFRBandResults.(roiName).(winName));

        nRows = nRows + numel(bands);

    end
end

%% ------------------------------------------------------------
% preallocation
%% ------------------------------------------------------------

ROI         = strings(nRows,1);
Window      = strings(nRows,1);
Band        = strings(nRows,1);

Consonant   = nan(nRows,1);
Dissonant   = nan(nRows,1);
Difference  = nan(nRows,1);

AbsDiff     = nan(nRows,1);
Priority    = strings(nRows,1);

%% ------------------------------------------------------------
% extraction
%% ------------------------------------------------------------

row = 1;

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    windows = ...
        fieldnames(TFRBandResults.(roiName));

    windows = ...
        setdiff(windows,{'Broadband','TimeCourse'});

    for w = 1:numel(windows)

        winName = windows{w};

        bands = ...
            fieldnames( ...
            TFRBandResults.(roiName).(winName));

        for b = 1:numel(bands)

            bandName = bands{b};

            S = ...
                TFRBandResults.(roiName) ...
                .(winName) ...
                .(bandName);

            diffVal = S.Difference;

            if abs(diffVal) >= 0.50
                priority = "HIGH";
            elseif abs(diffVal) >= 0.25
                priority = "MEDIUM";
            elseif abs(diffVal) >= 0.10
                priority = "LOW";
            else
                priority = "IGNORE";
            end

            ROI(row)        = roiName;
            Window(row)     = winName;
            Band(row)       = bandName;

            Consonant(row)  = S.Consonant;
            Dissonant(row)  = S.Dissonant;
            Difference(row) = diffVal;

            AbsDiff(row)    = abs(diffVal);

            Priority(row)   = priority;

            row = row + 1;

        end
    end
end

%% ------------------------------------------------------------
% table
%% ------------------------------------------------------------

Results = table( ...
    ROI,...
    Window,...
    Band,...
    Consonant,...
    Dissonant,...
    Difference,...
    AbsDiff,...
    Priority);

%% ------------------------------------------------------------
% sort
%% ------------------------------------------------------------

Results = sortrows( ...
    Results,...
    'AbsDiff',...
    'descend');

%% ------------------------------------------------------------
% save
%% ------------------------------------------------------------

writetable( ...
    Results,...
    outputFile);

disp(Results(1:min(30,height(Results)),:));

end