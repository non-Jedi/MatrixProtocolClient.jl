# [[file:~/repos/MatrixProtocolClient.jl/README.org::*Login][Login:8]]
module MatrixHTTP

# [[file:~/repos/MatrixProtocolClient.jl/README.org::matrix-type][matrix-type]]
struct MatrixType{T} end

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
    URI(; host=req.homeserver, path=req.path, query=query(req))
path(req::MatrixRequest) = req.path
query(::MatrixRequest) = ""
# url ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::headers][headers]]
headers(req::MatrixRequest) = defaultheaders(req)
defaultheaders(req::MatrixRequest) = ("Authorization" => "Bearer " * token(req),)
token(req::MatrixRequest) = req.token
# headers ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::body][body]]
body(::MatrixRequest) = Vector{UInt8}()
# body ends here
# [[file:~/repos/MatrixProtocolClient.jl/README.org::process_response][process_response]]
import JSON2

function process_response(req::MatrixRequest, res::HTTP.Response)
    # TODO: error handling for failure to parse
    JSON2.read(String(res.body), response_type(req))
end#function

response_type(::MatrixRequest) = NamedTuple
# process_response ends here

end#module
# Login:8 ends here
