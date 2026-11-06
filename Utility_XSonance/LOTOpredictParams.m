function   par = LOTOpredictParams(parSource)
% function par = LOTOpredictParams(parSource)
par.exec            = true;
par.InField         = 'y';
    try
        fnames=fieldnames(parSource);
        for in=1:length(fnames)
            par.(fnames{in})=parSource.(fnames{in});
        end
    catch
    end
end