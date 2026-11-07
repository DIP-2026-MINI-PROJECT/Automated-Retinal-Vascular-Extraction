function cfg = scale_params(cfg, imgSize)
% SCALE_PARAMS  Adapt pixel-based parameters to the size of the image.
%
%   cfg = scale_params(cfg, imgSize)
%
%   Purpose : The defaults in config.m are tuned for a DRIVE-sized image
%             (width cfg.scale.ref_width = 565 px). Vessel widths, blur
%             sizes and frequency cutoffs all scale with the image, so when
%             cfg.scale.auto is true every size parameter is multiplied by
%             s = width / ref_width (areas by s^2) and rounded sensibly.
%             Set cfg.scale.auto = false to use config.m values as typed.
%   Inputs  : cfg     - configuration struct
%             imgSize - size(rgb) of the loaded image
%   Outputs : cfg     - updated struct; cfg.scale.factor holds s
s = imgSize(2) / cfg.scale.ref_width;
cfg.scale.factor = s;
if ~cfg.scale.auto || abs(s - 1) < 0.05
    cfg.scale.factor = 1;
    return;
end
r  = @(v, lo) max(lo, round(v * s));          % scaled integer with a floor
cfg.fov.open_radius    = r(cfg.fov.open_radius, 1);
cfg.fov.erode_radius   = r(cfg.fov.erode_radius, 1);
cfg.zoom.size          = r(cfg.zoom.size, 24);
cfg.dft.lowfreq_radius = r(cfg.dft.lowfreq_radius, 3);
cfg.svd.k_list         = unique(max(1, round(cfg.svd.k_list * s)));
cfg.unit3.bg_sigma     = max(3, cfg.unit3.bg_sigma * s);
cfg.unit3.clahe_tiles  = max(2, round(cfg.unit3.clahe_tiles * s));
cfg.spatial.unsharp_sigma = max(0.7, cfg.spatial.unsharp_sigma * s);
cfg.freq.lp_cutoff     = r(cfg.freq.lp_cutoff, 5);
cfg.freq.hp_cutoff     = max(1, cfg.freq.hp_cutoff * s);
cfg.restore.per_freq   = max(4, round(cfg.restore.per_freq * s));
cfg.restore.notch_guard  = r(cfg.restore.notch_guard, 3);
cfg.restore.notch_radius = max(2, cfg.restore.notch_radius * s);
cfg.morph.disk_radius  = r(cfg.morph.disk_radius, 2);
cfg.morph.line_length  = r(cfg.morph.line_length, 9);     % shorter lines keep blobs
cfg.cleanup.min_area   = r(cfg.cleanup.min_area * s, 15);  % area: s^2
cfg.cleanup.max_hole_area = r(cfg.cleanup.max_hole_area * s, 3);
cfg.skel.min_branch    = r(cfg.skel.min_branch, 3);
cfg.skel.thin_width_px = max(2.5, cfg.skel.thin_width_px * s);
fprintf('      image width %d px vs reference %d px: size parameters scaled by %.2f\n', ...
        imgSize(2), cfg.scale.ref_width, s);
fprintf('      (disk r=%d, line L=%d, bg sigma=%.1f, CLAHE tiles=%s, min area=%d, thin<%.1f px)\n', ...
        cfg.morph.disk_radius, cfg.morph.line_length, cfg.unit3.bg_sigma, ...
        mat2str(cfg.unit3.clahe_tiles), cfg.cleanup.min_area, cfg.skel.thin_width_px);
end
