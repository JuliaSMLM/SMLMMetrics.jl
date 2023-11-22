using FFTW, Images

"""
Calculate the Fourier Ring Correlation at a given radius (in pixels), given fourier transforms of two images

Returns real part of the FRC
"""
function corellationradius(img1::Matrix, img2::Matrix, im_width::Int, im_height::Int, radius::Int, ringwidth::Int)

    im_x_center = Int(floor(im_width/2))
    im_y_center = Int(floor(im_height/2))

    numerator_sum = 0
    denominator_sum = 0

    #Computes the Fourier ring correlation at a given magnitude of spatial frequency
    for x in 1:im_width
        for y in 1:im_height
            if abs.(((x - im_x_center)^2 + (y - im_y_center) ^2) - radius^2) <= (radius * ringwidth)
                numerator_sum += (img1[y,x] * conj(img2[y,x]))
                denominator_sum += sqrt(abs2(img1[y,x]) * abs2(img2[y,x]))
            end
        end
    end

    result = real(numerator_sum)/denominator_sum

    if isnan(result)
        @error "Ring not defined at R = " * string(radius)
        return NaN
    end
    return result
end
"""
The FRC is a metric showing the correlation between two images as a function of spatial frequency.

This method calculates the FRC of two greyscale images given the two images and the number of data points.

The number of datapoints determines the "size" of the rings as the resulting FRC at every possible radius will be averaged to effectively widen the rings

The images are assumed to be square and the same size.

"""

function calcfrc(img1::Matrix, img2::Matrix, ringwidth::Int = 1)
    im_width = size(img1)[2]
    im_height = size(img1)[1]
    
    if size(img1) != size(img2) || size(img1)[1] != size(img1)[2]
        @error "Images must be the same size and square"
        return NaN
    end

    #Calculate the fourier transforms of the images, and shift them so that the zero frequency is in the center
    img1_fft = fftshift(fft(img1))
    img2_fft = fftshift(fft(img2))

    #Calculate the FRC at every radius
    full_ring_correlation = [corellationradius(img1_fft, img2_fft, im_width, im_height, r, ringwidth) for r in 1:Int(floor(im_width/2))]

    #Average the FRC to the number of datapoints specified to effectively widen the rings
    return full_ring_correlation
end
