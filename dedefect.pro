; Replace isolated bright pixels with a locally smoothed value.
; dedefect, data [, level=level, width=width]
; data is modified in place. level defaults to 3 and width defaults to 5.
; Negative input values are set to zero.

pro dedefect, data, level=level, width=width
	if n_elements(level) eq 0 then level = 3.0
	if n_elements(width) eq 0 then width = 5
	if level le 0 then message, 'LEVEL must be positive.'
	if width lt 1 then message, 'WIDTH must be positive.'

	data >= 0
	smoothed = smooth(data, width, /edge_truncate)
	defect_indices = where(data ge level * smoothed, n_defects)
	if n_defects gt 0 then data[defect_indices] = smoothed[defect_indices]
end
