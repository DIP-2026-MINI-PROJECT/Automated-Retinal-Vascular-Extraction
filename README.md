# RetinaVascNet

### Project Description:

#### Summary -

**Automated Extraction of Retinal Vascular Networks for Early Disease Screening**

This project develops an automated retinal blood vessel extraction pipeline using classical Digital Image Processing (DIP) techniques on colour fundus images. The objective is to identify retinal vascular structures and extract quantitative features that can support early screening for conditions such as diabetic retinopathy and glaucoma.

The implementation follows a four-stage processing pipeline:

1. **Image Preprocessing:** RGB channel analysis, field-of-view detection, intensity normalization, interpolation, and sampling analysis.
2. **Transform-Domain Processing:** Discrete Cosine Transform (DCT) compression and denoising, with comparisons against Discrete Fourier Transform (DFT) and Singular Value Decomposition (SVD).
3. **Image Enhancement:** Background illumination correction, Contrast Limited Adaptive Histogram Equalization (CLAHE), and spatial filtering.
4. **Vessel Extraction and Analysis:** Morphological black top-hat filtering, thresholding, mask cleanup, skeletonization, vessel feature extraction, and pseudocolour visualization.

The system generates a binary vessel segmentation mask, a colour-coded vascular network, and quantitative measurements including vessel density, branching points, vessel thickness, and skeleton length.

The project is implemented using MATLAB-compatible code and GNU Octave, without machine learning or deep learning.

#### Course concepts used -

1. **Digital Image Fundamentals**
   - RGB channel separation and grayscale image analysis.
   - Image histograms and intensity normalization.
   - Image interpolation, sampling, and quantization.

2. **Image Transforms and Compression**
   - Discrete Fourier Transform (DFT) and frequency spectrum analysis.
   - Discrete Cosine Transform (DCT) for image compression and denoising.
   - Singular Value Decomposition (SVD) for low-rank image approximation.
   - Comparison of compression efficiency using PSNR and MSE.

3. **Image Enhancement and Restoration**
   - Histogram equalization and CLAHE.
   - Gamma correction and contrast stretching.
   - Spatial filtering using Gaussian, mean, median, Laplacian, and unsharp masking.
   - Frequency-domain filtering using ideal, Butterworth, and Gaussian filters.
   - Image restoration using Wiener filtering and notch filtering.

4. **Morphological Image Processing**
   - Morphological opening and closing.
   - Black top-hat transformation for vessel enhancement.
   - Threshold-based vessel segmentation.
   - Connected-component analysis and noise removal.
   - Skeletonization and morphological feature extraction.

#### Additional concepts used -

1. **Retinal Vascular Feature Analysis**
   - Vessel density estimation.
   - Vessel thickness analysis using distance transforms.
   - Detection of vascular branching and endpoints.
   - Estimation of total vessel skeleton length.

2. **Segmentation Evaluation and Visualization**
   - Comparison with manually annotated ground-truth vessel masks.
   - Evaluation using sensitivity, specificity, accuracy, precision, and Dice coefficient.
   - Generation of pseudocoloured vessel masks and overlays.
   - Comparison against a global Otsu thresholding baseline.

#### Dataset -

The project processes colour retinal fundus images.

