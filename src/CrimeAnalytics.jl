"""
    CrimeAnalytics

A small, dependency-free toolkit for cleaning and summarising tabular crime
data, modelled on a typical "load → clean → explore → score" analysis pipeline.

Table values are represented by the [`Cell`](@ref) union and tables by the
column-oriented [`Table`](@ref) type.
"""
module CrimeAnalytics

export Cell, Table,
    nrows, ncols, colnames, getcolumn,
    parse_csv, dropcols, fillmissing, dropmissing, filtereq,
    value_counts, top_n, count_by_hour, bounding_box, accuracy, inner_join

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
# Accessors
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
# Internal helpers
# --------------------------------------------------------------------------

_isnum(x)::Bool = x isa Int || x isa Float64
_lt(a, b)::Bool = a < b

function _parse_cell(field::AbstractString)::Cell
    isempty(field) && return missing
    iv = tryparse(Int, field)
    iv === nothing || return iv
    fv = tryparse(Float64, field)
    fv === nothing || return fv
    return String(field)
end

# value => count over non-missing values, sorted by count desc then value asc.
function _counts_sorted(vals)::Vector{Pair{Cell,Int}}
    counts = Dict{Cell,Int}()
    for x in vals
        ismissing(x) && continue
        counts[x] = get(counts, x, 0) + 1
    end
    pairs = collect(counts)
    sort!(pairs, lt = (a, b) -> a.second > b.second ||
                                (a.second == b.second && !_lt(a.first, b.first)))
    return pairs
end

# Build a new table containing only the rows at positions `idx`.
function _select(t::Table, idx::Vector{Int})::Table
    newcols = Dict{String,Vector{Cell}}(n => t.cols[n][idx] for n in t.names)
    return Table(copy(t.names), newcols)
end

# --------------------------------------------------------------------------
# Operations
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
    raw = split(replace(text, '\r' => ""), '\n')
    lines = String[]
    for ln in raw
        isempty(ln) || push!(lines, String(ln))
    end
    isempty(lines) && throw(ArgumentError("CSV text has no header"))
    header = String.(split(lines[1], ','))
    nc = length(header)
    cols = Dict{String,Vector{Cell}}(h => Cell[] for h in header)
    for r in 2:length(lines)
        fields = split(lines[r], ',')
        length(fields) == nc ||
            throw(ArgumentError("row $(r - 1) has $(length(fields)) fields, expected $nc"))
        for (j, f) in enumerate(fields)
            push!(cols[header[j]], _parse_cell(f))
        end
    end
    return Table(header, cols)
end

"""
    dropcols(t, cols) -> Table

Return a new table with the columns named in `cols` removed; the remaining
columns keep their original order. Throws `KeyError` if any name in `cols` is
not a column of `t`.
"""
function dropcols(t::Table, cols::AbstractVector)::Table
    drop = Set(String(c) for c in cols)
    for c in drop
        haskey(t.cols, c) || throw(KeyError(c))
    end
    newnames = [n for n in t.names if !(n in drop)]
    newcols = Dict{String,Vector{Cell}}(n => copy(t.cols[n]) for n in newnames)
    return Table(newnames, newcols)
end

"""
    fillmissing(t, col, value) -> Table

Return a new table in which every `missing` entry of column `col` has been
replaced by `value`; all other columns and values are unchanged. Throws
`KeyError` if `col` is not a column of `t`.
"""
function fillmissing(t::Table, col::AbstractString, value)::Table
    c = String(col)
    haskey(t.cols, c) || throw(KeyError(c))
    newcols = Dict{String,Vector{Cell}}(n => copy(t.cols[n]) for n in t.names)
    newcols[c] = Cell[ismissing(x) ? x : value for x in t.cols[c]]
    return Table(copy(t.names), newcols)
end

"""
    dropmissing(t) -> Table

Return a new table containing only the rows that have no `missing` value in any
column. Column order is preserved.
"""
function dropmissing(t::Table)::Table
    keep = Int[i for i in 1:nrows(t) if !any(ismissing(t.cols[n][i]) for n in t.names)]
    return _select(t, keep)
end

"""
    filtereq(t, col, value) -> Table

Return a new table with only the rows where column `col` equals `value`. A
`missing` cell never equals `value`, so such rows are excluded. Throws
`KeyError` if `col` is not a column of `t`.
"""
function filtereq(t::Table, col::AbstractString, value)::Table
    c = String(col)
    haskey(t.cols, c) || throw(KeyError(c))
    column = t.cols[c]
    keep = Int[i for i in 1:nrows(t) if !ismissing(column[i]) && isequal(column[i], value)]
    return _select(t, keep)
end

