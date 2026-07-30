; Fit a normal cumulative distribution to a sample.
; parameters = gausshist(x [, weights=weights, sigma=sigma, yfit=yfit])
; Additional keywords are passed to curvefit. The returned parameters are
; the fitted mean and standard deviation.

function gausshist, x, weights=weights, sigma=sigma, yfit=yfit, $
		_ref_extra=extra
	n = n_elements(x)
	if n lt 2 then message, 'X must contain at least two values.'
	if n_elements(weights) eq 0 then weights = replicate(1.0, n)

	order = sort(x)
	parameters = [mean(x), stdev(x)]
	yfit = curvefit(x[order], findgen(n) / n, weights[order], parameters, sigma, $
		function_name='gauss_cdf', _extra=extra)

	return, parameters
end


; Normal cumulative distribution and its parameter derivatives for curvefit.

pro gauss_cdf, x, parameters, result, derivatives
	z = (x - parameters[0]) / parameters[1]
	result = 0.5 * (1 + erf(z / sqrt(2)))

	if n_params() ge 4 then begin
		density = exp(-z^2 / 2) / sqrt(2 * !pi)
		derivatives = [[-density / parameters[1]], $
			[-z * density / parameters[1]]]
	endif
end
