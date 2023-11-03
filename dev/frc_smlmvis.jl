using GLMakie, Distributions, FFTW, Images, Noise, TestImages, SMLMData, SMLMSim, SMLMVis

#This are the default values for data simulation
smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=1.0,
    σ_PSF=0.13, #micron 
    minphotons=50,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, # 1/s
    pattern=SMLMSim.NmerD(),
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; xpixels=256, ypixels=256, pixelsize=0.1) #pixelsize is microns
)

#Creating two datasets by dividing in half, 1 is first half, 2 is second
smld_noisy_1 = SMLMData.isolatesmld(smld_noisy, 1:Int(round(length(smld_noisy)/2)))
smld_noisy_2 = SMLMData.isolatesmld(smld_noisy, Int(round(length(smld_noisy)/2)):Int(length(smld_noisy)))

#img1 = SMLMVis.render_blobs(smld_noisy_1, normalization = :integral, n_sigmas = 3, colormap = :hot, zoom=1) 

#Returns error, seems to be in creating a range of z values based on intensity when z and z_range are set to default values of nothing

img1 = render_blobs(
        (1, smld_noisy_1.datasize[2]),
        (1, smld_noisy_1.datasize[1]),
        smld_noisy_1.x,
        smld_noisy_1.y,
        smld_noisy_1.σ_x,
        smld_noisy_1.σ_y;
        normalization= :integral,
        n_sigmas=3,
        colormap=:hot,
        zoom = 1
    )