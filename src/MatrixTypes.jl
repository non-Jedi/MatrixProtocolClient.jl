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
MS = Maybe{AbstractString}
MI = Maybe{Integer}
MF = Maybe{AbstractFloat}
MB = Maybe{Bool}

# since enums start at 0, add one to enum
"Map a numerical enum to an Array of strings."
senum(a::Array{String,1}, i::Enum) = a[Int(i)+1]

"Create a struct with field named `type` (substitutes for `typ`)"
macro typestruct(ex)
    if ex.head == :type
        for (j, b) in enumerate(ex.args[3].args)
            if b.head == :(::) && b.args[1] == :typ
                ex.args[3].args[j].args[1] = :type
            end
        end
    else
        ex = :(throw(ArgumentError("Must pass struct expression to @typestruct")))
    end
    ex
end

# /login endpoint
#-------------------------------------------------------------------------------

# request

@enum LoginType password token
const LoginTypeS = ["m.login.password", "m.login.token"]

"JSON body to send to /login. `type` must be in `LoginTypeS`"
@typestruct struct LoginParameters{A<:MS,B<:MS,C<:MS,D<:MS,E<:MS,F<:MS,G<:MS}
    typ::String
    user::A
    medium::B
    address::C
    password::D
    token::E
    device_id::F
    initial_device_display_name::G
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

@typestruct struct AuthenticationData{S<:MS}
    typ:String
    session::S
end

struct RegisterParameters{A<:Maybe{AuthenticationData},B<:MB,C<:MS,D<:MS,E<:MS,F<:MS}
    auth::A
    bind_email::B
    username::C
    password::D
    device_id::E
    initial_device_display_name::F
end

# response

# no different than login for 200

RegisterResponse = LoginResponse
Register401Response = InteractiveResponse

# /register/email/requestToken endpoint
#-------------------------------------------------------------------------------

struct EmailRequestTokenParameters{A<:MS,B<:Number}
    id_server::A
    client_secret::String
    email::String
    send_attempt::B
end

# /account/password endpoint
#-------------------------------------------------------------------------------

struct ChangePasswordParameters{A<:Maybe{AuthenticationData}}
    new_password::String
    auth::A
end

# /account/deactivate endpoint
#-------------------------------------------------------------------------------

struct DeactivateParameters{A<:Maybe{AuthenticationData}}
    auth::A
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

struct ThirdPartyIdentifierParameters{B<:MB}
    three_pid_creds::ThreePidCredentials
    bind::B
end

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

# errors
#-------------------------------------------------------------------------------

struct MatrixError{E<:MS}
    errcode::String
    error::E
end

end # module
