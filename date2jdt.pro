; Convert text dates to Julian dates.
; jdt = date2jdt(dates [, template=template])
; template marks the year, month, day, hour, minute, and second fields with
; Y, M, D, h, m, and s respectively.

function date2jdt, dates, template=template
	if ~keyword_set(template) then template = 'YYYY-MM-DD_hh-mm-sssss'

	pos = stregex(template, $
		'(Y+)[^YMDhms]*(M+)[^YMDhms]*(D+)[^YMDhms]*(h+)[^YMDhms]*(m+)[^YMDhms]*(s+)', $
		len=len, /subexpr)
	if pos[0] eq -1 then message, 'Incorrect date template.'

	years = fix(strmid(dates, pos[1], len[1]))
	months = fix(strmid(dates, pos[2], len[2]))
	days = fix(strmid(dates, pos[3], len[3]))
	hours = fix(strmid(dates, pos[4], len[4]))
	minutes = fix(strmid(dates, pos[5], len[5]))
	seconds = float(strmid(dates, pos[6], len[6]))

	return, julday(months, days, years, hours, minutes, seconds)
end
