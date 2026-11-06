function   par = tsneComputeParams(parSource)
% function par = tsneComputeParams(parSource)
par.exec    = true;
par.OutField= 'y';
par.InField = 'y';
par.xfld    = 'time';

try
    fnames=fieldnames(parSource);
    for in=1:length(fnames)
        par.(fnames{in})=parSource.(fnames{in});
    end
catch
end
end