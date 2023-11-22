using GLMakie, Distributions, FFTW, Images, Noise, TestImages, SMLMData, SMLMSim
include("../src/SMLMMetrics.jl")

#TODO: Implement SMLMVis
#TODO: Replace with Keywords

"""
To test this FRC Ring correlation method, I will generate data using SMLMSim, then images from the SMLMData packages, in the future I will implement the SMLMVis package

Then I will split the dataset
"""

#This are the default values for data simulation
smld_true, smld_model, smld_noisy = SMLMSim.sim(;
    ρ=1.0,
    σ_PSF=0.1, #micron 
    minphotons=50,
    ndatasets=10,
    nframes=500,
    framerate=50.0, # 1/s
    pattern=SMLMSim.Nmer2D(),
    molecule=SMLMSim.GenericFluor(; q=[0 50; 1e-2 0]), #1/s 
    camera=SMLMSim.IdealCamera(; xpixels=256, ypixels=256, pixelsize=0.1) #pixelsize is microns
)

#Creating two datasets by dividing in half, 1 is first half, 2 is second
smld_noisy_1 = SMLMData.isolatesmld(smld_noisy, 1:Int(round(length(smld_noisy)/2)))
smld_noisy_2 = SMLMData.isolatesmld(smld_noisy, Int(round(length(smld_noisy)/2)):Int(length(smld_noisy)))

#Generating test images of size 2056,2056
test_image_1 = SMLMData.gaussim(smld_noisy_1, .1; pxsize_out = 0.025)
test_image_2 = SMLMData.gaussim(smld_noisy_2, .1; pxsize_out = 0.025)

#Taking the fft's of both images for graphing
test_image_1_fft = fftshift(fft(test_image_1))
test_image_2_fft = fftshift(fft(test_image_2))

frc = SMLMMetrics.calcfrc(test_image_1, test_image_2)

fig = GLMakie.Figure(resolution=(1000,1300))


image(fig[1,1], test_image_1, axis = (aspect = DataAspect(), title="Image 1"))
image(fig[1,2], test_image_2, axis = (aspect = DataAspect(), title="Image 2"))

ax3 = GLMakie.Axis(fig[2,1], title = "Magnitude of Fourier Transform Image 1", aspect=DataAspect())
ax4 = GLMakie.Axis(fig[2,2], title = "Magnitude of Fourier Transform Image 2", aspect=DataAspect())

heatmap!(ax3, abs.(test_image_1_fft))
heatmap!(ax4, abs.(test_image_2_fft))

ax5 = GLMakie.Axis(fig[3, 1:2], ylabel="FRC", xlabel = "Spatial Frequency", title="FRC vs Spatial Frequency for Test Images")
scatter!(ax5, frc)
hlines!(ax5, [1/7], linestyle = :dot)

GLMakie.activate!(inline=false)
display(fig)