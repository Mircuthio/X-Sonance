function   par = BayesianInferenceClassificationParams(parSource)
% function par = BayesianInferenceClassificationParams(parSource)
par.exec        = true;
par.channelSets = {1};
par.InField     = 'y';
par.detachedmode= false;
try
    fnames=fieldnames(parSource);
    for in=1:length(fnames)
        par.(fnames{in})=parSource.(fnames{in});
    end
catch
end
end