function cfg = config()
% CONFIG  Central place for every path and tunable parameter of the project.
%
%   cfg = config()
%
%   Purpose : Collects all file paths and algorithm parameters in a single
%             struct so that no other file contains hard-coded values.
%             Edit THIS file to tune the pipeline.
%   Inputs  : none
%   Outputs : cfg - struct with sub-structs (paths, run, fig, fov, unit1,
%             dct, svd, compare, unit3, spatial, freq, restore, morph,
%             cleanup, skel, pseudo, baseline)
%
%   All paths are built relative to the folder that contains this file, so
%   the project can be copied anywhere (Windows, macOS or Linux).

%% ---------------------------------------------------------------- paths
root = fileparts(mfilename('fullpath'));
cfg.paths.root    = root;
cfg.paths.data    = fullfile(root, 'data');
cfg.paths.outputs = fullfile(root, 'outputs');
% Used only when data/ holds no fundus image: a synthetic test image with
% a known vessel mask, so the pipeline can be tried straight away.
cfg.paths.fallback_data = fullfile(root, 'data_synthetic');

% File names inside data/. Leave a field empty ('') to auto-detect:
%   image : first image in data/ that is not a mask / ground truth
%   gt    : a file whose name contains 'manual', '_gt', 'vessel' or 'label'
%   fov   : a file whose name contains 'mask' or 'fov' (and is not the gt)
% A missing gt only skips evaluation; a missing fov is generated.
cfg.paths.image = '';      % e.g. '21_training.tif'
cfg.paths.gt    = '';      % e.g. '21_manual1.gif'
cfg.paths.fov   = '';      % e.g. '21_training_mask.gif'

%% ------------------------------------------------------- image scaling
% Pixel sizes below are tuned for a DRIVE-sized image (565 px wide). With
% auto = true they are rescaled to the actual image width at run time
% (see utils/scale_params.m); the values used are printed and saved.
cfg.scale.auto      = true;
cfg.scale.ref_width = 565;
% Images narrower than this are first upsampled (bicubic, see Unit 1) to
% ref_width, because morphology on 1-2 px wide vessels is too coarse.
% Set to 0 to disable. Masks are resized with nearest neighbour.
cfg.scale.upsample_below = 400;

%% ------------------------------------------------------------ run flags
% 'all'   : load -> Unit 1 -> Unit 2 -> Unit 3 -> Unit 4 -> evaluation
% 'unit1' | 'unit2' | 'unit3' | 'unit4' | 'eval' : run only that stage.
%   A single-unit run takes its input from outputs/handoff.mat written by
%   an earlier full run, or falls back to the normalised green channel.
cfg.run.mode = 'all';
cfg.seed     = 42;          % random seed for all synthetic noise

%% -------------------------------------------------------------- figures
cfg.fig.dpi       = 150;                 % PNG resolution (>= 150)
cfg.fig.position  = [50 50 1500 820];    % default [left bottom width height] px
cfg.fig.panel_px  = [360 330];           % size of one subplot panel (w h) px
cfg.fig.max_width = 2000;                % cap on figure width px
cfg.fig.visible   = 'off';               % 'on' to watch figures appear
cfg.fig.keep_open = false;               % true keeps figures after saving

%% --------------------------------------------- foundation: FOV and zoom
cfg.fov.red_thresh   = 0.15;  % fraction of max(red) used to build a FOV
cfg.fov.open_radius  = 5;     % opening that cleans the generated FOV
cfg.fov.erode_radius = 4;     % erosion that removes the bright rim
cfg.fov.norm_prct    = [0.5 99.5];  % percentiles for normalisation in FOV

cfg.zoom.roi  = [];    % [row col height width]; [] = pick automatically
cfg.zoom.size = 90;    % side of the automatic thin-vessel zoom window

%% --------------------------------------------------------------- Unit 1
cfg.unit1.interp_scale   = 0.5;                       % down then up again
cfg.unit1.interp_methods = {'nearest', 'bilinear', 'bicubic'};
cfg.unit1.sample_factors = [1 2 4 8];                 % spatial subsampling
cfg.unit1.gray_levels    = [256 64 16 4];             % quantisation levels

%% --------------------------------------------------------------- Unit 2
cfg.dct.keep_ratios = [50 25 10];  % % of largest DCT coefficients kept
cfg.dct.noise_sigma = 0.05;        % std of synthetic Gaussian noise (0..1)
cfg.dct.psnr_thresh = 35;          % dB; lowest keep-ratio above this wins
cfg.dft.lowfreq_radius = 20;       % radius for the low-frequency energy

