function   par = pcaComputeParams(parSource)
% function par = pcaComputeParams(parSource)
par.exec            = true;
par.numComponents   = 0;
par.perc            = 90;
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