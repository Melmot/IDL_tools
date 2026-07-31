; Extract solar image geometry used by solar2polar and polar2solar.
; geometry = solgeom(header)
; header may be a FITS card array or a compatible structure.

function solgeom, header
	if size(header, /type) eq 7 then header = hdr_struct(header)
	if size(header, /type) ne 8 then $
		message, 'HEADER must be a FITS card array or structure.'

	tags = tag_names(header)
	required = ['NAXIS1', 'NAXIS2']
	for i = 0L, n_elements(required) - 1 do $
		if total(tags eq required[i]) eq 0 then $
			message, 'Missing header field: ' + required[i]

	index = where(tags eq 'NAXIS1')
	width = header.(index[0])
	index = where(tags eq 'NAXIS2')
	height = header.(index[0])

	if total(tags eq 'X0_MP') and total(tags eq 'Y0_MP') then begin
		index = where(tags eq 'X0_MP')
		x0 = header.(index[0])
		index = where(tags eq 'Y0_MP')
		y0 = header.(index[0])
	endif else begin
		if total(tags eq 'CRPIX1') eq 0 or total(tags eq 'CRPIX2') eq 0 then $
			message, 'Missing CRPIX1 or CRPIX2.'
		index = where(tags eq 'CRPIX1')
		x0 = header.(index[0])
		index = where(tags eq 'CRPIX2')
		y0 = header.(index[0])
	endelse

	if total(tags eq 'CROTA2') then begin
		index = where(tags eq 'CROTA2')
		angle = header.(index[0])
	endif else if total(tags eq 'SC_ROLL') then begin
		index = where(tags eq 'SC_ROLL')
		angle = header.(index[0])
	endif else if total(tags eq 'SAT_ROT') then begin
		index = where(tags eq 'SAT_ROT')
		angle = -header.(index[0])
	endif else angle = 0.0

	if total(tags eq 'R_SUN') then begin
		index = where(tags eq 'R_SUN')
		radius = header.(index[0])
	endif else if total(tags eq 'SOLAR_R') and total(tags eq 'CDELT1') then begin
		index = where(tags eq 'SOLAR_R')
		radius = header.(index[0])
		index = where(tags eq 'CDELT1')
		radius = radius / header.(index[0])
	endif else if total(tags eq 'DSUN_OBS') and total(tags eq 'CDELT1') then begin
		index = where(tags eq 'DSUN_OBS')
		pixel_size = header.(index[0])
		index = where(tags eq 'CDELT1')
		pixel_size = pixel_size * header.(index[0]) / 3600D * !dtor * 1D-3
		radius = 696000D / pixel_size
	endif else message, 'Cannot determine the solar radius in pixels.'

	return, {width:long(width), height:long(height), x0:double(x0), $
		y0:double(y0), angle:double(angle), radius:double(radius)}
end
