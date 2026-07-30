; Convert a string-array FITS header to an IDL structure.
; Input: header contains FITS cards.
; Output: the structure contains header values; descriptions, comments, and
; history optionally return the associated text.

function hdr_value_end, card
	in_quote = 0B
	for position = 10L, strlen(card) - 1 do begin
		character = strmid(card, position, 1)
		if character eq "'" then in_quote = ~in_quote
		if character eq '/' and ~in_quote then return, position
	endfor
	return, strlen(card)
end


function hdr_struct, header, descriptions=descriptions, $
		comments=comments, history=history
	if size(header, /type) ne 7 then message, 'HEADER must be a string array.'

	n_fields = 0L
	n_comments = 0L
	n_history = 0L
	comments = ''
	history = ''

	for i = 0L, n_elements(header) - 1 do begin
		card = header[i]
		tag = strtrim(strmid(card, 0, 8), 2)
		if tag eq 'END' then break

		if tag eq 'COMMENT' then begin
			text = strtrim(strmid(card, 8), 2)
			if n_comments eq 0 then comments = text else comments = [comments, text]
			n_comments = n_comments + 1
			continue
		endif
		if tag eq 'HISTORY' then begin
			text = strtrim(strmid(card, 8), 2)
			if n_history eq 0 then history = text else history = [history, text]
			n_history = n_history + 1
			continue
		endif
		if tag eq '' or strmid(card, 8, 1) ne '=' then continue

		position = strpos(tag, '-')
		while position ne -1 do begin
			strput, tag, '_', position
			position = strpos(tag, '-')
		endwhile

		value_end = hdr_value_end(card)
		value_text = strtrim(strmid(card, 10, value_end - 10), 2)
		description = ''
		if value_end lt strlen(card) then $
			description = strtrim(strmid(card, value_end + 1), 2)

		if strlen(value_text) ge 2 and strmid(value_text, 0, 1) eq "'" and $
				strmid(value_text, strlen(value_text) - 1, 1) eq "'" then begin
			value = strtrim(strmid(value_text, 1, strlen(value_text) - 2), 2)
		endif else if value_text eq 'T' or value_text eq 'F' then begin
			value = byte(value_text eq 'T')
		endif else if stregex(value_text, $
				'^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)([eEdD][+-]?[0-9]+)?$', $
				/boolean) then begin
			if strpos(value_text, '.') ne -1 or $
					strpos(strupcase(value_text), 'E') ne -1 or $
					strpos(strupcase(value_text), 'D') ne -1 then $
				value = double(value_text) $
			else value = long64(value_text)
		endif else value = value_text

		if n_fields eq 0 then begin
			result = create_struct(tag, value)
			descriptions = create_struct(tag, description)
			n_fields = 1
		endif else if total(tag_names(result) eq strupcase(tag)) eq 0 then begin
			result = create_struct(result, tag, value)
			descriptions = create_struct(descriptions, tag, description)
			n_fields = n_fields + 1
		endelse
	endfor

	if n_fields eq 0 then message, 'No FITS value cards found.'
	return, result
end
