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

BASE_PATH = ["_matrix"; "client"; "r0"]

struct MatrixCredentials
    homeserver_url::String
    token::String
end

function register(homeserver_url::String;
                  guest::Bool=false,
                  auth::Dict{String, Any}=Dict{String, Any}(),
                  bind_email::Bool=false,
                  username::String="",
                  password::String="",
                  device_id::String="",
                  initial_device_display_name::String=""
                  )::Dict{String, Any}

    query_params = if guest
        Dict("kind" => "guest")
    else
        Dict("Kind" => "user")
    end

    body = Dict{String, Any}()
    body["auth"] = auth
    if bind_email
        body["bind_email"] = true
    end
    if length(username) > 0
        body["username"] = username
    end
    if length(password) > 0
        body["password"] = password
    end
    if length(device_id) > 0
        body["device_id"] = device_id
    end
    if length(initial_device_display_name) > 0
        body["initial_device_display_name"] = initial_device_display_name
    end

    temp_creds = MatrixCredentials(homeserver_url, "")
    endpoint = ["register"]
    call_endpoint("POST", endpoint, temp_creds, body=body,
                  query_params=query_params)
end

function call_endpoint(method::String, endpoint::Array{String, 1},
                       creds::MatrixCredentials;
                       body::Dict{String, Any}=Dict{String, Any}(),
                       query_params::Dict{String, String}=Dict{String, String}(),
                       headers::Dict{String, String}=Dict{String, String}(),
                       )::Dict{String, Any}
    path = "/" * join(cat(1, BASE_PATH, endpoint), "/")
    url = HTTP.URL(creds.homeserver_url, path=path, query=query_params)

    if length(creds.token) > 0
        headers["Authorization"] = "Bearer " * creds.token
    end
    if ! haskey(headers, "Content-Type")
        headers["Content-Type"] = "application/json"
    end

    body_dump = JSON.json(body)

    response = HTTP.post(url, body=body_dump, headers=headers)
    JSON.parse(String(response))
end

end # module
