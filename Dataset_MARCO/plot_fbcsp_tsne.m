function ResultsTSNE = ...
    plot_fbcsp_tsne( ...
    Features,...
    TrainTrials,...
    TestTrials,...
    outdir,...
    prefix)
%% ============================================================
% PLOT FBCSP TSNE
%
% Visualize CSP/MI feature space:
%
%   Features.Xtrain / Features.Xtest
%
% - Joint t-SNE on train + test features
% - PCA fitted on train and applied to test
%% ============================================================

%% ============================================================
% INPUT VALIDATION
%% ============================================================
assert(isfield(Features,'Xtrain'), ...
    'Features.Xtrain not found');
assert(isfield(Features,'Xtest'), ...
    'Features.Xtest not found');
assert(isfield(Features,'Ytrain'), ...
    'Features.Ytrain not found');
assert(isfield(Features,'Ytest'), ...
    'Features.Ytest not found');

Xtrain = Features.Xtrain;
Ytrain = Features.Ytrain;
Xtest  = Features.Xtest;
Ytest  = Features.Ytest;

assert(size(Xtrain,2) == size(Xtest,2), ...
    'Train/test feature dimension mismatch');

prefix = strrep(prefix, '_', ' ');
%% ============================================================
% SUBJECT IDS
%% ============================================================
TrainSubjects = ...
    {TrainTrials.subjectID}';
TestSubjects = ...
    {TestTrials.subjectID}';

%% ============================================================
% COMBINE FEATURES
%% ============================================================
Xall = [Xtrain; Xtest];
Yall = [Ytrain; Ytest];

SubjectAll = [TrainSubjects; TestSubjects];

nTrain = size(Xtrain,1);
nTest  = size(Xtest,1);

SetAll = [ ...
    repmat("Train",nTrain,1); ...
    repmat("Test", nTest, 1)];

SetAll = categorical(SetAll);

%% ============================================================
% CLASS LABELS
%% ============================================================
Yplot = strings(size(Yall));

Yplot(Yall == 1) = "Consonant";
Yplot(Yall == 2) = "Dissonant";

assert(all(Yplot ~= ""), ...
    'Some class labels were not mapped');

Yplot = categorical(Yplot);

%% ============================================================
% TSNE ON CSP/MI FEATURES
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('TSNE ANALYSIS\n');
fprintf('================================\n');

rng(10)

YtsneAll = tsne( ...
    Xall,...
    'NumDimensions',2,...
    'Perplexity',30,...
    'Standardize',true);

%% ============================================================
% PCA: FIT ON TRAIN, APPLY TO TEST
%% ============================================================
[coeff,~,~,~,explained,mu] = pca(Xtrain);

YpcaTrain = (Xtrain - mu) * coeff(:,1:2);
YpcaTest  = (Xtest  - mu) * coeff(:,1:2);

%% ============================================================
% OUTPUT DIR
%% ============================================================
tsneOutDir = ...
    fullfile(outdir,'TSNE');

if ~exist(tsneOutDir,'dir')
    mkdir(tsneOutDir);
end

%% ============================================================
% TSNE CLASS
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YtsneAll(:,1),...
    YtsneAll(:,2),...
    Yplot);

grid on
xlabel('t-SNE 1');
ylabel('t-SNE 2');
title(sprintf( ...
    '%s - t-SNE by Class', ...
    prefix));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    [prefix '_TSNE_CLASS.png']), ...
    'Resolution',300);

close(f)

%% ============================================================
% TSNE SUBJECT
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YtsneAll(:,1),...
    YtsneAll(:,2),...
    SubjectAll);

grid on
xlabel('t-SNE 1');
ylabel('t-SNE 2');
title(sprintf( ...
    '%s - t-SNE by Subject', ...
    prefix));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    [prefix '_TSNE_SUBJECT.png']), ...
    'Resolution',300);

close(f)

%% ============================================================
% TSNE TRAIN VS TEST
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YtsneAll(:,1),...
    YtsneAll(:,2),...
    SetAll);

grid on
xlabel('t-SNE 1');
ylabel('t-SNE 2');
title(sprintf( ...
    '%s - t-SNE Train vs Test', ...
    prefix));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    [prefix '_TSNE_TRAIN_VS_TEST.png']), ...
    'Resolution',300);

close(f)

%% ============================================================
% PCA TRAIN CLASS
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YpcaTrain(:,1),...
    YpcaTrain(:,2),...
    Ytrain);

grid on
xlabel('PC1');
ylabel('PC2');
title(sprintf( ...
    '%s - PCA Train by Class', ...
    prefix));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    [prefix '_PCA_TRAIN_CLASS.png']), ...
    'Resolution',300);

close(f)

%% ============================================================
% PCA TEST CLASS
%% ============================================================
f = figure('Color','w');

gscatter( ...
    YpcaTest(:,1),...
    YpcaTest(:,2),...
    Ytest);

grid on
xlabel('PC1');
ylabel('PC2');
title(sprintf( ...
    '%s - PCA Test by Class', ...
    prefix));
legend('Location','bestoutside')

exportgraphics( ...
    f,...
    fullfile(tsneOutDir, ...
    [prefix '_PCA_TEST_CLASS.png']), ...
    'Resolution',300);

close(f)

%% ============================================================
% SAVE RESULTS
%% ============================================================
ResultsTSNE = struct();

ResultsTSNE.Xtrain = Xtrain;
ResultsTSNE.Ytrain = Ytrain;
ResultsTSNE.Xtest = Xtest;
ResultsTSNE.Ytest = Ytest;

ResultsTSNE.SubjectTrain = ...
    TrainSubjects;
ResultsTSNE.SubjectTest = ...
    TestSubjects;

ResultsTSNE.TSNE = ...
    YtsneAll;
ResultsTSNE.Set = ...
    SetAll;
ResultsTSNE.Yplot = ...
    Yplot;

ResultsTSNE.PCATrain = ...
    YpcaTrain;
ResultsTSNE.PCATest = ...
    YpcaTest;
ResultsTSNE.PCAExplainedVariance = ...
    explained(1:2);

save( ...
    fullfile( ...
    tsneOutDir,...
    [prefix '_TSNE_RESULTS.mat']),...
    'ResultsTSNE',...
    '-v7.3');

fprintf('TSNE COMPLETED\n');

end