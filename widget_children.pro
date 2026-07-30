; Return all descendants of an IDL widget.
; result = widget_children(widget_id)
; Direct children are followed recursively; 0 is returned if there are none.

function widget_children, widget_id
	n_children = widget_info(widget_id, /n_children)
	if n_children eq 0 then return, 0L

	children = widget_info(widget_id, /all_children)
	descendants = children
	for i = 0L, n_children - 1 do begin
		grandchildren = widget_children(children[i])
		if n_elements(grandchildren) gt 1 or grandchildren[0] ne 0 then $
			descendants = [descendants, grandchildren]
	endfor

	return, descendants
end