cfg.svd.k_list = [5 10 20 50 100]; % ranks for SVD reconstruction

cfg.compare.cr_list = [4 8 16 32 64];  % compression ratios swept
cfg.compare.cr_show = 16;              % ratio shown as images and table

%% --------------------------------------------------------------- Unit 3
cfg.unit3.input = 'dct';        % 'dct' | 'svd' | 'raw' (which Unit 2 image)
cfg.unit3.svd_k = 50;           % rank used when input = 'svd'
cfg.unit3.stretch_prct  = [1 99];   % contrast-stretch percentiles
cfg.unit3.gamma         = 0.8;      % gamma for the point operation
cfg.unit3.bg_sigma      = 25;       % px, Gaussian for background estimate
cfg.unit3.bg_mode       = 'subtract';   % 'subtract' | 'divide'
cfg.unit3.clahe_tiles   = [8 8];
cfg.unit3.clahe_clip    = 0.01;
cfg.unit3.clahe_bins    = 256;
cfg.unit3.final_filter  = 'median'; % 'none' | 'median' | 'gaussian' | 'wiener'
cfg.unit3.final_size    = 3;        % window for the final filter
cfg.unit3.proxy_prct    = 88;       % vessel proxy if no GT: top (100-x)% response

cfg.spatial.avg_size      = 5;
cfg.spatial.gauss_size    = 7;
cfg.spatial.gauss_sigma   = 1.5;
cfg.spatial.lap_alpha     = 0.2;    % shape parameter of fspecial('laplacian')
cfg.spatial.lap_weight    = 1.0;    % sharp = I - w * Laplacian(I)
cfg.spatial.unsharp_sigma = 2.0;
cfg.spatial.unsharp_amount= 1.0;

cfg.freq.lp_cutoff   = 100;   % D0 for ideal / Butterworth / Gaussian LPF
cfg.freq.butter_order= 2;
cfg.freq.hp_cutoff   = 6;    % D0 for Gaussian HPF (illumination flattening)

cfg.restore.gauss_var   = 0.005;   % imnoise Gaussian variance
cfg.restore.sp_density  = 0.05;    % salt-and-pepper density
cfg.restore.filt_size   = 3;       % mean / median window
cfg.restore.wiener_size = [5 5];
cfg.restore.periodic    = true;    % also demo periodic noise + notch
cfg.restore.per_amp     = 0.1;     % amplitude of the sinusoid
cfg.restore.per_freq    = [60 45]; % [cycles across width, cycles down height]
cfg.restore.notch_radius= 6;       % Gaussian notch radius (freq samples)
cfg.restore.notch_guard = 15;      % ignore peaks closer than this to DC

%% --------------------------------------------------------------- Unit 4
cfg.morph.disk_radius   = 7;           % black top-hat SE (> half max width)
cfg.morph.use_line_bank = true;        % suppress non-linear dark blobs
cfg.morph.line_length   = 15;          % px
cfg.morph.line_angles   = 0:15:165;    % degrees
cfg.morph.thresh_method = 'percentile'; % 'otsu' | 'fixed' | 'percentile'
cfg.morph.fixed_thresh  = 0.25;        % on the [0,1] normalised response
cfg.morph.percentile    = 88;          % keep the top (100-x)% of FOV pixels

cfg.cleanup.open_radius   = 0;   % 0 skips opening (it erases thin vessels)
cfg.cleanup.close_radius  = 1;
cfg.cleanup.min_area      = 150; % px (at 565-px width), smaller components are removed
cfg.cleanup.max_hole_area = 30;  % px, only holes smaller than this are filled

cfg.skel.min_branch    = 8;   % px, spur length pruned from the skeleton
cfg.skel.thin_width_px = 4;   % vessels narrower than this are 'thin'
cfg.skel.pixel_size_um = [];  % set (e.g. 20) to also report lengths in mm

cfg.pseudo.colormap = 'turbo'; % falls back to 'jet' if unavailable
cfg.pseudo.alpha    = 0.75;    % overlay opacity

%% ----------------------------------------------------------- Evaluation
cfg.baseline.method = 'otsu';  % 'otsu' | 'fixed'
cfg.baseline.fixed_thresh = 0.4;
end
