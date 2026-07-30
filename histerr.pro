; Calculate a histogram and account for Gaussian measurement errors.
; result = histerr(values [, errors=errors, min=min, max=max, binsize=size,
;   nbins=n, locations=locations, expected=expected, sigma=sigma])
; result contains integer counts. expected and sigma describe probabilistic
; bin populations when errors are supplied.

function histerr, values, errors=errors, min=minimum, max=maximum, $
		binsize=binsize, nbins=nbins, locations=locations, $
		expected=expected, sigma=sigma
	values = reform(values)
	n_values = n_elements(values)
	if n_values eq 0 then message, 'VALUES must not be empty.'

	if n_elements(minimum) eq 0 then minimum = min(values)
	if n_elements(maximum) eq 0 then maximum = max(values)
	if maximum lt minimum then message, 'MAX must not be smaller than MIN.'

	if n_elements(binsize) eq 0 then begin
		if n_elements(nbins) eq 0 then begin
			binsize = 1.0
			nbins = long(ceil((maximum - minimum) / binsize)) > 1L
		endif else begin
			if nbins lt 1 then message, 'NBINS must be positive.'
			if maximum eq minimum then message, 'MIN and MAX must differ.'
			binsize = double(maximum - minimum) / nbins
		endelse
	endif else begin
		if binsize le 0 then message, 'BINSIZE must be positive.'
		if n_elements(nbins) eq 0 then $
			nbins = long(ceil((maximum - minimum) / binsize)) > 1L
	endelse
	nbins = long(nbins)

	maximum = minimum + nbins * binsize
	edges = minimum + dindgen(nbins + 1) * binsize
	locations = edges[0:nbins - 1] + binsize / 2.0
	histogram = lonarr(nbins)
	expected = fltarr(nbins)
	sigma = fltarr(nbins)

	has_errors = n_elements(errors) ne 0
	if has_errors then begin
		errors = reform(errors)
		if n_elements(errors) ne n_values then $
			message, 'ERRORS and VALUES must have the same number of elements.'
		if min(errors) le 0 then message, 'ERRORS must be positive.'
	endif

	for i = 0L, nbins - 1 do begin
		if i eq nbins - 1 then $
			histogram[i] = total(values ge edges[i] and values le edges[i + 1]) $
		else histogram[i] = total(values ge edges[i] and values lt edges[i + 1])

		if has_errors then begin
			z1 = (edges[i] - values) / (sqrt(2.0) * errors)
			z2 = (edges[i + 1] - values) / (sqrt(2.0) * errors)
			probability = 0.5 * (erf(z2) - erf(z1))
			expected[i] = total(probability)
			sigma[i] = sqrt(total(probability * (1.0 - probability)))
		endif else expected[i] = histogram[i]
	endfor

	return, histogram
end
