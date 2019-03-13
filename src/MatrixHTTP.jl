# [[file:~/repos/MatrixProtocolClient.jl/README.org::*MatrixHTTP.jl][MatrixHTTP.jl:1]]
module MatrixHTTP

# [[file:~/repos/MatrixProtocolClient.jl/README.org::matrix-type][matrix-type]]
abstract type Endpoint{M} end

abstract type Response{E <: Endpoint} end
# matrix-type ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::identifier-types][identifier-types]]
import JSON

abstract type Identifier end

struct UserIdentifier <: Identifier
	user::String
end#struct

identifier_type(::UserIdentifier) = "m.id.user"

struct ThirdPartyIdentifier <: Identifier
	medium::String
	Address::String
end#struct

identifier_type(::ThirdPartyIdentifier) = "m.id.thirdparty"

struct PhoneIdentifier <: Identifier
	country::String
	phone::String
end#struct

identifier_type(::PhoneIdentifier) = "m.id.phone"

struct IdentifierWrapper{T<:Identifier}
	wrapped::T
	fns::Vector{Symbol}
end

IdentifierWrapper(x::Identifier, syms) = IdentifierWrapper(x, collect(syms))
IdentifierWrapper(x::T) where {T <: Identifier} = IdentifierWrapper(x, fieldnames(T))

JSON.lower(a::Identifier) = IdentifierWrapper(a)

function JSON.show_json(io::JSON.StructuralContext, s::JSON.CommonSerialization,
						x::IdentifierWrapper)
	JSON.begin_object(io)
	JSON.show_pair(io, s, "type", identifer_type(x.wrapped))
	for fn in x.fns
		JSON.show_pair(io, s, fn, getfield(x.wrapped, fn))
	end#for
	JSON.end_object(io)
end#function
# identifier-types ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::matrix-request][matrix-request]]
import HTTP

export request

"""
    request(::Endpoint; layers)::Tuple

Calls a matrix endpoint and returns a tuple for input to `HTTP.request`

`layers` is passed through to `HTTP.stack` as kwargs to specify which layers to
include.
"""
function request(req::Endpoint, body; layers...)::Tuple{
    DataType, String, HTTP.URI, HTTP.Headers, Any
}
    (HTTP.stack(;layers...), method(req), url(req), headers(req), body)
end#function
# matrix-request ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::method][method]]
function method(req::Endpoint{M})::AbstractString where {M}
    if M in (:GET, :HEAD, :POST, :PUT, :DELETE, :TRACE, :OPTIONS, :CONNECT, :PATCH)
        string(M)
    else
        throw(DomainError(M, "Not a valid HTTP method."))
    end#if
end#function
# method ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::url][url]]
import HTTP.URIs: URI

url(req::Endpoint)::URI =
    URI(; scheme="https", host=req.host, path=path(req), query=query(req))
query(::Endpoint) = ""
# url ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::headers][headers]]
headers(req::Endpoint) = defaultheaders(req)
defaultheaders(req::Endpoint) = ["Authorization" => "Bearer " * token(req)]
token(req::Endpoint) = req.token
# headers ends here

# [[file:~/repos/MatrixProtocolClient.jl/README.org::http-consts][http-consts]]
const base_path = ["/_matrix", "client", "r0"]
extend_path(extpath::AbstractVector{<:AbstractString}) =
    join(vcat(base_path, extpath), "/")
# http-consts ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::login-request][login-request]]
struct GetLogin <: Endpoint{:GET}
    host::String
end

headers(::GetLogin) = HTTP.Headers()
path(::GetLogin) = extend_path(["login"])
# login-request ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::login-request-process][login-request-process]]
struct GetLoginResponse{S <: AbstractString} <: Response{GetLogin}
	flows::Vector{S}
end#struct

import LazyJSON
const LJ = LazyJSON

function process_response(endpoint::GetLogin, resp::HTTP.Response)
	GetLoginResponse([i.type for i in LJ.value(String(resp.body)).flows])
end#function
# login-request-process ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::post-login][post-login]]
struct PostLogin <: Endpoint{:POST}
    host::String
end

"Return body for `POST` login request"
function (ep::PostLogin)(logintype::String; identifier=nothing, password=nothing,
                         token=nothing, device_id=nothing,
                         initial_device_display_name=nothing)
    # First check for valid input
    logintype in ("m.login.password", "m.login.token") || throw(DomainError(logintype))
    if logintype == "m.login.password" && isnothing(password)
        throw(DomainError(password,
                          "Password must be provided for \"m.login.password\""))
    end#if
    if logintype == "m.login.token" && isnothing(token)
        throw(DomainError(token,
                          "Token must be provided for \"m.login.token\""))
    end#if
end#function

headers(::PostLogin) = HTTP.Headers()
path(::PostLogin) = extend_path(["login"])
# post-login ends here

end#module
# MatrixHTTP.jl:1 ends here
