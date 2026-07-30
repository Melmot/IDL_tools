; Calculate one or more percentiles of an array using linear interpolation.
; result = percentile(array, levels)
; levels may be a scalar or an array and must lie between 0 and 1.

function percentile, array, levels
	n = n_elements(array)
	if n eq 0 then message, 'ARRAY must not be empty.'
	if min(levels) lt 0 or max(levels) gt 1 then $
		message, 'Percentile levels must lie between 0 and 1.'

	sorted = array[sort(array)]
	position = levels * (n - 1)
	lower = long(floor(position))
	upper = long(ceil(position))
	fraction = position - lower

	return, sorted[lower] + fraction * (sorted[upper] - sorted[lower])
end
