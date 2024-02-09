using GLMakie, Distributions, FFTW, Images, Noise, SMLMData, SMLMSim, SMLMVis

#Skeleton for function to create histogram 


xpixels = 256
ypixels = 256
zpixels = 128

xypixelsize = 0.1
zpixelsize = .2

#Using the SMLM Sim package to generate 3D simulated data
#Returns values in units of pixels for x and y, microns for z

smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=10.0,
    σ_PSF=.13, #micron 
    minphotons=1000,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, # 1/s
    pattern=SMLMSim.Nmer3D(),   #Default Nmer of 8 points and a 0.1 (micron?) diameter
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; xpixels=256, ypixels=256, pixelsize=.1), #pixelsize is microns
    zrange=[0.0,  zpixels * zpixelsize] #Zrange size is in microns?
)

#The next step is to create a histogram using the coordinates. Each datapoint specifies a number of photons at a location

#First I will create a rectangular shaped 3D array of the size 256, 256, 128 
#Scale x and y coordinates to sizes in microns
smld_noisy.x .= smld_noisy.x .* xypixelsize
smld_noisy.y .= smld_noisy.y .* xypixelsize


#For now the bin size corresponds to the size of the pixels in the x and y direction
xybinsize = 0.1 
zbinsize = 0.2 
xyarraysize = 256
zarraysize = 128

max = minimum(smld_noisy.x)

hist_array = zeros(xyarraysize, xyarraysize, zarraysize)
#Iterate through the coordinates and add the number of photons to the corresponding bin
for i in 1:length(smld_noisy)
    xbin = 0
    ybin = 0
    zbin = 0

    if smld_noisy.x[i] < 0
        xbin = 1
    elseif smld_noisy.x[i] > 25.6
        xbin = 256
    else 
        xbin = Int(floor(smld_noisy.x[i] / xybinsize)) + 1
    end

    if smld_noisy.y[i] < 0
        ybin = 1
    elseif smld_noisy.y[i] > 25.6
        ybin = 256
    else 
        ybin = Int(floor(smld_noisy.y[i] / xybinsize)) + 1
    end

    if smld_noisy.z[i] < 0
        zbin = 1
    elseif smld_noisy.z[i] > 25.6
        zbin = 128
    else 
        zbin = Int(floor(smld_noisy.z[i] / zbinsize)) + 1
    end

    hist_array[xbin, ybin, zbin] += smld_noisy.photons[i]
end

hist_array