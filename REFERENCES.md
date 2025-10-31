# References for Single Particle Tracking Methods

This document contains citations for the tracking performance metrics and the tracking software packages supported by SMLMMetrics.jl.

---

## Performance Metrics

### Chenouard et al. (2014) - Objective Comparison of Particle Tracking Methods

**Full Citation**:
> Chenouard, N., Smal, I., de Chaumont, F., Maška, M., Sbalzarini, I. F., Gong, Y., Cardinale, J., Carthel, C., Coraluppi, S., Winter, M., Cohen, A. R., Godinez, W. J., Rohr, K., Kalaidzidis, Y., Liang, L., Duncan, J., Shen, H., Xu, Y., Magnusson, K. E. G., Jaldén, J., Blau, H. M., Paul-Gilloteaux, P., Roudot, P., Kervrann, C., Waharte, F., Tinevez, J.-Y., Shorte, S. L., Willemse, J., Celler, K., van Wezel, G. P., Dan, H.-W., Tsai, Y.-S., Ortiz de Solórzano, C., Olivo-Marin, J.-C., & Meijering, E. (2014). **Objective comparison of particle tracking methods**. *Nature Methods*, 11(3), 281–289.

**DOI**: [10.1038/nmeth.2808](https://doi.org/10.1038/nmeth.2808)

**Key Contributions**:
- Defines the 14 performance measures used for objective tracking evaluation
- Introduces optimal track pairing using the Munkres (Hungarian) algorithm
- Establishes gated Euclidean distance for comparing trajectories
- Provides comprehensive benchmark datasets (Particle Tracking Challenge)
- Measures: α, β, TP, FN, FP, JSC, TP_θ, FN_θ, FP_θ, JSC_θ, RMSE, Min, Max, SD

**Supplementary Note 3**: Contains detailed mathematical definitions of all performance measures

**Particle Tracking Challenge Website**: http://bioimageanalysis.org/track/

---

## Tracking Software Packages

### 1. SMITE - Single Molecule Imaging Toolbox Extraordinaire

**Repository**: https://github.com/LidkeLab/smite

**Developed by**: Lidke Lab, University of New Mexico

**Language**: MATLAB

**Key Features**:
- Single molecule localization and tracking
- Integrated analysis pipeline for SMLM data
- SMD (Single Molecule Data) format output
- ConnectID field for trajectory identification

**Output Format**:
- MATLAB .mat files
- Structure fields: X, Y, Z (positions), Photons, FrameNum, ConnectID (track IDs)

---

### 2. u-track - Particle Tracking Software

**Repository**: https://github.com/DanuserLab/u-track

**Developed by**: Danuser Lab, UT Southwestern Medical Center

**Language**: MATLAB

**Primary Reference**:
> Jaqaman, K., Loerke, D., Mettlen, M., Kuwata, H., Grinstein, S., Schmid, S. L., & Danuser, G. (2008). **Robust single-particle tracking in live-cell time-lapse sequences**. *Nature Methods*, 5(8), 695–702.

**DOI**: [10.1038/nmeth.1237](https://doi.org/10.1038/nmeth.1237)

**Key Features**:
- Handles particle merging and splitting (compound tracks)
- Gap closing for missed detections
- Kalman filtering for motion prediction
- Validated on Particle Tracking Challenge datasets

**Output Format**:
- MATLAB .mat files with `tracksFinal` structure
- Complex format: `tracksCoordAmpCG` (8-element pattern per frame)
- `seqOfEvents` matrix describes merging/splitting events
- Pattern: [x, y, z, amplitude, σx, σy, σz, σamplitude] per frame
- NaN values indicate gaps in trajectories

---

### 3. BNP-Track - Bayesian Nonparametric Particle Tracking

**Repository**: https://github.com/LabPresse/BNP-Track

**Developed by**: Presse Lab

**Language**: MATLAB

**Key Features**:
- Fully Bayesian approach using RJMCMC
- Infers number of particles and trajectories from data
- Provides posterior distributions over particle positions and track identities

**Output Format**:
- MATLAB .mat files with MCMC chain samples
- Structure: `chain.sample` with fields X, Y, Z, K (atom assignments), b (existence indicator)
