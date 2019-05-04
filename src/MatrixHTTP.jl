# This file is part of MatrixProtocolClient.jl.

# MatrixProtocolClient.jl is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# MatrixProtocolClient.jl is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# * MatrixHTTP.jl
# Since the structure of an HTTP API is generally relatively
# declarative in nature, this module seeks to make the API definitions
# as declarative as possible. To that end, we will have a type
# representing each API endpoint ~<: Endpoint~ where an instance of
# the type represents the endpoint for a particular homeserver. HTTP
# request payloads will be represented as a simple container type with
# fields ~endpoint::(<:Endpoint)~, ~body::(<:RequestBody)~, and
# ~parameters::(<:Parameters)~.

module MatrixHTTP

# ** Abstract Types

export Request

abstract type Endpoint{M} end
abstract type RequestBody{E <: Endpoint} end
abstract type Parameters{E <: Endpoint} end

struct Request{E<:Endpoint, RB<:RequestBody{E}, P<:Parameters{E}}
    endpoint::E
    body::RB
    parameters::P
end#struct

abstract type Response{E <: Endpoint} end

# ** HTTP.jl integration
# Here we define how the set of types we created above are used to
# actually make an HTTP request using the HTTP.jl library.

import HTTP

export request

"""
    request(req::Request{E})::Response{E}

Makes the request contained in `req` using HTTP.jl and returns `Response`.
"""
function request(req::Request{E})::Response{E} where {E <: Endpoint}
    resp = let e=req.endpoint, b=req.body, p=req.parameters
        HTTP.request(method(e), url(e, p), headers(e), dump(b))
    end#let
    load(resp)
end#function

# The ~request~ method above defines the interface that must be defined
# for each endpoint:

# - ~method(::Endpoint)~
# - ~url(::Endpoint, ::Parameters)~ or both ~path(::Endpoint)~ and ~path(::Parameters)~
# - ~headers(::Endpoint)~
# - ~dump(::RequestBody)~

# We define a generic implementation of ~method~, ~url~, ~path~,
# ~headers~, and ~dump~ here so that none will be required for the
# simplest endpoint cases.

# Method will generally be encoded in the type paramter of ~Endpoint~
# since it doesn't vary across calls to the same endpoint.

method(::Endpoint{M}) where M = string(M)

# URL will be obtained by combining the base-url with a path specific
# to each endpoint.

const MATRIX_R0 = "/_matrix/client/r0/"

url(e::Endpoint, p::Parameters) = HTTP.URI(; scheme="https", host=e.host,
                                           path=MATRIX_R0*path(e), query=path(p))

# Unless otherwise specified, no query parameters are needed.

path(::Parameters) = Pair{String,String}[]

# In general the only header needed is the token which will assume to
# be stored in a ~token~ field on the ~Endpoint~ object.

headers(e::Endpoint) = ("Authorization" => "Bearer " * e.token, )

# When requesting with =GET=, the request body should be empty. We
# treat that as the default case for ~<:RequestBody{:GET}~.

dump(::RequestBody{<:Endpoint{:GET}}) = ""

end#module MatrixHTTP
