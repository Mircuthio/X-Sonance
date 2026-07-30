function savePlotEpsPdfMat(gcf,par)

if ~isfield(par,'save_png'); par.save_png = true; end
if ~isfield(par,'save_pdf'); par.save_pdf = true; end
if ~isfield(par,'save_fig'); par.save_fig = true; end

% Create dirs only if needed
if par.save_png
    if ~exist(par.dir_png,'dir')
        mkdir(par.dir_png);
    end
end

if par.save_pdf
    if ~exist(par.dir_pdf,'dir')
        mkdir(par.dir_pdf);
    end
end

if par.save_fig
    if ~exist(par.dir_mat,'dir')
        mkdir(par.dir_mat);
    end
end

file_name_png = strcat(par.file_name, '.png');
file_name_pdf = strcat(par.file_name, '.pdf');
file_name_mat = strcat(par.file_name, '.mat');

% PNG
if isfield(par,'save_png') && par.save_png

    set(gcf, 'InvertHardcopy', 'off');

    fulldir_png = fullfile(par.dir_png, file_name_png);

    saveas(gcf, fulldir_png, 'png');

end

% PDF
if isfield(par,'save_pdf') && par.save_pdf

    set(gcf, 'InvertHardcopy', 'off');
    set(gcf, 'PaperPositionMode', 'auto');
    set(gcf, 'PaperOrientation', 'landscape');

    fulldir_pdf = fullfile(par.dir_pdf, file_name_pdf);

    exportgraphics(gcf, fulldir_pdf, ...
        'ContentType', 'vector');

end

% FIG
if isfield(par,'save_fig') && par.save_fig

    fulldir_fig = fullfile(par.dir_mat, ...
        strrep(file_name_mat, '.mat', '.fig'));

    savefig(gcf, fulldir_fig);

end