- **Primary input:** Retinal fundus image (`testimage3.jpeg`, 224 × 224 pixels) used during initial testing.
- **Reference dataset:** [DRIVE — Digital Retinal Images for Vessel Extraction](https://drive.grand-challenge.org/).
- **Ground-truth masks:** Optional manually segmented vessel masks used for quantitative evaluation.
- **Field-of-view masks:** Either supplied with the dataset or automatically generated.

The pipeline supports processing individual images as well as multiple images in a dataset.

For small images, bicubic interpolation is used to increase resolution before vessel extraction.

A synthetic test image is also provided as a fallback to verify pipeline execution when no real fundus image is available.

#### Novelty -

1. **Integrated Classical Image Processing Pipeline**
   - Combines transform-domain denoising, illumination correction, adaptive contrast enhancement, and morphological vessel extraction into a unified processing framework.
   - Operates without requiring training datasets or machine learning models.

2. **Resolution-Adaptive Vessel Extraction**
   - Automatically adjusts filtering parameters and morphological structuring elements based on image resolution.
   - Supports images of varying sizes while maintaining a consistent processing workflow.

3. **Quantitative Vascular Analysis and Visualization**
   - Extracts vessel density, branching points, vessel thickness distribution, and vascular skeleton length.
   - Produces pseudocolour diagnostic visualizations distinguishing thin and thick vessels.
   - Supports evaluation against ground-truth masks and comparison with conventional thresholding methods.

### Contributors:

1. Shriya Arunkumar (PES1UG24EC206)
2. Samarth Sheshadri (PES1UG24EC180)
3. Sahil Nair (PES1UG24EC174)

### Steps:

1. **Clone Repository**

   ```bash
   git clone <repo-url>
   cd Automated-Retinal-Vascular-Extraction
   ```

2. **Install Dependencies**

   The project requires MATLAB with the Image Processing Toolbox, or a compatible GNU Octave installation with the image package.

   No Python dependencies are required.

3. **Prepare Input Images**

   Place the retinal fundus image in the `data/` directory.

   Optionally, include:
   - Ground-truth vessel segmentation mask.
   - Field-of-view (FOV) mask.

   Image paths and processing parameters can be modified in `config.m`.

4. **Run the Code**

   Open MATLAB, navigate to the project directory, and execute:

   ```matlab
   main_pipeline
   ```

5. **Process Multiple Images**

   To run the pipeline across all images in the `data/` directory:

   ```matlab
   run_all_images
   ```

6. **View Results**

   Generated images, evaluation metrics, and intermediate processing outputs are saved in the `outputs/` directory.

### Outputs:

**Important Intermediate Steps**

- RGB channel separation and histogram analysis.
- Field-of-view extraction and green-channel normalization.
- DFT spectrum and DCT/SVD compression comparisons.
- Illumination correction and CLAHE enhancement.
- Morphological black top-hat vessel enhancement.
- Binary vessel segmentation and mask cleanup.
- Skeletonization and vascular feature analysis.

**Final Output Images**

- `pseudocolor_mask.png` — Colour-coded retinal vascular network.
- `pseudocolor_overlay.png` — Extracted blood vessels overlaid on the original fundus image.
- `u4_03_skeleton_analysis.png` — Vascular skeleton and structural features.
- `eval_error_map_*.png` — Segmentation error visualization when ground truth is available.

**Quantitative Results**

The following results were obtained using the initial 224 × 224 retinal fundus image, upsampled to 565 pixels wide:

| Parameter | Result |
|---|---|
| Vessel Density | 0.082 (8.2%) |
| Branch Points | 67 |
| End Points | 142 |
| Thin/Thick Vessel Pixel Ratio | 0.37 |
| Total Skeleton Length | 3393 pixels |
| DCT Compression | 10% coefficients retained |
| DCT Reconstruction PSNR | 42.7 dB |

These measurements were obtained without an accompanying ground-truth mask. Therefore, segmentation accuracy, sensitivity, specificity, and Dice score were not calculated for this image.

Additional numerical results are saved in `metrics.csv`, `clinical_features.csv`, `summary.csv`, and `results.mat`.

### References:

1. **DRIVE: Digital Retinal Images for Vessel Extraction**
   - [DRIVE Dataset](https://drive.grand-challenge.org/)

2. **Digital Image Processing — Gonzalez and Woods**
   - Reference for image enhancement, frequency-domain processing, morphological operations, and segmentation.

3. **MATLAB Image Processing Toolbox**
   - [MathWorks Documentation](https://www.mathworks.com/help/images/)

### Limitations and Future Work:

**Limitations**

- Low-resolution fundus images may not contain sufficient detail to preserve the thinnest retinal capillaries.
- Morphological extraction may produce discontinuities in the vascular network.
- Fixed or percentile-based thresholding may incorrectly identify lesion boundaries or other dark structures as vessels.
- Processing parameters may require adjustment for images with significantly different illumination or contrast.
- Extracted vascular features are intended to support screening-related image analysis and do not independently establish a medical diagnosis.
- Comprehensive quantitative validation requires ground-truth vessel segmentation masks.

**Future Work**

- Evaluate the pipeline on a larger collection of DRIVE retinal images.
- Compare segmentation performance using Dice score, sensitivity, specificity, and accuracy.
- Improve extraction of thin and low-contrast capillaries.
- Investigate adaptive segmentation techniques for images with uneven illumination.
- Improve vessel connectivity and reduce false-positive detections.
- Extend the framework to support vessel tortuosity and other vascular morphology measurements.
- Investigate machine learning-based segmentation as a future comparison with the classical DIP approach.
