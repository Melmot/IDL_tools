; Interactively draw a two-dimensional spline on an image.
; Input: image is a two-dimensional or RGB array; step is the target spacing between
; returned points in input-array elements; zoom sets the initial display scale; radius
; sets the selection distance for existing points and the curve in screen pixels;
; color sets the packed RGB color of the spline and control points.
; Output: a structure containing the x and y coordinates of the curve.

function draw_curve_number, value
	text = strtrim(string(value, format='(f0.12)'), 2)
	while strmid(text, strlen(text) - 1, 1) eq '0' do begin
		if strmid(text, strlen(text) - 2, 1) eq '.' then break
		text = strmid(text, 0, strlen(text) - 1)
	endwhile
	return, text
end


pro draw_curve_event, event
	case widget_info(event.id,/uname) of
		'canvas': draw_curve_track, event
		'zoom_in': draw_curve_zoom, event.top, /in
		'zoom_out': draw_curve_zoom, event.top, /out
		'step': draw_curve_set_step, event.top, /quiet
		'clear': draw_curve_clear, event.top
		'done': begin
			draw_curve_set_step, event.top, valid=valid
			if valid then widget_control, event.top, /destroy
		end
    	else:
	endcase
end



pro draw_curve_cleanup, mainwin
	widget_control, mainwin, get_uvalue=data, /no_copy
	ptr_free, data.points.x, data.points.y
	device, decomposed=data.old_decomposed
end



function draw_curve, image, step=step, zoom=zoom, radius=radius, color=color
	image_ndims = size(image, /n_dimensions)
	image_dims = size(image, /dimensions)
	true = 0L
	if image_ndims eq 2 then begin
		dims = image_dims
	endif else if image_ndims eq 3 then begin
		if image_dims[0] eq 3 then begin
			true = 1L
			dims = image_dims[1:2]
		endif else if image_dims[1] eq 3 then begin
			true = 2L
			dims = image_dims[[0, 2]]
		endif else if image_dims[2] eq 3 then begin
			true = 3L
			dims = image_dims[0:1]
		endif else message, 'RGB image must have one dimension of length 3'
	endif else message, 'image must be a two-dimensional or RGB array'
	numeric_types = [1, 2, 3, 4, 5, 12, 13, 14, 15]
	if n_elements(step) eq 0 then begin
		step = 1D
	endif else begin
		if n_elements(step) ne 1 then message, 'step must be a positive scalar'
		step_type = size(step, /type)
		if total(step_type eq numeric_types) eq 0 then $
			message, 'step must be a positive scalar'
		step = double(step)
		if finite(step) eq 0 or step le 0 then message, 'step must be positive'
	endelse
	if n_elements(zoom) eq 0 then begin
		zoom = 1D
	endif else begin
		if n_elements(zoom) ne 1 then message, 'zoom must be a positive scalar'
		zoom_type = size(zoom, /type)
		if total(zoom_type eq numeric_types) eq 0 then $
			message, 'zoom must be a positive scalar'
		zoom = double(zoom)
		if finite(zoom) eq 0 or zoom le 0 then message, 'zoom must be positive'
	endelse
	if n_elements(radius) eq 0 then begin
		radius = 5D
	endif else begin
		if n_elements(radius) ne 1 then $
			message, 'radius must be a non-negative scalar'
		radius_type = size(radius, /type)
		if total(radius_type eq numeric_types) eq 0 then $
			message, 'radius must be a non-negative scalar'
		radius = double(radius)
		if finite(radius) eq 0 or radius lt 0 then $
			message, 'radius must be non-negative'
	endelse
	if n_elements(color) eq 0 then begin
		color = '00ffff'xl
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
	min_zoom = max(1D / dims)
	if zoom lt min_zoom then message, 'zoom is too small for this image'
	draw_dims = long(round(dims * zoom)) > 1L

	curve_x = ptr_new(-1)
	curve_y = ptr_new(-1)
	curve_t = ptr_new(-1)

	device, get_decomposed=old_decomposed
	data = {image:image, dims:dims, draw_dims:draw_dims, true:true, zoom:zoom, $
			radius:radius, color:color, old_decomposed:old_decomposed, $
			min_zoom:min_zoom, $
			points:{x:ptr_new(), y:ptr_new(), n:0, move:-1}, $
			curve:{x:curve_x, y:curve_y, t:curve_t, step:step} }

	mainwin = widget_base(title='DRAW CURVE', mbar=mainwin_mbar, /col)
	canvas = widget_draw(mainwin, x_scroll_size=draw_dims[0], $
		xsize=draw_dims[0], y_scroll_size=draw_dims[1], ysize=draw_dims[1], $
		uname='canvas', /motion, /button, /scroll, frame=0)
	controls = widget_base(mainwin, row=1, space=2, uname='controls', /base_align_left)
	zoom_title = widget_label(controls, value='Zoom', /align_left)
	zoom_out_btn = widget_button(controls, value='-', uname='zoom_out', $
		/align_center, sensitive=zoom / 2D ge min_zoom)
	zoom_label = widget_label(controls, uname='zoom_label', $
		value=string(round(zoom*100), form='(i0,"%")'), /align_left)
	zoom_in_btn = widget_button(controls, value='+', uname='zoom_in', /align_center, sensitive=1)
	step_title = widget_label(controls, value='Step', /align_left)
	step_text = widget_text(controls, value=draw_curve_number(step), $
		xsize=8, uname='step', /editable, /all_events)
	clear_btn = widget_button(controls, value='Clear', uname='clear', /align_center, sensitive=1)
	finish_btn = widget_button(controls, value='Done', uname='done', /align_center, sensitive=1)

	winsize = widget_info(mainwin,/geometry)
	scrsize = get_screen_size()
	maxcanv = [scrsize[0] - winsize.xsize + draw_dims[0], $
		scrsize[1] - winsize.ysize + draw_dims[1]] - [50,100]
	widget_control, canvas, xsize=draw_dims[0] < maxcanv[0], $
		ysize=draw_dims[1] < maxcanv[1]
	winsize = widget_info(mainwin,/geometry)
	widget_control, mainwin, /realize, set_uvalue=data, /no_copy, $
		xoffs=(scrsize[0]-winsize.xsize)/2, yoffs=(scrsize[1]-winsize.ysize)/2-50, /delay_destroy
	draw_curve_draw, mainwin
	xmanager, 'draw_curve', mainwin, /no_block, $
		cleanup='draw_curve_cleanup', /modal

	result = {x:*curve_x, y:*curve_y}
	ptr_free, curve_x, curve_y, curve_t
	return, result
