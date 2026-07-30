; Print a compact description of an IDL structure.
; strhelp, structure [, indent_length=n, /tab_indent, /noprint,
;   return_tags=tags, return_types=types, return_vals=values]
; Nested structures and valid pointers are followed recursively. Structure
; arrays are represented by their dimensions and their first element.

pro strhelp, structure, indent_length=indent_length, tab_indent=tab_indent, $
		noprint=noprint, return_tags=return_tags, $
		return_types=return_types, return_vals=return_vals
	if size(structure, /type) ne 8 then $
		message, 'STRUCTURE must be an IDL structure.'

	tab = string(9B)
	case keyword_set(tab_indent) + 2B * (n_elements(indent_length) ne 0) of
		0: begin
			indent_length = 4
			indent = '    '
		end
		1: indent = tab
		2: begin
			if indent_length lt 0 then message, 'INDENT_LENGTH must not be negative.'
			if indent_length eq 0 then indent = '' $
				else indent = strjoin(replicate(' ', indent_length))
		end
		3: message, 'INDENT_LENGTH and TAB_INDENT cannot be used together.'
	endcase

	tags = strlowcase(tag_names(structure))
	for i = 0L, n_elements(tags) - 1 do begin
		element = structure.(i)
		element_size = size(element, /structure)
		element_size.type_name = firstcap(element_size.type_name)

		describe_pointer:
		if element_size.n_elements gt 1 then begin
			dimensions = element_size.dimensions[0:element_size.n_dimensions - 1]
			element_value = 'Array[' + $
				strjoin(string(dimensions, format='(i0)'), ', ') + ']'
			element = element[0]
		endif else begin
			case element_size.type_name of
				'Undefined': element_value = ''
				'String': element_value = "'" + element + "'"
				'Struct': begin
					element_size.type_name = ''
					element_value = ''
				end
				'*Struct': element_value = ''
				'Pointer': begin
					if ptr_valid(element) then begin
						if size(*element, /type) eq 0 then element = 'UNDEFINED' $
							else element = *element
						element_size = size(element, /structure)
						element_size.type_name = '*' + firstcap(element_size.type_name)
						goto, describe_pointer
					endif else element_value = 'Null'
				end
				else: element_value = strtrim(string(element), 1)
			endcase
		endelse

		if i eq 0 then begin
			full_tags = tags[i]
			full_types = element_size.type_name
			full_values = element_value
		endif else begin
			full_tags = [full_tags, tags[i]]
			full_types = [full_types, element_size.type_name]
			full_values = [full_values, element_value]
		endelse

		if element_size.type_name eq '' or $
				element_size.type_name eq '*Struct' or $
				element_size.type_name eq 'Struct' then begin
			if keyword_set(tab_indent) then begin
				strhelp, element, /tab_indent, /noprint, return_tags=sub_tags, $
					return_types=sub_types, return_vals=sub_values
			endif else begin
				strhelp, element, indent_length=indent_length, /noprint, $
					return_tags=sub_tags, return_types=sub_types, $
					return_vals=sub_values
			endelse
			full_tags = [full_tags, indent + sub_tags]
			full_types = [full_types, sub_types]
			full_values = [full_values, sub_values]
		endif
	endfor

	return_tags = full_tags
	return_types = full_types
	return_vals = full_values

	if ~keyword_set(noprint) then begin
		max_tag_length = max(strlen(full_tags))
		max_type_length = max(strlen(full_types))
		for i = 0L, n_elements(full_tags) - 1 do begin
			tag_padding = max_tag_length - strlen(full_tags[i])
			type_padding = max_type_length - strlen(full_types[i])
			if tag_padding gt 0 then $
				space1 = strjoin(replicate(' ', tag_padding + 1)) + tab $
			else space1 = tab
			if type_padding gt 0 then $
				space2 = strjoin(replicate(' ', type_padding + 1)) + tab $
			else space2 = tab
			print, full_tags[i], space1, full_types[i], space2, $
				full_values[i], format='(a,a,a,a,a)'
		endfor
	endif
end
