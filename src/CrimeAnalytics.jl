"""
    CrimeAnalytics

A small, dependency-free toolkit for cleaning and summarising tabular crime
data, modelled on a typical "load → clean → explore → score" analysis pipeline.

Table values are represented by the [`Cell`](@ref) union and tables by the
column-oriented [`Table`](@ref) type. The cleaning/summary operations
([`parse_csv`](@ref), [`dropcols`](@ref), [`value_counts`](@ref),
[`bounding_box`](@ref), …) are currently unimplemented and throw
`"not implemented"` until filled in.
"""
module CrimeAnalytics

export Cell, Table,
    nrows, ncols, colnames, getcolumn,
    parse_csv, dropcols, fillmissing, dropmissing, filtereq,
    value_counts, top_n, count_by_hour, bounding_box, accuracy

"""
    Cell

A single table value: an `Int`, a `Float64`, a `String`, or `missing`.
"""
const Cell = Union{Int,Float64,String,Missing}

"""
    Table(names, cols)

Column-oriented table. `names` is the ordered vector of column names and `cols`
maps each name to its column vector. Every column has the same length, which is
the number of rows of the table.
"""
struct Table
    names::Vector{String}
    cols::Dict{String,Vector{Cell}}
end

# --------------------------------------------------------------------------
# Accessors (provided)
# --------------------------------------------------------------------------

"""
    nrows(t) -> Int

Number of rows in `t` (0 when the table has no columns).
"""
nrows(t::Table)::Int = isempty(t.names) ? 0 : length(t.cols[t.names[1]])

"""
    ncols(t) -> Int

Number of columns in `t`.
"""
ncols(t::Table)::Int = length(t.names)

"""
    colnames(t) -> Vector{String}

The column names of `t`, in order.
"""
colnames(t::Table)::Vector{String} = copy(t.names)

"""
    getcolumn(t, name) -> Vector{Cell}

The column vector stored under `name`. Throws `KeyError` if the column is
absent.
"""
function getcolumn(t::Table, name::AbstractString)::Vector{Cell}
    c = String(name)
    haskey(t.cols, c) || throw(KeyError(c))
    return t.cols[c]
end

# --------------------------------------------------------------------------
# Operations (to be implemented)
# --------------------------------------------------------------------------

"""
    parse_csv(text) -> Table

Parse CSV `text` into a [`Table`](@ref). The first non-empty line is the
header; the remaining non-empty lines are data rows. Fields are split on commas
(there is no quoting/escaping). A carriage return (`\\r`) is stripped from line
ends so that CRLF input is accepted, and fully empty lines are skipped.

Each field is converted to a [`Cell`](@ref): an empty field becomes `missing`;
a field that parses as an integer becomes an `Int`; otherwise a field that
parses as a real number becomes a `Float64`; anything else is kept as a
`String`.

Throws `ArgumentError` if the text has no header, if the header contains a
duplicate column name, or if a data row does not have exactly as many fields as
the header.
"""
function parse_csv(text::AbstractString)::Table
    error("not implemented")
end

"""
    dropcols(t, cols) -> Table

Return a new table with the columns named in `cols` removed; the remaining
columns keep their original order. Throws `KeyError` if any name in `cols` is
not a column of `t`.
"""
function dropcols(t::Table, cols::AbstractVector)::Table
    error("not implemented")
end

"""
    fillmissing(t, col, value) -> Table

Return a new table in which every `missing` entry of column `col` has been
replaced by `value`; all other columns and values are unchanged. Throws
`KeyError` if `col` is not a column of `t`.
"""
function fillmissing(t::Table, col::AbstractString, value)::Table
    error("not implemented")
end

"""
    dropmissing(t) -> Table

Return a new table containing only the rows that have no `missing` value in any
column. Column order is preserved.
"""
function dropmissing(t::Table)::Table
    error("not implemented")
end

"""
    filtereq(t, col, value) -> Table

Return a new table with only the rows where column `col` equals `value`. A
`missing` cell never equals `value`, so such rows are excluded. Throws
`KeyError` if `col` is not a column of `t`.
"""
function filtereq(t::Table, col::AbstractString, value)::Table
    error("not implemented")
end

"""
    value_counts(t, col) -> Vector{Pair{Cell,Int}}

Count the occurrences of each distinct non-`missing` value in column `col`.
Returns a vector of `value => count` pairs sorted by `count` descending; pairs
with the same count are ordered by `value` ascending. `missing` values are not
counted. Throws `KeyError` if `col` is not a column of `t`.
"""
function value_counts(t::Table, col::AbstractString)::Vector{Pair{Cell,Int}}
    error("not implemented")
end

"""
    top_n(t, group_col, value_col, n) -> Vector{Pair{Cell,Vector{Pair{Cell,Int}}}}

For each distinct non-`missing` value `g` of `group_col`, compute the
[`value_counts`](@ref) of `value_col` over the rows where `group_col == g` and
keep at most the first `n` of them. The result pairs each group `g` with its
top-`n` `value => count` vector, and the groups are ordered by `g` ascending.

`n` must be a positive integer (`ArgumentError` otherwise). Throws `KeyError`
if either column is absent.
"""
function top_n(t::Table, group_col::AbstractString, value_col::AbstractString, n::Integer)
    error("not implemented")
end

"""
    count_by_hour(t, col) -> Vector{Int}

Return a length-24 vector whose element at index `h + 1` is the number of rows
whose `col` value is exactly the integer `h`, for `h` in `0:23`. Values that
are missing, non-integer, or outside `0:23` are ignored. Throws `KeyError` if
`col` is not a column of `t`.
"""
function count_by_hour(t::Table, col::AbstractString)::Vector{Int}
    error("not implemented")
end

"""
    bounding_box(t, xcol, ycol, xmin, xmax, ymin, ymax) -> Table

Return a new table with only the rows whose `xcol` value is strictly between
`xmin` and `xmax` *and* whose `ycol` value is strictly between `ymin` and
`ymax` (that is, `xmin < x < xmax` and `ymin < y < ymax`). Rows whose value in
either column is `missing` or non-numeric are excluded. Throws `KeyError` if
either column is absent.
"""
function bounding_box(t::Table, xcol::AbstractString, ycol::AbstractString,
                      xmin::Real, xmax::Real, ymin::Real, ymax::Real)::Table
    error("not implemented")
end

"""
    accuracy(predicted, actual) -> Float64

The fraction of positions at which `predicted` and `actual` are equal. The two
vectors must have the same, non-zero length. Throws `ArgumentError` if the
lengths differ or if the inputs are empty.
"""
function accuracy(predicted::AbstractVector, actual::AbstractVector)::Float64
    error("not implemented")
end

end # module CrimeAnalytics
