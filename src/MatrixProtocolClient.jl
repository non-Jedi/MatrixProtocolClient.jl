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

# * MatrixProtocolClient

module MatrixProtocolClient

# ** Login
# Start building the client by simply creating a function that logs in
# to Matrix using a username and password. As we go, we will create
# types and helper functions as necessary and eventually refactor this
# into a sans-io version.

# First we need a type to represent a homeserver. Eventually,
# facilities will be built with this to allow .well-known discovery
# and other such features.

"Represents a homeserver."
struct HomeServer
    url::String
end

# Then we'll have a type to represent a request that can be made to
# the homeserver. This is the object that will be returned by
# functions in this module. In a separate MatrixHTTP module, we'll
# define a function for flinging these requests at the server and
# returning coherent responses.

const Param = Pair{String,String}

struct ClientRequest{B}
    homeserver::HomeServer
    endpoint::String
    method::String
    token::Union{String,Nothing}
    body::B
    params::Vector{Param}
end

"Represents a matrix identifier, e.g. m.id.user (UserIdentifier)."
abstract type Identifier end

# The login requests encapsulates the username or other user
# identifier into an identifier JSON object.

"""
    UserIdentifier(user)

Create an `m.id.user` object for `user`.

`user` should be either a fully-qualified Matrix user ID or the
localpart of an ID.
"""
struct UserIdentifier <: Identifier
    user::String
end

# LoginBody has all the required or optional fields for the body of a
# login request.

abstract type RequestBody end

struct LoginBody{I<:Identifier} <: RequestBody
    # TODO: this should be an enum limiting type to either
    # m.login.password or m.login.token
    type::String
    identifier::I
    # Fields that are nothing in an instance will have their keys not
    # included in the generated JSON.
    password::Union{String,Nothing}
    token::Union{String,Nothing}
    device_id::Union{String,Nothing}
    initial_device_display_name::Union{String,Nothing}
end

"""
    LoginBody(id, password; device_id=nothing, initial_device_display_name=nothing)

Represents the JSON body of a "m.login.password" request to login endpoint.
"""
function LoginBody(id::Identifier, password::AbstractString;
                   device_id=nothing, initial_device_display_name=nothing)
    LoginBody("m.login.password", id, String(password), nothing,
                   device_id, initial_device_display_name)
end

"""
    login(homeserver, username, password)

Logs into `homeserver` as `username` with `password`.
"""
function login(homeserver::AbstractString, username::AbstractString,
               password::AbstractString)
    # This function does not currently validate using GET
    # /_matrix/client/r0/login that "m.login.password" is supported by
    # homeserver.
    login(HomeServer(String(homeserver)), UserIdentifier(String(username)), password)
end

login(hs::HomeServer, id::UserIdentifier, password::AbstractString) =
    login(hs, LoginBody(id, password))

function login(hs::HomeServer, body::LoginBody)
    ClientRequest(hs, "login", "POST", nothing, body, Param[])
end

end#module
