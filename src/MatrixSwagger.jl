module MatrixSwagger

"""
    typename(path::AbstractString)::Symbol

Returns a name for e.g. "/_matrix/client/r0/my/fun/path" like "MyFunPath".
"""
function typename(path::AbstractString)::Symbol
    splitpath = split(path, "/"; keep=false)
    Symbol(join(titlecase.(splitpath[4:end]), ""))
end

# Need convenience function to turn types into symbols/expressions for `insertfield!`
"Inserts field `a` of type `T` into a type expression."
function insertfield!(ex::Expr, a::Symbol, T::Union{Symbol,Expr})
    if ex.head == :type
        push!(ex.args[end].args, :($a::$T))
    else
        throw(ArgumentError("Can only add field to concrete type expression"))
    end#if
end#function

"""
    juliatype(topleveltype::String[, nestedtypes...])::Type

Return corresponding Julia type for a swagger type string.

Throws ArgumentError for unknown types.
"""
function juliatype(s::AbstractString, args...)::Union{Symbol,Expr}
    if s == "string"
        :String
    elseif s == "array" && !isempty(args)
        :(Vector{$(juliatype(args...))})
    elseif s == "object"
        :(Dict{String,Any})
    elseif s == "boolean"
        :Bool
    elseif s == "file"
        :IOBuffer
    elseif s == "integer"
        :Int64
    elseif s == "number"
        :Float64
    else
        throw(ArgumentError("No known corresponding Julia type"))
    end#if
end#function

end#module
