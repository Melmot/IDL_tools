; Calculate a partial derivative of a two-dimensional array.
; result = parder(grid, array, dim=dimension)
; dim must be 1 or 2; grid supplies the coordinates along that dimension.

function parder, grid, array, dim=dim
	if size(array, /n_dimensions) ne 2 then $
		message, 'ARRAY must be 2-dimensional.'
	if n_elements(dim) eq 0 or (dim ne 1 and dim ne 2) then $
		message, 'DIM must be 1 or 2.'

	dims = size(array, /dimensions)
	if n_elements(grid) ne dims[dim - 1] then $
		message, 'GRID length must match the selected ARRAY dimension.'

	derivative = dblarr(dims)
	if dim eq 1 then begin
		for i = 0L, dims[1] - 1 do $
			derivative[*, i] = deriv(grid, array[*, i])
	endif else begin
		for i = 0L, dims[0] - 1 do $
			derivative[i, *] = deriv(grid, array[i, *])
	endelse

	return, derivative
end
