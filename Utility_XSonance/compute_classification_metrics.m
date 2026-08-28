function Metrics = compute_classification_metrics( ...
    Ytrue,...
    Ypred)

%% ============================================================
% INPUT VALIDATION
%% ============================================================
assert(~isempty(Ytrue), ...
    'Ytrue is empty');

assert(~isempty(Ypred), ...
    'Ypred is empty');

assert(numel(Ytrue)==numel(Ypred), ...
    'Ytrue and Ypred size mismatch');

Ytrue = Ytrue(:);
Ypred = Ypred(:);

%% ============================================================
% CLASSES
%% ============================================================
classLabels = ...
    unique([Ytrue;Ypred]);

nClasses = ...
    numel(classLabels);

%% ============================================================
% CONFUSION MATRIX
%% ============================================================
CM = ...
    confusionmat( ...
    Ytrue,...
    Ypred,...
    'Order',...
    classLabels);

%% ============================================================
% GLOBAL METRICS
%% ============================================================
ACC = ...
    mean(Ytrue == Ypred);

%% ============================================================
% PER-CLASS METRICS
%% ============================================================
PrecisionVec   = zeros(nClasses,1);
RecallVec      = zeros(nClasses,1);
SpecificityVec = zeros(nClasses,1);
F1Vec          = zeros(nClasses,1);

for iClass = 1:nClasses

    TP = CM(iClass,iClass);

    FN = ...
        sum(CM(iClass,:)) - TP;

    FP = ...
        sum(CM(:,iClass)) - TP;

    TN = ...
        sum(CM(:)) - TP - FN - FP;

    PrecisionVec(iClass) = ...
        TP / max(1,(TP+FP));

    RecallVec(iClass) = ...
        TP / max(1,(TP+FN));

    SpecificityVec(iClass) = ...
        TN / max(1,(TN+FP));

    F1Vec(iClass) = ...
        2 * ...
        (PrecisionVec(iClass) * RecallVec(iClass)) / ...
        max(eps,...
        PrecisionVec(iClass)+RecallVec(iClass));

end

%% ============================================================
% MACRO AVERAGES
%% ============================================================
MacroPrecision = ...
    mean(PrecisionVec);

MacroRecall = ...
    mean(RecallVec);

MacroSpecificity = ...
    mean(SpecificityVec);

MacroF1 = ...
    mean(F1Vec);

BalancedAccuracy = ...
    mean(RecallVec);

%% ============================================================
% MICRO AVERAGES
%% ============================================================
TPmicro = ...
    sum(diag(CM));

FPmicro = ...
    sum(sum(CM,1)) - TPmicro;

FNmicro = ...
    sum(sum(CM,2)) - TPmicro;

MicroPrecision = ...
    TPmicro / max(1,TPmicro + FPmicro);

MicroRecall = ...
    TPmicro / max(1,TPmicro + FNmicro);

MicroF1 = ...
    2 * ...
    (MicroPrecision * MicroRecall) / ...
    max(eps,...
    MicroPrecision + MicroRecall);

%% ============================================================
% MCC
%% ============================================================
if nClasses == 2

    TP = CM(1,1);
    FN = CM(1,2);

    FP = CM(2,1);
    TN = CM(2,2);

    num = ...
        (TP * TN) - ...
        (FP * FN);

    den = sqrt( ...
        (TP+FP)* ...
        (TP+FN)* ...
        (TN+FP)* ...
        (TN+FN));

    MCC = ...
        num / max(eps,den);

else

    MCC = NaN;

end

%% ============================================================
% OUTPUT
%% ============================================================
Metrics = struct();

Metrics.nSamples = ...
    numel(Ytrue);

Metrics.ClassLabels = ...
    classLabels;

Metrics.nClasses = ...
    nClasses;

Metrics.IsBinary = ...
    (nClasses==2);

Metrics.CM = ...
    CM;

Metrics.ACC = ...
    ACC;

Metrics.BA = ...
    BalancedAccuracy;

%% ------------------------------------------------------------
% PER CLASS
%% ------------------------------------------------------------
Metrics.PrecisionPerClass = ...
    PrecisionVec;

Metrics.RecallPerClass = ...
    RecallVec;

Metrics.SpecificityPerClass = ...
    SpecificityVec;

Metrics.F1PerClass = ...
    F1Vec;

%% ------------------------------------------------------------
% MACRO
%% ------------------------------------------------------------
Metrics.MacroPrecision = ...
    MacroPrecision;

Metrics.MacroRecall = ...
    MacroRecall;

Metrics.MacroSpecificity = ...
    MacroSpecificity;

Metrics.MacroF1 = ...
    MacroF1;

%% ------------------------------------------------------------
% MICRO
%% ------------------------------------------------------------
Metrics.MicroPrecision = ...
    MicroPrecision;

Metrics.MicroRecall = ...
    MicroRecall;

Metrics.MicroF1 = ...
    MicroF1;

%% ------------------------------------------------------------
% LEGACY COMPATIBILITY
%% ------------------------------------------------------------
Metrics.Precision = ...
    MacroPrecision;

Metrics.Recall = ...
    MacroRecall;

Metrics.Sensitivity = ...
    MacroRecall;

Metrics.Specificity = ...
    MacroSpecificity;

Metrics.F1 = ...
    MacroF1;

Metrics.MCC = ...
    MCC;

%% ============================================================
% SUMMARY
%% ============================================================
fprintf('\n');
fprintf('================================\n');
fprintf('CLASSIFICATION METRICS\n');
fprintf('================================\n');

fprintf('Samples         : %d\n', ...
    Metrics.nSamples);

fprintf('Classes         : %d\n', ...
    Metrics.nClasses);

fprintf('Accuracy        : %.2f %%\n', ...
    100*Metrics.ACC);

fprintf('Balanced Acc    : %.2f %%\n', ...
    100*Metrics.BA);

fprintf('Macro Precision : %.2f %%\n', ...
    100*Metrics.MacroPrecision);

fprintf('Macro Recall    : %.2f %%\n', ...
    100*Metrics.MacroRecall);

fprintf('Macro F1        : %.4f\n', ...
    Metrics.MacroF1);

fprintf('Micro F1        : %.4f\n', ...
    Metrics.MicroF1);

if Metrics.IsBinary
    fprintf('MCC             : %.4f\n', ...
        Metrics.MCC);
end

fprintf('--------------------------------\n');

end