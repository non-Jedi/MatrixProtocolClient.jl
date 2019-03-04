# [[file:~/repos/MatrixProtocolClient.jl/README.org::*MatrixHTTP.jl][MatrixHTTP.jl:1]]
module MatrixHTTP

# [[file:~/repos/MatrixProtocolClient.jl/README.org::matrix-type][matrix-type]]
abstract type MatrixRequest{M} end

abstract type MatrixResponse end
# matrix-type ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::matrix-request][matrix-request]]
import HTTP

export request

"""
    request(::MatrixRequest)::MatrixResponse

Calls a matrix endpoint and returns a processed response.
"""
function request(req::MatrixRequest)::MatrixResponse
    res = HTTP.request(method(req), url(req), headers(req), body(req))
    # We expect different response formats depending on details of request
    process_response(req, res)
end#function
# matrix-request ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::method][method]]
function method(req::MatrixRequest{M})::AbstractString where {M}
    if M in (:GET, :HEAD, :POST, :PUT, :DELETE, :TRACE, :OPTIONS, :CONNECT, :PATCH)
        string(M)
    else
        throw(DomainError(M, "Not a valid HTTP method."))
    end#if
end#function
# method ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::url][url]]
import HTTP.URIs: URI

url(req::MatrixRequest)::URI =
    URI(; scheme="https", host=req.host, path=path(req), query=query(req))
query(::MatrixRequest) = ""
# url ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::headers][headers]]
headers(req::MatrixRequest) = defaultheaders(req)
defaultheaders(req::MatrixRequest) = ["Authorization" => "Bearer " * token(req)]
token(req::MatrixRequest) = req.token
# headers ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::body][body]]
body(::MatrixRequest) = Vector{UInt8}()
# body ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::http-consts][http-consts]]
const base_path = ["/_matrix", "client", "r0"]
extend_path(extpath::AbstractVector{<:AbstractString}) =
    join(vcat(base_path, extpath), "/")
# http-consts ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::login-request][login-request]]
struct GetLogin <: MatrixRequest{:GET}
    host::String
end

headers(::GetLogin) = Pair{String,String}[]
path(::GetLogin) = extend_path(["login"])
# login-request ends here

end#module
# MatrixHTTP.jl:1 ends here
