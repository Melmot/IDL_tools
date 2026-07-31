; Convert a rectangular radius-angle map back to a solar image.
; result = polar2solar(polar_map, header [, rmin=rmin, hmin=hmin,
;   hres=hres, fimin=fimin, fires=fires, /interp, cubic=cubic,
;   missing=missing])
; Heights and hres are in km; angles are in degrees clockwise from solar north.

function polar2solar, polar_map, header, rmin=rmin, hmin=hmin, $
		hres=hres, fimin=fimin, fires=fires, interp=interp, cubic=cubic, $
		missing=missing
	if size(polar_map, /n_dimensions) ne 2 then $
		message, 'POLAR_MAP must be 2-dimensional.'
	if n_elements(missing) eq 0 then missing = 0

	geometry = solgeom(header)
	dims = size(polar_map, /dimensions)
	solar_radius_km = 696300D

	if n_elements(rmin) ne 0 then min_radius = rmin * geometry.radius $
		else if n_elements(hmin) ne 0 then $
			min_radius = (1D + hmin / solar_radius_km) * geometry.radius $
		else min_radius = geometry.radius
	if n_elements(hres) ne 0 then $
		radius_step = hres * geometry.radius / solar_radius_km $
		else radius_step = 1D
	if n_elements(fimin) eq 0 then fimin = 0D
	if n_elements(fires) eq 0 then fires = 360D / (dims[0] - 1)
	if radius_step le 0 or fires le 0 then message, 'HRES and FIRES must be positive.'

	x = rebin(dindgen(geometry.width), geometry.width, geometry.height)
	y = rebin(transpose(dindgen(geometry.height)), geometry.width, geometry.height)
	angle = atan(x - geometry.x0, y - geometry.y0) / !dpi * 180D - $
		geometry.angle
	negative = where(angle lt 0, n_negative)
	if n_negative gt 0 then angle[negative] = angle[negative] + 360D
	radius = sqrt((x - geometry.x0)^2 + (y - geometry.y0)^2)

	angle_index = (angle - fimin) / fires
	radius_index = (radius - min_radius) / radius_step
	valid = angle_index ge 0 and angle_index lt dims[0] and $
		radius_index ge 0 and radius_index lt dims[1]

	if keyword_set(interp) then begin
		result = interpolate(polar_map, angle_index, radius_index, $
			cubic=cubic, missing=missing)
	endif else begin
		safe_angle = (round(angle_index) > 0L) < (dims[0] - 1L)
		safe_radius = (round(radius_index) > 0L) < (dims[1] - 1L)
		result = polar_map[safe_angle, safe_radius]
		invalid = where(~valid, n_invalid)
		if n_invalid gt 0 then result[invalid] = missing
	endelse

	return, result
end
