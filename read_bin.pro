; Read an array stored by write_bin.
; array = read_bin(file)
; The compact file header preserves the IDL data type and dimensions.
; This is efficient for large low-bit-depth arrays but less flexible than save.

function read_bin, file
	dtype = fix(read_binary(file, data_start=0, data_type=1, data_dims=0))
	ndims = fix(read_binary(file, data_start=1, data_type=1, data_dims=0))
	dims = read_binary(file, data_start=2, data_type=3, data_dims=ndims, $
		endian='little')

	return, read_binary(file, data_start=2 + ndims * 4, data_type=dtype, $
		data_dims=dims, endian='little')
end
