module Swagger

"""
    typename(path::AbstractString)::Symbol

Returns a name for e.g. "/_matrix/client/r0/my/fun/path" like "MyFunPath".
"""
function typename(path::AbstractString)::Symbol
    splitpath = split(path, "/"; keepempty=false)
    Symbol(join(titlecase.(splitpath[4:end]), ""))
end

# Need convenience function to turn types into symbols/expressions for `insertfield!`
"Inserts field `a` of type `T` into a type expression."
function insertfield!(ex::Expr, a::Symbol, T::Union{Symbol,Expr})
    if ex.head == :struct
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

"A single matrix endpoint."
abstract type MatrixEndpoint end

"The body in any HTTP request or response."
abstract type HTTPBody end

"The body in an HTTP request to endpoint `T`."
abstract type RequestBody{T<:MatrixEndpoint} <: HTTPBody end
"The body from an HTTP response to endpoint T with status code `Status`."
abstract type ResponseBody{T<:MatrixEndpoint,Status} <: HTTPBody end

"""
    path(e::MatrixEndpoint)::Vector{<:AbstractString}

Returns the path to an endpoint.

Each element of the string represents part of the path. For a normal HTTP
endpoint, they should be joined together with `/` characters and appended to the
base URL of the homeserver.
"""
path(::MatrixEndpoint) = throw(ArgumentError("Unknown endpoint path"))

"""
    createpath(path::AbstractString)::Expr

Returns an expression to add a method to `path` for an endpoint.
"""
function createpath(path::AbstractString)::Expr
    endpoint = typename(path)
    :(path(::$endpoint) = $(split(path, "/"; keepempty=false)))
end#function

end#module
