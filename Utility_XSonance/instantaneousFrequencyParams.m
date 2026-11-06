function   par = instantaneousFrequencyParams(parSource)
% function par = instantaneousFrequencyParams(parSource)
par.exec    = true;
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