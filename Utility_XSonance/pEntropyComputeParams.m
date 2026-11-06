function   par = pEntropyComputeParams(parSource)
% function par = pEntropyComputeParams(parSource)
par.exec    = true;
par.mutrain = false;
par.InField = 'y';
par.OutField= 'y';
    try
        fnames=fieldnames(parSource);
        for in=1:length(fnames)
            par.(fnames{in})=parSource.(fnames{in});
        end
    catch
    end
end