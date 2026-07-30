; Iteratively reject values outside a mean-centered sigma threshold.
; result = devcut(data [, dim=dim, nsigma=n, mask=mask, /onlytop,
;   std=std, count=count, /index, maxsigma=maxsigma, avg=avg, dev=dev])
; result is a byte mask, or rejected flat indices with /index. mask, avg, and
; dev have the shape of data; std is reduced along dim. count is the number
; of iterations. For vectors, dim defaults to 1.

function devcut, data, dim=dim, nsigma=nsigma, mask=mask, onlytop=onlytop, $
		std=std, count=count, index=index, maxsigma=maxsigma, avg=avg, dev=dev
	if n_elements(nsigma) eq 0 then nsigma = 3.0
	if nsigma le 0 then message, 'NSIGMA must be positive.'

	n_dims = size(data, /n_dimensions)
	if n_dims eq 0 then message, 'DATA must be at least a vector.'
	if n_dims eq 1 then dim = 1 $
		else if n_elements(dim) eq 0 then message, 'DIM must be specified.'
	if dim lt 1 or dim gt n_dims then message, 'DIM is outside DATA dimensions.'

	full_dims = size(data, /dimensions)
	reduced_dims = full_dims
	reduced_dims[dim - 1] = 1

	if n_elements(mask) eq 0 then begin
		mask = make_array(full_dims, /byte, value=1)
	endif else begin
		if size(mask, /n_dimensions) ne n_dims then $
			message, 'MASK must have the same dimensions as DATA.'
		if n_elements(mask) ne n_elements(data) then $
			message, 'MASK must have the same dimensions as DATA.'
		if total(size(mask, /dimensions) ne full_dims) ne 0 then $
			message, 'MASK must have the same dimensions as DATA.'
		mask = byte(mask ne 0)
	endelse

	iterations = 0L
	repeat begin
		n_valid = total(mask, dim)
		if min(n_valid) eq 0 then $
			message, 'At least one slice contains no valid values.'

		mean_reduced = total(data * mask, dim, /double) / n_valid
		avg = rebin(reform(mean_reduced, reduced_dims), full_dims)
		dev = mask * (data - avg)
		sigma_reduced = sqrt(total(dev^2, dim, /double) / n_valid)
		if n_elements(maxsigma) ne 0 then sigma_reduced <= maxsigma
		sigma = rebin(reform(sigma_reduced, reduced_dims), full_dims)

		if keyword_set(onlytop) then $
			reject = dev gt nsigma * sigma $
		else reject = abs(dev) gt nsigma * sigma
		reject_indices = where(reject, n_reject)
		if n_reject gt 0 then mask[reject_indices] = 0
		iterations = iterations + 1
	endrep until n_reject eq 0

	n_valid = total(mask, dim)
	mean_reduced = total(data * mask, dim, /double) / n_valid
	avg = rebin(reform(mean_reduced, reduced_dims), full_dims)
	dev = mask * (data - avg)
	std = sqrt(total(dev^2, dim, /double) / n_valid)
	if arg_present(count) then count = iterations

	if keyword_set(index) then return, where(mask eq 0) else return, mask
end
