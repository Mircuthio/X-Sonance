function export_stats_summary(StatsStruct,outputFile)

roiNames = fieldnames(StatsStruct);

%% ============================================================
% COUNT ROWS
%% ============================================================
nRows = 0;

for r = 1:numel(roiNames)

    roiName = roiNames{r};
    winNames = fieldnames(StatsStruct.(roiName));

    for w = 1:numel(winNames)

        winName = winNames{w};

        metricNames = ...
            fieldnames(StatsStruct.(roiName).(winName));

        nRows = nRows + numel(metricNames);

    end
end

%% ============================================================
% PREALLOCATION
%% ============================================================
ROI        = strings(nRows,1);
Window     = strings(nRows,1);
Metric     = strings(nRows,1);

p          = nan(nRows,1);
CohenD     = nan(nRows,1);
t          = nan(nRows,1);
df         = nan(nRows,1);

Status     = strings(nRows,1);
Priority   = strings(nRows,1);
FigureFile = strings(nRows,1);

%% ============================================================
% EXTRACT RESULTS
%% ============================================================
row = 1;

for r = 1:numel(roiNames)

    roiName = roiNames{r};

    winNames = fieldnames(StatsStruct.(roiName));

    for w = 1:numel(winNames)

        winName = winNames{w};

        metricNames = ...
            fieldnames(StatsStruct.(roiName).(winName));

        for m = 1:numel(metricNames)

            metricName = metricNames{m};

            S = StatsStruct.(roiName) ...
                .(winName) ...
                .(metricName);

            %% STATUS

            if S.p < 0.05
                status = "SIGNIFICANT";
            elseif S.p < 0.10
                status = "TREND";
            else
                status = "NS";
            end

            %% PPT PRIORITY

            if S.p < 0.05 && abs(S.cohen_d) >= 0.8
                priority = "HIGH";
            elseif S.p < 0.05
                priority = "MEDIUM";
            elseif S.p < 0.10 && abs(S.cohen_d) >= 0.5
                priority = "LOW";
            else
                priority = "IGNORE";
            end

            %% STORE

            ROI(row)        = string(roiName);
            Window(row)     = string(winName);
            Metric(row)     = string(metricName);

            p(row)          = S.p;
            CohenD(row)     = S.cohen_d;
            t(row)          = S.tstat;
            df(row)         = S.df;

            Status(row)     = status;
            Priority(row)   = priority;

            FigureFile(row) = sprintf( ...
                '%s_%s_%s.png', ...
                roiName, ...
                winName, ...
                metricName);

            row = row + 1;

        end
    end
end

%% ============================================================
% TABLE
%% ============================================================
Results = table( ...
    ROI,...
    Window,...
    Metric,...
    p,...
    CohenD,...
    t,...
    df,...
    Status,...
    Priority,...
    FigureFile);

Results = sortrows(Results,'p');

%% ============================================================
% SAVE
%% ============================================================
writetable(Results,outputFile);

%% ============================================================
% DISPLAY
%% ============================================================
disp(Results(1:min(30,height(Results)),:));

end