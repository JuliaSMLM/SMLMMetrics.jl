"""
Format type tags for multiple dispatch in load_tracks function.

Each format type represents a different particle tracking software package.
"""

"""
    SmiteFormat

Format tag for SMITE (Single Molecule Imaging Toolbox Extraordinaire) tracking data.

# Usage
```julia
tracks = load_tracks(SmiteFormat(), "path/to/data.mat")
```
"""
struct SmiteFormat end

"""
    UTrackFormat

Format tag for u-track tracking data.

# Usage
```julia
tracks = load_tracks(UTrackFormat(), "path/to/tracksFinal.mat")
```
"""
struct UTrackFormat end

"""
    BNPTrackFormat

Format tag for BNP-Track (Bayesian Nonparametric Tracking) data.

# Usage
```julia
tracks = load_tracks(BNPTrackFormat(), "path/to/chain.mat")
```
"""
struct BNPTrackFormat end

"""
    ChallengeFormat

Format tag for Particle Tracking Challenge ground truth XML files.

The Particle Tracking Challenge (Chenouard et al. 2014) uses XML format
for ground truth data with 0-indexed frames and coordinates in pixels.

# Usage
```julia
tracks = load_tracks(ChallengeFormat(), "ground_truth.xml", pixel_size=0.107)
```

# Notes
- Frame numbers are converted from 0-indexed (XML) to 1-indexed (Julia)
- Coordinates are converted from pixels to micrometers using pixel_size
"""
struct ChallengeFormat end
