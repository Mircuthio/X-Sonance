function   par = powerdensityParams(parSource)
% function par = powerdensityParams(parSource)
par.exec    = true;
par.mutrain = false;
par.InField = 'y';
par.OutField= 'y';
par.t_overlap= 0;
    try
        fnames=fieldnames(parSource);
        for in=1:length(fnames)
            par.(fnames{in})=parSource.(fnames{in});
        end
    catch
    end
end