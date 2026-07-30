; Capitalize a string or an array of strings.
; result = firstcap(input [, /all_words, /except])
; all_words capitalizes every word. except keeps common short words lowercase,
; except at the beginning of a string.

function firstcap, input, all_words=all_words, except=except
	if size(input, /type) ne 7 then return, input

	exceptions = ['a', 'an', 'the', 'at', 'by', 'for', 'in', 'of', 'on', $
		'to', 'up', 'and', 'as', 'but', 'or', 'nor']
	if size(input, /n_dimensions) eq 0 then output = '' $
		else output = strarr(size(input, /dimensions))

	for k = 0L, n_elements(input) - 1 do begin
		if keyword_set(all_words) then begin
			words = strsplit(input[k], ' ', /extract, count=n_words)
		endif else begin
			words = input[k]
			n_words = 1
		endelse

		for i = 0L, n_words - 1 do begin
			if i gt 0 and keyword_set(except) and $
					max(strlowcase(words[i]) eq exceptions) then begin
				words[i] = strlowcase(words[i])
			endif else if strlen(words[i]) eq 1 then begin
				words[i] = strupcase(words[i])
			endif else begin
				words[i] = strupcase(strmid(words[i], 0, 1)) + $
					strlowcase(strmid(words[i], 1))
			endelse
		endfor

		output[k] = strjoin(words, ' ')
	endfor

	return, output
end