end



pro draw_curve_draw, mainwin
	widget_control, mainwin, get_uvalue=data
	widget_control, widget_info(mainwin, find_by_uname='canvas'), get_value=win_id

	wset, win_id
	if data.true eq 1 then begin
		display_image = congrid(data.image, 3, data.draw_dims[0], data.draw_dims[1])
	endif else if data.true eq 2 then begin
		display_image = congrid(data.image, data.draw_dims[0], 3, data.draw_dims[1])
	endif else if data.true eq 3 then begin
		display_image = congrid(data.image, data.draw_dims[0], data.draw_dims[1], 3)
	endif else display_image = congrid(data.image, data.draw_dims[0], data.draw_dims[1])
	if data.true gt 0 then begin
		device, decomposed=1
		tv, display_image, true=data.true
	endif else begin
		device, decomposed=0
		tv, display_image
	endelse
	device, decomposed=1

	if data.points.n gt 0 then begin
		plot, [-1],[-1], /noerase, /nodata, xr=[-0.5,data.dims[0]-0.5], yr=[-0.5,data.dims[1]-0.5], xst=5, yst=5, pos=[0,0,1,1], color=data.color
		if data.points.n ge 1 then oplot, [(*data.points.x)[0]], [(*data.points.y)[0]], ps=5, syms=0.5, thick=2, color=data.color
		if data.points.n ge 2 then oplot, [(*data.points.x)[1:data.points.n-1]], [(*data.points.y)[1:data.points.n-1]], ps=4, syms=0.5, thick=2, color=data.color
		if n_elements(*data.curve.x) gt 1 then oplot, *data.curve.x, *data.curve.y, thick=1, color=data.color
	endif
end


