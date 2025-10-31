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

# Usage
```julia
tracks = load_tracks(ChallengeFormat(), "path/to/ground_truth.xml")
```
"""
struct ChallengeFormat end
