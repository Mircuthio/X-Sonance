function OUT = ...
    plot_erp_spectrogram_difference( ...
    tfData,...
    titleStr,...
    cfg)

%% ============================================================
% DEFAULT CONFIG
%% ============================================================

if nargin < 3
    cfg = struct();
end

if ~isfield(cfg,'colormap')
    cfg.colormap = turbo;
end

if ~isfield(cfg,'clim')
    cfg.clim = 'auto';
end

%% ============================================================
% VALIDATION
%% ============================================================

assert( ...
    isfield(tfData,'Difference'),...
    'Difference field missing');

%% ============================================================
% FIGURE
%% ============================================================

f = figure( ...
    'Color','w',...
    'Position',[200 150 900 600]);

imagesc( ...
    tfData.Difference.time,...
    tfData.Difference.freq,...
    tfData.Difference.power);

axis xy

freqVec = ...
    tfData.Difference.freq;

freqMaxDisplay = ...
    ceil(max(freqVec)/10)*10;

ylim([ ...
    min(freqVec) ...
    freqMaxDisplay])

yticks(0:10:freqMaxDisplay)

xlabel('Time (s)')
ylabel('Frequency (Hz)')
title(titleStr,...
    'Interpreter','none')

colormap(cfg.colormap)

colorbar

if ~isequal(cfg.clim,'auto')
    clim(cfg.clim)
end
%% ============================================================
% SAVE
%% ============================================================

if isfield(cfg,'save_path') && ...
        ~isempty(cfg.save_path)

    [saveDir,~,~] = ...
        fileparts(cfg.save_path);

    if ~isempty(saveDir) && ...
            ~exist(saveDir,'dir')

        mkdir(saveDir);

    end

    exportgraphics( ...
        f,...
        cfg.save_path,...
        'Resolution',300);

end
OUT.figure = f;