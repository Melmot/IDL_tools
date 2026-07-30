; Find the interval with the most precisely determined non-zero linear slope.
; parameters = linearize(y [, x=x, range=range, err=errors, /plt,
;   minlen=minlen, fit=fit, step=step])
; minlen <= 1 is a fraction of the search range; larger values are point
; counts. range is returned as the selected pair of flat indices.

function linearize, y, x=x, range=range, err=err, plt=plt, $
		minlen=minlen, fit=fit, step=step
	y = double(reform(y))
	n = n_elements(y)
	if n lt 3 then message, 'Y must contain at least three values.'
	if n_elements(x) eq 0 then x = dindgen(n) else x = double(reform(x))
	if n_elements(x) ne n then message, 'X and Y must have equal lengths.'
	if min(finite(x)) eq 0 or min(finite(y)) eq 0 then $
		message, 'X and Y must contain only finite values.'

	if n_elements(range) eq 0 then range = [0L, n - 1L] $
		else range = long(range)
	if n_elements(range) ne 2 then message, 'RANGE must contain two indices.'
	if range[1] eq -1 then range[1] = n - 1
	if range[0] lt 0 or range[1] ge n or range[0] ge range[1] then $
		message, 'Invalid RANGE.'

	search_length = range[1] - range[0] + 1
	if n_elements(minlen) eq 0 then min_points = long(ceil(search_length * 0.5)) $
		else if minlen le 1 then min_points = long(ceil(search_length * minlen)) $
		else min_points = long(minlen)
	min_points = min_points > 3L
	if min_points gt search_length then message, 'MINLEN exceeds RANGE.'
	if n_elements(step) eq 0 then step = 1L else step = long(step)
	if step lt 1 then message, 'STEP must be positive.'

	cx = [0D, total(x, /cumulative, /double)]
	cy = [0D, total(y, /cumulative, /double)]
	cxx = [0D, total(x^2, /cumulative, /double)]
	cxy = [0D, total(x * y, /cumulative, /double)]
	cyy = [0D, total(y^2, /cumulative, /double)]

	best_score = 1D300
	best_range = [-1L, -1L]
	for first = range[0], range[1] - min_points + 1, step do begin
		for last = first + min_points - 1, range[1], step do begin
			n_points = double(last - first + 1)
			sx = cx[last + 1] - cx[first]
			sy = cy[last + 1] - cy[first]
			sxx = cxx[last + 1] - cxx[first]
			sxy = cxy[last + 1] - cxy[first]
			syy = cyy[last + 1] - cyy[first]
			denominator = n_points * sxx - sx^2
			if denominator le 0 then continue

			slope = (n_points * sxy - sx * sy) / denominator
			if slope eq 0 then continue
			intercept = (sy - slope * sx) / n_points
			sse = (syy - intercept * sy - slope * sxy) > 0D
			slope_error = sqrt(sse / (n_points - 2) * n_points / denominator)
			score = abs(slope_error / slope)
			if score lt best_score then begin
				best_score = score
				best_range = [first, last]
			endif
		endfor
	endfor

	if best_range[0] eq -1 then message, 'No valid linear interval found.'
	range = best_range
	parameters = linfit(x[range[0]:range[1]], y[range[0]:range[1]], sigma=err)
	fit = parameters[0] + parameters[1] * x

	if keyword_set(plt) then begin
		plot, x, y, xstyle=1
		oplot, x, fit
		oplot, x[range[0]:range[1]], y[range[0]:range[1]], thick=2
	endif

	return, parameters
end
