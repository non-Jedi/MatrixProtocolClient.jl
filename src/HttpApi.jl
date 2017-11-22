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
module HttpApi

import HTTP
import JSON
import Base.Enums

# Export all necessary functions
export MatrixCredentials
export register, login, send_state, send_event, redact_event, create_room
export matrix_send

# Export enums needed to call functions
export HTTPget, HTTPput, HTTPpost
export publicvisibility, privatevisibility
export private_chat, trusted_private_chat, public_chat

"""
This matrix SDK uses the [r0.3.0 version of the matrix spec exclusively](
https://matrix.org/docs/spec/client_server/r0.3.0.html)
"""
const BASE_PATH = Array{String,1}(["_matrix"; "client"; "r0"])

"Query parameters can be either a string or multiple strings"
QueryParamsTypes = Union{String, Array{String,1}}

"Enum for the valid HTTP methods used to send matrix requests"
Enums.@enum HttpMethod HTTPget HTTPput HTTPpost

"Struct with data needed to auth with matrix server"
struct MatrixCredentials
    homeserver_url::String
    token::String
end

function MatrixCredentials(homeserver_url::String, json::Dict{String,Any})
    MatrixCredentials(homeserver_url, json["access_token"])
end

"Struct with data needed to make a matrix request"
struct MatrixRequest{T<:Union{Dict{String,Any}}}
    method::HttpMethod
    endpoint::Array{String,1}
    credentials::MatrixCredentials
    body::T
    query_params::Dict{String,QueryParamsTypes}
    headers::Dict{String,String}
end

"""
    register(homeserver_url[, guest[, auth]]; <keyword arguments>)

Return MatrixRequest calling POST `/register`.

# Arguments
- `homeserver_url::String`: URL of homeserver to register with.
- `guest::Bool=false`: whether to register as a guest user.
- `auth::Dict{String,Any}`: additional auth info for user-interactive auth.
- `bind_email::Bool`=false: whether to bind email used for auth to Matrix ID.
- `username::String`: localpart of the desired Matrix ID.
- `password::String`: desired password for the account.
- `device_id::String`: ID of the client device.
- `initial_device_display_name::String`: display name for newly created device.
"""
function register(homeserver_url::String, guest::Bool=false,
                  auth::Dict{String,Any}=Dict{String,Any}();
                  bind_email::Bool=false,
                  username::String="", password::String="",
                  device_id::String="", initial_device_display_name::String=""
                  )::MatrixRequest{Dict{String,Any}}

    query_params = if guest
        Dict{String,QueryParamsTypes}("kind" => "guest")
    else
        Dict{String,QueryParamsTypes}("kind" => "user")
    end

    body = Dict{String,Any}()
    setvalueiflength!(body, "auth", auth)
    body["bind_email"] = bind_email
    setvalueiflength!(body, "username", username)
    setvalueiflength!(body, "password", password)
    setvalueiflength!(body, "device_id", device_id)
    setvalueiflength!(body, "initial_device_display_name", initial_device_display_name)

    temp_creds = MatrixCredentials(homeserver_url, "")
    endpoint = Array{String,1}(["register"])
    MatrixRequest(HTTPpost, endpoint, temp_creds,
                  body, query_params, Dict{String,String}())
end

"""
    login(homeserver_url, login_type[, user[, password]]; <keyword arguments>)

Return MatrixRequest calling POST `/login`.

# Arguments
- `homeserver_url::String`: URL of homeserver to login to.
- `login_type::String`: login type being used (e.g. `m.login.password`).
- `user::String`: user ID or localpart to login.
- `password::String`: user's password if `login_type` is `m.login.password`.
- `token::String`: the login token if `login_type` is `m.login.token`.
- `medium::String`: medium of identifier if logging in with 3pid (must be "email").
- `address::String`: 3pid for the user (supplied instead of `user`).
- `device_id::String`: ID of the client device.
- `initial_device_display_name::String`: display name for newly created device.
"""
function login(homeserver_url::String, login_type::String,
               user::String="", password::String="";
               token::String="",
               medium::String="", address::String="",
               device_id::String="", initial_device_display_name::String=""
               )::MatrixRequest{Dict{String,Any}}
    body = Dict{String,Any}()
    body["type"] = login_type
    setvalueiflength!(body, "user", user)
    setvalueiflength!(body, "password", password)
    setvalueiflength!(body, "medium", medium)
    setvalueiflength!(body, "address", address)
    setvalueiflength!(body, "token", token)
    setvalueiflength!(body, "device_id", device_id)
    setvalueiflength!(body, "initial_device_display_name", initial_device_display_name)

    temp_creds = MatrixCredentials(homeserver_url, "")
    endpoint = Array{String,1}(["login"])
    MatrixRequest(HTTPpost, endpoint, temp_creds, body,
                  Dict{String,QueryParamsTypes}(), Dict{String,String}())
