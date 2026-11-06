function   par = predictQDAParams(parSource)
% function par = predictQDAParams(parSource)
par.exec            = true;
par.InField         = 'y';
par.OutField        = 'y';
par.SuccessField    = 'success';
    try
        fnames=fieldnames(parSource);
        for in=1:length(fnames)
            par.(fnames{in})=parSource.(fnames{in});
        end
    catch
    end
end