function   par = CSDComputeParams(parSource)
% function par = dataNormalizeParams(parSource)
par.exec    = true;
par.ARp     = 8;    % Order of MAR model
% par.rsfactor= 0.2;  % rescale factor
par.Hz      = (1:64)'; % freqs - [Nf x 1] vector of frequencies to evaluate spectra at
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