end

"""
    send_state(credentials, roomid, eventtype, body, statekey="")

Return `MatrixRequest` calling PUT `/rooms/{roomId}/state/{eventType}/{stateKey}`

Calls to this endpoint send a state event of `eventtype` to room, `roomid`, with
body, `body`. State events are overwritten by server if `roomid`, `eventtype`,
and `statekey` all match an existing state event.
"""
function send_state(credentials::MatrixCredentials, roomid::String,
                    eventtype::String, body::Dict{String,Any};
                    statekey::String=""
                   )::MatrixRequest{Dict{String,Any}}
    endpoint = Array{String,1}(["rooms"; roomid; "state"; eventtype; statekey])
    MatrixRequest(HTTPput, endpoint, credentials, body,
                  Dict{String,QueryParamsTypes}(), Dict{String,String}())
end

"""
    send_event(credentials, roomid, eventtype, body, txnid)

Return `MatrixRequest` calling PUT `/rooms/{roomId}/send/{eventType}/{txnId}`

Calls to this endpoint send an event of `eventtype` to room, `roomid`, with
body, `body`. The `txnid` should be a string unique to the given credentials to
ensure idempotency.
"""
function send_event(credentials::MatrixCredentials, roomid::String,
                    eventtype::String, body::Dict{String,Any}, txnid::String
                    )::MatrixRequest{Dict{String,Any}}
    endpoint = Array{String,1}(["rooms"; roomid; "send"; eventtype; txnid])
    MatrixRequest(HTTPput, endpoint, credentials, body,
                  Dict{String,QueryParamsTypes}(), Dict{String,String}())
end

"""
    redact_event(credentials, roomid, eventid, txnid, reason="")

Return `MatrixRequest` for calling PUT `/rooms/{roomId}/redact/{eventId}/{txnId}`

Calls to this endpoint "redact" the message, `eventid` from room `roomid` for
`reason`. A redacted message should be stripped by server of all keys other
than:

- "event_id"
- "type"
- "room_id"
- "sender"
- "state_key"
- "prev_content"
- "content"

The `txnid` should be a string unique to the given credentials to ensure
idempotency.
"""
function redact_event(credentials::MatrixCredentials, roomid::String,
                      eventid::String, txnid::String, reason::String=""
                      )::MatrixRequest{Dict{String,Any}}
    endpoint = Array{String,1}(["rooms"; roomid; "redact"; eventid; txnid])
    body = Dict{String,Any}()
    setvalueiflength!(body, "reason", reason)
    MatrixRequest(HTTPput, endpoint, credentials, body,
                  Dict{String,QueryParamsTypes}(), Dict{String,String}())
end

Enums.@enum RoomVisibility publicvisibility privatevisibility novisibility
Enums.@enum RoomPreset private_chat trusted_private_chat public_chat no_preset

