%% ============================================================
% STEP4A_BANDPOWER_FEATURES
% ERP-like quantitative feature extraction
%% ============================================================
clear
close all
clc

load( ...
    'BANDPOWER_STEP4A_RESULTS.mat',...
    'BandPower_Subj');

subjNames = fieldnames(BandPower_Subj);

%% ============================================================
% SETTINGS
%% ============================================================

roiNames = { ...
    'ERAN_CORE'};
% ,...
%     'MMN',...
%     'FrontoCentral',...
%     'N5_CENTRAL',...
%     'Occipital',...
%     'Parietal'};

bandNames = { ...
    'Delta',...
    'Theta',...
    'Alpha',...
    'BetaLow',...
    'BetaHigh',...
    'GammaLow',...
    'GammaHigh'};

%% ============================================================
% WINDOWS
%% ============================================================

Windows = struct();

Windows.EarlyNeg = [0.170 0.220];
Windows.Rebound  = [0.220 0.320];
Windows.Late     = [0.450 0.550];
Windows.Global   = [0.000 0.800];
Windows.ERAN     = [0.100 0.250];

windowNames = fieldnames(Windows);

%% ============================================================
% OUTPUT CONTAINERS
%% ============================================================
nSubj  = numel(subjNames);
nROI   = numel(roiNames);
nBand  = numel(bandNames);
nWin   = numel(windowNames);

maxLongRows = nSubj * nROI * nBand * nWin;

LongCell = cell(maxLongRows,1);
longRowCounter = 0;

WideCell = cell(nSubj,1);
wideRowCounter = 0;

%% ============================================================
% LOOP SUBJECTS
%% ============================================================

for iSub = 1:numel(subjNames)

    subjID = subjNames{iSub};

    fprintf('\n%s\n',subjID);

    WideStruct = struct();
    WideStruct.Subject = string(subjID);

    for r = 1:numel(roiNames)

        roiName = roiNames{r};

        for b = 1:numel(bandNames)

            bandName = bandNames{b};

            try

                bp = ...
                    BandPower_Subj.(subjID).(roiName).(bandName);

                timeVec = bp.time(:);
                wave    = bp.Difference.power(:);

            catch ME
                fprintf('Missing %s | %s\n', ...
                    roiName,...
                    bandName);
                fprintf('%s\n',ME.message);
                continue
            end

            for w = 1:numel(windowNames)

                winName = windowNames{w};

                winLim = Windows.(winName);

                idx = ...
                    timeVec >= winLim(1) & ...
                    timeVec <= winLim(2);

                tWin = timeVec(idx);
                yWin = wave(idx);

                if isempty(yWin)
                    continue
                end

                %% ==========================================
                % FEATURES
                %% ==========================================

                MeanVal = mean(yWin);

                StdVal  = std(yWin);

                RMSVal  = rms(yWin);

                [PeakMin,idxMin] = min(yWin);
                PeakMinLat = tWin(idxMin);

                [PeakMax,idxMax] = max(yWin);
                PeakMaxLat = tWin(idxMax);

                PeakToPeak = PeakMax - PeakMin;

                SignedAUC = trapz(tWin,yWin);

                AbsAUC = trapz( ...
                    tWin,...
                    abs(yWin));

                MeanAbs = mean(abs(yWin));

                %% ==========================================
                % LONG FORMAT
                %% ==========================================

                tmp = table( ...
                    string(subjID),...
                    string(roiName),...
                    string(bandName),...
                    string(winName),...
                    MeanVal,...
                    StdVal,...
                    RMSVal,...
                    PeakMin,...
                    PeakMinLat,...
                    PeakMax,...
                    PeakMaxLat,...
                    PeakToPeak,...
                    SignedAUC,...
                    AbsAUC,...
                    MeanAbs,...
                    'VariableNames',{ ...
                    'Subject',...
                    'ROI',...
                    'Band',...
                    'Window',...
                    'Mean',...
                    'Std',...
                    'RMS',...
                    'PeakMin',...
                    'PeakMinLatency',...
                    'PeakMax',...
                    'PeakMaxLatency',...
                    'PeakToPeak',...
                    'SignedAUC',...
                    'AbsAUC',...
                    'MeanAbs'});

                longRowCounter = longRowCounter + 1;
                LongCell{longRowCounter} = tmp;

                %% ==========================================
                % WIDE FORMAT
                %% ==========================================

                prefix = sprintf( ...
                    '%s_%s_%s',...
                    roiName,...
                    bandName,...
                    winName);

                WideStruct.([prefix '_Mean']) = MeanVal;
                WideStruct.([prefix '_Std']) = StdVal;
                WideStruct.([prefix '_RMS']) = RMSVal;

                WideStruct.([prefix '_PeakMin']) = PeakMin;
                WideStruct.([prefix '_PeakMinLat']) = PeakMinLat;

                WideStruct.([prefix '_PeakMax']) = PeakMax;
                WideStruct.([prefix '_PeakMaxLat']) = PeakMaxLat;

                WideStruct.([prefix '_PeakToPeak']) = PeakToPeak;

                WideStruct.([prefix '_SignedAUC']) = SignedAUC;
                WideStruct.([prefix '_AbsAUC'])    = AbsAUC;

                WideStruct.([prefix '_MeanAbs'])   = MeanAbs;

            end
        end
    end

    wideRowCounter = wideRowCounter + 1;
    WideCell{wideRowCounter} = WideStruct;

end

%% ============================================================
% OUTPUT DIRECTORY
%% ============================================================

outdir = fullfile( ...
    pwd,...
    'STEP4A_FEATURES');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% ============================================================
% CONVERT ACCUMULATED DATA TO TABLES
%% ============================================================
if longRowCounter == 0
    LongTable = table( ...
        string([]),string([]),string([]),string([]),...
        [],[],[],[],[],[],[],[],[],[],[],...
        'VariableNames',{ ...
        'Subject','ROI','Band','Window',...
        'Mean','Std','RMS',...
        'PeakMin','PeakMinLatency',...
        'PeakMax','PeakMaxLatency',...
        'PeakToPeak','SignedAUC','AbsAUC','MeanAbs'});
else
    LongTable = vertcat(LongCell{1:longRowCounter});
end

if wideRowCounter == 0
    error('Nessun soggetto valido trovato in BandPower_Subj.');
else
    WideStructArray = ...
        [WideCell{1:wideRowCounter}];

    WideRows = ...
        struct2table(WideStructArray);
end
%% ============================================================
% EXPORT CSV
%% ============================================================

writetable( ...
    LongTable,...
    fullfile( ...
    outdir,...
    'BandPower_Features_Long.csv'));

writetable( ...
    WideRows,...
    fullfile( ...
    outdir,...
    'BandPower_Features_Wide.csv'));

%% ============================================================
% SAVE MAT
%% ============================================================

save( ...
    fullfile( ...
    outdir,...
    'BandPower_Features.mat'),...
    'LongTable',...
    'WideRows',...
    'Windows',...
    '-v7.3');

%% ============================================================
% SUMMARY
%% ============================================================

fprintf('\n');
fprintf('=====================================\n');
fprintf('STEP4A FEATURE EXTRACTION COMPLETED\n');
fprintf('=====================================\n');

fprintf('Subjects : %d\n',numel(subjNames));
fprintf('ROIs     : %d\n',numel(roiNames));
fprintf('Bands    : %d\n',numel(bandNames));
fprintf('Windows  : %d\n',numel(windowNames));
fprintf('Long rows: %d\n',height(LongTable));
fprintf('\n');