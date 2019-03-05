# [[file:~/repos/MatrixProtocolClient.jl/README.org::*MatrixHTTP.jl][MatrixHTTP.jl:1]]
module MatrixHTTP

# [[file:~/repos/MatrixProtocolClient.jl/README.org::matrix-type][matrix-type]]
abstract type Endpoint{M} end

abstract type Response{E <: Endpoint} end
# matrix-type ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::matrix-request][matrix-request]]
import HTTP

export request

"""
    request(::Endpoint)::Response

Calls a matrix endpoint and returns a processed response.
"""
function request(req::T)::Response{T} where {T <: Endpoint}
    res = HTTP.request(method(req), url(req), headers(req), body(req))
    # We expect different response formats depending on details of request
    process_response(req, res)
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
# [[file:~/repos/MatrixProtocolClient.jl/README.org::body][body]]
body(::Endpoint) = Vector{UInt8}()
# body ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::http-consts][http-consts]]
const base_path = ["/_matrix", "client", "r0"]
extend_path(extpath::AbstractVector{<:AbstractString}) =
    join(vcat(base_path, extpath), "/")
# http-consts ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::login-request][login-request]]
struct GetLogin <: Endpoint{:GET}
    host::String
end

headers(::GetLogin) = Pair{String,String}[]
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

end#module
# MatrixHTTP.jl:1 ends here
