function   par = fitLSTMParams(parSource)
% function par = fitLSTMParams(parSource)
par.exec            = 1;
par.maxEpochs       = 150;
par.numHiddenUnits  = 100;

par.InField         = 'y';
par.OutField        = 'y';
    try
        fnames=fieldnames(parSource);
        for in=1:length(fnames)
            par.(fnames{in})=parSource.(fnames{in});
        end
    catch
    end
end