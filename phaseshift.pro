; Shift a two-dimensional image by a fractional number of pixels using FFT.
; shifted = phaseshift(image, dx, dy)
; The result is complex; use real_part or abs when a real image is required.
; The original idea was proposed by Artem Ulyanov.

function phaseshift, image, dx, dy
	dims = size(image, /dimensions)
	if n_elements(dims) ne 2 then message, 'IMAGE must be 2-dimensional.'

	if dims[0] mod 2 eq 0 then $
		fx = 1.0 / dims[0] * [indgen(dims[0] / 2 + 1), $
			indgen(dims[0] / 2 - 1) - dims[0] / 2 + 1] $
	else $
		fx = 1.0 / dims[0] * [indgen(dims[0] / 2 + 1), $
			indgen(dims[0] / 2) - dims[0] / 2]

	if dims[1] mod 2 eq 0 then $
		fy = 1.0 / dims[1] * [indgen(dims[1] / 2 + 1), $
			indgen(dims[1] / 2 - 1) - dims[1] / 2 + 1] $
	else $
		fy = 1.0 / dims[1] * [indgen(dims[1] / 2 + 1), $
			indgen(dims[1] / 2) - dims[1] / 2]

	frequency_x = rebin(fx, dims)
	frequency_y = rebin(transpose(fy), dims)
	phase = 2 * !pi * (frequency_x * dx + frequency_y * dy)

	return, fft(fft(image) * exp(complex(0, -1) * phase), /inverse)
end
