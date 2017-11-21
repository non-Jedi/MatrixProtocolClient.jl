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

module HttpApi

import HTTP
import JSON
import Base.Enums

export register, login, send_state, send_event, redact_event, matrix_send
export HTTPget, HTTPput, HTTPpost
export publicvisibility, privatevisibility

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

Return MatrixRequest for calling POST `/register`.

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
    if length(auth) > 0
        body["auth"] = auth
    end
    body["bind_email"] = bind_email
    if username != ""
        body["username"] = username
    end
    if password != ""
        body["password"] = password
    end
    if device_id != ""
        body["device_id"] = device_id
    end
    if initial_device_display_name != ""
        body["initial_device_display_name"] = initial_device_display_name
    end

    temp_creds = MatrixCredentials(homeserver_url, "")
    endpoint = Array{String,1}(["register"])
    MatrixRequest(HTTPpost, endpoint, temp_creds,
                  body, query_params, Dict{String,String}())
end

"""
    login(homeserver_url, login_type[, user[, password]]; <keyword arguments>)

Return MatrixRequest for calling POST `/login`.

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
    if user != ""
        body["user"] = user
    end
    if password != ""
        body["password"] = password
    end
    if medium != ""
        body["medium"] = medium
    end
    if address != ""
        body["address"] = address
    end
    if token != ""
        body["token"] = token
    end
    if device_id != ""
        body["device_id"] = device_id
    end
    if initial_device_display_name != ""
        body["initial_device_display_name"] = initial_device_display_name
    end

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
    body = if reason == ""
        Dict{String,Any}()
    else
        body = Dict{String,Any}("reason" => reason)
    end
    MatrixRequest(HTTPput, endpoint, credentials, body,
                  Dict{String,QueryParamsTypes}(), Dict{String,String}())
end

Enums.@enum RoomVisibility publicvisibility privatevisibility

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

end # module