pro draw_curve_spline, data
	if data.points.n ge 3 then begin
		t_points = dindgen(data.points.n) / (data.points.n - 1)
		dx = (*data.points.x)[1:data.points.n - 1] - $
			(*data.points.x)[0:data.points.n - 2]
		dy = (*data.points.y)[1:data.points.n - 1] - $
			(*data.points.y)[0:data.points.n - 2]
		control_length = total(sqrt(dx^2 + dy^2), /double)
		resolution = (data.curve.step / 5D) < 0.1D
		dense_n = long(ceil(control_length / resolution)) + 1L
		dense_n = (dense_n > (data.points.n * 20L) > 200L) < 1000000L
		dense_t = dindgen(dense_n) / (dense_n - 1)
		dense_x = spline(t_points, *data.points.x, dense_t)
		dense_y = spline(t_points, *data.points.y, dense_t)
		dx = dense_x[1:dense_n - 1] - dense_x[0:dense_n - 2]
		dy = dense_y[1:dense_n - 1] - dense_y[0:dense_n - 2]
		curve_length = [0D, total(sqrt(dx^2 + dy^2), /cumulative, /double)]
		total_length = curve_length[dense_n - 1]

		if total_length gt 0 then begin
			valid = [0L, where(curve_length[1:dense_n - 1] gt $
				curve_length[0:dense_n - 2], n_valid) + 1L]
			n_intervals = long(round(total_length / data.curve.step)) > 1L
			target_length = dindgen(n_intervals + 1L) * $
				total_length / n_intervals
			*data.curve.t = interpol(dense_t[valid], curve_length[valid], $
				target_length)
			*data.curve.x = spline(t_points, *data.points.x, *data.curve.t)
			*data.curve.y = spline(t_points, *data.points.y, *data.curve.t)
		endif else begin
			*data.curve.x = (*data.points.x)[0]
			*data.curve.y = (*data.points.y)[0]
			*data.curve.t = 0D
		endelse
	endif else begin
		*data.curve.x = -1
		*data.curve.y = -1
		*data.curve.t = -1
	endelse
end


pro draw_curve_set_step, mainwin, valid=valid, quiet=quiet
	widget_control, mainwin, get_uvalue=data
	step_id = widget_info(mainwin, find_by_uname='step')
	widget_control, step_id, get_value=text
	text = strtrim(text[0], 2)
	pattern = '^[+]?(0*[.]?[0-9]+|[0-9]+[.][0-9]*)' + $
		'([eEdD][+-]?[0-9]+)?$'
	valid = stregex(text, pattern, /boolean)
	if valid then begin
		new_step = double(text)
		valid = finite(new_step) and new_step gt 0
	endif

	if not valid then begin
		if not keyword_set(quiet) then begin
			print, 'Step must be a positive number.'
			widget_control, step_id, $
				set_value=draw_curve_number(data.curve.step)
		endif
		return
	endif

	if new_step ne data.curve.step then begin
		data.curve.step = new_step
		draw_curve_spline, data
		widget_control, mainwin, set_uvalue=data, /no_copy
		draw_curve_draw, mainwin
	endif
end


