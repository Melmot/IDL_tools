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

### Statistics and fitting

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

### Array utilities

#### `arr_match`

Returns pairs of flat indices containing equal values in two arrays. Duplicate
values produce all matching pairs; `-1` is returned when there are no matches.

```idl
matches = arr_match(array1, array2)
```

#### `sign`

Returns `-1`, `0`, or `1` according to the sign of each scalar or array value.

```idl
directions = sign(values)
```

### Numerical analysis

#### `linearize`

Finds the interval with the most precisely determined non-zero linear slope
and returns its linear-fit parameters.

```idl
parameters = linearize(values, x=x, range=range, fit=fit)
```

`range` specifies the search limits on input and returns the selected interval.
`minlen` sets its minimum length, `err` supplies point uncertainties, and
`fit` returns the fitted values.

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

### Files and data exchange

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

#### `write_csv`

Writes a two-dimensional array to a delimited text file.

```idl
write_csv, 'table.csv', data
write_csv, 'table.tsv', data, headers=headers, delimiter=string(9b)
```

The default delimiter is a semicolon.

#### `hdr_struct`

Converts a string-array FITS header to an IDL structure. `descriptions`
returns the comments associated with its fields; `comments` and `history`
return the corresponding FITS cards.

```idl
header_struct = hdr_struct(header, descriptions=descriptions)
```

### Image alignment

#### `phaseshift`

Shifts a two-dimensional image by a fractional number of pixels using the
Fourier shift theorem.

```idl
shifted = phaseshift(image, dx, dy)
```

The result is complex. Use `real_part` or `abs` when a real-valued image is
required. The original idea was proposed by Artem Ulyanov.

#### `findshift`

Finds the periodic displacement of `image1` relative to `image2` and returns
it with subpixel precision.

```idl
shift = findshift(image1, image2, corr=correlation, intshft=integer_shift)
```

`corr` returns the correlation map and `intshft` the shift before subpixel
refinement.

### Interactive image tools

#### `plot_clicker`

Digitizes points from an image file. The first, required step is calibration:
press the left mouse button at one corner of the plot frame, drag to the
opposite corner, and release. The corner order does not matter. After that,
left-click to add a point. To move an existing point or a frame corner, press
the left button near it, drag, and release. Right-click near a point to delete
it. Close the window to finish and return the selected coordinates.

```idl
plot_clicker, 'plot.png', [xmin, xmax], [ymin, ymax], x, y
```

The second and third arguments give the axis ranges. A previous calibration
can be reused with `box=box`, skipping the first step. `/xlog` and `/ylog`
select logarithmic axes. `zoom=2` requests twofold enlargement, limited by the
screen size. `radius=8` sets how close, in screen pixels, the cursor must be to
select an existing point or frame corner. `color` sets the packed RGB color of
the frame and points and defaults to red.

#### `draw_curve`

Interactively draws a spline on a two-dimensional or RGB array and returns its
pixel coordinates. RGB arrays may use any of the standard IDL channel layouts.

```idl
image = bytscl(data)
curve = draw_curve(image, step=0.5, zoom=2, radius=8, color='00ffff'xl)

values = interpolate(data, curve.x, curve.y, cubic=-0.5)
dx = curve.x[1:*] - curve.x
dy = curve.y[1:*] - curve.y
distance = [0D, total(sqrt(dx^2 + dy^2), /cumulative, /double)]
plot, distance, values
```

Left-click to add a control point. Left-click near an existing point and drag
to move it; left-click near the curve to insert a point at that position.
Right-click near a control point to remove it. The spline appears after the
third point is added. The `+` and `-` buttons change the display scale, the
`Step` field changes the output spacing, `Clear` removes all points, and
`Done` finishes.

The returned points are distributed uniformly along the curve. `step` sets
their target spacing in input-array elements and defaults to `1`.
`zoom` sets the initial display scale and defaults to `1`. The `+` and `-`
buttons change the current scale by a factor of two. `radius` sets the selection
distance for existing control points and the curve in screen pixels and defaults to `5`.
`color` sets the packed RGB color of the spline and control points and defaults
to yellow. Two-dimensional images use the active IDL color table.

### Image processing and transforms

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

Replaces bright temporal spikes in a three-dimensional image cube. The cube
is modified in place.

```idl
despike_cube, cube, threshold=1.1, width=2
```

Each frame is compared with the temporal median of `width` neighboring frames
on either side. Pixels exceeding it by the factor `threshold` are replaced.

#### `solar2polar` and `polar2solar`

Convert solar images between Cartesian and rectangular radius-angle forms.
Both functions use the image geometry stored in a FITS header.

```idl
polar = solar2polar(image, header, /interp)
image = polar2solar(polar, header, /interp)
```

For `solar2polar`, radial limits may be given in solar radii with `rmin` and
`rmax`, or as heights in kilometres with `hmin` and `hmax`. `polar2solar`
uses `rmin` or `hmin` for the first row of the polar map. Angular positions
are measured in degrees clockwise from solar north; `fires` and `hres` set
the angular and radial steps.

### Strings

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

### Structures

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

### Widgets

#### `widget_children`

Returns all descendants of an IDL widget, or `0` when the widget has no
children.

```idl
descendants = widget_children(top_widget)
```
