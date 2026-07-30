; Smooth data on an arbitrary time grid with a centered moving mean.
; result = tsmooth(x, t, dt)
; Each result contains the mean of points whose times lie within t[i] +/- dt.

function tsmooth, x, t, dt
	n = n_elements(x)
	if n_elements(t) ne n then $
		message, 'X and T must contain the same number of elements.'
	if n_elements(dt) ne 1 or dt lt 0 then $
		message, 'DT must be a non-negative scalar.'

	smoothed = 1.0 * x
	for i = 0L, n - 1 do begin
		indices = where((t ge t[i] - dt) and (t le t[i] + dt), count)
		if count eq 0 then message, 'No data points found inside a smoothing window.'
		smoothed[i] = total(x[indices]) / count
	endfor

	return, smoothed
end
