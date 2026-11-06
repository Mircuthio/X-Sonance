function   par = TimeSelectionParams(parSource)
% function par = TimeSelectionParams(parSource)
par.exec    = 1;
par.it1     = 0;
par.it2     = 1;
par.dt      = 1;
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