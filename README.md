This is a collection of small, self-contained IDL utilities for miscellaneous tasks.

The code was originally written and used with IDL 6.4, but it is expected to work with newer IDL versions as well.

### Date and time

#### `date2jdt`

Converts date strings to Julian dates.

```idl
jdt = date2jdt('2026-07-30 12:34:56', template='YYYY-MM-DD hh:mm:ss')
```

The default template is `YYYY-MM-DD_hh-mm-sssss`. The letters `Y`, `M`, `D`,
`h`, `m`, and `s` mark the positions of the corresponding fields; separators
may be chosen freely. All six fields must be present.

#### `jdt2date`

Converts Julian dates to date strings.

```idl
date = jdt2date(jdt)
date = jdt2date(jdt, ddelim='-', delim='T', sdigits=3)
```

The keywords `notime`, `nodate`, and `nosec` omit the corresponding parts.
`ddelim`, `delim`, and `tdelim` set the date, date-time, and time separators.
`sdigits` sets the number of digits after the decimal point in seconds; the
default value of `0` produces integer seconds.

#### `yearfrac`

Converts Julian dates to decimal years, taking leap years into account.

```idl
decimal_year = yearfrac(jdt)
```

### Arrays and statistics

#### `percentile`

Calculates one or more percentiles using linear interpolation. Levels are
specified between `0` and `1`.

```idl
median = percentile(data, 0.5)
limits = percentile(data, [0.05, 0.95])
```

#### `gausshist`

Fits a normal cumulative distribution to a sample and returns its fitted mean
and standard deviation. Keywords not handled directly are passed to `curvefit`.

```idl
parameters = gausshist(data, sigma=errors)
```

#### `histerr`

Calculates integer bin counts and, when measurement errors are supplied,
probabilistic bin populations and uncertainties.

```idl
counts = histerr(values, errors=errors, binsize=1, $
  expected=expected, sigma=sigma)
```

#### `arr_match`

Returns pairs of flat indices containing equal values in two arrays.

```idl
matches = arr_match(array1, array2)
```

#### `linearize`

Finds the interval with the most precisely determined non-zero linear slope.

```idl
parameters = linearize(values, x=x, range=range, fit=fit)
```

#### `sign`

Returns `-1`, `0`, or `1` according to the sign of each scalar or array value.

```idl
directions = sign(values)
```

#### `tsmooth`

Applies a centered moving mean on an arbitrary time grid. For every point, the
averaging window extends by `dt` in both time directions.

```idl
smoothed = tsmooth(values, times, dt)
```

#### `parder`

Calculates a partial derivative of a two-dimensional array along the selected
dimension.

```idl
derivative_x = parder(x, array, dim=1)
derivative_y = parder(y, array, dim=2)
```

#### `devcut`

Performs iterative sigma clipping along a selected array dimension. It returns
a validity mask by default, or rejected flat indices with `/index`.

```idl
mask = devcut(data, dim=2, nsigma=3)
indices = devcut(values, nsigma=2.5, /index)
```

`/onlytop` rejects only positive deviations. An initial `mask` may be supplied;
it is updated in place. `std`, `avg`, and `dev` return the final statistics,
while `count` returns the number of iterations.

### Binary arrays

#### `write_bin` and `read_bin`

Write and read IDL arrays in a compact binary format.

```idl
write_bin, 'array.bin', array
array_copy = read_bin('array.bin')
```

The file contains:

1. one byte with the IDL type code;
2. one byte with the number of dimensions;
3. one 32-bit integer per dimension;
4. the array data.

Multi-byte values are stored in little-endian order. This makes the format
suitable for exchanging numeric arrays with Python and other languages.
Dimensions are written in IDL order (the first dimension varies fastest).

For large `byte` or `int` arrays this is usually more compact than an IDL save
file, but it stores no variable names or other metadata.

### Images

#### `phaseshift`

Shifts a two-dimensional image by a fractional number of pixels using the
Fourier shift theorem.

```idl
shifted = phaseshift(image, dx, dy)
```

The result is complex. Use `real_part` or `abs` when a real-valued image is
required. The original idea was proposed by Artem Ulyanov.

#### `findshift`

Finds an arbitrary periodic image shift by FFT correlation and refines it to
subpixel precision.

```idl
shift = findshift(image1, image2, corr=correlation)
```

#### `plot_clicker`

Digitizes points from an image file. Dragging across the plotting area defines
the axis frame, which is updated while dragging; its orientation is detected
automatically. The left mouse button adds points. Dragging near an existing
point moves it; frame corners can be moved in the same way. The right button
deletes a nearby point. Closing the window finishes and returns the selected
coordinates. The frame and selected points are drawn in red. Large images are
reduced to fit the screen.

```idl
plot_clicker, 'plot.png', [xmin, xmax], [ymin, ymax], x, y
```

The second and third arguments give the axis ranges. The calibration can be
reused with `box=box`; `/xlog` and `/ylog` select logarithmic axes, while
`zoom=2` enlarges the image by up to a factor of two. `radius=8` sets the
point selection distance in screen pixels. The resulting window is always
limited by the screen size.

#### `dedefect`

Replaces isolated bright pixels with locally smoothed values. The input array
is modified in place.

```idl
dedefect, image
dedefect, image, level=4, width=7
```

Negative values are set to zero. `level` is the brightness threshold relative
to the smoothed image, and `width` is the smoothing width.

#### `despike_cube`

Replaces bright temporal spikes in a three-dimensional image cube.

```idl
despike_cube, cube, threshold=1.1, width=2
```

#### `solar2polar` and `polar2solar`

Convert solar images between Cartesian and rectangular radius-angle forms.

```idl
polar = solar2polar(image, header, /interp)
image = polar2solar(polar, header, /interp)
```

### Strings and structures

#### `firstcap`

Capitalizes strings. `/all_words` processes every word; adding `/except` keeps
common articles, conjunctions, and short prepositions lowercase.

```idl
title = firstcap(text, /all_words, /except)
```

#### `unstring`

Converts a scalar numeric string to an IDL numeric value, recognizing the
standard integer suffixes. Non-numeric strings are returned unchanged.

```idl
value = unstring('12.5')
count = unstring('100l')
```

#### `write_tag`

Writes a value to a structure tag specified by name or a dotted path. Missing
tags along the path are created as anonymous structures; `/delete` removes a
tag.

```idl
measurement = {result: {value: 0.0}}
write_tag, measurement, 'result.value', 12.5
write_tag, measurement, 'result.error.random', 0.2
write_tag, measurement, 'result.error.systematic', 0.1
write_tag, measurement, 'result.error.systematic', /delete
```

#### `strhelp`

Prints a compact, recursive description of a structure, including tag names,
types, array dimensions, and scalar values.

```idl
strhelp, structure
strhelp, structure, return_tags=tags, return_types=types, $
  return_vals=values, /noprint
```

#### `hdr_struct`

Converts a string-array FITS header to an IDL structure.

```idl
header_struct = hdr_struct(header)
```

### Text files

#### `write_csv`

Writes a two-dimensional array to a delimited text file.

```idl
write_csv, 'table.csv', data
write_csv, 'table.tsv', data, headers=headers, delimiter=string(9b)
```

The default delimiter is a semicolon.

### Widgets

#### `widget_children`

Returns all descendants of an IDL widget, or `0` when the widget has no
children.

```idl
descendants = widget_children(top_widget)
```
