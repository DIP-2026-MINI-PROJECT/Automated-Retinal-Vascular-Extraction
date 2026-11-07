function outPath = save_fig(fig, name, cfg)
% SAVE_FIG  Save a figure as a PNG in the outputs folder.
%
%   outPath = save_fig(fig, name, cfg)
%
%   Purpose : Write a figure to <cfg.paths.outputs>/<name>.png at
%             cfg.fig.dpi and close it unless cfg.fig.keep_open is true.
%   Inputs  : fig  - figure handle
%             name - file name without extension
%             cfg  - configuration struct from config()
%   Outputs : outPath - full path of the PNG that was written
if ~exist(cfg.paths.outputs, 'dir')
    mkdir(cfg.paths.outputs);
end
outPath = fullfile(cfg.paths.outputs, [name '.png']);
set(fig, 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off');
drawnow;
if exist('exportgraphics', 'file') && ~is_octave()
    exportgraphics(fig, outPath, 'Resolution', cfg.fig.dpi);
else
    print(fig, outPath, '-dpng', sprintf('-r%d', cfg.fig.dpi));
end
fprintf('      saved %s\n', outPath);
if ~cfg.fig.keep_open
    close(fig);
end
end
