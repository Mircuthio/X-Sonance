%% =========================================================================
% STEP106A_ANALYZE_FOLDS
%
% ANALISI FOLD-BY-FOLD
%
% DATASETS:
%   FULL_264
%   ERP_ONLY_156
%   BANDPOWER_ONLY_108
%   REDUCED_29
%
%% =========================================================================
clear
close all
clc

%% =========================================================================
% PATHS
%% =========================================================================

projectRoot = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

indir = fullfile( ...
    projectRoot,...
    'STEP106_GENERAL_CLASSIFIER_LOSO','noZscore');

%% =========================================================================
% FILES
%% =========================================================================

DatasetFiles = { ...
    'FULL_264_LOSO.mat'
    'ERP_ONLY_156_LOSO.mat'
    'BANDPOWER_ONLY_108_LOSO.mat'
    'REDUCED_29_LOSO.mat'};

Classifiers = { ...
    'QDA'
    'KNN'};
    % 'NB'};

%% =========================================================================
% ANALYSIS
%% =========================================================================

SummaryTable = table();

for iDataset = 1:numel(DatasetFiles)

    fprintf('\n');
    fprintf('====================================================\n');
    fprintf('%s\n',DatasetFiles{iDataset});
    fprintf('====================================================\n');

    S = load(fullfile(indir,DatasetFiles{iDataset}));

    Results_LOSO = S.Results_LOSO;

    for iClf = 1:numel(Classifiers)

        classifierName = Classifiers{iClf};

        fprintf('\n');
        fprintf('%s\n',classifierName);

        Folds = ...
            Results_LOSO.(classifierName).Fold;

        for iFold = 1:numel(Folds)

            ACC = ...
                Folds(iFold).TestMetrics.ACC;

            BA = ...
                Folds(iFold).TestMetrics.BA;

            F1 = ...
                Folds(iFold).TestMetrics.F1;

            MCC = ...
                Folds(iFold).TestMetrics.MCC;

            fprintf(['Subject %-10s ' ...
                'ACC=%.3f  BA=%.3f  ' ...
                'F1=%.3f  MCC=%.3f\n'], ...
                Folds(iFold).testSubject,...
                ACC,...
                BA,...
                F1,...
                MCC);

            newRow = table( ...
                string(Results_LOSO.DatasetName), ...
                string(classifierName), ...
                string(Folds(iFold).testSubject), ...
                ACC,...
                BA,...
                F1,...
                MCC,...
                'VariableNames',{ ...
                'Dataset',...
                'Classifier',...
                'Subject',...
                'ACC',...
                'BA',...
                'F1',...
                'MCC'});

            SummaryTable = ...
                [SummaryTable ; newRow];

        end
    end
end

%% =========================================================================
% SAVE
%% =========================================================================

writetable( ...
    SummaryTable,...
    fullfile( ...
    indir,...
    'STEP106_FOLD_BY_FOLD_RESULTS.xlsx'));

save( ...
    fullfile( ...
    indir,...
    'STEP106_FOLD_BY_FOLD_RESULTS.mat'),...
    'SummaryTable');

%% =========================================================================
% BEST / WORST SUBJECTS
%% =========================================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('SUBJECT SUMMARY\n');
fprintf('====================================================\n');

Subjects = unique(SummaryTable.Subject);

for i = 1:numel(Subjects)

    idx = ...
        SummaryTable.Subject == Subjects(i);

    fprintf('%s\n',Subjects(i));

    fprintf('Mean BA  = %.3f\n', ...
        mean(SummaryTable.BA(idx)));

    fprintf('Mean MCC = %.3f\n', ...
        mean(SummaryTable.MCC(idx)));

    fprintf('\n');

end

fprintf('DONE\n');