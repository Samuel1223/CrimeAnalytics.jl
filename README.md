# CrimeAnalytics.jl

A small, dependency-free Julia toolkit for cleaning and summarising tabular
crime data — a compact, typed reimplementation of the kind of work usually done
with `pandas`/`matplotlib`: load a CSV, clean it, explore it, and score a
prediction.

The package is column-oriented. A table value is a [`Cell`](src/CrimeAnalytics.jl)
(`Int`, `Float64`, `String`, or `missing`) and a dataset is a `Table` (ordered
column names plus a name → column map).

## Pipeline at a glance

| Function | Purpose |
| --- | --- |
| `parse_csv` | Read CSV text into a `Table`, inferring `Int`/`Float64`/`String`/`missing` per field |
| `dropcols` | Remove columns by name |
| `fillmissing` | Replace `missing` in a column with a value |
| `dropmissing` | Drop rows that contain any `missing` |
| `filtereq` | Keep rows where a column equals a value |
| `value_counts` | Frequency of each distinct value in a column |
| `top_n` | Top-`n` values of one column within each group of another |
| `count_by_hour` | Per-hour (0–23) row histogram |
| `bounding_box` | Keep rows inside a 2-D coordinate box |
| `accuracy` | Fraction of matching predictions |

## Example

```julia
using CrimeAnalytics

raw = """
YEAR,HOUR,DISTRICT,STREET,SHOOTING,Lat,Long
2017,13,B2,WASHINGTON ST,,42.33,-71.08
2017,9,A1,TREMONT ST,Y,42.35,-71.06
2016,9,A1,TREMONT ST,,42.36,-71.05
"""

t = parse_csv(raw)
t = filtereq(t, "YEAR", 2017)          # only 2017 incidents
t = fillmissing(t, "SHOOTING", "N")    # blanks mean "no shooting"
value_counts(t, "DISTRICT")            # => ["A1" => 1, "B2" => 1]
count_by_hour(t, "HOUR")               # 24-element histogram
```

## Tests

```julia
julia --project=. test/runtests.jl
```
