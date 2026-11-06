function   par = removeBaselineParams(parSource)
% function par = removeBaselineParams(parSource)
par.exec        = true;
par.bs_start    = 1;
par.bs_stop     = 1;
par.InField     = 'y';
par.ApplyField  = 'y';
par.OutField    = 'y';
    try
        fnames=fieldnames(parSource);
        for in=1:length(fnames)
            par.(fnames{in})=parSource.(fnames{in});
        end
    catch
    end
end