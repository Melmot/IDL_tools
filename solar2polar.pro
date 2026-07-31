; Convert a solar image to a rectangular radius-angle map.
; result = solar2polar(image, header [, rmin=rmin, rmax=rmax,
;   hmin=hmin, hmax=hmax, hres=hres, fimin=fimin, fimax=fimax,
;   fires=fires, /interp, cubic=cubic, missing=missing])
; Heights and hres are in km; angles are in degrees clockwise from solar north.

function solar2polar, image, header, rmin=rmin, rmax=rmax, $
		hmin=hmin, hmax=hmax, hres=hres, fimin=fimin, fimax=fimax, $
		fires=fires, interp=interp, cubic=cubic, missing=missing
	if size(image, /n_dimensions) ne 2 then message, 'IMAGE must be 2-dimensional.'
	if n_elements(missing) eq 0 then missing = 0

	geometry = solgeom(header)
	solar_radius_km = 696300D

	if n_elements(rmin) ne 0 then min_radius = rmin * geometry.radius $
		else if n_elements(hmin) ne 0 then $
			min_radius = (1D + hmin / solar_radius_km) * geometry.radius $
		else min_radius = geometry.radius
	if n_elements(rmax) ne 0 then max_radius = rmax * geometry.radius $
		else if n_elements(hmax) ne 0 then $
			max_radius = (1D + hmax / solar_radius_km) * geometry.radius $
		else max_radius = sqrt(max([geometry.width - geometry.x0, $
			geometry.x0])^2 + max([geometry.height - geometry.y0, $
			geometry.y0])^2)

	if n_elements(hres) ne 0 then $
		radius_step = hres * geometry.radius / solar_radius_km $
		else radius_step = 1D
	if n_elements(fimin) eq 0 then fimin = 0D
	if n_elements(fimax) eq 0 then fimax = 360D
	if n_elements(fires) eq 0 then fires = 180D / (geometry.radius * !dpi)
	if radius_step le 0 or fires le 0 then message, 'HRES and FIRES must be positive.'

	radius = dindgen(round((max_radius - min_radius) / radius_step) + 1) * $
		radius_step + min_radius
	angle = dindgen(round((fimax - fimin) / fires) + 1) * fires + $
		fimin + geometry.angle
	x = sin(angle * !dtor) # radius + geometry.x0
	y = cos(angle * !dtor) # radius + geometry.y0
	valid = x ge 0 and x lt geometry.width and y ge 0 and y lt geometry.height

	if keyword_set(interp) then begin
		result = interpolate(image, x, y, cubic=cubic, missing=missing)
	endif else begin
		safe_x = (round(x) > 0L) < (geometry.width - 1L)
		safe_y = (round(y) > 0L) < (geometry.height - 1L)
		result = image[safe_x, safe_y]
		invalid = where(~valid, n_invalid)
		if n_invalid gt 0 then result[invalid] = missing
	endelse

	return, result
end
