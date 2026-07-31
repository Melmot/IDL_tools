; Digitize points from an image file.
; Input: file is the image path; xrange and yrange give the axis limits.
; Output: x and y contain the selected data coordinates; box contains the
; left, bottom, right, and top device coordinates and may be reused as input.
; Keywords: xlog and ylog select logarithmic axes, zoom sets the display
; scale, radius sets the point selection distance in pixels, nomark suppresses
; point markers, color sets the packed RGB color of the frame and points.

function plot_clicker_window_open, window_id
	device, window_state=states
	if window_id lt 0 or window_id ge n_elements(states) then return, 0B
	return, states[window_id]
end

pro plot_clicker, file, xrange, yrange, x, y, box=box, xlog=xlog, $
		ylog=ylog, zoom=zoom, radius=radius, color=color, nomark=nomark
	if size(file, /type) ne 7 or n_elements(file) ne 1 then $
		message, 'file must be a scalar string'
	if not file_test(file) then message, 'File not found: ' + file
	if not query_image(file, info) then $
		message, 'Unsupported image file: ' + file

	if n_elements(xrange) ne 2 or n_elements(yrange) ne 2 then $
		message, 'xrange and yrange must contain two elements'
	if xrange[0] eq xrange[1] or yrange[0] eq yrange[1] then $
		message, 'Axis ranges must have non-zero length'
	if keyword_set(xlog) and min(xrange) le 0 then $
		message, 'xrange must be positive for a logarithmic axis'
	if keyword_set(ylog) and min(yrange) le 0 then $
		message, 'yrange must be positive for a logarithmic axis'

	numeric_types = [1, 2, 3, 4, 5, 12, 13, 14, 15]
	if n_elements(zoom) eq 0 then begin
		zoom_factor = 1D
	endif else begin
		zoom_type = size(zoom, /type)
		if n_elements(zoom) ne 1 or $
				total(zoom_type eq numeric_types) eq 0 then $
			message, 'zoom must be a positive scalar number'
		zoom_factor = double(zoom)
		if zoom_factor le 0 then message, 'zoom must be positive'
	endelse
	if n_elements(color) eq 0 then begin
		color = 255L
	endif else begin
		if n_elements(color) ne 1 then $
			message, 'color must be a packed RGB scalar'
		color_type = size(color, /type)
		if total(color_type eq numeric_types) eq 0 then $
			message, 'color must be a packed RGB scalar'
		color = double(color)
		if finite(color) eq 0 then $
			message, 'color must be an integer from 0 to 16777215'
		if color ne floor(color) or color lt 0 or color gt 16777215D then $
			message, 'color must be an integer from 0 to 16777215'
		color = long(color)
	endelse

	if n_elements(radius) eq 0 then begin
		radius = 8D
	endif else begin
		if n_elements(radius) ne 1 then $
			message, 'radius must be a non-negative scalar'
		radius_type = size(radius, /type)
		if total(radius_type eq numeric_types) eq 0 then $
			message, 'radius must be a non-negative scalar'
		radius = double(radius)
		if radius lt 0 then message, 'radius must be non-negative'
	endelse

	image = read_image(file, red, green, blue)
	image_ndims = size(image, /n_dimensions)
	is_rgb = 0B
	if image_ndims eq 3 then begin
		image_dims = size(image, /dimensions)
		if image_dims[0] ge 3 then begin
			image = image[0:2, *, *]
			is_rgb = 1B
		endif else if image_dims[0] eq 2 then begin
			image = reform(image[0, *, *])
			image_ndims = 2
		endif else message, 'Unsupported channel layout'
	endif

	display_size = info.dimensions
	screen_size = get_screen_size()
	scale = min([zoom_factor, 0.90D * screen_size[0] / display_size[0], $
		0.85D * screen_size[1] / display_size[1]])
	if scale ne 1D then begin
		display_size = long(display_size * scale)
		display_size = display_size > 1L
		if is_rgb then begin
			image = congrid(image, 3, display_size[0], display_size[1])
		endif else if info.has_palette then begin
			image = congrid(image, display_size[0], display_size[1])
		endif else begin
			image = congrid(image, display_size[0], display_size[1], /interp)
		endelse
	endif

	device, get_decomposed=old_decomposed
	window, /free, xsize=display_size[0], ysize=display_size[1], $
		title=file_basename(file)
	window_id = !d.window
	if is_rgb then begin
		tv, image, true=1
	endif else begin
		device, decomposed=0
		if info.has_palette then begin
			tvlct, red, green, blue
			tv, image
		endif else begin
			gray = bindgen(256)
			tvlct, gray, gray, gray
			tvscl, image
		endelse
	endelse
	device, decomposed=1

	box_valid = 0B
	if n_elements(box) ne 0 then begin
		if n_elements(box) ne 4 then message, 'box must contain four elements'
		box = double(box)
		box = [min(box[[0, 2]]), min(box[[1, 3]]), $
			max(box[[0, 2]]), max(box[[1, 3]])]
		box_valid = box[0] ne box[2] and box[1] ne box[3]
		if not box_valid then $
			print, 'Calibration box must have non-zero width and height.'
	endif

	while not box_valid do begin
		print, 'Drag across the plotting area with the left mouse button.'
		button = 0L
		while plot_clicker_window_open(window_id) and button ne 1 do begin
			cursor, x0, y0, /device, /nowait
			button = !mouse.button
			wait, 0.01
		endwhile
		if not plot_clicker_window_open(window_id) then begin
			device, decomposed=old_decomposed
			x = !values.d_nan
			y = !values.d_nan
			return
		endif
		x1 = x0
		y1 = y0
		while plot_clicker_window_open(window_id) and !mouse.button eq 1 do begin
			cursor, x1, y1, /device, /nowait
			if is_rgb then begin
				tv, image, true=1
			endif else if info.has_palette then begin
				device, decomposed=0
				tv, image
				device, decomposed=1
			endif else begin
				device, decomposed=0
				tvscl, image
				device, decomposed=1
			endelse
			plots, [x0, x1, x1, x0, x0], [y0, y0, y1, y1, y0], $
				/device, color=color
			wait, 0.01
		endwhile
		if not plot_clicker_window_open(window_id) then begin
			device, decomposed=old_decomposed
			x = !values.d_nan
			y = !values.d_nan
			return
		endif
		box = double([min([x0, x1]), min([y0, y1]), $
			max([x0, x1]), max([y0, y1])])
		box_valid = box[0] ne box[2] and box[1] ne box[3]
		if not box_valid then begin
			print, 'Calibration box must have non-zero width and height.'
			if is_rgb then begin
				tv, image, true=1
			endif else if info.has_palette then begin
				device, decomposed=0
				tv, image
				device, decomposed=1
			endif else begin
				device, decomposed=0
				tvscl, image
				device, decomposed=1
			endelse
		endif
	endwhile

	plots, [box[0], box[2], box[2], box[0], box[0]], $
		[box[1], box[1], box[3], box[3], box[1]], /device, $
		color=color

	xlimits = double(xrange)
	ylimits = double(yrange)
	if keyword_set(xlog) then xlimits = alog10(xlimits)
	if keyword_set(ylog) then ylimits = alog10(ylimits)

	print, 'Left button: add or move; right button: delete; close window: finish.'
	x = !values.d_nan
	y = !values.d_nan
	px = !values.d_nan
	py = !values.d_nan
	count = 0L
	while 1 do begin
		button = 0L
		while plot_clicker_window_open(window_id) and button eq 0 do begin
			cursor, xd, yd, /device, /nowait
			button = !mouse.button
			wait, 0.01
		endwhile
		if not plot_clicker_window_open(window_id) then break
		if button eq 4 then begin
			if count gt 0 and radius gt 0 then begin
				distance = sqrt((px - xd) ^ 2 + (py - yd) ^ 2)
				minimum = min(distance, delete_index)
				if minimum le radius then begin
					if count eq 1 then begin
						px = !values.d_nan
						py = !values.d_nan
						x = !values.d_nan
						y = !values.d_nan
						count = 0L
					endif else begin
						keep_indices = where(lindgen(count) ne delete_index)
						px = px[keep_indices]
						py = py[keep_indices]
						count = count - 1L
					endelse
				endif
			endif
			if is_rgb then begin
				tv, image, true=1
			endif else if info.has_palette then begin
				device, decomposed=0
				tv, image
				device, decomposed=1
			endif else begin
				device, decomposed=0
				tvscl, image
				device, decomposed=1
			endelse
			plots, [box[0], box[2], box[2], box[0], box[0]], $
				[box[1], box[1], box[3], box[3], box[1]], /device, $
				color=color
			if count gt 0 and not keyword_set(nomark) then $
				plots, px, py, /device, psym=1, color=color
			while plot_clicker_window_open(window_id) and $
					!mouse.button ne 0 do begin
				cursor, xd, yd, /device, /nowait
				wait, 0.01
			endwhile
			if count gt 0 then begin
				tx = (px - box[0]) / (box[2] - box[0])
				ty = (py - box[1]) / (box[3] - box[1])
				x = xlimits[0] + tx * (xlimits[1] - xlimits[0])
				y = ylimits[0] + ty * (ylimits[1] - ylimits[0])
				if keyword_set(xlog) then x = 10D ^ x
				if keyword_set(ylog) then y = 10D ^ y
			endif
			continue
		endif
		if button ne 1 then begin
			while plot_clicker_window_open(window_id) and !mouse.button ne 0 do begin
				cursor, xd, yd, /device, /nowait
				wait, 0.01
			endwhile
			continue
		endif

		move_index = -1L
		move_corner = -1L
		closest = radius + 1D
		if radius gt 0 then begin
			corner_x = [box[0], box[2], box[2], box[0]]
			corner_y = [box[1], box[1], box[3], box[3]]
			corner_distance = sqrt((corner_x - xd) ^ 2 + $
				(corner_y - yd) ^ 2)
			corner_minimum = min(corner_distance, corner_index)
			if corner_minimum le radius then begin
				move_corner = corner_index
				closest = corner_minimum
			endif
		endif
		if count gt 0 and radius gt 0 then begin
			distance = sqrt((px - xd) ^ 2 + (py - yd) ^ 2)
			minimum = min(distance, min_index)
			if minimum le radius and minimum lt closest then begin
				move_index = min_index
				move_corner = -1L
			endif
		endif

		if move_corner ge 0 then begin
			old_box = box
			opposite = (move_corner + 2) mod 4
			opposite_x = corner_x[opposite]
			opposite_y = corner_y[opposite]
		endif else if move_index lt 0 then begin
			if count eq 0 then begin
				px = double(xd)
				py = double(yd)
			endif else begin
				px = [px, double(xd)]
				py = [py, double(yd)]
			endelse
			move_index = count
			count = count + 1L
		endif

		while plot_clicker_window_open(window_id) and !mouse.button eq 1 do begin
			cursor, xd, yd, /device, /nowait
			if move_corner ge 0 then begin
				box = double([min([xd, opposite_x]), $
					min([yd, opposite_y]), max([xd, opposite_x]), $
					max([yd, opposite_y])])
			endif else begin
				px[move_index] = xd
				py[move_index] = yd
			endelse
			if is_rgb then begin
				tv, image, true=1
			endif else if info.has_palette then begin
				device, decomposed=0
				tv, image
				device, decomposed=1
			endif else begin
				device, decomposed=0
				tvscl, image
				device, decomposed=1
			endelse
			plots, [box[0], box[2], box[2], box[0], box[0]], $
				[box[1], box[1], box[3], box[3], box[1]], /device, $
				color=color
			if not keyword_set(nomark) then $
				plots, px, py, /device, psym=1, color=color
			wait, 0.01
		endwhile

		if move_corner ge 0 then begin
			if box[0] eq box[2] or box[1] eq box[3] then box = old_box
		endif
		if count gt 0 then begin
			tx = (px[0:count - 1] - box[0]) / (box[2] - box[0])
			ty = (py[0:count - 1] - box[1]) / (box[3] - box[1])
			x = xlimits[0] + tx * (xlimits[1] - xlimits[0])
			y = ylimits[0] + ty * (ylimits[1] - ylimits[0])
			if keyword_set(xlog) then x = 10D ^ x
			if keyword_set(ylog) then y = 10D ^ y
		endif
	endwhile

	device, decomposed=old_decomposed
	if count eq 0 then message, 'No points were selected', /continue
end
