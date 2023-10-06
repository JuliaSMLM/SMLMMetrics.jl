using GLMakie, Distributions, FFTW, Images, Noise, TestImages

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
        @error "Ring not defined at R = " + radius
        return NaN
    end
    return result
end

#For now I will use the 
test_image_base  = testimage("straw_512")

test_image_base = gray.(test_image_base)


test_image_1 = poisson(test_image_base, 250)
test_image_2 = poisson(test_image_base, 250)

test_image_1_fft = fftshift(fft(test_image_1))
test_image_2_fft = fftshift(fft(test_image_2))

ring_correlation_example = [corellationradius(test_image_1_fft, test_image_2_fft, r, 512, 512) for r in 1:256]


fig = GLMakie.Figure()

ax1 = GLMakie.Axis(fig[1,1])
ax2 = GLMakie.Axis(fig[1,2])

ax3 = GLMakie.Axis(fig[2,1])

ax4 = GLMakie.Axis(fig[2,2])


heatmap!(ax1, test_image_base)
heatmap!(ax2, test_image_2)


heatmap!(ax3, abs.(test_image_1_fft))
heatmap!(ax4, abs.(test_image_2_fft))

ax5 = GLMakie.Axis(fig[3, 1:2])
scatter!(ax5, abs2.(ring_correlation_example))
fig

