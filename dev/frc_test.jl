using GLMakie, Distributions, FFTW, Images, Noise, TestImages
#using SMLMMetrics

#For now I will use an image from the test image library 
test_image_base  = rotr90(testimage("brick_wall_512.tiff"))

test_image_base = gray.(test_image_base)

#The noise library contains a method for adding noise to an image
test_image_1 = add_gauss(test_image_base, .5)
test_image_2 = add_gauss(test_image_base, .5)

test_image_1_fft = fftshift(fft(test_image_1))
test_image_2_fft = fftshift(fft(test_image_2))

rounded_frc = SMLMMetrics.calcfrc(test_image_1, test_image_2, 8)

fig = GLMakie.Figure(resolution=(1000,1300))


image(fig[1,1], test_image_1, axis = (aspect = DataAspect(), title="Image 1"))
image(fig[1,2], test_image_2, axis = (aspect = DataAspect(), title="Image 2"))

ax3 = GLMakie.Axis(fig[2,1], title = "Magnitude of Fourier Transform Image 1", aspect=DataAspect())
ax4 = GLMakie.Axis(fig[2,2], title = "Magnitude of Fourier Transform Image 2", aspect=DataAspect())

heatmap!(ax3, abs.(test_image_1_fft))
heatmap!(ax4, abs.(test_image_2_fft))

ax5 = GLMakie.Axis(fig[3, 1:2], ylabel="FRC", xlabel = "Spatial Frequency (λ^-1)", title="FRC vs Spatial Frequency for Test Images")
scatter!(ax5, 1:32:256 , (rounded_frc))
hlines!(ax5, [1/7], linestyle = :dot)
fig

