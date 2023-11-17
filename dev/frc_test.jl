using GLMakie, Distributions, FFTW, Images, Noise, TestImages, ImageFiltering
include("../src/SMLMMetrics.jl")

#For now I will use an image from the test image library 
test_image_base  = rotr90(testimage("house.tif"))

test_image_base = gray.(test_image_base)

#Smoothing image before adding noise causes correlation to decrease at lower frequencies
test_image_base = imfilter(test_image_base, Kernel.gaussian(1))

#The noise library contains a method for adding noise to an image
test_image_1 = add_gauss(test_image_base, .5)
test_image_2 = add_gauss(test_image_base, .5)


#Smoothing image after adding noise causes correlation to increase at high frequency values (mostly zero)

test_image_1 = imfilter(test_image_1, Kernel.gaussian(1))
test_image_2 = imfilter(test_image_2, Kernel.gaussian(1))

test_image_1_fft = fftshift(fft(test_image_1))
test_image_2_fft = fftshift(fft(test_image_2))

radii, frc = SMLMMetrics.calcfrc(test_image_1, test_image_2, ringextension = 1)

fig = GLMakie.Figure(resolution=(1000,1300))


image(fig[1,1], test_image_1, axis = (aspect = DataAspect(), title="Image 1"))
image(fig[1,2], test_image_2, axis = (aspect = DataAspect(), title="Image 2"))

ax3 = GLMakie.Axis(fig[2,1], title = "Magnitude of Fourier Transform Image 1", aspect=DataAspect())
ax4 = GLMakie.Axis(fig[2,2], title = "Magnitude of Fourier Transform Image 2", aspect=DataAspect())

heatmap!(ax3, abs.(test_image_1_fft))
heatmap!(ax4, abs.(test_image_2_fft))

ax5 = GLMakie.Axis(fig[3, 1:2], ylabel="FRC", xlabel = "Spatial Frequency (λ^-1)", title="FRC vs Spatial Frequency for Test Images")
scatter!(ax5, radii, frc)
hlines!(ax5, [1/7], linestyle = :dot)
fig

