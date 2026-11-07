function fig = new_fig(name, cfg, rows, cols)
% NEW_FIG  Create a figure with the project's standard size and style.
%
%   fig = new_fig(name, cfg)
%   fig = new_fig(name, cfg, rows, cols)
%
%   Purpose : All figures share one look: white background, and a size
%             derived from the subplot grid so every panel gets the same
%             on-screen size (cfg.fig.panel_px) in every saved PNG.
%   Inputs  : name - window title
%             cfg  - configuration struct (cfg.fig.*)
%             rows, cols - (optional) subplot grid; default uses
%                          cfg.fig.position as is
%   Outputs : fig  - figure handle
pos = cfg.fig.position;
if nargin >= 4
    pos(3) = min(cfg.fig.max_width, cols * cfg.fig.panel_px(1));
    pos(4) = rows * cfg.fig.panel_px(2) + 40;
end
fig = figure('Name', name, 'NumberTitle', 'off', 'Color', 'w', ...
             'Position', pos, 'Visible', cfg.fig.visible);
end
