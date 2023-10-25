#copy of example code from SMLMSim to verify functionality
## Simulation of SMLM Data using Nmer Pattern

using SMLMSim
using SMLMData
using GLMakie

# Simulation paramters use physical units
# smld structures are in units of pixels and frames 


#I believe this defaults to 8mer

smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=1.0,
    σ_PSF=0.13, #micron 
    minphotons=50,
    ndatasets=10,
    nframes=1000,
    framerate=50.0, # 1/s
    pattern=SMLMSim.Nmer2D(),
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; xpixels=256, ypixels=256, pixelsize=0.1) #pixelsize is microns
)

fig = Figure()

ax1 = GLMakie.Axis(fig[1:2,1:2])
scatter!(ax1, smld_noisy.x, smld_noisy.y)

ax2 = GLMakie.Axis(fig[3, 1])
scatter!(ax2,  smld_noisy.x[1:10265], smld_noisy.y[1:10265])

ax3 = GLMakie.Axis(fig[3,2])
scatter!(ax3, smld_noisy.x[10265:20531], smld_noisy.y[10265:20531])

fig

image = SMLMData.gaussim(smld_noisy,.1, pxsize_out::Float64 = 0.1)

ax4 = GLMakie.Axis(fig[4:5, 1:2])
heatmap!(ax4, image)
fig