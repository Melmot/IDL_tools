; Find equal values in two arrays without constructing a comparison matrix.
; result = arr_match(array1, array2)
; result[n, 0] and result[n, 1] are matching flat indices. Duplicate values
; produce all matching index pairs. -1 is returned when there are no matches.

function arr_match, array1, array2
	n1 = n_elements(array1)
	n2 = n_elements(array2)
	if n1 eq 0 or n2 eq 0 then return, -1L

	flat1 = reform(array1, n1)
	flat2 = reform(array2, n2)
	order1 = sort(flat1)
	order2 = sort(flat2)
	sorted1 = flat1[order1]
	sorted2 = flat2[order2]

	i = 0L
	j = 0L
	n_pairs = 0D
	while i lt n1 and j lt n2 do begin
		if sorted1[i] eq sorted2[j] then begin
			i2 = i
			while i2 lt n1 - 1 do begin
				if sorted1[i2 + 1] ne sorted1[i] then break
				i2 = i2 + 1
			endwhile
			j2 = j
			while j2 lt n2 - 1 do begin
				if sorted2[j2 + 1] ne sorted2[j] then break
				j2 = j2 + 1
			endwhile
			n_pairs = n_pairs + double(i2 - i + 1) * double(j2 - j + 1)
			i = i2 + 1
			j = j2 + 1
		endif else if sorted1[i] lt sorted2[j] then i = i + 1 $
			else j = j + 1
	endwhile

	if n_pairs eq 0 then return, -1L
	if n_pairs gt 2147483647D then message, 'Too many matching pairs.'

	matches = lonarr(long(n_pairs), 2)
	i = 0L
	j = 0L
	offset = 0L
	while i lt n1 and j lt n2 do begin
		if sorted1[i] eq sorted2[j] then begin
			i2 = i
			while i2 lt n1 - 1 do begin
				if sorted1[i2 + 1] ne sorted1[i] then break
				i2 = i2 + 1
			endwhile
			j2 = j
			while j2 lt n2 - 1 do begin
				if sorted2[j2 + 1] ne sorted2[j] then break
				j2 = j2 + 1
			endwhile

			run1 = i2 - i + 1
			for k = j, j2 do begin
				matches[offset:offset + run1 - 1, 0] = order1[i:i2]
				matches[offset:offset + run1 - 1, 1] = order2[k]
				offset = offset + run1
			endfor
			i = i2 + 1
			j = j2 + 1
		endif else if sorted1[i] lt sorted2[j] then i = i + 1 $
			else j = j + 1
	endwhile

	return, matches
end
