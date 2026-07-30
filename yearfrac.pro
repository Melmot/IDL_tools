; Convert Julian dates to decimal years.
; result = yearfrac(jdt)
; The fractional part accounts for the actual length of each calendar year.

function yearfrac, jdt
	caldat, jdt, month, day, year
	year_start = julday(1, 1, year, 0)
	next_year_start = julday(1, 1, year + 1, 0)

	return, year + (jdt - year_start) / (next_year_start - year_start)
end
