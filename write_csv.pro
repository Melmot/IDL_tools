; Write a two-dimensional array to a delimited text file.
; write_csv, file_path, data [, headers=headers, delimiter=delimiter]
; delimiter defaults to a semicolon.

pro write_csv, file_path, data, headers=headers, delimiter=delimiter
	if size(data, /n_dimensions) ne 2 then message, 'DATA must be 2-dimensional.'
	if n_elements(delimiter) eq 0 then delimiter = ';'

	data_dims = size(data, /dimensions)
	n_cols = data_dims[0]
	n_rows = data_dims[1]
	if n_elements(headers) ne 0 and n_elements(headers) ne n_cols then $
		message, 'The number of headers must match the number of columns.'

	catch, error
	if error ne 0 then begin
		error_message = !error_state.msg
		catch, /cancel
		if n_elements(unit) ne 0 then free_lun, unit
		message, error_message
	endif

	openw, unit, file_path, /get_lun
	if n_elements(headers) ne 0 then printf, unit, strjoin(headers, delimiter)
	for row = 0L, n_rows - 1 do $
		printf, unit, strjoin(string(data[*, row]), delimiter)
	free_lun, unit
end