"""
    create_room(credentials[, preset::RoomPreset]; <keyword arguments>)

Return `MatrixRequest` for calling POST `/createRoom`

Calls to this endpoint create a room using `credentials`.

# Arguments
- `preset::RoomPreset`: room settings preset (automatically sets other
  settings). Must be one of `private_chat`, `trusted_private_chat`, or
  `public_chat` if set.
- `room_alias_name::String`: localpart for desired room alias.
- `name::String`: name for `m.room.name` event in new room.
- `topic::String`: topic for `m.room.topic` event in new room.
- `visibility::RoomVisibility`: one of `publicvisibility` or `privatevisibility`.
  specifies whether room will be shown in published room list.
- `invite::Array{String,1}`: array of user ids to invite to the room.
- `invite_3pid::Array{Dict{String,String}}`: array of objects representing 3pids
  to invite to the room. Object will have following keys:
  - "id_server": the hostname+port of the identity server used for 3pid lookups.
  - "medium": the kind of address being passed in address field.
  - "address": the invitee's third party identifier.
- `creation_content::Dict{String,Any}`: extra keys to be added to the content of
  `m.room.create` event. Only key that can be used right now is "creator".
- `initial_state::Array{Dict{String,Any}}`: an array of state events to set in
  the new room. Objects in array should be dicts with keys:
  - "type"
  - "state_key"
  - "content" => ::Dict{String,Any}
- `is_direct::Bool=false`: whether the "is_direct" flag should be set.
"""
function create_room(credentials::MatrixCredentials,
                     preset::RoomPreset=no_preset;
                     room_alias_name::String="",
                     name::String="", topic::String="",
                     visibility::RoomVisibility=novisibility,
                     invite::Array{String,1}=Array{String,1}(),
                     invite_3pid::Array{Dict{String,String},1}=
                         Array{Dict{String,String},1}(),
                     creation_content::Dict{String,Any}=Dict{String,Any}(),
                     initial_state::Array{Dict{String,Any}}=
                         Array{Dict{String,Any}}(),
                     is_direct::Bool=false
                     )::MatrixRequest{Dict{String,Any}}
    body = Dict{String,Any}()
    # Deal with enums first
    if visibility != novisibility
        body["visibility"] = if visibility == publicvisibility
            "public"
        elseif visibility == privatevisibility
            "private"
        else
            "private"
        end
    end
    if preset != no_preset
        body["preset"] = if preset == private_chat
            "private_chat"
        elseif preset == trusted_private_chat
            "trusted_private_chat"
        elseif preset == public_chat
            "public_chat"
        else
            "private_chat"
        end
    end
    # Then deal with rest of body parameters
    setvalueiflength!(body, "room_alias_name", room_alias_name)
    setvalueiflength!(body, "name", name)
    setvalueiflength!(body, "topic", topic)
    setvalueiflength!(body, "invite", invite)
    setvalueiflength!(body, "invite_3pid", invite_3pid)
    setvalueiflength!(body, "creation_content", creation_content)
    body["is_direct"] = is_direct

    endpoint = Array{String,1}(["createRoom"])
    MatrixRequest(HTTPpost, endpoint, credentials, body,
                  Dict{String,QueryParamsTypes}(), Dict{String,String}())
end

"""
    matrix_send(request::MatrixRequest)::Dict{String,Any}

Returns the body from making the specified matrix request.

If request doesn't specify a `Content-Type` header, this function will add
one with value `application/json`.
"""
function matrix_send(request::MatrixRequest{Dict{String,Any}})::Dict{String,Any}
    path = "/" * join(cat(1, BASE_PATH, request.endpoint)::Array{String,1}, "/")
    url = HTTP.URL(request.credentials.homeserver_url, path=path,
                   query=request.query_params)

    if length(request.credentials.token) > 0
        request.headers["Authorization"] = "Bearer " * request.credentials.token
    end
    if ! haskey(request.headers, "Content-Type")
        request.headers["Content-Type"] = "application/json"
    end

    json_body = JSON.json(request.body)
    response::HTTP.Response = if HTTPpost == request.method
        HTTP.post(url, body=json_body, headers=request.headers)::HTTP.Response
    elseif HTTPget == request.method
        HTTP.get(url, body=json_body, headers=request.headers)::HTTP.Response
    elseif HTTPput == request.method
        HTTP.put(url, body=json_body, headers=request.headers)::HTTP.Response
    else
        # This can't happen since all enum cases are handled above
        HTTP.Response(400, "{}")::HTTP.Response
    end

    JSON.parse(String(response))
end

"Sets `body[key]` to `key_value` if length(key_value) > 0"
function setvalueiflength!(body::Dict{String,Any}, key::String, key_value::Any)
    if length(key_value) > 0
        body[key] = key_value
    end
end

end # module
