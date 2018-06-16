#=
Copyright 2017 Adam Beckmeyer

This file is part of MatrixClient.jl.

MatrixClient.jl is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

MatrixClient.jl is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
MatrixClient.jl. If not, see <http://www.gnu.org/licenses/>.
=#

__precompile__()
module MatrixTypes

import Base: Enums
import Missings: Missing

# first define useful functions/macros
#-------------------------------------------------------------------------------

# lightweight alternative to Nullable
"May or may not contain a value of type T"
Maybe{T} = Union{Missing,T}

# These will be needed for long-winded parametric types
MS = Maybe{String}
MI = Maybe{Int64}
MF = Maybe{Float64}
MB = Maybe{Bool}
"JSON number might be either Float or Int"
JSONNumber = Union{Float64,Int64}

# since enums start at 0, add one to enum
"Map a numerical enum to an Array of strings."
senum(a::Array{String,1}, i::Enum) = a[Int(i)+1]

"Create a struct with field named `type` (substitutes for `typ`)"
macro typestruct(ex)
    if ex.head == :type
        for (j, b) in enumerate(ex.args[3].args)
            if b.head == :(::) && b.args[1] == :typ
                ex.args[3].args[j].args[1] = :type
            end#if
        end#for
    else
        ex = :(throw(ArgumentError("Must pass struct expression to @typestruct")))
    end#if
    ex
end#macro

# User-Interactive Auth
#-------------------------------------------------------------------------------

struct InteractiveStages
    stages::Vector{String}
end

struct InteractiveResponse
    flows::Vector{InteractiveStages}
    params::Dict{String,Any}
    session::String
end

# /login endpoint
#-------------------------------------------------------------------------------

# request

@enum LoginType password token
const LoginTypeS = ["m.login.password", "m.login.token"]

"JSON body to send to /login. `type` must be in `LoginTypeS`"
@typestruct struct LoginParameters
    typ::String
    user::MS
    medium::MS
    address::MS
    password::MS
    token::MS
    device_id::MS
    initial_device_display_name::MS
end

# response

"JSON body reply from /login"
struct LoginResponse
    user_id::String
    access_token::String
    device_id::String
end

# /logout endpoint
#-------------------------------------------------------------------------------

# no parameters

# /register endpoint
#-------------------------------------------------------------------------------

# request

@typestruct struct AuthenticationData
    typ::String
    session::MS
end#struct

struct RegisterParameters
    auth::Maybe{AuthenticationData}
    bind_email::MB
    username::MS
    password::MS
    device_id::MS
    initial_device_display_name::MS
end

# response

# no different than login for 200

RegisterResponse = LoginResponse
Register401Response = InteractiveResponse

# /register/email/requestToken endpoint
#-------------------------------------------------------------------------------

struct EmailRequestTokenParameters
    id_server::MS
    client_secret::String
    email::String
    send_attempt::JSONNumber
end

# /account/password endpoint
#-------------------------------------------------------------------------------

struct ChangePasswordParameters
    new_password::String
    auth::Maybe{AuthenticationData}
end

# /account/deactivate endpoint
#-------------------------------------------------------------------------------

struct DeactivateParameters
    auth::Maybe{AuthenticationData}
end

Deactivate401Response = InteractiveResponse

# GET /account/3pid endpoint
#-------------------------------------------------------------------------------

struct ThirdPartyIdentifier
    medium::String
    address::String
end

struct ThirdPartyIdentifiersResponse
    threepids::Vector{ThirdPartyIdentifier}
end

# POST /account/3pid endpoint
#-------------------------------------------------------------------------------

struct ThreePidCredentials
    client_secret::String
    id_server::String
    sid::String
end

struct ThirdPartyIdentifierParameters
    three_pid_creds::ThreePidCredentials
    bind::MB
end

# POST /account/3pid/email/requestToken endpoint
#-------------------------------------------------------------------------------

# No types or parameters

# errors
#-------------------------------------------------------------------------------

struct MatrixError
    errcode::String
    error::MS
end

end # module