pro draw_curve_track, event
	widget_control, event.top, get_uvalue=data
	if (event.press ne 1) and (event.release ne 1) and (data.points.move eq -1) and (event.press ne 4) then return
	raw_x = (event.x + 0.5D) * data.dims[0] / data.draw_dims[0] - 0.5D
	raw_y = (event.y + 0.5D) * data.dims[1] / data.draw_dims[1] - 0.5D
	inside = raw_x ge -0.5D and raw_x le data.dims[0] - 0.5D and $
		raw_y ge -0.5D and raw_y le data.dims[1] - 0.5D
	if not inside and data.points.move eq -1 then return
	cur = {x:0D > raw_x < (data.dims[0] - 1D), $
		y:0D > raw_y < (data.dims[1] - 1D)}

	if event.press eq 1 then begin
		if data.points.n gt 0 then begin
			points_dist = ((*data.points.x - cur.x) * $
				data.draw_dims[0] / data.dims[0])^2 + $
				((*data.points.y - cur.y) * $
				data.draw_dims[1] / data.dims[1])^2
			min_dist = min(points_dist, min_ind)
			if min_dist le data.radius^2 then $
				data.points.move = min_ind else data.points.move = -1
		endif
		if data.points.move eq -1 then begin
			if data.points.n eq 0 then begin
				data.points.x = ptr_new([cur.x])
				data.points.y = ptr_new([cur.y])
				data.points.move = 0
			endif else begin
				if data.points.n ge 3 then begin
					curve_dist = ((*data.curve.x - cur.x) * $
						data.draw_dims[0] / data.dims[0])^2 + $
						((*data.curve.y - cur.y) * $
						data.draw_dims[1] / data.dims[1])^2
					min_dist = min(curve_dist, min_ind)
					insert_flag = min_dist le data.radius^2
				endif else insert_flag = 0b
				if insert_flag then begin
					point_position = (*data.curve.t)[min_ind] * $
						(data.points.n - 1)
					ind_before = floor(point_position)
					ind_after = ceil(point_position)
					*data.points.x = [(*data.points.x)[0:ind_before], cur.x, (*data.points.x)[ind_after:*]]
					*data.points.y = [(*data.points.y)[0:ind_before], cur.y, (*data.points.y)[ind_after:*]]
					data.points.move = ind_after
				endif else begin
					*data.points.x = [*data.points.x, cur.x]
					*data.points.y = [*data.points.y, cur.y]
					data.points.move = data.points.n
				endelse
			endelse
			data.points.n+= 1
		endif
	endif

	if data.points.move ne -1 then begin
		(*data.points.x)[data.points.move] = cur.x
		(*data.points.y)[data.points.move] = cur.y
	endif
	if event.release eq 1 then data.points.move = -1

	if event.press eq 4 then begin
		if data.points.n gt 0 then begin
			dist = ((*data.points.x - cur.x) * $
				data.draw_dims[0] / data.dims[0])^2 + $
				((*data.points.y - cur.y) * $
				data.draw_dims[1] / data.dims[1])^2
			min_dist = min(dist, min_ind)
			if min_dist le data.radius^2 then begin
				leave_ind = where(lindgen(data.points.n) ne min_ind, n_leave)
				if n_leave eq 0 then begin
					data.points.n = 0
					ptr_free, data.points.x, data.points.y
				endif else begin
					data.points.n-= 1
					*data.points.x = (*data.points.x)[leave_ind]
					*data.points.y = (*data.points.y)[leave_ind]
				endelse
			endif
		endif
	endif

	draw_curve_spline, data
	widget_control, event.top, set_uvalue=data, /no_copy
	draw_curve_draw, event.top
end



pro draw_curve_zoom, mainwin, in=in, out=out
	widget_control, mainwin, get_uvalue=data

	if keyword_set(in) then begin
		data.zoom*= 2.
	endif
	if keyword_set(out) then begin
		if data.zoom / 2D ge data.min_zoom then $
			data.zoom /= 2.
	endif
	data.draw_dims = long(round(data.dims * data.zoom)) > 1L
	widget_control, widget_info(mainwin, find_by_uname='zoom_out'), $
		sensitive=data.zoom / 2D ge data.min_zoom

	widget_control, widget_info(mainwin, find_by_uname='zoom_label'), $
		set_value=string(round(data.zoom*100), form='(i0,"%")')

	canvsd_id = widget_info(mainwin, find_by_uname='canvas')
	cansize = widget_info(canvsd_id, /geometry)
	winsize = widget_info(mainwin, /geometry)
	scrsize = get_screen_size()
	maxcanv = [scrsize[0] - winsize.xsize + cansize.xsize, scrsize[1] - winsize.ysize + cansize.ysize] - [50,100]

	widget_control, canvsd_id, draw_xsize=data.draw_dims[0], $
		draw_ysize=data.draw_dims[1], $
		xsize=data.draw_dims[0] < maxcanv[0], $
		ysize=data.draw_dims[1] < maxcanv[1]
	widget_control, mainwin, set_uvalue=data, /no_copy
	winsize = widget_info(mainwin, /geometry)
	widget_control, mainwin, xoffs=(scrsize[0]-winsize.xsize)/2, yoffs=(scrsize[1]-winsize.ysize)/2-50
	draw_curve_draw, mainwin
end



pro draw_curve_clear, mainwin
	widget_control, mainwin, get_uvalue=data

	data.points.n = 0
	ptr_free, data.points.x, data.points.y
	*data.curve.x = -1
	*data.curve.y = -1
	data.points.move = -1
	*data.curve.t = -1

	widget_control, mainwin, set_uvalue=data, /no_copy
	draw_curve_draw, mainwin
end
