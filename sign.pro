; Return the sign of a scalar or array.
; result = sign(x)
; The result is -1 for negative values, 0 for zero, and 1 for positive values.

function sign, x
	return, fix(x gt 0) - fix(x lt 0)
end
