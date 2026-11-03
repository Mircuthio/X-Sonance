%% =========================================================================
% STEP109_TSNE_FRAMEWORK
%
% VISUALIZATION OF FEATURE SPACES
%
% DATASETS
%
%   FULL_264
%   ERP_ONLY_156
%   BANDPOWER_ONLY_108
%   REDUCED_29
%
%% =========================================================================
clear
close all
clc
origState = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','off');

set(groot,...
    'defaultTextInterpreter','tex');
set(groot,...
    'defaultAxesTickLabelInterpreter','tex');
set(groot,...
    'defaultLegendInterpreter','tex');
%% =========================================================================
% PATHS
%% =========================================================================
projectRoot = ...
    'C:\Users\mirco\Desktop\X-SONANCE\Dataset_MARCO';

indir = fullfile( ...
    projectRoot,...
    'STEP105_FINAL_DATASETS');

outdir = fullfile( ...
    projectRoot,...
    'STEP109_TSNE_FRAMEWORK');

if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% =========================================================================
% CONFIG
%% =========================================================================
cfgTSNE = struct();
cfgTSNE.randomSeed = 10;
cfgTSNE.perplexity = 30;
cfgTSNE.numDimensions = 3;

cfgTSNE.pca = true;

rng(cfgTSNE.randomSeed)

%% =========================================================================
% DATASETS
%% =========================================================================
DatasetInfo = {
    'DATASET_FULL_264.mat'           'FULL_264'
    'DATASET_ERP_ONLY_156.mat'       'ERP_ONLY_156'
    'DATASET_BANDPOWER_ONLY_108.mat' 'BANDPOWER_ONLY_108'
    'DATASET_REDUCED_29.mat'         'REDUCED_29'
    };

