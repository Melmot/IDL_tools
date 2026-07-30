; Convert a scalar numeric string to the corresponding IDL value.
; value = unstring(string)
; IDL integer suffixes B, L, U, ul, ll, and ull are recognized. Other input
; is returned unchanged.

function unstring, input
	if size(input, /type) ne 7 then return, input
	if n_elements(input) ne 1 then message, 'INPUT must be a scalar string.'

	value = strtrim(input, 2)
	if value eq '' then return, input

	if stregex(value, '^[+-]?[0-9]+[sS]?$', /boolean) then return, fix(value)
	if stregex(value, '^[+-]?[0-9]+[bB]$', /boolean) then $
		return, byte(fix(value))
	if stregex(value, '^[+-]?[0-9]+[lL]$', /boolean) then return, long(value)
	if stregex(value, '^[+-]?[0-9]+[uU]$', /boolean) then return, uint(value)
	if stregex(value, '^[+-]?[0-9]+[uU][lL]$', /boolean) then $
		return, ulong(value)
	if stregex(value, '^[+-]?[0-9]+[lL][lL]$', /boolean) then $
		return, long64(value)
	if stregex(value, '^[+-]?[0-9]+[uU][lL][lL]$', /boolean) then $
		return, ulong64(value)

	number_pattern = '^([+-]?([0-9]+([.,][0-9]*)?|[.,][0-9]+))'
	float_pattern = number_pattern + '([eE][+-]?[0-9]+)?$'
	double_pattern = number_pattern + '[dD][+-]?[0-9]+$'
	if stregex(value, float_pattern, /boolean) then begin
		comma = strpos(value, ',')
		if comma ne -1 then strput, value, '.', comma
		return, float(value)
	endif
	if stregex(value, double_pattern, /boolean) then begin
		comma = strpos(value, ',')
		if comma ne -1 then strput, value, '.', comma
		return, double(value)
	endif

	return, input
end
