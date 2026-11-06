function   par = concat2Params(parSource)
% function par = concat2Params(parSource)
par.exec    = true;
par.OutField= 'y';
    try
        fnames=fieldnames(parSource);
        for in=1:length(fnames)
            par.(fnames{in})=parSource.(fnames{in});
        end
    catch
    end
end