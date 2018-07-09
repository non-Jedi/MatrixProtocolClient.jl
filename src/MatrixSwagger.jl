module MatrixSwagger

"""
    typename(path::AbstractString)::Symbol

Returns a name for e.g. "/_matrix/client/r0/my/fun/path" like "MyFunPath".
"""
function typename(path::AbstractString)::Symbol
    splitpath = split(path, "/"; keep=false)
    Symbol(join(titlecase.(splitpath[4:end]), ""))
end

end#module
