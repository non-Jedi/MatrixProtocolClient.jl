#=
Copyright 2017 Adam Beckmeyer

This file is part of MatrixClientProtocol.jl.

MatrixClientProtocol.jl is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

MatrixClientProtocol.jl is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
MatrixClientProtocol.jl. If not, see <http://www.gnu.org/licenses/>.
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
senum(a::Vector{String}, i::Enum) = a[Int(i)+1]

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

abstract type MatrixJSONStruct end
abstract type MatrixRequestStruct{T}<:MatrixJSONStruct end
abstract type MatrixResponseStruct<:MatrixJSONStruct end
abstract type MatrixNestedStruct<:MatrixJSONStruct end

# User-Interactive Auth
#-------------------------------------------------------------------------------

struct InteractiveStages <: MatrixNestedStruct
    stages::Vector{String}
end

struct InteractiveResponse <: MatrixResponseStruct
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
@typestruct struct LoginParameters <: MatrixRequestStruct{:Get}
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
struct LoginResponse <: MatrixResponseStruct
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

@typestruct struct AuthenticationData <: MatrixNestedStruct
    typ::String
    session::MS
end#struct

struct RegisterParameters <: MatrixRequestStruct{:Post}
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

# GET /account/whoami endpoint
#-------------------------------------------------------------------------------

struct WhoamiResponse
    user_id::String
end

# POST /user/{userid}/filter
#-------------------------------------------------------------------------------

struct Filter
    limit::MI
    not_senders::Maybe{Vector{String}}
    not_types::Maybe{Vector{String}}
    senders::Maybe{Vector{String}}
    types::Maybe{Vector{String}}
end

struct RoomEventFilter
    limit::MI
    not_senders::Maybe{Vector{String}}
    not_types::Maybe{Vector{String}}
    senders::Maybe{Vector{String}}
    types::Maybe{Vector{String}}
    not_rooms::Maybe{Vector{String}}
    rooms::Maybe{Vector{String}}
    contains_url::MB
end

struct RoomFilter
    not_rooms::Maybe{Vector{String}}
    rooms::Maybe{Vector{String}}
    ephemeral::Maybe{RoomEventFilter}
    include_leave::MB
    state::Maybe{RoomEventFilter}
    timeline::Maybe{RoomEventFilter}
    account_data::Maybe{RoomEventFilter}
end

struct FilterParameters
    event_fields::Maybe{Vector{String}}
    event_format::MS
    presence::Maybe{Filter}
    account_data::Maybe{Filter}
    room::Maybe{RoomFilter}
end

struct FilterIDResponse
    filter_id::String
end

# GET /user/{userid}/filter/{filterId} endpoint
#-------------------------------------------------------------------------------

# No JSON needed in request body

FilterResponse = FilterParameters

# GET /sync endpoint
#-------------------------------------------------------------------------------

# TODO: figure out how to have RedactEvent as field in Unsigned when RedactEvent also Unsigned field
struct Unsigned
    age::Int64
    prev_content::Maybe{Dict{String,Any}}
    transaction_id::MS
#    redacted_because::Maybe{RedactEvent}
end

abstract type AbstractEvent end
abstract type AbstractEvents{E<:AbstractEvent} end

for ev in [:EphemeralEvent,
           :TimelineEvent,
           :PresenceEvent,
           :AccountDataEvent,
#           :RedactEvent,
]
    ex = quote
        struct $ev <: AbstractEvent
            event_id::MS
            content::Dict{String,Any}
            origin_server_ts::Int64
            sender::String
            typ::String
            unsigned::Unsigned
        end#struct
    end#quote
    eval(ex)
end#for

struct StateEvent <: AbstractEvent
    event_id::MS
    content::Dict{String,Any}
    origin_server_ts::Int64
    sender::String
    state_key::String
    typ::String
    unsigned::Unsigned
end

struct InviteState <: AbstractEvents{StateEvent}
    events::Vector{StateEvent}
end

struct State <: AbstractEvents{StateEvent}
    events::Vector{StateEvent}
end

struct Timeline <: AbstractEvents{TimelineEvent}
    events::Vector{TimelineEvent}
    limited::Bool
    prev_batch::String
end

struct Ephemerals <: AbstractEvents{EphemeralEvent}
    events::Vector{EphemeralEvent}
end

struct AccountData <: AbstractEvents{AccountDataEvent}
    events::Vector{AccountDataEvent}
end

struct Presence <: AbstractEvents{PresenceEvent}
    events::Vector{PresenceEvent}
end

struct UnreadNotificationCounts
    highlight_count::Int64
    notification_count::Int64
end

abstract type AbstractRoom end

struct JoinedRoom <: AbstractRoom
    state::State
    timeline::Timeline
    ephemeral::Ephemerals
    account_data::AccountData
    unread_notifications::UnreadNotificationCounts
end

struct InvitedRoom <: AbstractRoom
    invite_state::InviteState
end

struct LeftRoom <: AbstractRoom
    state::State
    timeline::Timeline
end

struct Rooms
    join::Dict{String,JoinedRoom}
    invite::Dict{String,InvitedRoom}
    leave::Dict{String,LeftRoom}
end

struct Sync
    next_batch::String
    rooms::Rooms
    presence::Presence
    account_data::AccountData
    # TODO: Implement ToDevice extension to /sync
#    to_device::ToDevice
    # TODO: Implement DeviceLists from E2E section
#    device_lists::DeviceLists
end

# errors
#-------------------------------------------------------------------------------

struct MatrixError
    errcode::String
    error::MS
end

end # module
