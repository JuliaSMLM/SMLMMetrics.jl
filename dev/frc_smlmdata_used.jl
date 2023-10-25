using GLMakie, Distributions, FFTW, Images, Noise, TestImages, SMLMData, SMLMSim

#TODO: Implement SMLMVis
#TODO: Replace with Keywords

"""
Calculate the Fourier Ring Correlation at a given radius (in spatial frequency), given fourier transforms of two images


Results are complex valued
"""
function corellationradius(img1::Matrix, img2::Matrix, radius, im_width, im_height)

    im_x_center = Int(im_width/2)
    im_y_center = Int(im_height/2)

    numerator_sum = 0
    denominator_sum = 0

    #Computes the Fourier ring correlation at a given magnitude of spatial frequency
    for x in 1:im_width
        for y in 1:im_height
            if (x - im_x_center)^2 + (y - im_y_center) ^2 == radius^2
                numerator_sum += (img1[x,y] * conj(img2[x,y]))
                denominator_sum += sqrt(abs2(img1[x,y]) * abs2(img2[x,y]))
            end
        end
    end

    result = numerator_sum/denominator_sum

    if isnan(result)
        @error "Ring not defined at R = " + String(radius)
        return NaN
    end
    return result
end


"""
To test this FRC Ring correlation method, I will generate data using SMLMSim, then images from the SMLMData packages, in the future I will implement the SMLMVis package

Then I will split the dataset


"""

#This are the default values for data simulation
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

#Creating two datasets by dividing in half, 1 is first half, 2 is second
smld_noisy_1 = SMLMData.isolatesmld(smld_noisy, 1:Int(round(length(smld_noisy)/2)))
smld_noisy_2 = SMLMData.isolatesmld(smld_noisy, Int(round(length(smld_noisy)/2)):Int(length(smld_noisy)))

#Generating test images of size 2056,2056
test_image_1 = SMLMData.gaussim(smld_noisy_1, .1; pxsize_out = 0.0125)
test_image_2 = SMLMData.gaussim(smld_noisy_2, .1; pxsize_out = 0.0125)

#Now I will take the Fourier Transform of both images
test_image_1_fft = fftshift(fft(test_image_1))
test_image_2_fft = fftshift(fft(test_image_2))


ring_correlation_example = [corellationradius(test_image_1_fft, test_image_2_fft, r, 2048, 2048) for r in 1:512]

#Next step, we will average the data, effectively widening the width of the fourier rings to 8 pixels
rounded_frc = [mean(ring_correlation_example[(1 + (n-1)*8 ): n*8]) for n in 1:64]


fig = GLMakie.Figure(resolution=(1000,1300))


image(fig[1,1], test_image_1, axis = (aspect = DataAspect(), title="Image 1"))
image(fig[1,2], test_image_2, axis = (aspect = DataAspect(), title="Image 2"))

ax3 = GLMakie.Axis(fig[2,1], title = "Magnitude of Fourier Transform Image 1", aspect=DataAspect())
ax4 = GLMakie.Axis(fig[2,2], title = "Magnitude of Fourier Transform Image 2", aspect=DataAspect())

heatmap!(ax3, abs.(test_image_1_fft))
heatmap!(ax4, abs.(test_image_2_fft))

ax5 = GLMakie.Axis(fig[3, 1:2], ylabel="FRC", xlabel = "Spatial Frequency (1/λ)", title="FRC vs Angular Frequency for Test Images")
scatter!(ax5, 1:8:512,abs.(rounded_frc))
scatter!(ax5, 1:8:512, ifft(rounded_frc))
hlines!(ax5, [1/7], linestyle = :dot)
fig

