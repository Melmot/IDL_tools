; Write an IDL array to a compact little-endian binary file.
; write_bin, file, array
; The data type and dimensions are stored in a small file header.
; This is efficient for large low-bit-depth arrays but less flexible than save.

pro write_bin, file, array
	catch, error
	if error ne 0 then begin
		error_message = !error_state.msg
		catch, /cancel
		if n_elements(unit) ne 0 then free_lun, unit
		message, error_message
	endif

	openw, unit, file, /get_lun, /swap_if_big_endian
	writeu, unit, byte(size(array, /type))
	writeu, unit, byte(size(array, /n_dimensions))
	writeu, unit, size(array, /dimensions)
	writeu, unit, array
	free_lun, unit
end
