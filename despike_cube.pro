; Replace bright temporal spikes in a three-dimensional image cube.
; despike_cube, cube [, threshold=threshold, width=width]
; cube is modified in place. Each frame is compared with the temporal median
; over width neighboring frames on either side.

pro despike_cube, cube, threshold=threshold, width=width
	if size(cube, /n_dimensions) ne 3 then $
		message, 'CUBE must be 3-dimensional.'
	if n_elements(threshold) eq 0 then threshold = 1.1
	if n_elements(width) eq 0 then width = 2L
	if threshold le 0 then message, 'THRESHOLD must be positive.'
	if width lt 1 then message, 'WIDTH must be positive.'
	width = long(width)

	dims = size(cube, /dimensions)
	for frame = 0L, dims[2] - 1 do begin
		first = (frame - width) > 0L
		last = (frame + width) < (dims[2] - 1L)
		local_median = median(cube[*, *, first:last], dimension=3)
		indices = where(cube[*, *, frame] gt threshold * local_median, n_spikes)
		if n_spikes gt 0 then begin
			cube_indices = indices + frame * dims[0] * dims[1]
			cube[cube_indices] = local_median[indices]
		endif
	endfor
end