"""
    value_counts(t, col) -> Vector{Pair{Cell,Int}}

Count the occurrences of each distinct non-`missing` value in column `col`.
Returns a vector of `value => count` pairs sorted by `count` descending; pairs
with the same count are ordered by `value` ascending. `missing` values are not
counted. Throws `KeyError` if `col` is not a column of `t`.
"""
function value_counts(t::Table, col::AbstractString)::Vector{Pair{Cell,Int}}
    c = String(col)
    haskey(t.cols, c) || throw(KeyError(c))
    return _counts_sorted(t.cols[c])
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
    gc = String(group_col)
    vc = String(value_col)
    haskey(t.cols, gc) || throw(KeyError(gc))
    haskey(t.cols, vc) || throw(KeyError(vc))
    n > 0 || throw(ArgumentError("n must be a positive integer"))
    gcol = t.cols[gc]
    vcol = t.cols[vc]
    groups = Cell[]
    seen = Set{Cell}()
    for g in gcol
        ismissing(g) && continue
        if !(g in seen)
            push!(seen, g)
            push!(groups, g)
        end
    end
    sort!(groups, lt = _lt)
    result = Pair{Cell,Vector{Pair{Cell,Int}}}[]
    for g in groups
        vals = Cell[vcol[i] for i in 1:length(gcol) if !ismissing(gcol[i]) && isequal(gcol[i], g)]
        counts = _counts_sorted(vals)
        topk = counts[1:min(n, length(counts))]
        push!(result, g => topk)
    end
    return result
end

"""
    count_by_hour(t, col) -> Vector{Int}

Return a length-24 vector whose element at index `h + 1` is the number of rows
whose `col` value is exactly the integer `h`, for `h` in `0:23`. Values that
are missing, non-integer, or outside `0:23` are ignored. Throws `KeyError` if
`col` is not a column of `t`.
"""
function count_by_hour(t::Table, col::AbstractString)::Vector{Int}
    c = String(col)
    haskey(t.cols, c) || throw(KeyError(c))
    out = zeros(Int, 24)
    for x in t.cols[c]
        if x isa Int && 0 <= x < 23
            out[x + 1] += 1
        end
    end
    return out
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
    xc = String(xcol)
    yc = String(ycol)
    haskey(t.cols, xc) || throw(KeyError(xc))
    haskey(t.cols, yc) || throw(KeyError(yc))
    xv = t.cols[xc]
    yv = t.cols[yc]
    keep = Int[]
    for i in 1:nrows(t)
        x = xv[i]
        y = yv[i]
        if _isnum(x) && _isnum(y) && xmin <= x < xmax && ymin <= y < ymax
            push!(keep, i)
        end
    end
    return _select(t, keep)
end

"""
    accuracy(predicted, actual) -> Float64

The fraction of positions at which `predicted` and `actual` are equal. The two
vectors must have the same, non-zero length. Throws `ArgumentError` if the
lengths differ or if the inputs are empty.
"""
function accuracy(predicted::AbstractVector, actual::AbstractVector)::Float64
    length(predicted) == length(actual) ||
        throw(ArgumentError("predicted and actual must have the same length"))
    correct = count(i -> isequal(predicted[i], actual[i]), eachindex(predicted))
    return correct / length(predicted)
end

"""
    inner_join(left, right, key) -> Table

Inner-join `left` and `right` on the shared column `key`. For every pair of a
`left` row and a `right` row whose `key` values are equal (by `isequal`) and
non-`missing`, emit one joined row; duplicate keys therefore produce a cartesian
combination. Rows are ordered left-major: iterate `left`'s rows in order, and
for each, its matching `right` rows in order.

Output columns are, in order: `key`, then `left`'s other columns (original
order), then `right`'s other columns (original order). Any `right` column whose
name also occurs in `left` is renamed `"<name>_right"`. A `missing` key never
matches. Throws `KeyError` if `key` is not a column of both tables.
"""
function inner_join(left::Table, right::Table, key::AbstractString)::Table
    k = String(key)
    haskey(left.cols, k) || throw(KeyError(k))
    haskey(right.cols, k) || throw(KeyError(k))
    leftkey = left.cols[k]
    rightkey = right.cols[k]
    left_other = [n for n in left.names if n != k]
    right_other = [n for n in right.names if n != k]
    left_names = Set(left.names)
    right_out = [n in left_names ? n * "_r" : n for n in right_other]
    outnames = vcat([k], left_other, right_out)
    outcols = Dict{String,Vector{Cell}}(n => Cell[] for n in outnames)
    for i in 1:length(leftkey)
        li = leftkey[i]
        ismissing(li) && continue
        for j in 1:length(rightkey)
            rj = rightkey[j]
            (ismissing(rj) || !isequal(li, rj)) && continue
            push!(outcols[k], li)
            for n in left_other
                push!(outcols[n], left.cols[n][i])
            end
            for (idx, n) in enumerate(right_other)
                push!(outcols[right_out[idx]], right.cols[n][j])
            end
        end
    end
    return Table(outnames, outcols)
end

end # module CrimeAnalytics
