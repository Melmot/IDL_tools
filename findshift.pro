; Find the displacement of image1 relative to image2 by FFT correlation.
; result = findshift(image1, image2 [, corr=correlation,
;   intshft=integer_shift])
; The correlation peak gives the integer shift; a three-point parabola refines
; each coordinate to subpixel precision. Shifts are periodic FFT shifts.

function findshift, image1, image2, corr=correlation, intshft=integer_shift
	if size(image1, /n_dimensions) ne 2 or $
			size(image2, /n_dimensions) ne 2 then $
		message, 'Both images must be 2-dimensional.'
	dims = size(image1, /dimensions)
	if total(size(image2, /dimensions) ne dims) ne 0 then $
		message, 'Images must have the same dimensions.'
	if min(dims) lt 3 then message, 'Image dimensions must be at least 3 pixels.'

	data1 = double(image1) - mean(image1, /double)
	data2 = double(image2) - mean(image2, /double)
	if total(data1^2, /double) eq 0 or total(data2^2, /double) eq 0 then $
		message, 'Images must contain non-constant data.'

	spectrum1 = fft(data1)
	spectrum2 = fft(data2)
	correlation_map = real_part(fft(spectrum1 * conj(spectrum2), /inverse))
	correlation_map = shift(correlation_map, dims[0] / 2, dims[1] / 2)
	peak = max(correlation_map, peak_index)
	peak_position = array_indices(dims, peak_index, /dimensions)

	integer_shift = peak_position - dims / 2

	x_minus = (peak_position[0] - 1 + dims[0]) mod dims[0]
	x_plus = (peak_position[0] + 1) mod dims[0]
	y_minus = (peak_position[1] - 1 + dims[1]) mod dims[1]
	y_plus = (peak_position[1] + 1) mod dims[1]

	center = correlation_map[peak_position[0], peak_position[1]]
	left = correlation_map[x_minus, peak_position[1]]
	right = correlation_map[x_plus, peak_position[1]]
	denominator = left - 2D * center + right
	if denominator ne 0 then dx = 0.5D * (left - right) / denominator $
		else dx = 0D

	down = correlation_map[peak_position[0], y_minus]
	up = correlation_map[peak_position[0], y_plus]
	denominator = down - 2D * center + up
	if denominator ne 0 then dy = 0.5D * (down - up) / denominator $
		else dy = 0D
	dx = (dx > -0.5D) < 0.5D
	dy = (dy > -0.5D) < 0.5D

	auto1 = max(real_part(fft(spectrum1 * conj(spectrum1), /inverse)))
	auto2 = max(real_part(fft(spectrum2 * conj(spectrum2), /inverse)))
	correlation = peak / sqrt(auto1 * auto2)

	return, double(integer_shift) + [dx, dy]
end
