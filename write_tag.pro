; Write, add, or delete a field specified by a dotted structure path.
; Input: structure is modified in place; path may include nested fields.
; Missing intermediate structures are created unless /delete is set.
; Output: changed is 1 if the structure was modified, otherwise 0.

function write_tag_branch, path, value
	separator = strpos(path, '.')
	if separator eq -1 then return, create_struct(path, value)

	tag = strmid(path, 0, separator)
	rest = strmid(path, separator + 1)
	return, create_struct(tag, write_tag_branch(rest, value))
end


function write_tag_without, structure, index
	if n_tags(structure) eq 1 then $
		message, 'The only tag of a structure cannot be deleted'

	names = tag_names(structure)
	first = 1B
	for i = 0, n_tags(structure) - 1 do begin
		if i ne index then begin
			if first then begin
				result = create_struct(names[i], structure.(i))
				first = 0B
			endif else result = create_struct(result, names[i], structure.(i))
		endif
	endfor
	return, result
end


function write_tag_replace, structure, index, value
	names = tag_names(structure)
	for i = 0, n_tags(structure) - 1 do begin
		if i eq index then item = value else item = structure.(i)
		if i eq 0 then result = create_struct(names[i], item) $
		else result = create_struct(result, names[i], item)
	endfor
	return, result
end


pro write_tag, structure, path, value, delete=delete, changed=changed
	changed = 0B
	if size(structure, /type) ne 8 then message, 'STRUCTURE must be a structure'
	if n_elements(structure) ne 1 then message, 'STRUCTURE must be scalar'
	if size(path, /type) ne 7 or n_elements(path) ne 1 then $
		message, 'PATH must be a scalar string'
	if strlen(path) eq 0 then message, 'PATH must not be empty'
	if strpos(path, '..') ne -1 then message, 'Invalid tag path: ' + path
	if not keyword_set(delete) and n_params() lt 3 then $
		message, 'VALUE is required unless DELETE is set'

	separator = strpos(path, '.')
	if separator eq -1 then begin
		tag = path
		rest = ''
	endif else begin
		tag = strmid(path, 0, separator)
		rest = strmid(path, separator + 1)
	endelse

	if strlen(tag) eq 0 or (separator ne -1 and strlen(rest) eq 0) then $
		message, 'Invalid tag path: ' + path

	match = where(tag_names(structure) eq strupcase(tag), count)
	if count eq 0 then begin
		if keyword_set(delete) then message, 'Tag not found: ' + tag
		if tag_names(structure, /structure_name) ne '' then $
			message, 'Tags cannot be added to a named structure'
		if separator eq -1 then branch = value $
			else branch = write_tag_branch(rest, value)
		structure = create_struct(structure, tag, branch)
		changed = 1B
		return
	endif

	if separator eq -1 then begin
		if keyword_set(delete) then begin
			if tag_names(structure, /structure_name) ne '' then $
				message, 'Tags cannot be deleted from a named structure'
			structure = write_tag_without(structure, match[0])
			changed = 1B
		endif else structure.(match[0]) = value
	endif else begin
		nested = structure.(match[0])
		if size(nested, /type) ne 8 or n_elements(nested) ne 1 then $
			message, 'Tag is not a scalar structure: ' + tag
		if keyword_set(delete) then $
			write_tag, nested, rest, /delete, changed=nested_changed $
		else write_tag, nested, rest, value, changed=nested_changed
		if nested_changed then begin
			if tag_names(structure, /structure_name) ne '' then $
				message, 'Nested tags cannot be added or deleted in a named structure'
			structure = write_tag_replace(structure, match[0], nested)
			changed = 1B
		endif else structure.(match[0]) = nested
	endelse
end