%% =========================================================================
% LOOP DATASETS
%% =========================================================================
for iDataset = 1:size(DatasetInfo,1)

    datasetFile = DatasetInfo{iDataset,1};
    variableName = DatasetInfo{iDataset,2};

    fprintf('\n');
    fprintf('========================================\n');
    fprintf('%s\n',variableName);
    fprintf('========================================\n');

    S = load(fullfile(indir,datasetFile));
    Dataset = S.(variableName);
    assert(isfield(Dataset,'cfg'), ...
        'Dataset.cfg not found');

    assert(isfield(Dataset.cfg,'class_codes'), ...
        'Dataset.cfg.class_codes not found');

    assert(isfield(Dataset.cfg,'class_labels'), ...
        'Dataset.cfg.class_labels not found');

    class_codes = ...
        Dataset.cfg.class_codes;

    class_labels = ...
        Dataset.cfg.class_labels;

    X = Dataset.X;
    Y = Dataset.Y;
    SubjectID = Dataset.SubjectID;
    SubjectID = categorical(SubjectID);
    SubjectPlot = removecats(SubjectID);
    fprintf('\n');
    fprintf('Classes found:\n');
    for iClass = 1:numel(class_codes)
        fprintf('%s (%d)\n',class_labels{iClass},class_codes(iClass));
    end

    %% ============================================================
    % CHECKS
    %% ============================================================
    assert(size(X,1) == length(Y))
    assert(size(X,1) == length(SubjectID))

    fprintf('Trials   : %d\n', ...
        size(X,1));
    fprintf('Features : %d\n', ...
        size(X,2));

    %% ============================================================
    % CLASS LABELS
    %% ============================================================
    classesFound = unique(Y);
    assert(numel(classesFound) == numel(class_labels), ...
        'Mismatch between Y classes and labels');
    Yplot = strings(size(Y));
    for iClass = 1:numel(classesFound)
        Yplot(Y == classesFound(iClass)) = ...
            string(class_labels{iClass});
    end
    Yplot = categorical(Yplot);

    %% ============================================================
    % ZSCORE
    %% ============================================================
    X = zscore(X);

    %% ============================================================
    % TSNE
    %% ============================================================
    fprintf('Computing TSNE...\n');

    fprintf('Running t-SNE...\n');
    fprintf('Perplexity : %d\n', ...
        cfgTSNE.perplexity);

    fprintf('Dimensions : %d\n', ...
        cfgTSNE.numDimensions);

    rng(cfgTSNE.randomSeed)

    Ytsne = tsne( ...
        X,...
        'NumDimensions',cfgTSNE.numDimensions,...
        'Perplexity',cfgTSNE.perplexity,...
        'Standardize',false);

    %% ============================================================
    % PCA
    %% ============================================================
    if cfgTSNE.pca
        fprintf('Computing PCA...\n');

        [~,score,~,~,explained] = pca(X);

        Ypca = score(:,1:2);

        fprintf('PCA variance explained: PC1 %.2f%%, PC2 %.2f%%\n', ...
            explained(1), ...
            explained(2));
    end
    %% ============================================================
    % OUTPUT DIR
    %% ============================================================
    datasetOut = ...
        fullfile(outdir,variableName);

    if ~exist(datasetOut,'dir')
        mkdir(datasetOut);
    end

    %% ============================================================
    % TSNE CLASS
    %% ============================================================
    f = figure('Color','w');

    if cfgTSNE.numDimensions == 2

        gscatter( ...
            Ytsne(:,1),...
            Ytsne(:,2),...
            Yplot);

        xlabel('t-SNE 1')
        ylabel('t-SNE 2')

    elseif cfgTSNE.numDimensions == 3

        classes = categories(Yplot);

        hold on

        for iClass = 1:numel(classes)
            idx = Yplot == classes{iClass};
            scatter3( ...
                Ytsne(idx,1),...
                Ytsne(idx,2),...
                Ytsne(idx,3),...
                25,...
                'filled');
        end

        hold off

        legend(classes, ...
            'Location','bestoutside')

        xlabel('t-SNE 1')
        ylabel('t-SNE 2')
        zlabel('t-SNE 3')

        grid on
        view(45,25)
    end

    title(sprintf( ...
        '%s - t-SNE by Class', ...
        format_tex_name(variableName)))

    exportgraphics( ...
        f,...
        fullfile(datasetOut, ...
        sprintf('%s_TSNE_CLASS_3D.png',variableName)), ...
        'Resolution',300);

    close(f)

    %% ============================================================
    % TSNE SUBJECT
    %% ============================================================
    f = figure('Color','w');

    if cfgTSNE.numDimensions == 2

        gscatter( ...
            Ytsne(:,1),...
            Ytsne(:,2),...
            SubjectPlot);

        xlabel('t-SNE 1')
        ylabel('t-SNE 2')

    elseif cfgTSNE.numDimensions == 3

        subjects = categories(SubjectPlot);

        hold on

        for iSub = 1:numel(subjects)
            idx = SubjectPlot == subjects{iSub};
            scatter3( ...
                Ytsne(idx,1),...
                Ytsne(idx,2),...
                Ytsne(idx,3),...
                25,...
                'filled');
        end

        hold off

        legend(subjects, ...
            'Location','bestoutside')

        xlabel('t-SNE 1')
        ylabel('t-SNE 2')
        zlabel('t-SNE 3')

        grid on
        view(45,25)
    end

    title(sprintf( ...
        '%s - t-SNE by Subject', ...
        format_tex_name(variableName)))

    exportgraphics( ...
        f,...
        fullfile(datasetOut, ...
        sprintf('%s_TSNE_SUBJECT_3D.png',variableName)), ...
        'Resolution',300);

    close(f)
    %% ============================================================
    % PCA
    %% ============================================================
    if cfgTSNE.pca
        %% ============================================================
        % PCA CLASS
        %% ============================================================
        f = figure('Color','w');

        gscatter( ...
            Ypca(:,1),...
            Ypca(:,2),...
            Yplot);

        title(sprintf( ...
            '%s - PCA by Class', ...
            format_tex_name(variableName)));

        xlabel('PC1')
        ylabel('PC2')

        legend('Location','bestoutside')

        exportgraphics( ...
            f,...
            fullfile(datasetOut, ...
            sprintf('%s_PCA_CLASS.png',variableName)), ...
            'Resolution',300);

        close(f)

        %% ============================================================
        % PCA SUBJECT
        %% ============================================================
        f = figure('Color','w');

        gscatter( ...
            Ypca(:,1),...
            Ypca(:,2),...
            SubjectPlot);

        title(sprintf( ...
            '%s - PCA by Subject', ...
            format_tex_name(variableName)));

        xlabel('PC1')
        ylabel('PC2')
        legend('Location','bestoutside')
        exportgraphics( ...
            f,...
            fullfile(datasetOut, ...
            sprintf('%s_PCA_SUBJECT.png',variableName)), ...
            'Resolution',300);

        close(f)
    end
    %% ============================================================
    % SAVE RESULTS
    %% ============================================================
    TSNEResults = struct();

    TSNEResults.DatasetName = variableName;
    TSNEResults.X = X;
    TSNEResults.TSNE = Ytsne;
    TSNEResults.Y = Y;
    TSNEResults.Yplot =  Yplot;
    TSNEResults.SubjectID = SubjectID;
    TSNEResults.cfg = cfgTSNE;
    TSNEResults.Classes = unique(Y);
    TSNEResults.ClassLabels = categories(Yplot);
    TSNEResults.ClassCodes = class_codes;
    TSNEResults.ClassLabelsOriginal = class_labels;

    if cfgTSNE.pca
        TSNEResults.PCA = ...
            Ypca;
        TSNEResults.PCAExplainedVariance = ...
            explained(1:2);
    end

    save( ...
        fullfile(datasetOut,'TSNE_RESULTS.mat'),...
        'TSNEResults');

end

%% =========================================================================
% COMPLETED
%% =========================================================================
fprintf('\n');
fprintf('========================================\n');
fprintf('STEP109 TSNE FRAMEWORK COMPLETED\n');
fprintf('========================================\n');