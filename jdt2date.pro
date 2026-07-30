; Convert Julian dates to text dates.
; dates = jdt2date(jdt [, delim=string, ddelim=string, tdelim=string,
;   sdigits=n, /nosec, /notime, /nodate])
; sdigits is the number of digits after the decimal point in seconds.

function jdt2date, jdt, delim=delim, ddelim=ddelim, tdelim=tdelim, $
		sdigits=sdigits, nosec=nosec, notime=notime, nodate=nodate
	if ~keyword_set(delim) then delim = ' '
	if ~keyword_set(ddelim) then ddelim = '/'
	if ~keyword_set(tdelim) then tdelim = ':'
	if ~keyword_set(sdigits) then sdigits = 0

	if sdigits gt 0 then begin
		sec_format = string(sdigits + 3, sdigits, $
			format='("(f0",i0,".",i0,")")')
	endif else sec_format = '(i02)'

	caldat, jdt, months, days, years, hours, minutes, seconds

	years = string(years, format='(i04)')
	months = string(months, format='(i02)')
	days = string(days, format='(i02)')
	hours = string(hours, format='(i02)')
	minutes = string(minutes, format='(i02)')
	seconds = string(seconds, format=sec_format)

	if keyword_set(nodate) then begin
		if keyword_set(nosec) then return, hours + tdelim + minutes
		return, hours + tdelim + minutes + tdelim + seconds
	endif

	if keyword_set(notime) then return, years + ddelim + months + ddelim + days
	if keyword_set(nosec) then return, years + ddelim + months + ddelim + $
		days + delim + hours + tdelim + minutes

	return, years + ddelim + months + ddelim + days + delim + hours + $
		tdelim + minutes + tdelim + seconds
end
