using GLMakie, Distributions, FFTW, Images, Noise, SMLMData, SMLMSim, SMLMVis

#Using the SMLM Sim package to generate 3D simulated data

smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=10.0,
    σ_PSF=.13, #micron 
    minphotons=1000,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, # 1/s
    pattern=SMLMSim.Nmer3D(),   #Default Nmer of 8 points and a 0.1 diameter
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; xpixels=256, ypixels=256, pixelsize=.1) #pixelsize is microns
)

#The next step is to create a histogram using the coordinates. Each datapoint specifies a number of photons at a location
#First I will create a square shaped array

gen_data_z_max = maximum(smld_noisy.z)
gen_data_z_min = minimum(smld_noisy.z)