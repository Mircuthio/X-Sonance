function ResultsTSNE = ...
    OLDplot_fbcsp_tsne( ...
    Features,...
    TrainTrials,...
    TestTrials,...
    outdir,...
    prefix)

%% ============================================================
% INPUT VALIDATION
%% ============================================================

assert(isfield(Features,'Xtrain'));
assert(isfield(Features,'Xtest'));

Xtrain = Features.Xtrain;
Ytrain = Features.Ytrain;

Xtest  = Features.Xtest;
Ytest  = Features.Ytest;

%% ============================================================
% SUBJECT IDS
%% ============================================================

TrainSubjects = ...
    {TrainTrials.subjectID}';

TestSubjects = ...
    {TestTrials.subjectID}';

%% ============================================================
% TSNE
%% ============================================================

fprintf('\n');
fprintf('================================\n');
fprintf('TSNE ANALYSIS\n');
fprintf('================================\n');

YtsneTrain = tsne( ...
    Xtrain,...
    'NumDimensions',2,...
    'Perplexity',30,...
    'Standardize',true);

YtsneTest = tsne( ...
    Xtest,...
    'NumDimensions',2,...
    'Perplexity',30,...
    'Standardize',true);

%% ============================================================
% PCA
%% ============================================================

[~,scoreTrain] = pca(Xtrain);
[~,scoreTest]  = pca(Xtest);

YpcaTrain = scoreTrain(:,1:2);
YpcaTest  = scoreTest(:,1:2);

%% ============================================================
% OUTPUT DIR
%% ============================================================

tsneOutDir = ...
    fullfile(outdir,'TSNE');

if ~exist(tsneOutDir,'dir')
    mkdir(tsneOutDir);
end

%% ============================================================
% TSNE TRAIN CLASS
%% ============================================================

f = figure('Color','w');

gscatter( ...
    YtsneTrain(:,1),...
    YtsneTrain(:,2),...
    Ytrain);

grid on

xlabel('TSNE 1');
ylabel('TSNE 2');

title(sprintf( ...
    '%s - TSNE TRAIN CLASS', ...
    prefix));

saveas( ...
    f,...
    fullfile( ...
    tsneOutDir,...
    [prefix '_TSNE_TRAIN_CLASS.png']));

close(f)

%% ============================================================
% TSNE TRAIN SUBJECT
%% ============================================================

f = figure('Color','w');

gscatter( ...
    YtsneTrain(:,1),...
    YtsneTrain(:,2),...
    TrainSubjects);

grid on

xlabel('TSNE 1');
ylabel('TSNE 2');

title(sprintf( ...
    '%s - TSNE TRAIN SUBJECT', ...
    prefix));

saveas( ...
    f,...
    fullfile( ...
    tsneOutDir,...
    [prefix '_TSNE_TRAIN_SUBJECT.png']));

close(f)

%% ============================================================
% TSNE TEST CLASS
%% ============================================================

f = figure('Color','w');

gscatter( ...
    YtsneTest(:,1),...
    YtsneTest(:,2),...
    Ytest);

grid on

xlabel('TSNE 1');
ylabel('TSNE 2');

title(sprintf( ...
    '%s - TSNE TEST CLASS', ...
    prefix));

saveas( ...
    f,...
    fullfile( ...
    tsneOutDir,...
    [prefix '_TSNE_TEST_CLASS.png']));

close(f)

%% ============================================================
% TSNE TEST SUBJECT
%% ============================================================

f = figure('Color','w');

gscatter( ...
    YtsneTest(:,1),...
    YtsneTest(:,2),...
    TestSubjects);

grid on

xlabel('TSNE 1');
ylabel('TSNE 2');

title(sprintf( ...
    '%s - TSNE TEST SUBJECT', ...
    prefix));

saveas( ...
    f,...
    fullfile( ...
    tsneOutDir,...
    [prefix '_TSNE_TEST_SUBJECT.png']));

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
    '%s - PCA TRAIN CLASS', ...
    prefix));

saveas( ...
    f,...
    fullfile( ...
    tsneOutDir,...
    [prefix '_PCA_TRAIN_CLASS.png']));

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
    '%s - PCA TEST CLASS', ...
    prefix));

saveas( ...
    f,...
    fullfile( ...
    tsneOutDir,...
    [prefix '_PCA_TEST_CLASS.png']));

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

ResultsTSNE.TSNETrain = ...
    YtsneTrain;

ResultsTSNE.TSNETest = ...
    YtsneTest;

ResultsTSNE.PCATrain = ...
    YpcaTrain;

ResultsTSNE.PCATest = ...
    YpcaTest;

save( ...
    fullfile( ...
    tsneOutDir,...
    [prefix '_TSNE_RESULTS.mat']),...
    'ResultsTSNE',...
    '-v7.3');

fprintf('TSNE COMPLETED\n');

end